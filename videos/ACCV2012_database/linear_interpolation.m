function [frame] = linear_interpolation(x, y, x_ratio)
    y_ratio = 1.0 - x_ratio;
    frame = x * x_ratio + y * y_ratio;
end