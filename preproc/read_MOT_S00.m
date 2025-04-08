%% get motion data
% sampling rate is 240 Hz, 
% position data is in inch relative to electromagnetic source

ftPath   = '../../../m-lib/fieldtrip/'; 
addpath(ftPath); ft_defaults;
bidsPath = '../../bids/';
rawPath  = '../../bids/sourcedata/';
srate    = 240; 

motionData = readtable(fullfile(rawPath, 'sub-S00_task-Grasping.csv'));
mData = motionData(:, {'Frame', 'Sensor' ,'X', 'Y', 'Z', ...
                                'Sensor_1', 'X_1', 'Y_1', 'Z_1', ...
                                'Sensor_2', 'X_2', 'Y_2', 'Z_2', ...
                                'Sensor_3', 'btn1_3'});
        % Button 1 of sensor 3 ("btn1_3") contains marker
                            
%% identify onsets and offsets of 3s movement segments 
AO = mData.btn1_3;
IdxON  = find(diff(AO) == 1) + 1;
IdxOFF = find(diff(AO) == -1) + 1;
changeIdx = [IdxON, IdxOFF, IdxOFF - IdxON];
rmv = find(changeIdx(:,3) < 700); % exclude marker before onset of experiment
changeIdx(rmv,:) = [];
fprintf("\nNumber of trials:\t%i\n", size(changeIdx, 1));
fprintf("\nSegment length:\t\t%.3f +- %.3f s\n\n", ...
            mean((changeIdx(:,2)-changeIdx(:,1)) * 1/srate), ...
            std((changeIdx(:,2)-changeIdx(:,1)) * 1/srate));

% what is the frameRate?


% find 0 -> 1 or 1 -> 0

                            
% trial and session
numTrial = 24;
numSession = 4;
wholeTrial = numTrial*numSession;
halfTrial = wholeTrial./2;

% get the timestamp 0/1
AO_col = 41;  % Sensor4 btn1

% set the index
startIdx = [1; changeIdx]; 
endIdx = [changeIdx - 1; height(motionData)];

% create segment list
allSegments = cell(length(startIdx), 1);
for i = 1:length(startIdx)
    allSegments{i} = motionData(startIdx(i):endIdx(i), :);
end

% remove first two segments (the motionData before the experiment)
if length(allSegments) > 2
    allSegments(1:3) = [];
end

% remove odd number segments (trial start sign)
filteredSegments = allSegments(2:2:end);

% remove break/session ended segments
skipIdx = numTrial+1:numTrial+1:length(filteredSegments);
finalSegments = filteredSegments;
finalSegments(skipIdx) = [];

% save in structure
segments = struct();
for i = 1:length(finalSegments)
    segName = sprintf('trial_%d', i);
    segments.(segName) = finalSegments{i};
end

% display data
disp(segments);


% get the timestamp 0/1
AO_col = 41;  % Sensor4 btn1
AO = motionData{:, AO_col};

% find 0 -> 1 or 1 -> 0
changeIdx = find(diff(AO) ~= 0) + 1;

% set the index
startIdx = [1; changeIdx]; 
endIdx = [changeIdx - 1; height(motionData)];

% create segment list
allSegments = cell(length(startIdx), 1);
for i = 1:length(startIdx)
    allSegments{i} = motionData(startIdx(i):endIdx(i), :);
end

% remove first two segments (the data before the experiment)
if length(allSegments) > 2
    allSegments(1:3) = [];
end

% remove odd number segments (trial start sign)
filteredSegments = allSegments(2:2:end);

% remove break/session ended segments
skipIdx = numTrial+1:numTrial+1:length(filteredSegments); 
finalSegments = filteredSegments;
finalSegments(skipIdx) = []; 

% create structure
segments = struct();
for i = 1:length(finalSegments)
    segName = sprintf('trial_%d', i);
    segments.(segName) = finalSegments{i};
end
% disp(segments);

% separte between movement task and imaging task, and save
for i = 1:halfTrial
    segName = sprintf('trial_%d', i);
    aSegments.(segName) = finalSegments{i};
end

for j = (halfTrial+1):wholeTrial
    segName = sprintf('trial_%d', j-halfTrial);
    bSegments.(segName) = finalSegments{j};
end

firstTask = expInfo.task(1);
    MovName = 'cleaned_Movement_S';
    ImgName = 'cleaned_Imaging_S';

if firstTask == 1
    MovData = bSegments;
    ImgData = aSegments;
else
    ImgData = bSegments;
    MovData = aSegments;
end

fileName = [outpath, MovName, '1', '.mat'];
save(fileName, "MovData");

fileName = [outpath, ImgName, '1', '.mat'];
save(fileName, "ImgData");
% 
% 
% 
% 

