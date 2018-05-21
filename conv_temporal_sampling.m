function [sampled_chunks, col_new, row_new] = conv_temporal_sampling(...
    X, sampled_chunks, max_tp_size, max_sp_size, max_sp_stride)

    frame_height = size(X, 2);
    frame_width = size(X, 3);
    
    chunkIdx = 1;
    row_new = 0;
    for row=1:max_sp_stride:frame_height
        start_y = row;
        end_y = start_y + max_sp_size - 1;
        if end_y > frame_height
            continue
        end
        row_new = row_new + 1;
        col_new = 0;
        for col=1:max_sp_stride:frame_width
            start_x = col;
            end_x = start_x + max_sp_size - 1;
            if end_x > frame_width
                continue;
            end
            col_new = col_new + 1;
            chunk = X(1:max_tp_size, start_y: end_y, start_x: end_x, 1:3);
            sampled_chunks(:, chunkIdx) = reshape(chunk, numel(chunk), 1);
            chunkIdx = chunkIdx + 1;
        end
    end
    
    sampled_chunks = sampled_chunks(:, 1:chunkIdx-1);
end