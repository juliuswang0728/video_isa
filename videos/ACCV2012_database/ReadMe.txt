DATABASE CONTENT :

1) The folder 'videos' contains each video in "wmv" format

2) The folder 'raw data' contains the corresponding eyetracker data. 
They are stored in the 'raw_data' matrix where:

		--> size 1: X and Y coordinates
		--> size 2: Number of frames
		--> size 3: Number of observers


DATABASE VISUALIZATION

If you want to visualize a given video and frame in the ASCMN database, run "Example.m" with the video and frame number you want.


BENCHMARK

1) Add the folder "confidence-interval-AUC" to your Matlab Path 

2) Replace in the script "Evaluation.m" the line under the comment "Your saliency map" by your own model

3) Run the script and you will get a .mat file with the metrics results for each video frame

4) Send us your .mat file so we can add your model to this webpage


EXTRA NOTES

1) If you need raw data with a larger sampling rate, please contact us.

2) If you use this code, please cite the ACCV 2012 paper:
N. RICHE, M. MANCAS, D. ?ULIBRK, V. ?RNOJEVIC, B. GOSSELIN, T. DUTOIT, 2012, "Dynamic saliency models and human attention: a comparative study on videos", 
Proceedings of the 11th Asian Conference on Computer Vision (ACCV), Daejeon, Korea, November 5-9.