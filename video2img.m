for video_idx=1:24
    filename = sprintf('videos/video%d.mp4', video_idx);
    video = VideoReader(filename);
    i = 1;
    while hasFrame(video)
       img = readFrame(video);
       filename = sprintf('videos/video%d/%05d.jpg', video_idx, i);
       imwrite(img, filename);
       i = i+1;
    end
end