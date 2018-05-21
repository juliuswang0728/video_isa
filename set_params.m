function [ params ] = set_params(tpsize, tpsize2)
% set the parameters of the system in the params structure

%% network type and layers
%% set layer architecture parameters
params.inputType = 'video'; % the network input type if it is image or video
%params.inputType = 'image'; % the network input type if it is image or video
params.num_layers = 2; % two layers correspond to V2, but we can have more layers

type{1} = 'isa';
type{2} = 'isa';

params.type = type;

%% set the fovea parameters, it tells us how large or small the filters should be
% the size of filters increas as we move forward

fovea{1}.spatial_size = 24;
fovea{2}.spatial_size = 32;

if strcmp(params.inputType, 'video')
    %fovea{1}.temporal_size = 7;
    %fovea{2}.temporal_size = 7;
    fovea{1}.temporal_size = tpsize;
    fovea{2}.temporal_size = tpsize2;
end

params.fovea = fovea;

%% set the layer output parameters

outputConfig{1}.type = 'lhthresh';
outputConfig{1}.threshold.low = 0.01;
outputConfig{1}.threshold.high = 1;

outputConfig{2}.type = 'lhthresh';
outputConfig{2}.threshold.low = 0.01;
outputConfig{2}.threshold.high = 1;

params.outputConfig = outputConfig;


%% set between level convolution parameters
% this is useful for subsampling within an image patch, it is equivalant to
% sliding the covolution window step on the signal a strid of 0 means a
% full convolution by sliding the window on each pixel 1 step

stride{1}.spatial_stride = 4; 
if strcmp(params.inputType, 'video')
    stride{1}.temporal_stride = 2;
end

params.stride = stride;

%% feature parameters

pca_dim{1} = 300;
pca_dim{2} = 200;

group_size{1} = 4; % this is the number of subspaces in isa setting
group_size{2} = 4;

params.group_size = group_size;
params.pca_dim = pca_dim;

global color_space
global image_canonical_size

if 1
for i = 1:params.num_layers
    if strcmp(params.inputType, 'image')
        params.base_id{i} = sprintf('%s_%s_layer_%d_fov_%d_pca_%d_gs_%d_%s_%d', ...
        params.inputType, params.type{i}, i, fovea{i}.spatial_size, params.pca_dim{i}, params.group_size{i}, color_space, image_canonical_size);
        if i > 1
            params.base_id{i} = sprintf('%s_stride_%d', params.base_id{i}, params.stride{i-1}.spatial_stride);
        end
    elseif strcmp(params.inputType, 'video')
        params.base_id{i} = sprintf('%s_%s_layer_%d_fov_%d_tpsize_%d_pca_%d_gs_%d_%s_%d', ...
        params.inputType, params.type{i}, i, fovea{i}.spatial_size, fovea{i}.temporal_size, params.pca_dim{i}, params.group_size{i}, color_space, image_canonical_size);
        if i > 1
            params.base_id{i} = sprintf('%s_stride_%d_tpstride_%d', params.base_id{i}, params.stride{i-1}.spatial_stride, ...
                params.stride{i-1}.temporal_stride);
        end
        
    end
end
end

%params.base_id{1} = 'video_isa_bases_fov_24_32_tp_8_8/video_isa_layer_1_fov_24_pca_300_gs_4_rgb_800_tp_8';
%params.base_id{2} = 'video_isa_bases_fov_24_32_tp_8_8/video_isa_layer_2_fov_32_pca_200_gs_4_rgb_800_stride_4_tp_8';
%params.base_id{1} = 'video_isa_bases_fov_24_32_tp_4_4/video_isa_layer_1_fov_24_pca_300_gs_4_rgb_800';
%params.base_id{2} = 'video_isa_bases_fov_24_32_tp_4_4/video_isa_layer_2_fov_32_pca_200_gs_4_rgb_800_stride_4_tpstride_2';


end

