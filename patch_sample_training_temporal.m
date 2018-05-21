function patch_sample_training_temporal(data_dir, imgExt, save_data_file_name, sampling_params)

spSize = sampling_params.spatial_size;
tpSize = sampling_params.temporal_size;
nSample = sampling_params.num_patches;

fileList = dir([data_dir filesep '*' imgExt]);
nFiles = length(fileList);

% we are going to store all the sampled patches (so they are 'chunks' of images for videos)
% here allocate possible maximal # of chunks, but trim the excessive
% columns afterwards (if the trailing columns haven't been used)
EST_MAX_CHUNKS = 20000;
sampled_chunks = zeros(spSize^2 * 3 * tpSize, EST_MAX_CHUNKS, 'uint8');

stride = sampling_params.temporal_stride;
num_skipped_frames = 1;
margin = 5; % 5 pixel margin to avoid the borders of the image
chunkIdx = 1; % this is a counter for the extracted chunks
%margin_temporal = tpSize; % margin (in the temporal dimension) to avoid boundaries of the sequences

for i = 1:nFiles
    fileName = [data_dir, filesep, fileList(i).name];
    fprintf('sample from file [%d] : %s\n', i, fileName);
    
    % reading video file
    video = VideoReader(fileName);
    idx = 1;
    frame_count = 1;
    % read video frame by frame
    X = zeros(tpSize, video.Height, video.Width, 3, 'uint8');
    while hasFrame(video)
        if frame_count >= 6000
            break
        end
        frame_count = frame_count + 1;
        if mod(frame_count, 1000) == 1
            fprintf('processed [%d] frames...\n', frame_count);
        end
        % also skip first some frames which are usually blank
        if mod(frame_count, (num_skipped_frames + 1)) == 1 || frame_count < 180
            % if num_skipped_frames = 1, only even frames are sampled (0, 2, 4, ...)
            readFrame(video);
            continue
        end
        X(idx, :, :, :) = readFrame(video);
        if idx >= tpSize
            % now we have enough frames to sample from
            for j = 1:nSample
                yPos = randi([1+margin, video.Height-margin-spSize+1]);
                xPos = randi([1+margin, video.Width-margin-spSize+1]);
                % first index is how many frames in a chunk
                chunk = X(1:tpSize, yPos: yPos+spSize-1, xPos: xPos+spSize-1, 1:3);
                % numel(): # of elements in chunk
                sampled_chunks(:, chunkIdx) = reshape(chunk, numel(chunk), 1);
                chunkIdx = chunkIdx + 1;
            end
            % discard the first n frames, n is stride here
            X(1:tpSize-stride, :, :, :) = X(1+stride:tpSize, :, :, :);
            X(tpSize-stride+1, :, :, :) = 0;
            idx = tpSize-stride;
        end
        
        idx = idx + 1;
    end
end

% trim excessive rows that might have been allocated
sampled_chunks = sampled_chunks(:, 1:chunkIdx - 1);
X = sampled_chunks;
fprintf('saving %s', save_data_file_name);
save(save_data_file_name, 'X', 'spSize', 'tpSize', '-v7.3');

end

