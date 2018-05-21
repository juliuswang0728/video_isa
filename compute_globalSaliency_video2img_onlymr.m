function [] = compute_globalSaliency_video2img_onlymr(video_idx, tpsize, tpsize2, sigma)
% compute the global saliency using the network features and Graphs.
% for video files
%sigma = 0.1;       % {0.01, 0.01, 0.1}
%video_idx = 12;    % [1, 24], from 1 to 24
%tpsize = 7;        % {5, 7}
%tpsize2 = 7;       % {5, 7}
addpath('tools/ojwoodford-sc-79bee53'); % for adding sc functions
addpath('videos/ACCV2012_database/'); % for adding ground truth extraction functions
addpath('videos/ACCV2012_database/confidence-interval-AUC');

global basesPath
%global image_canonical_size
%global color_space
%filename = sprintf('videos/video%d.mp4', video_idx);
%[pathstr, name, ext] = fileparts(filename);
fileroot = sprintf('videos/video%d', video_idx);
filepath = sprintf('%s/*.jpg', fileroot);
filelist = dir(filepath);

%% parameters for calculating functions relevant to saliency
gamma = 0.05;   % global saliency
alpha = 0.0;    % local saliency
setup_globalSetting();
params = set_params(tpsize, tpsize2); % set the system parameters
net = setup_network(params, basesPath, 1, [1, 2]);
max_sp_size = net.layer{end}.fovea.spatial_size;
max_tp_size = net.layer{end}.fovea.temporal_size;
%max_sp_stride = params.stride{end}.spatial_stride;
max_sp_stride = 16;
max_tp_stride = params.stride{end}.temporal_stride;

num_skipped_frames = 0; % number of frames we skip when doing sampling
multi_res_sf = sqrt(2);  % scaling factor (for downsampling) of the original frame size
multi_res_num = 3;      % how many lower-resoluted layers
multi_res_init_scale = 1 / sqrt(2); % initial scale
%%
% load ground truth saliency map
gt_filename = strcat('videos/ACCV2012_database/raw_data/raw_data_video', num2str(video_idx),'.mat');
load(gt_filename)
num_frames_eval = [878 125 627 125 834 37 462 150 881 466 1142 103 888 71 950 113 785 113 240 113 749 31 143 154];
idx = 1;
frame_count = 1;

% se, se2, level are used in processing ground-truth map
% provided by ASCMN dataset
se = strel('ball',4,2);
se2 = strel('rectangle',[12 2]);
level = 0.7;

sampled_chunks = zeros(max_sp_size^2 * 3 * max_tp_size, 1200, 'single');
% resizing for preventing some artifact near image borders
filename = sprintf('%s/%s', fileroot, filelist(1).name);
dummy_img = imread(filename);
frame_height = size(dummy_img, 1);
frame_width = size(dummy_img, 2);

save_idx = 1;
for i=1:multi_res_num
    multi_res{i}.sampled_chunks = zeros(max_sp_size^2 * 3 * max_tp_size, 1200, 'single');
    multi_res{i}.scaling_factor = multi_res_init_scale * multi_res_sf ^ (i - 1);
end

for i=1:multi_res_num
    multi_res{i}.width = frame_width / multi_res{i}.scaling_factor;
    multi_res{i}.height = frame_height / multi_res{i}.scaling_factor;
    % resizing for preventing some artifact near image borders
    multi_res{i}.width = ceil(multi_res{i}.width / max_sp_size) * max_sp_size;
    multi_res{i}.height = ceil(multi_res{i}.height / max_sp_size) * max_sp_size;
    multi_res{i}.X = zeros(max_tp_size, multi_res{i}.height, multi_res{i}.width, 3, 'single');
end

CCs = zeros(num_frames_eval(video_idx), 1);
NSSs = zeros(num_frames_eval(video_idx), 1);
KLDIVs = zeros(num_frames_eval(video_idx), 1);
AUROCs = zeros(num_frames_eval(video_idx), 1);

for i=1:multi_res_num
    if multi_res{i}.scaling_factor == 1
        ori_res_idx = i;
        break;
    end     
end

% generate center-biased saliency map
sigma = abs(sigma);
is_cb = false;
if sigma > 0.001
    is_cb = true;
    saliency_cb = generate_center_biased_map(frame_width, frame_height, sigma);
end

