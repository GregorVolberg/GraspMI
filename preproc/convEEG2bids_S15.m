% from https://www.fieldtriptoolbox.org/example/other/bids_eeg/
ftPath   = '../../../m-lib/fieldtrip/'; 
addpath(ftPath); ft_defaults;
bidsPath = '../../bids/';
rawPath  = '../../bids/sourcedata/';

%% per-subject information (modify these)
sub = 'S15';
age = 32;
sex = 'f';
capsize = 56;

%% files
eegfilename      = [rawPath, 'sub-', sub, '_task-Grasping.vhdr'];
hdr              = ft_read_header(eegfilename);
protocolFileName = [rawPath, 'sub-', sub, '_task-Grasping.mat'];
protocol         = importdata(protocolFileName);

allElecs         = ft_read_sens('easycap-M1.txt'); % in fieldtrip templates
removeElecs = find(~ismember(allElecs.label, hdr.label));
elecs  = allElecs;
elecs.chanpos(removeElecs,:) = [];
elecs.chantype(removeElecs)  = [];
elecs.chanunit(removeElecs)  = [];
elecs.elecpos(removeElecs,:) = [];
elecs.label(removeElecs)     = [];
elecs.label(63) = {'VEOG'};
elecs.chantype(63) = {'VEOG'};
elecs.chanpos(63,:) = [nan nan nan];
elecs.elecpos(63,:) = [nan nan nan];
elecs.chanunit(63) = elecs.chanunit(62);
elecs.label(64) = {'HEOG'};
elecs.chantype(64) = {'HEOG'};
elecs.chanpos(64,:) = [nan nan nan];
elecs.elecpos(64,:) = [nan nan nan];
elecs.chanunit(64) = elecs.chanunit(62);

%% events and onsets
event = ft_read_event(eegfilename);
event = ft_filter_event(event, 'type', 'Stimulus'); % 234 trials
event = event(ismember({event.value}, {'S 20'})); % 234 trials

vpixxOffset_s       = 0.006; % fix offset of 6 ms at ViewPixx
vpixxOffset_samples = vpixxOffset_s / (1/hdr.Fs);

sample   = ([event(:).sample]-vpixxOffset_samples)'; 
onset    = ((sample - 1) * (1/hdr.Fs));
duration = zeros(numel(onset),1) + (1/hdr.Fs);
markerValue    = {event.value}';
markerType     = {event.type}';
cfgtable = table(sample, onset, duration, markerType, markerValue);
protable = array2table(protocol.protocol, ...
             'VariableNames', {'blocknum', 'trialnum', 'keyCode', 'rating', 'responseTime', ...
             'movement', 'movType', 'plannedISI', 'actualISI', 'CueTime', 'TaskTime'});
protable.movement = cellstr(categorical(protable.movement, 1:3, {'mouth', 'shoulder', 'forward'}));
protable.movType  = cellstr(categorical(protable.movType, 21:22, {'real', 'imagined'}));
alltable = [cfgtable, protable]; % added information from stimulus protocol file
%alltable.type = char(alltable.type);

%% standard cfg for data2bids
cfg = [];
cfg.method    = 'copy';
cfg.suffix    = 'eeg';
cfg.dataset   = eegfilename;
cfg.bidsroot  = bidsPath;
cfg.sub       = sub;
%cfg.participants.age              = age;
%cfg.participants.sex              = sex;
%cfg.participants.responsehand     = protocol.response_hand;
fmt = 'yyyy-MM-dd''T''HH:mm:ss''Z''';
cfg.scans.acq_time = datetime(protocol.date, 'Format', fmt); % convert to RFC 3339, UTC+0

cfg.InstitutionName             = 'University of Regensburg';
cfg.InstitutionalDepartmentName = 'Institute for Psychology';
cfg.InstitutionAddress          = 'Universitaetsstrasse 31, 93053 Regensburg, Germany';
cfg.Manufacturer                = 'Brain Products GmbH, Gilching, Germany';
cfg.ManufacturersModelName      = 'BrainAmp MR plus';
cfg.dataset_description.Name    = 'Real and imagined movement for food intake';
cfg.dataset_description.Authors = {'Gregor Volberg', 'Philip Burkhard', 'Angelika Lingnau'};

cfg.TaskName        = 'graspingMotorImagery';
cfg.TaskDescription = 'Participants performed three different arm movements related to food intake (to mouth, to shoulder, forward). In different blocks, the motion was either real or imagined. The task was performed with concurrent EEG recording and motion tracking.';

cfg.eeg.PowerLineFrequency = 50;   
cfg.eeg.EEGReference       = 'FCz';
cfg.eeg.EEGGround          = 'AFz'; 
cfg.eeg.CapManufacturer    = 'EasyCap'; 
cfg.eeg.CapManufacturersModelName = 'M1'; 
cfg.eeg.EEGChannelCount    = 62;
cfg.eeg.EOGChannelCount    = 2; 
cfg.eeg.RecordingType      = 'continuous';
cfg.eeg.EEGPlacementScheme = '10-10';
cfg.eeg.SoftwareFilters    = 'n/a';
cfg.eeg.HeadCircumference  = capsize; 

cfg.elec                   = elecs;
cfg.coordsystem.EEGCoordinateSystem = 'CapTrak'; % RAS orientation
cfg.coordsystem.EEGCoordinateUnits  = 'mm';

%% these do not work
%cfg.channels.low_cutoff    = 0.1;
%cfg.channels.high_cutoff    = 1000;
%cfg.electrodes.type        = 'ring';
%cfg.electrodes.material    = 'Ag/AgCl'; 

%%
%alltable.truth    = cellstr(alltable.truth);
%alltable.language = cellstr(alltable.language);
%alltable.visual   = cellstr(alltable.visual);
cfg.events = alltable;%cfgevt.event;

data2bids(cfg);

