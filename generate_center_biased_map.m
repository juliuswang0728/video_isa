function [saliency_cb] = generate_center_biased_map(frame_width, frame_height, sigma)
    [X, Y] = meshgrid([1:1:frame_width], [1:1:frame_height]);
    X = X / frame_width;
    Y = Y / frame_height;
    mu = [0.5 0.5];
    SIGMA = [sigma 0; 0 sigma];
    X = X(:);
    Y = Y(:);
    saliency_cb = mvnpdf([Y X], mu, SIGMA);
    saliency_cb = ( saliency_cb - min(saliency_cb) ) / (max(saliency_cb) - min(saliency_cb));
    saliency_cb = reshape(saliency_cb, frame_height, frame_width);
    
    %imshow(saliency_cb, []);
    
    sigma_str = num2str(sigma, '%10.0e');
    filename = sprintf('saliency_cb_wh_%d_%d_sigma_%s.png', frame_width, ...
                        frame_height, sigma_str);
    imwrite(saliency_cb, filename);
end