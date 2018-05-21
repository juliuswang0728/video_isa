function eval_map = post_processing_eval(map, se, se2)
    eval_map = imdilate(map,se);
    eval_map = imdilate(eval_map,se2);
    eval_map = imfilter(eval_map, fspecial('gaussian', [8, 8], 8));
end