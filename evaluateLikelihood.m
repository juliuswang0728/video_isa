function logLik = evaluateLikelihood(feature, hyperParams)



logLik = (log(hyperParams.thetaStd) - ((feature - hyperParams.thetaMu).^2) ./ (2*hyperParams.thetaVar));
logLik = sum(logLik);
