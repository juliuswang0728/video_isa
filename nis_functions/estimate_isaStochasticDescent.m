function Weights=estimate_isaStochasticDescent(Z, V, n, subspacesize, basis_filename)

% This code is adapted from Natural Image
% Statistics (Hyv??rinen, Hurri, Hoyer, 2009) 
% and the code from Le et al.

% Z                      : whitened data
% V                      : dewhitening matrix
% n = 60..windowsize^2-1 : number of linear components to be estimated
%                          (must be divisible by subspacesize)
% subspacesize= 2...10   : subspace size 
% basis_fileame          : the file name to store the estimates


%------------------------------------------------------------
% Initialize algorithm
%------------------------------------------------------------

%create matrix where the i,j-th element is one if they are in same subspace
%and zero if in different subspaces
ISAmatrix = subspacematrix(n,subspacesize);
%ISAmatrix = ISAmatrix(1:subspacesize:end,:); % this becomes a bit faster
%by ommting half of the data multiplicaiton during the objective funciton
%evaluation


%create random initial value of Weights, and orthogonalize it
Weights = orthogonalizerows(randn(n,size(Z,1))); 

%read sample size from data matrix
N = size(Z, 2);

%Initial step size
mu = 1;

%------------------------------------------------------------
% Start algorithm
%------------------------------------------------------------

fprintf('Doing ISA. Iteration count: \n ')

iter = 0;
notconverged = 1;

obj = [];

while notconverged && (iter < 2000) %maximum of 2000 iterations

  iter=iter+1;
  
  %print iteration count
  fprintf('%d ', iter);
  if mod(iter, 20)==0
      fprintf('\n');
  end


  %-------------------------------------------------------------
  % Gradient step for ISA
  %-------------------------------------------------------------  

    selInputBatch = randi([1 N], 1, 50000); % we do it with the batches of 50k as done in the original code of Apo, however, here the number of samples is several times bigger
    
    % Compute separately estimates of independent components to speed up 
    Y = Weights*Z(:, selInputBatch); 
    
    %compute energies of subspaces
    K = ISAmatrix*Y.^2;
    
    % This is nonlinearity corresponding to generalized exponential density
    % (note minus sign)
    epsilon = 0.0001;
    gK = -(epsilon+K).^(-0.5);
    
    % Store the objective function value
    obj = [obj sum(sum(sqrt(epsilon+K)))];

    % Calculate product with subspace indicator matrix
    F = ISAmatrix'*gK;
    
    % This is the basic gradient
    grad = (Y.*F)*Z(:, selInputBatch)'/N;

    % project gradient on tangent space of orthogonal matrices (optional)
    grad = grad-Weights*grad'*Weights;

    %store old value
    Weightsold = Weights;

    % do gradient step
    Weights = Weights + mu*grad;

    % Orthogonalize rows or decorrelate estimated components
    Weights = orthogonalizerows(Weights);

    % Adapt step size every step, or every n-th step? remove this?
    if rem(iter, 1) == 0 || iter==1

        %How much do we want to change the step size? Choose this factor
        changefactor=4/3;

        % Take different length steps
        Weightsnew1 = Weightsold + 1/changefactor*mu*grad;
        Weightsnew2 = Weightsold + changefactor*mu*grad;
        Weightsnew1 = orthogonalizerows(Weightsnew1);
        Weightsnew2 = orthogonalizerows(Weightsnew2);
      
        % Compute objective function values
        J1 = -sum(sum(sqrt(epsilon+ISAmatrix*(Weightsnew1*Z).^2)));
        J2 = -sum(sum(sqrt(epsilon+ISAmatrix*(Weightsnew2*Z).^2)));
        J0 = -sum(sum(sqrt(epsilon+ISAmatrix*(Weights*Z).^2)));
        
        % Compare objective function values, pick step giving minimum
        if J1>J2 && J1>J0
            % Take shorter step because it is best
            mu = 1/changefactor*mu;
            Weights=Weightsnew1;
        elseif J2>J1 && J2>J0
            % Take longer step because it is best
            mu = changefactor*mu;
            Weights=Weightsnew2;
        end
    end
    
    %check convergence
    if iter > 200 && obj(iter) / obj(iter - 50) >= 0.999
        notconverged = 0;
    end
    
end %of gradient iterations loop


basesInfo{1}.W = Weights*V;
basesInfo{1}.A = pinv(basesInfo{1}.W);
basesInfo{1}.H = ISAmatrix;
basesInfo{1}.V = V;
basesInfo{1}.iters = iter;
basesInfo{1}.obj = obj; % the objective function
% saving the estimated bases
fprintf('\n saving the bases \n')
save(basis_filename, 'basesInfo', '-v7.3');
end

