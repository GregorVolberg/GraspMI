%% paths and files
vp       = 'S08';   

bidsPath    = '../../bids/';
onsetsfile  = ['../results_motion/', vp, '_movement_onsets.csv'];
eventsfile  = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_events.tsv'];

oldevents   = readtable(eventsfile, 'FileType', 'text', 'Delimiter', '\t');
disp(['old: ', num2str(size(oldevents))]);
newevents   = readtable(onsetsfile);
disp(['new: ', num2str(size(newevents))]);
allevents   = [oldevents, newevents];
disp(['all: ', num2str(size(allevents))]);

writetable(allevents, eventsfile, 'FileType', 'Text', 'Delimiter', '\t');

