function [] = interpolate_frames(video_idx, tpsize)
    addpath('confidence-interval-AUC/');
    video_idx = 22; % 2 4 16 18 20
    tpsize = 5;
    % 1 3 5 9
    input_filename = sprintf('saliency_maps/video%d_tp_%d_%d.mat', video_idx, tpsize, tpsize);
    
    %% parameters for evaluation purposes
    % Raw_data Reader
    filename=strcat('raw_data/raw_data_video', num2str(video_idx),'.mat');
    load(filename)
    
    num_frames_eval = [878 125 627 125 834 37 462 150 881 466 1142 103 888 71 950 113 785 113 240 113 749 31 143 154];
    
    CC_score_local = [];
    AUROC_score_local = [];
    NSS_score_local   = [];
    KLDIV_score_local = [];
    
    CC_score_global = [];
    AUROC_score_global = [];
    NSS_score_global   = [];
    KLDIV_score_global = [];
    
    CC_score_local_global = [];
    AUROC_score_local_global = [];
    NSS_score_local_global   = [];
    KLDIV_score_local_global = [];
    
    CC_score_weighted_local = [];
    AUROC_score_weighted_local = [];
    NSS_score_weighted_local   = [];
    KLDIV_score_weighted_local = [];
    
    se = strel('ball',4,2);
    se2 = strel('rectangle',[12 2]);
    
    %%
    num_frames_full = num_frames_eval(video_idx);
    
    saliency_set = load(input_filename);
    saliency_set = saliency_set.saliency_set;
    
    n_frames = length(saliency_set);
    
    for i=1:n_frames
        saliency_set_interp = {}; % clear it off every loop
        
        frame_idx = saliency_set{i}.frame_idx;
        saliency_local = saliency_set{i}.local;
        saliency_global = saliency_set{i}.global;
        saliency_local_global = saliency_set{i}.local_global;
        saliency_weighted_local = saliency_set{i}.weighted_local;
        
        if i == 1
            % interpolate the first few frames
            
            for j=1:frame_idx-1
                saliency_set_interp{j}.frame_idx = j;
                %saliency_set_interp{j}.local = saliency_local;
                %saliency_set_interp{j}.global = saliency_global;
                %saliency_set_interp{j}.local_global = saliency_local_global;
                %saliency_set_interp{j}.weighted_local = saliency_weighted_local;
                
                saliency_set_interp{j}.local = zeros(size(saliency_local));
                saliency_set_interp{j}.global = zeros(size(saliency_local));
                saliency_set_interp{j}.local_global = zeros(size(saliency_local));
                saliency_set_interp{j}.weighted_local = zeros(size(saliency_local));
                
            end
            current_idx = j + 1;
        else
            re_idx = 1;
            for j=frame_idx_prev+1:frame_idx-1
                x = (j - frame_idx_prev);
                y = (frame_idx - j);
                x = x / (x + y);
                x = 1.0 - x;
                saliency_set_interp{re_idx}.frame_idx = j;
                saliency_set_interp{re_idx}.local = linear_interpolation(...
                    saliency_set{i-1}.local, saliency_local, x);
                saliency_set_interp{re_idx}.global = linear_interpolation(...
                    saliency_set{i-1}.global, saliency_global, x);
                saliency_set_interp{re_idx}.local_global = linear_interpolation(...
                    saliency_set{i-1}.local_global, saliency_local_global, x);
                saliency_set_interp{re_idx}.weighted_local = linear_interpolation(...
                    saliency_set{i-1}.weighted_local, saliency_weighted_local, x);
                re_idx = re_idx + 1;
            end
            current_idx = re_idx;
        end
        
        saliency_set_interp{current_idx}.frame_idx = frame_idx;
        saliency_set_interp{current_idx}.local = saliency_local;
        saliency_set_interp{current_idx}.global = saliency_global;
        saliency_set_interp{current_idx}.local_global = saliency_local_global;
        saliency_set_interp{current_idx}.weighted_local = saliency_weighted_local;
        
        frame_idx_prev = frame_idx;

        buffer_length = length(saliency_set_interp);        
        if i == n_frames
            % in case that no saliency map calculated for last few frames
            for j=1:buffer_length
                frame_idx = saliency_set_interp{j}.frame_idx;
            end
            k = buffer_length + 1;
            % just copy the saliency map from the last frame whose saliency map is actually
            % calculated with your approach
            for j=frame_idx+1:num_frames_full
                saliency_set_interp{k}.frame_idx = j;
                saliency_set_interp{k}.local = saliency_set_interp{buffer_length}.local;
                saliency_set_interp{k}.global = saliency_set_interp{buffer_length}.global;
                saliency_set_interp{k}.local_global = saliency_set_interp{buffer_length}.local_global;
                saliency_set_interp{k}.weighted_local = saliency_set_interp{buffer_length}.weighted_local;
                k = k + 1;
            end
        end
        
        % update length in the buffer
        buffer_length = length(saliency_set_interp);        
        for j=1:buffer_length
            frame_idx = saliency_set_interp{j}.frame_idx;
            saliency_local = saliency_set_interp{j}.local;
            saliency_global = saliency_set_interp{j}.global;
            saliency_local_global = saliency_set_interp{j}.local_global;
            saliency_weighted_local = saliency_set_interp{j}.weighted_local;
            
            disp(strcat('Video: ',num2str(video_idx),' -- Frame: ', num2str(frame_idx)))
            
            saliency_local = post_processing_eval(saliency_local, se, se2);
            saliency_global = post_processing_eval(saliency_global, se, se2);
            saliency_local_global = post_processing_eval(saliency_local_global, se, se2);
            saliency_weighted_local = post_processing_eval(saliency_weighted_local, se, se2);
    
            
            %% evaluation codes
            Image = RawData2Image(raw_data, frame_idx, vidHeight, vidWidth);
            Iet = imfilter(imdilate(Image,strel('disk',10)),fspecial('gaussian',60,20),'replicate');
            Iet = (Iet-min(Iet(:)))./(max(Iet(:))-min(Iet(:)));    
            level = 0.7;
            ET = im2bw(Iet,level);
            
            % Comparison metrics
            % add CC score here
            score = calcCCscore(saliency_local, ET);
            CC_score_local(1, frame_idx) = mean(score);
            
            score = calcCCscore(saliency_global, ET);
            CC_score_global(1, frame_idx) = mean(score);
            
            score = calcCCscore(saliency_local_global, ET);
            CC_score_local_global(1, frame_idx) = mean(score);
            
            score = calcCCscore(saliency_weighted_local, ET);
            CC_score_weighted_local(1, frame_idx) = mean(score);
            
            
            % 1) KL-Div 
            score = calcKLDivscore(ET,saliency_local);
            KLDIV_score_local(1,frame_idx) = mean(score);
            
            score = calcKLDivscore(ET,saliency_global);
            KLDIV_score_global(1,frame_idx) = mean(score);
            
            score = calcKLDivscore(ET,saliency_local_global);
            KLDIV_score_local_global(1,frame_idx) = mean(score);
            
            score = calcKLDivscore(ET,saliency_weighted_local);
            KLDIV_score_weighted_local(1,frame_idx) = mean(score);
                    
            % 2) NSS
            score1 = calcNSSscore(saliency_local,ET);
            NSS_score_local(1,frame_idx) = mean(score1);
            
            score1 = calcNSSscore(saliency_global,ET);
            NSS_score_global(1,frame_idx) = mean(score1);
            
            score1 = calcNSSscore(saliency_local_global,ET);
            NSS_score_local_global(1,frame_idx) = mean(score1);
            
            score1 = calcNSSscore(saliency_weighted_local,ET);
            NSS_score_weighted_local(1,frame_idx) = mean(score1);
                   
            % 3) AUROC
            Iet1 = reshape(Iet,size(Iet,1)*size(Iet,2),1);                    
            
            map2 = double(imresize(saliency_local,size(Iet),'nearest'));
            map3 = reshape(map2,size(map2,1)*size(map2,2),1);                                        
            [A,Aci] = auc([Iet1,map3],0.05,'hanley');
            AUROC_score_local(1,frame_idx) = mean(A);
            
            map2 = double(imresize(saliency_global,size(Iet),'nearest'));
            map3 = reshape(map2,size(map2,1)*size(map2,2),1);                                        
            [A,Aci] = auc([Iet1,map3],0.05,'hanley');
            AUROC_score_global(1,frame_idx) = mean(A);
            
            map2 = double(imresize(saliency_local_global,size(Iet),'nearest'));
            map3 = reshape(map2,size(map2,1)*size(map2,2),1);                                        
            [A,Aci] = auc([Iet1,map3],0.05,'hanley');
            AUROC_score_local_global(1,frame_idx) = mean(A);         
            
            map2 = double(imresize(saliency_weighted_local,size(Iet),'nearest'));
            map3 = reshape(map2,size(map2,1)*size(map2,2),1);                                        
            [A,Aci] = auc([Iet1,map3],0.05,'hanley');
            AUROC_score_weighted_local(1,frame_idx) = mean(A);            
            
        end
    end
       
    % for each video, the metrics score are saved in a .mat file
    % you can change the .mat name if needed
    [pathstr, name, ext] = fileparts(input_filename);
    name = sprintf('evaluation_results/video%d_tp_%d_%d_metrics.mat', video_idx, tpsize, tpsize);
    save(name, 'CC_score_local', 'CC_score_global', 'CC_score_local_global', 'CC_score_weighted_local', ...
        'KLDIV_score_local','KLDIV_score_global','KLDIV_score_local_global','KLDIV_score_weighted_local',...
        'NSS_score_local', 'NSS_score_global', 'NSS_score_local_global', 'NSS_score_weighted_local', ...
        'AUROC_score_local', 'AUROC_score_global', 'AUROC_score_local_global', 'AUROC_score_weighted_local');
end