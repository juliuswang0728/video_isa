function [ E ] = computeMarkovAttention( featureMatrix , sigma, gamma)
%COMPUTEATTENTION computes the amount of attention in terms of expected
%number of steps
%   Input:
%       @featureMatrix: size nxk, n number of samples
%   Ouput:
%       @E: the average step of reaching one node
%

if isreal(featureMatrix)
    distanceMatrix = pdist2(featureMatrix, featureMatrix, 'spearman');
else
    distanceMatrix = pdist2(abs(featureMatrix), abs(featureMatrix), 'spearman');
end

Deg = diag(sum(distanceMatrix,2));
  
P = inv(Deg)*distanceMatrix;

clear distanceMatrix Deg;

% solve pie
[VR, D, VL] = eig(P);
piP = VL(:,1)';
piP = piP / sum(piP);


%W = repmat(piP, [size(P, 1), 1]);
%I = eye(numel(piP));
%Z = inv(I - P + W);

E = 1./piP;

%E = E - mean(E(:));
%E = E / std(E(:));
E = exp(-E/(gamma*sigma));
%E = exp(-E/sigma);

%E = diag(1./piP);

% for i = 1:numel(piP)
%      for j = 1:numel(piP)
%          if ( i ~= j )
%              E(i,j) = E(j,j)*(Z(j,j) - Z(i,j));
%              E(j,i) = E(i,j);
%          end
%      end
% end

end

