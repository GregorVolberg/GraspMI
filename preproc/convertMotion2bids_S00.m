%% Files,  paths, constants
participant = 'S00';
subj        = ['sub-', participant];
task        = '_task-Grasping';
tracksys    = '_tracksys-PolhemusViper';
rawdatafile = [subj, task '.csv'];
motion_tsv_name  = [subj, task, tracksys, '_motion.tsv'];
evt_tsv_name     = [subj, task, tracksys, '_events.tsv'];

ftPath   = '../../../m-lib/fieldtrip/'; 
addpath(ftPath); ft_defaults;
bidsPath = '../../bids/';
rawPath  = '../../bids/sourcedata/';
SRATE    = 240; % sampling rate is 240 Hz, 

%% read motion data
motionData = readtable(fullfile(rawPath, rawdatafile));
mData = motionData(:, {'X', 'Y', 'Z', ...
                       'X_1', 'Y_1', 'Z_1', ...
                       'X_2', 'Y_2', 'Z_2'});
motiontsv = table2array(mData); 
button1 = motionData.btn1_3; % Button 1 of sensor 3 ("btn1_3") contains marker

%% identify onsets and offsets of 3s movement segments 
IdxON  = find(diff(button1) == 1) + 1;
IdxOFF = find(diff(button1) == -1) + 1;
changeIdx = [IdxON, IdxOFF, IdxOFF - IdxON];
rmv = find(changeIdx(:,3) < 700); % exclude marker before onset of experiment
changeIdx(rmv,:) = [];
fprintf("\nNumber of trials:\t%i", size(changeIdx, 1));
fprintf("\nSegment length:\t\t%.3f +- %.3f s\n\n", ...
            mean((changeIdx(:,2)-changeIdx(:,1)) * 1/SRATE), ...
            std((changeIdx(:,2)-changeIdx(:,1)) * 1/SRATE));

%% event file
%clear motionData;
onset    = ((sample - 1) * (1/hdr.Fs));
duration = zeros(numel(onset),1) + (1/hdr.Fs);
markerValue    = {event.value}';
