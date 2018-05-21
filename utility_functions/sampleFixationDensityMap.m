function [ samples  ] = sampleFixationDensityMap( fdMap, nPosSample, nNegSample, posTopRatio, negTopRatio, foveaSize)
%generate random nSamples from an image with nRow and nCol
% The sampling considers the fovea size around each sample take to avoid out of map patches
% samples is a matrix of samples each row has  [row_sample, col_sample,
% fdMap_Value, Label], psotive label is 1 and negative is -1

samples = single(zeros(4, nPosSample+nNegSample));

[row, col, c] = size(fdMap);

assert(c == 1); % if this fails the map is not correct

margin = 3 + round(foveaSize/2); % the margin to discard from the borders of the image

fdMap(1:margin, :) = [];
fdMap(:, 1:margin) = [];
fdMap(row-2*margin+1:row-margin, :) = [];
fdMap(:, col-2*margin+1:col-margin) = [];

[row_n, col_n] = size(fdMap);

fdMap = ( fdMap - min(fdMap(:)) ) / ( max(fdMap(:)) - min(fdMap(:)) ); % just normalize the values of the map 

positiveMap = fdMap;
negativeMap = 1 - fdMap;

th = getThreshold(positiveMap, posTopRatio);
positiveMap(positiveMap < th) = 0;

th = getThreshold(negativeMap, negTopRatio);
negativeMap(negativeMap < th) = 0;

% convert the maps to a distribution
positiveMap = positiveMap / sum(positiveMap(:));
negativeMap = negativeMap / sum(negativeMap(:));

% now we sample from the maps
cnt = 1;

for i = 1:nPosSample
    [colSample, rowSample] = pinky(1:col_n, 1:row_n, positiveMap);
    samples(:, cnt) = [rowSample+margin; colSample+margin; fdMap(rowSample,colSample); 1]; % we need to shift the coordinates for the original map    
    cnt = cnt + 1;
end

for i = 1:nNegSample
    [colSample, rowSample] = pinky(1:col_n, 1:row_n, negativeMap);
    samples(:, cnt) = [rowSample+margin; colSample+margin; fdMap(rowSample,colSample); -1];
    cnt = cnt+1;
end

samples = single(samples);

end

function th = getThreshold(map, ratio)

[hPos, binLocations] = imhist(map);
hPos = cumsum(hPos);
hPos = hPos ./ hPos(end);
th = min(binLocations(hPos >= (1 - ratio)));

end
