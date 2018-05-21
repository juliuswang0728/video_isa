function output = feedForwardVideo(X, sLayer, dLayer)

if strcmp(lower(sLayer.type), 'pool')
    error('pooling layer needs to be implemented')
    return % we do not continue
end

nPatches = size(X, 2); % number of image patches

sFovea_spSize = sLayer.fovea.spatial_size;
dFovea_spSize = dLayer.fovea.spatial_size;
sFovea_tempSize = sLayer.fovea.temporal_size;
dFovea_tempSize = dLayer.fovea.temporal_size;

src_spatial_stride = sLayer.spatial_stride;
src_temporal_stride = sLayer.temporal_stride;

nSubSample_per_spCol_dL = floor(1 + (dLayer.fovea.spatial_size - sLayer.fovea.spatial_size) / src_spatial_stride);
nSubSample_temporal = floor(1 + (dFovea_tempSize - sFovea_tempSize) / src_temporal_stride);

nSubSample = sLayer.num_subsamples;

nFoveaSRC = 3*sFovea_tempSize*sFovea_spSize^2; % we assume that we have 3 channel data so the spatial size is multiplied by 3
nFoveaDES = 3*dFovea_tempSize*dFovea_spSize^2;

filt_dim = size(sLayer.H, 1);
output = zeros(nSubSample*filt_dim, nPatches, 'single');

X = reshape(X, [dFovea_tempSize, dFovea_spSize, dFovea_spSize, 3, nPatches]);
for it = 0: nSubSample - 1
    [x, y, t] = ind2sub([nSubSample_per_spCol_dL, nSubSample_per_spCol_dL, nSubSample_temporal], it+1);
    startx = (x - 1) * src_spatial_stride + 1;
    starty = (y - 1) * src_spatial_stride + 1;
    startt = (t - 1) * src_temporal_stride + 1;
    endx = startx + sFovea_spSize - 1;
    endy = starty + sFovea_spSize - 1;
    endt = startt + sFovea_tempSize - 1;
    
    subFoveaX = reshape(X(startt:endt, startx:endx, starty:endy, :, :), nFoveaSRC, nPatches);
    
    resIdx = it*filt_dim+1: (it+1)*filt_dim;
    output(resIdx, :) = activateLayer(subFoveaX, sLayer);
end


end