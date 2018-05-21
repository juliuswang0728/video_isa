function saliency = compute_globalSaliency(img)
% compute the global saliency using the network features and Graphs.

%   Detailed explanation goes here

global basesPath
%global image_canonical_size
%global color_space

%image_canonical_size = 800;
%color_space = 'cielab';


params = set_params(); % set the system parameters

net = setup_network(params, basesPath, 1, [1, 2]);

%tmp_data_file_name = sprintf('%stmpPatches_%s.mat', tmpFolder, params.base_id{net.num_layers});

%load(tmp_data_file_name);
img  = loadImage(img);
[x, y, c] = size(img);
nPady = 0;
nPadx = 0;
% if ( (y / net.layer{end}.fovea.spatial_size) > round(y / net.layer{end}.fovea.spatial_size) )
%     % pad the image
%     
%     while((y / net.layer{end}.fovea.spatial_size) > round(y / net.layer{end}.fovea.spatial_size) )
%         y = y + 1;
%         nPady = nPady + 1;
%     end
%     img = padarray(img, [0 nPady], 0, 'post');
% end
% if ( (x / net.layer{end}.fovea.spatial_size) > round(x / net.layer{end}.fovea.spatial_size) )
%     % pad the image
%     
%     while( (x / net.layer{end}.fovea.spatial_size) > round(x / net.layer{end}.fovea.spatial_size) )
%         x = x + 1;
%         nPadx = nPadx + 1;
%     end
%     img = padarray(img, [nPadx 0], 0, 'post');
% end

X = reshape(img, x, []);
X = im2col(X, [net.layer{end}.fovea.spatial_size net.layer{end}.fovea.spatial_size], 'distinct');
 if ((size(X, 2) / c) ~= floor(size(X, 2) / c))
     n = 0;
     while (((size(X, 2)+n) / c) ~= floor((size(X, 2)+n) / c))
         n = n+1;
     end
     X = padarray(X, [0, n], 0, 'post');
 end
    
X = reshape(X, [], c);
X = im2col(X, [net.layer{end}.fovea.spatial_size^2 c], 'distinct');
result = network_response(X, net);


feature = [result{2}.reduced_output; result{1}.reduced_output]';
feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2))); % L2 normalize

E = computeMarkovAttention(feature, max(x,y));

x_new = ceil(x / net.layer{end}.fovea.spatial_size);
y_new = ceil(y / net.layer{end}.fovea.spatial_size);

if size(E, 2) < (x_new * y_new)
    n = abs(size(E, 2) - x_new*y_new);
    E = [E, zeros(size(E, 1), n)];
end

saliency = col2im(E, [1, 1], [x_new, y_new], 'distinct');
% discard the values not corresponding to valid image area
if ((x / net.layer{end}.fovea.spatial_size ) ~= x_new)
    saliency(x_new, :) = [];
end
if ((y / net.layer{end}.fovea.spatial_size ) ~= y_new)
    saliency(:, y_new) = [];
end


saliency = imfilter(saliency, fspecial('Gaussian', [5 5], 2), 'replicate');

saliency = imresize(saliency, [x, y]);

y = y - nPady;
x = x - nPadx;

saliency = saliency(1:x, 1:y);

saliency =  ( saliency - min(saliency(:)) ) / ( max(saliency(:)) - min(saliency(:)) );




end