% 
% % per-subject information (modify these)
% sub = 'S00';
% age = 27;
% sex = 'm';
% capsize = 58;
% 
% % files
% eegfilename      = [rawPath, 'sub-', sub, '_task-Grasping.vhdr'];
% hdr              = ft_read_header(eegfilename);
% protocolFileName = [rawPath, 'sub-', sub, '_task-Grasping.mat'];
% protocol         = importdata(protocolFileName);
% 
% allElecs         = ft_read_sens('easycap-M1.txt'); % in fieldtrip templates
% removeElecs = find(~ismember(allElecs.label, hdr.label));
% elecs  = allElecs;
% elecs.chanpos(removeElecs,:) = [];
% elecs.chantype(removeElecs)  = [];
% elecs.chanunit(removeElecs)  = [];
% elecs.elecpos(removeElecs,:) = [];
% elecs.label(removeElecs)     = [];
% elecs.label(63) = {'VEOG'};
% elecs.chantype(63) = {'VEOG'};
% elecs.chanpos(63,:) = [nan nan nan];
% elecs.elecpos(63,:) = [nan nan nan];
% elecs.chanunit(63) = elecs.chanunit(62);
% elecs.label(64) = {'HEOG'};
% elecs.chantype(64) = {'HEOG'};
% elecs.chanpos(64,:) = [nan nan nan];
% elecs.elecpos(64,:) = [nan nan nan];
% elecs.chanunit(64) = elecs.chanunit(62);
% 
% % events and onsets
% event = ft_read_event(eegfilename);
% event = ft_filter_event(event, 'type', 'Stimulus');
% event = event(ismember({event.value}, {'S  5', 'S  6'})); % keep only 
% 
% vpixxOffset_s       = 0.006; % fix offset of 6 ms at ViewPixx
% vpixxOffset_samples = vpixxOffset_s / (1/hdr.Fs);
% 
% sample   = ([event(:).sample]-vpixxOffset_samples)'; 
% onset    = ((sample - 1) * (1/hdr.Fs));
% duration = zeros(numel(onset),1) + (1/hdr.Fs);
% value    = {event.value}';
% type     = {event.type}';
% cfgtable = table(sample, onset, duration, type, value);
% protable = array2table(protocol.protocol, ...
%              'VariableNames', {'blocknum', 'trialnum', 'keyCode', 'rating', 'responseTime', ...
%              'movement', 'movType', 'plannedISI', 'actualISI', 'CueTime', 'TaskTime'});
% protable.movement = categorical(protable.movement, 1:3, {'mouth', 'shoulder', 'forward'});
% protable.movType  = categorical(protable.movType, 5:6, {'real', 'imagined'});
% alltable = [cfgtable, protable]; % added information from stimulus protocol file
% alltable.type = char(alltable.type);
% 
% % standard cfg for data2bids
% cfg = [];
% cfg.method    = 'copy';
% cfg.suffix    = 'eeg';
% cfg.dataset   = eegfilename;
% cfg.bidsroot  = bidsPath;
% cfg.sub       = sub;
% cfg.participants.age              = age;
% cfg.participants.sex              = sex;
% cfg.participants.responsehand     = protocol.response_hand;
% fmt = 'yyyy-MM-dd''T''HH:mm:ss''Z''';
% cfg.scans.acq_time = datetime(protocol.date, 'Format', fmt); % convert to RFC 3339, UTC+0
% 
% cfg.InstitutionName             = 'University of Regensburg';
% cfg.InstitutionalDepartmentName = 'Institute for Psychology';
% cfg.InstitutionAddress          = 'Universitaetsstrasse 31, 93053 Regensburg, Germany';
% cfg.Manufacturer                = 'Brain Products GmbH, Gilching, Germany';
% cfg.ManufacturersModelName      = 'BrainAmp MR plus';
% cfg.dataset_description.Name    = 'Real and imagined movement for food intake';
% cfg.dataset_description.Authors = {'Gregor Volberg', 'Philip Burkhard', 'Angelika Lingnau'};
% 
% cfg.TaskName        = 'graspingMotorImagery';
% cfg.TaskDescription = 'Participants performed three different arm movements related to food intake (to mouth, to shoulder, forward). In different blocks, the motion was either real or imagined. The task was performed with concurrent EEG recording and motion tracking.';
% 
% cfg.eeg.PowerLineFrequency = 50;   
% cfg.eeg.EEGReference       = 'FCz';
% cfg.eeg.EEGGround          = 'AFz'; 
% cfg.eeg.CapManufacturer    = 'EasyCap'; 
% cfg.eeg.CapManufacturersModelName = 'M1'; 
% cfg.eeg.EEGChannelCount    = 62;
% cfg.eeg.EOGChannelCount    = 2; 
% cfg.eeg.RecordingType      = 'continuous';
% cfg.eeg.EEGPlacementScheme = '10-10';
% cfg.eeg.SoftwareFilters    = 'n/a';
% cfg.eeg.HeadCircumference  = capsize; 
% 
% cfg.elec                   = elecs;
% cfg.coordsystem.EEGCoordinateSystem = 'CapTrak'; % RAS orientation
% cfg.coordsystem.EEGCoordinateUnits  = 'mm';
% 
% % these do not work
% cfg.channels.low_cutoff    = 0.1;
% cfg.channels.high_cutoff    = 1000;
% cfg.electrodes.type        = 'ring';
% cfg.electrodes.material    = 'Ag/AgCl'; 
% 
% %
% alltable.truth    = cellstr(alltable.truth);
% alltable.language = cellstr(alltable.language);
% alltable.visual   = cellstr(alltable.visual);
% cfg.events = alltable;%cfgevt.event;
% 
% data2bids(cfg);
% 
