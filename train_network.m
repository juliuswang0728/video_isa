function train_network()
% train the filters of the network and save them,
%   Detailed explanation goes here

global data_dir
global basesPath
global tmpFolder
global imgExt
global videoExt
global n_samplePerData
global use_cache

setup_globalSetting();
loadBasisFlag = 0; % during the training phase we do not load the layers

params = set_params(); % set the system parameters

net = setup_network(params, basesPath, loadBasisFlag);

for i = 1:net.num_layers
    % 'patches' for images, 'chunks' for videos, i.e. a pile of patches
    %tmp_data_file_name{i} = sprintf('%stmpPatches_%s.mat', tmpFolder, params.base_id{i});
    tmp_data_file_name{i} = sprintf('%stmpChunks_%s.mat', tmpFolder, params.base_id{i});
    if (use_cache == 1) && exist(tmp_data_file_name{i}, 'file')
        continue;
    end
    if strcmp(net.input_type, 'image')
        sampling_params.spatial_size = net.layer{i}.fovea.spatial_size;
        sampling_params.num_patches = n_samplePerData(i);
        % sample patches and saves them
        patch_sample_training(data_dir, imgExt, tmp_data_file_name{i}, sampling_params);
        
    elseif strcmp(net.input_type, 'video')
        sampling_params.spatial_size = net.layer{i}.fovea.spatial_size;
        sampling_params.temporal_size = net.layer{i}.fovea.temporal_size;
        sampling_params.num_patches = n_samplePerData(i);
        sampling_params.temporal_stride = params.stride{1}.temporal_stride;
        patch_sample_training_temporal(data_dir, videoExt, tmp_data_file_name{i}, sampling_params);
    end
end

for i = 1:net.num_layers
    loadBasisFlag = i - 1; % the previous bases should be loaded for the first layer it is zero    
    if (use_cache == 1) && exist([basesPath filesep net.layer{i}.base_id '.mat'], 'file')
        continue;
    end
    if loadBasisFlag > 0;
        net = setup_network(params, basesPath, loadBasisFlag, 1:i-1);
    end
    train_filters(net, i, tmp_data_file_name{i}, basesPath)
end

if 0
net = setup_network(params, basesPath, 1, 1:2);
% X: (32x32x3, n_patches)
X = load('tmpData/tmpChunks_video_isa_layer_2_fov_32_pca_200_gs_4_rgb_800_stride_4.mat');
X = X.X;
if isinteger(X)
    X = im2single(X);
end
layer_result = network_response(X, net);
end
end