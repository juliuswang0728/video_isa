function [ rowList, colList  ] = drawSampleFromImagePlane( nRow, nCol, nSamples, foveaSize)
%generate random nSamples from an image with nRow and nCol
% The sampling considers the fovea size around each sample take to avoid out of map patches

margin = 3 + round(foveaSize/2); % the margin to discard from the borders of the image
rowStart = margin;
colStart = margin;
rowEnd = nRow - margin;
colEnd = nCol - margin;

rowList = randi([rowStart, rowEnd], 1, nSamples);
colList = randi([colStart, colEnd], 1, nSamples);

end

