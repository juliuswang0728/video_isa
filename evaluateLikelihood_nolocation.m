function logLik = evaluateLikelihood_nolocation(feature, hyperParams)

nParams = size(hyperParams.thetaStd,1);

logLik = (log(hyperParams.thetaStd) - ((feature - hyperParams.thetaMu).^2) ./ (2*hyperParams.thetaVar));
logLik = sum(logLik(1:nParams-2));