for img_idx=1:length(filelist)
    filename = sprintf('%s/%s', fileroot, filelist(img_idx).name);
    frame_count = frame_count + 1;
    if mod(frame_count, 500) == 1
        fprintf('processed [%d] frames...\n', frame_count);
    end
    % also skip first some frames which are usually blank
    if mod(frame_count, (num_skipped_frames + 1)) == 1
        % if num_skipped_frames = 1, only even frames are sampled (0, 2, 4, ...)
        %readFrame(video);
        continue
    end
    current_frame = imread(filename);
    %current_frame = readFrame(video);
    current_frame = im2single(current_frame);
    
    for i=1:multi_res_num
        multi_res{i}.X(idx, :, :, :) = imresize(current_frame, ...
                            [multi_res{i}.height multi_res{i}.width]);
    end
    
    if idx >= max_tp_size
        % now we have enough frames to sample from
        
        saliency_map_idx = floor(idx / 2) + 1;
        corresponding_frame_idx = frame_count - 1 - (max_tp_size - saliency_map_idx);
        % we take 1 to idx frames, and compute the saliency map for
        % (saliency_map_idx)-th frame
        current_frame = squeeze(multi_res{ori_res_idx}.X(saliency_map_idx, :, :, :));
        
        for i=1:multi_res_num
            [multi_res{i}.sampled_chunks, col_new, row_new] = conv_temporal_sampling(...
                multi_res{i}.X, multi_res{i}.sampled_chunks, ...
                max_tp_size, max_sp_size, max_sp_stride);
            
            % discard the first n frames, n is stride here
            multi_res{i}.X(1:max_tp_size-max_tp_stride, :, :, :) = multi_res{i}.X(1+max_tp_stride:max_tp_size, :, :, :);
            multi_res{i}.X(max_tp_size-max_tp_stride+1, :, :, :) = 0;
            idx = max_tp_size - max_tp_stride;

            % compute saliency map for this frame based on this and previously
            % 12 frames
            multi_res{i}.result = network_response(multi_res{i}.sampled_chunks, net);
            
            multi_res{i}.feature = [multi_res{i}.result{2}.reduced_output; ...
                                    multi_res{i}.result{1}.reduced_output]';
            multi_res{i}.feature = bsxfun(@rdivide, multi_res{i}.feature, ...
                                    sqrt(sum(multi_res{i}.feature.^2))); % L2 normalize
            % local saliency, better to make S and E to be in the same shape
            S = alpha + 0.5 * sum(multi_res{i}.feature.^2, 2)';
            S = ( S - min(S) ) / (max(S) - min(S));
            
            % global saliency
            E = computeMarkovAttention(multi_res{i}.feature, max(multi_res{i}.height, multi_res{i}.width), gamma);
            E = ( E - min(E) ) / (max(E) - min(E));
            
            x_new = col_new;
            y_new = row_new;
            
            % global saliency measure
            saliency_global = col2im(E, [1, 1], [x_new, y_new], 'distinct');
            saliency_global = saliency_global';
            % local saliency measure
            saliency_local = col2im(S, [1, 1], [x_new, y_new], 'distinct');
            saliency_local = saliency_local';
            
            saliency = saliency_local .* saliency_global;
            multi_res{i}.saliency = upscaling2ori_resolution(saliency, frame_width, frame_height);
            multi_res{i}.saliency_lc = upscaling2ori_resolution(saliency_local, frame_width, frame_height);
            multi_res{i}.saliency_gb = upscaling2ori_resolution(saliency_global, frame_width, frame_height);
        end
        
        saliency = multi_res{1}.saliency;
        saliency_lc = multi_res{1}.saliency_lc;
        saliency_gb = multi_res{1}.saliency_gb;

        for i=2:multi_res_num
            saliency = saliency + multi_res{i}.saliency;
            saliency_lc = saliency_lc + multi_res{i}.saliency_lc;
            saliency_gb = saliency_gb + multi_res{i}.saliency_gb;
        end
        saliency = saliency / multi_res_num;
        saliency_lc = saliency_lc / multi_res_num;
        saliency_gb = saliency_gb / multi_res_num;
        
        % add center bias
        if is_cb
            saliency = saliency .* saliency_cb;
            saliency_lc = saliency_lc .* saliency_cb;
            saliency_gb = saliency_gb .* saliency_cb;
        end
        
        % ground turth saliency map
        raw_fixation = RawData2Image(raw_data, corresponding_frame_idx, frame_height, frame_width);
        Iet = imfilter(imdilate(raw_fixation,strel('disk',10)),fspecial('gaussian',60,20),'replicate');
        Iet = (Iet-min(Iet(:)))./(max(Iet(:))-min(Iet(:)));    
        ET = im2bw(Iet,level);
    
        [CC, NSS, AUROC, KLDIV] = compute_all_metrics(raw_fixation, ET, Iet, saliency);
        CCs(corresponding_frame_idx, 1) = CC;
        NSSs(corresponding_frame_idx, 1) = NSS;
        KLDIVs(corresponding_frame_idx, 1) = KLDIV;
        AUROCs(corresponding_frame_idx, 1) = AUROC;
        
        if corresponding_frame_idx <= (tpsize + 1) / 2
            % first saliency map output, duplicate the saliency map for all
            % the previous frames
            for i = 1:corresponding_frame_idx-1
                raw_fixation = RawData2Image(raw_data, corresponding_frame_idx, frame_height, frame_width);
                Iet = imfilter(imdilate(raw_fixation,strel('disk',10)),fspecial('gaussian',60,20),'replicate');
                Iet = (Iet-min(Iet(:)))./(max(Iet(:))-min(Iet(:)));    
                ET = im2bw(Iet,level);
                
                [CC, NSS, AUROC, KLDIV] = compute_all_metrics(raw_fixation, ET, Iet, saliency);                
                CCs(i, 1) = CC;
                NSSs(i, 1) = NSS;
                KLDIVs(i, 1) = KLDIV;
                AUROCs(i, 1) = AUROC;
            end
            
        else
            raw_fixation = RawData2Image(raw_data, corresponding_frame_idx - 1, frame_height, frame_width);
            Iet = imfilter(imdilate(raw_fixation,strel('disk',10)),fspecial('gaussian',60,20),'replicate');
            Iet = (Iet-min(Iet(:)))./(max(Iet(:))-min(Iet(:)));    
            ET = im2bw(Iet,level);
            
            saliency_interp = linear_interpolation(saliency_prev, saliency, 0.5);
            [CC, NSS, AUROC, KLDIV] = compute_all_metrics(raw_fixation, ET, Iet, saliency_interp);
            CCs(corresponding_frame_idx - 1, 1) = CC;
            NSSs(corresponding_frame_idx - 1, 1) = NSS;
            KLDIVs(corresponding_frame_idx - 1, 1) = KLDIV;
            AUROCs(corresponding_frame_idx - 1, 1) = AUROC;
        end
        
        saliency_prev = saliency;
        
        raw_fixation = RawData2Image(raw_data, corresponding_frame_idx, frame_height, frame_width);
        Iet = imfilter(imdilate(raw_fixation,strel('disk',20)),fspecial('gaussian',60,20),'replicate');
        Iet = (Iet-min(Iet(:)))./(max(Iet(:))-min(Iet(:)));
        [out, clim, map] = sc(Iet, 'jet');
        Iet_overlay = imfuse(current_frame, out, 'blend');
        
        [out, clim, map] = sc(saliency, 'jet');
        saliency_overlay = imfuse(current_frame, out, 'blend');
        %result_image = imfuse(current_frame, out, 'blend');
        
        %[out, clim, map] = sc(multi_res{1}.saliency, 'jet');
        %saliency_sr_overlay = imfuse(current_frame, out, 'blend');
        
        %result_image = cat(3, saliency_sr_overlay, saliency_overlay, Iet_overlay);
        %result_image = [result_image(:, :, 1:3) result_image(:, :, 4:6) ...
        %    result_image(:, :, 7:9)];
        
        %result_image = cat(2, saliency_overlay, Iet_overlay);
        %result_image = [result_image(:, :, 1:3) result_image(:, :, 4:6)];
        
        [out, clim, map] = sc(saliency_lc, 'jet');
        saliency_local = imfuse(current_frame, out, 'blend');
        [out, clim, map] = sc(saliency_gb, 'jet');
        saliency_global = imfuse(current_frame, out, 'blend');
        
        result_image = cat(4, saliency_local, saliency_global, ...
                            saliency_overlay, Iet_overlay);
        result_image = [result_image(:, :, :, 1) result_image(:, :, :, 2); 
            result_image(:, :, :, 3) result_image(:, :, :, 4)];
        
        %out_filename = sprintf('videos/%s_tp_%d_%d/frame_sal_%d.png', name, tpsize, tpsize, corresponding_frame_idx);
        [pathstr, name, ext] = fileparts(filelist(img_idx).name);
        out_filename = sprintf('results/%d_%d_%d_%s.png', video_idx, tpsize, tpsize2, name);
        imwrite(result_image, out_filename);

        save_idx = save_idx + 1;
    end
    idx = idx + 1;
end

if 0
CC = mean(CCs);
NSS = mean(NSSs);
KLDIV = mean(KLDIVs);
AUROC = mean(AUROCs);
sigma_str = num2str(sigma, '%10.0e');
name = sprintf('experiments/combo_mr4_video%d_tp_%d_%d_sigma_%s_metrics.mat', ...
                video_idx, tpsize, tpsize2, sigma_str);
save(name, 'CC', 'NSS', 'AUROC', 'KLDIV');
end
end

