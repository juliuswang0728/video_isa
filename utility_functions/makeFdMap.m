function [ fdmap ] = makeFdMap( fmap, sigma )
%convolve a fixation map to get the fixation density map
%   Detailed explanation goes here

if nargin < 2
    sigma = 19;
end

w = round(4*sigma);
fdmap = imfilter(fmap, fspecial('Gaussian', [w, w], sigma), 'replicate');

fdmap = (fdmap - min(fdmap(:))) / (max(fdmap(:)) - min(fdmap(:)));

end

