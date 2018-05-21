clear all; close all; clc;

% for each video in the database
for video = 1:1:24
 input_filename = sprintf('saliency_maps/video%d_tp_8_8_test.mat', video);
 
 if     video ==1  
                  N_frames = 878;
 elseif video == 2 
                  N_frames = 125;
 elseif video == 3 
                  N_frames = 627;
 elseif video == 4 
                  N_frames = 125;
 elseif video == 5 
                  N_frames = 834;
 elseif video == 6 
                  N_frames = 37;
 elseif video == 7 
                  N_frames = 462;
 elseif video == 8 
                  N_frames = 150;
 elseif video == 9 
                  N_frames = 881;
 elseif video == 10 
                  N_frames = 466;
 elseif video == 11 
                  N_frames = 1142;
 elseif video == 12
                  N_frames = 103;
 elseif video == 13 
                  N_frames = 888;
 elseif video == 14 
                  N_frames = 71;
 elseif video == 15 
                  N_frames = 950;
 elseif video == 16 
                  N_frames = 113;
 elseif video == 17 
                  N_frames = 785;
 elseif video == 18 
                  N_frames = 113;
 elseif video == 19 
                  N_frames = 240;
 elseif video == 20 
                  N_frames = 113;
 elseif video == 21 
                  N_frames = 749;
 elseif video == 22 
                  N_frames = 31;
 elseif video == 23 
                  N_frames = 143;
 elseif video == 24 
                  N_frames = 154;             
 end
 

AUROC_score   = [];
NSS_score   = [];
KLDIV_score = [];

se = strel('ball',4,2);
se1 = strel('rectangle',[12 2]);

% for each frame in the video
for frame = 1:1:N_frames
    
    disp(strcat('Video: ',num2str(video),' -- Frame: ',num2str(frame)))
    
    % Video Reader: only works in the windows system (if you use other systems, we can provide the corresponding frames on request.)
    %name=strcat('videos/video',num2str(video),'.wmv');
    %xyloObj = mmreader(name);
    %mov = read(xyloObj, frame); 
    
    % Raw_data Reader
    filename=strcat('raw_data/raw_data_video',num2str(video),'.mat');
    load(filename)
    Image = RawData2Image(raw_data,frame,vidHeight, vidWidth);

    Iet = imfilter(imdilate(Image,strel('disk',10)),fspecial('gaussian',60,20),'replicate');
    Iet = (Iet-min(Iet(:)))./(max(Iet(:))-min(Iet(:)));    
    level = 0.7;
    ET = im2bw(Iet,level);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%% Your saliency map %%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
  % Please replace here with your own model 
  % ---------------------------------------
  
  % map = your_model(mov); 

  % post processing for fair evaluation
    map = imdilate(map,se);
    map = imdilate(map,se1);
    map = imfilter(map, fspecial('gaussian', [8, 8], 8));


     
  % Comparison metrics
               
                % 1) KL-Div 
            
                   score = calcKLDivscore(ET,map);
                   KLDIV_score(1,frame) = mean(score);

                % 2) NSS

                   score1 = calcNSSscore(map,ET);
                   NSS_score(1,frame) = mean(score1);
                   
                % 3) AUROC

                   Iet1 = reshape(Iet,size(Iet,1)*size(Iet,2),1);
                    
                   map2 = double(imresize(map,size(Iet),'nearest'));
                   map3 = reshape(map2,size(map2,1)*size(map2,2),1);  
                                      
                   [A,Aci] = auc([Iet1,map3],0.05,'hanley');
                   AUROC_score(1,frame) = mean(A);
                                
end
   
% for each video, the metrics score are saved in a .mat file
% you can change the .mat name if needed
name = strcat('Your_model_name_video',num2str(video),'.mat');
save(name,'KLDIV_score','NSS_score','AUROC_score')

end

        
   


