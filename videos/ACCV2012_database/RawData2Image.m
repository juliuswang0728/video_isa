function Volume = Data2Image(fixation,frame,vidHeight, vidWidth)



Volume = zeros(vidHeight, vidWidth, 1); 
i=frame;

    for j=1:size(fixation,3)
        if and(fixation(1,i,j)>0, fixation(2,i,j)>0)
    Volume(fixation(2,i,j), fixation(1,i,j), 1) = 1;
        end
    end
