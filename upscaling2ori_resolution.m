function sal = upscaling2ori_resolution(saliency, frame_width, frame_height)
    sal = imfilter(saliency, fspecial('Gaussian', [3 3], 2), 'replicate');        
    % normalize saliency map back to original frame size
    sal = imresize(sal, [frame_height, frame_width]);
    sal = ( sal - min(sal(:)) ) / ( max(sal(:)) - min(sal(:)) );
end