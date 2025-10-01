%% paths and file names
ftPath   = '../../../m-lib/fieldtrip/'; 
addpath(ftPath); ft_defaults;

bidsPath = '../../bids/';
rawPath  = '../../bids/sourcedata/';
participant = 'S14';
%subj        = ['sub-', participant];
%task        = '_task-Grasping';
%tracksys    = '_tracksys-PolhemusViper';
rawdatafile = ['sub-', participant, '_task-Grasping.csv'];
protocolFileName = [rawPath, 'sub-', participant, '_task-Grasping.mat'];

%% polhemus csv to ft raw data
SRATE    = 240; % sampling rate is 240 Hz, 
motionData = readtable(fullfile(rawPath, rawdatafile));
time_axis  = [0:size(motionData,1)-1]' * (1/SRATE); %the time axis, , relative to start of recodring, is not saved anywere
button1    = motionData.btn1_3; % Button 1 of sensor 3 ("btn1_3") contains marker
mdata      = motionData(:, {'X', 'Y', 'Z', ...
                       'X_1', 'Y_1', 'Z_1', ...
                       'X_2', 'Y_2', 'Z_2'}); % the motion data
channel_names = {'T_pos_x', 'T_pos_y', 'T_pos_z', ...  % thumb
        'F_pos_x', 'F_pos_y', 'F_pos_z', ...  % Fovea radialis, between thumb and index finger
        'I_pos_x', 'I_pos_y', 'I_pos_z'}';     
hdr = [];
hdr.Fs          = 240;
hdr.label       = channel_names;
hdr.nChans      = numel(hdr.label);
hdr.nSamples    = size(motionData,1);
hdr.nSamplesPre = 0;
hdr.nTrials     = 1;
hdr.chanunit    = repmat({'cm'}, 1, numel(hdr.label))';
hdr.chantype    = repmat({'POS'}, 1, numel(hdr.label))';

inch2cm = @(x) x.* 2.54;
rawdata          = [];
rawdata.label    = channel_names;
rawdata.trial{1} = inch2cm(table2array(mdata)');
rawdata.time{1}  = time_axis';
rawdata.hdr      = hdr;

clear motionData

%% events
vpixxOffset_s       = 0.006; % fix offset of 6 ms at ViewPixx
vpixxOffset_samples = round(vpixxOffset_s / (1/hdr.Fs));
IdxON  = find(diff(button1) == 1) + 1 - vpixxOffset_samples;
IdxOFF = find(diff(button1) == -1) + 1 - vpixxOffset_samples;
changeIdx = [IdxON, IdxOFF, IdxOFF - IdxON];
rmv = find(changeIdx(:,3) < 700); % exclude marker before onset of experiment
changeIdx(rmv,:) = [];
fprintf("\nNumber of trials:\t%i", size(changeIdx, 1));
fprintf("\nSegment length:\t\t%.3f +- %.3f s\n\n", ...
            mean((changeIdx(:,2)-changeIdx(:,1)) * 1/SRATE), ...
            std((changeIdx(:,2)-changeIdx(:,1)) * 1/SRATE));
onset    = (changeIdx(:,1)-1) * (1/SRATE);
duration = repmat(1/SRATE, numel(changeIdx(:,1)), 1); %((changeIdx(:,2)-1) * (1/SRATE)) - ((changeIdx(:,1)-1) * (1/SRATE));
protocol = importdata(protocolFileName);
protable = array2table(protocol.protocol, ...
             'VariableNames', {'block', 'trial', 'keyCode', 'rating', 'response_time', ...
             'movement', 'type', 'plannedISI', 'ISI', 'cue_time', 'task_time'});
protable.movement = cellstr(categorical(protable.movement, 1:3, {'mouth', 'chin', 'forward'}));
protable.type = repmat({'real'}, length(protable.type), 1);
if protocol.starting_condition == 1 
    protable.type(ismember(protable.block, [2 4 6 8])) = {'imagined'};
elseif protocol.starting_condition == 2 
    protable.type(ismember(protable.block, [1 3 5 7])) = {'imagined'};
end
sample_point    = changeIdx(:,1);
sequence_number = 1:numel(changeIdx(:,1));
events = addvars(removevars(protable, [3 8]), onset, duration, sample_point, sequence_number', 'before', 'block');

%% cfg for converting to BIDS
cfg = [];
cfg.method    = 'convert'; 
cfg.events    = events;
cfg.writejson = 'yes';
cfg.writetsv  = 'yes';
cfg.suffix    = 'motion';
cfg.bidsroot  = bidsPath;
cfg.sub       = participant;

%cfg.scans.acq_time = datetime(protocol.date, 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''); % convert to RFC 3339, UTC+0

cfg.InstitutionName             = 'University of Regensburg';
cfg.InstitutionalDepartmentName = 'Institute for Psychology';
cfg.InstitutionAddress          = 'Universitaetsstrasse 31, 93053 Regensburg, Germany';
cfg.dataset_description.Name    = 'Real and imagined movement for food intake';
cfg.dataset_description.Authors = {'Gregor Volberg', 'Philip Burkhard', 'Miku Tsuboi', 'Angelika Lingnau'};
cfg.TaskName                    = 'grasping';
cfg.TaskDescription             = 'Participants performed three different arm movements related to food intake (to mouth, to chin, forward). In different blocks, the motion was either real or imagined. The task was performed with concurrent EEG recording and motion tracking.';
cfg.tracksys                    = 'PolhemusViper';
   

%% motion specific
cfg.motion.TrackingSystemName     = 'Polhemus Viper';%            = ft_getopt(cfg.motion, 'TrackingSystemName'        );
cfg.motion.Manufacturer           = 'Polhemus';
cfg.motion.ManufacturersModelName = 'Viper';
cfg.motion.SamplingFrequency      = SRATE; %ft_getopt(cfg.motion, 'SamplingFrequency'         );
cfg.motion.RecordingDuration      = time_axis(end); %ft_getopt(cfg.motion, 'RecordingDuration'         );
cfg.motion.RecordingType          = 'continuous';

%% channels
type          = repmat({'POS'}, 9, 1);
units         = repmat({'cm'}, 9, 1);
component     = {'x', 'y', 'z', 'x', 'y', 'z', 'x', 'y', 'z'}';
tracked_point = cellstr(strvcat(repmat('RightThumb', 3, 1), ...
                 repmat('RightFoveaRadialis', 3, 1), ...
                 repmat('RightIndexFinger', 3, 1)));
cfg.channels.name      = channel_names; 
cfg.channels.type      = type;
cfg.channels.units     = units; 
cfg.channels.component = component;
cfg.channels.tracked_point = tracked_point;

data2bids(cfg, rawdata);


template_filename     = dir([bidsPath, 'sub-', participant, '/motion/*channels.tsv']);
channels_json_filename = [template_filename.name(1:end-12), 'channels.json'];
copyfile('motion_channels.json', [bidsPath, 'sub-', participant, '/motion/', channels_json_filename]);