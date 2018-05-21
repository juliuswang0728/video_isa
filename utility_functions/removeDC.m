function  X = removeDC( X )
% Removes DC component from image patches
% Data given as a matrix where each patch is one column vectors
% That is, the patches are vectorized.

%X = bsxfun(@minus, X, mean(X));

% the momeory efficient way, but slower one is

mX = mean(X);
for i = 1:size(X,1)
    X(i,:) = X(i,:) - mX;
end

end
