function train_filters(net, layerID, file2load, basesPath)
% trains the filters for the specific layer
% load data files
load(file2load); % loading data, i.e., X, etc
n_samples = 150000;
X = X(:, 1:n_samples);
if isinteger(X)
    X = im2single(X);
end

if layerID > 1
    % ToDo perform the convolution
    fprintf('computing the activation functions on previous layers\n');    
    for i = 1:layerID-1
        tic
        X = feedForward(X, net.layer{i}, net.layer{layerID}, net.input_type);
        toc
    end       
end

fprintf('removing the DC component\n');

X = removeDC(X);

fprintf('training filters of layer %d\n', layerID);

% perform PCA whitening

fprintf('whiten the data\n');

[V, E, D] = pca(X);

Z = V(1:net.layer{layerID}.pca_dim, :)*X;

saveFileName = [basesPath filesep net.layer{layerID}.base_id '.mat'];
fprintf('Estimating %s bases and saving them to \n %s\n', net.layer{layerID}.type, saveFileName);

switch lower(net.layer{layerID}.type)
    case 'isa'
        %estimate_isa(Z, V(1:net.layer{layerID}.pca_dim, :), net.layer{layerID}.pca_dim, net.layer{layerID}.group_size, saveFileName);
        estimate_isaStochasticDescent(Z, V(1:net.layer{layerID}.pca_dim, :), net.layer{layerID}.pca_dim, net.layer{layerID}.group_size, saveFileName);
    otherwise
        error('the basis type, %s, is not supported', net.layer{ID}.type);
        
end

end