function [CC, NSS, AUROC, KLDIV] = compute_all_metrics(raw_fixation, ET, Iet, saliency_map)
% ET as ground truth
% saliency map as saliency from the model
% Comparison metrics
    %saliency_map = post_processing_eval(saliency_map, se, se2);
    
    score = calcCCscore(saliency_map, Iet);
    CC = mean(score);

    score = calcKLDivscore(ET, saliency_map);
    KLDIV = mean(score);
    
    score = calcNSSscore(saliency_map, raw_fixation);
    NSS = mean(score);

    Iet1 = reshape(Iet, size(Iet, 1)*size(Iet, 2), 1);
    map2 = double(imresize(saliency_map, size(Iet), 'nearest'));
    map3 = reshape(map2, size(map2,1)*size(map2,2),1);                                        
    [A, Aci] = auc([Iet1, map3], 0.05, 'hanley');
    AUROC = mean(A);
end