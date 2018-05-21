function compute_network( )
% train the filters of the network and save them,
%   Detailed explanation goes here

global basesPath
global image_canonical_size
global color_space

image_canonical_size = 800;
color_space = 'cielab';


close all

params = set_params(); % set the system parameters

net = setup_network(params, basesPath, 1, [1, 2]);


%tmp_data_file_name = sprintf('%stmpPatches_%s.mat', tmpFolder, params.base_id{net.num_layers});



%load(tmp_data_file_name);
[img, orig_img] = loadImage('./images/22.jpg', 1);
[x, y, c] = size(img);
X = reshape(img, x, []);
X = im2col(X, [net.layer{end}.fovea.spatial_size net.layer{end}.fovea.spatial_size], 'distinct');
X = reshape(X, [], c);
X = im2col(X, [net.layer{end}.fovea.spatial_size^2 c], 'distinct');
result = network_response(X, net);


feature = [result{2}.reduced_output; result{1}.reduced_output]';

E = computeMarkovAttention(feature);

x_new = ceil(x / net.layer{end}.fovea.spatial_size);
y_new = ceil(y / net.layer{end}.fovea.spatial_size);



saliency = col2im(E, [1, 1], [x_new, y_new], 'distinct');
% discard the values not corresponding to valid image area
if (x / net.layer{end}.fovea.spatial_size ~= x_new)
    saliency(x_new, :) = [];
end
if (y / net.layer{end}.fovea.spatial_size ~= y_new)
    saliency(:, y_new) = [];
end
%minVal = min(saliency(:));
% saliency(1, :) = minVal;
% saliency(:, 1) = minVal;
% saliency(x_new, :) = minVal;
%saliency(:, y_new) = minVal;

saliency = imfilter(saliency, fspecial('Gaussian', [5 5], 2), 'replicate');

saliency =  ( saliency - min(saliency(:)) ) / ( max(saliency(:)) - min(saliency(:)) );

figure, imshow(orig_img);
figure, imshow(imresize(saliency, [x, y]).*orig_img(:,:,1));
figure, imagesc(saliency);

end

