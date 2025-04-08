% from https://www.fieldtriptoolbox.org/example/other/bids_eeg/
ftPath   = '../../../m-lib/fieldtrip/'; 
addpath(ftPath); ft_defaults;
bidsPath = '../../data/bids/';
rawPath  = '../../data/raw/';

%% per-subject information (modify these)
age = 23;
sex = 'f';
sub = 'S00';

%% files
eegfilename      = [rawPath, sub, '.vhdr'];
hdr              = ft_read_header(eegfilename);
protocolFileName = [rawPath, 'sub-', sub, '_task-credibilityJudgement.mat'];
protocol         = importdata(protocolFileName);

allElecs         = ft_read_sens('easycap-M1.txt');
removeElecs = find(~ismember(allElecs.label, hdr.label));
elecs  = allElecs;
elecs.chanpos(removeElecs,:) = [];
elecs.chantype(removeElecs)  = [];
elecs.chanunit(removeElecs)  = [];
elecs.elecpos(removeElecs,:) = [];
elecs.label(removeElecs)     = [];

%% events and onsets
event = ft_read_event(eegfilename);
event = ft_filter_event(event, 'type', 'Stimulus');

vpixxOffset_s       = 0.006; % fix offset of 6 ms at ViewPixx
vpixxOffset_samples = vpixxOffset_s / (1/hdr.Fs);

sample   = ([event(:).sample]-vpixxOffset_samples)'; 
onset    = ((sample - 1) * (1/hdr.Fs));
duration = zeros(numel(onset),1) + (1/hdr.Fs);
value    = {event.value}';
type     = {event.type}';
cfgtable = table(sample, onset, duration, type, value);
alltable = [cfgtable, protocol.protocol]; % added information from stimulus protocol file

%% standard cfg for data2bids
cfg = [];
cfg.method    = 'copy';
cfg.suffix    = 'eeg';
cfg.dataset   = eegfilename;
cfg.bidsroot  = bidsPath;
cfg.sub       = sub;
cfg.participants.age              = age;
cfg.participants.sex              = sex;
cfg.participants.responsehand     = protocol.response_hand;
fmt = 'yyyy-MM-dd''T''HH:mm:ss''Z''';
cfg.scans.acq_time = datetime(protocol.date, 'Format', fmt); % convert to RFC 3339, UTC+0

cfg.InstitutionName             = 'University of Regensburg';
cfg.InstitutionalDepartmentName = 'Institute for Psychology';
cfg.InstitutionAddress          = 'Universitaetsstrasse 31, 93053 Regensburg, Germany';
cfg.Manufacturer                = 'Brain Products GmbH, Gilching, Germany';
cfg.ManufacturersModelName      = 'BrainAmp MR plus';
cfg.dataset_description.Name    = 'Credibility Judgements for websites';
cfg.dataset_description.Authors = {'Gregor Volberg', 'David Elsweiler', 'Sophia Eberhardt', 'Tanja Holtermann'};

cfg.TaskName        = 'credibilityJudgements';
cfg.TaskDescription = 'Participants judged the credibility of fullscreen images of websites that contained true or fake news, and mimicking the visual aesthetics and the language style of high or low quality media outlets.';

cfg.eeg.PowerLineFrequency = 50;   
cfg.eeg.EEGReference       = 'FCz';
cfg.eeg.EEGGround          = 'AFz'; 
cfg.eeg.CapManufacturer    = 'EasyCap'; 
cfg.eeg.CapManufacturersModelName = 'M1'; 
cfg.eeg.EEGChannelCount    = 62;
cfg.eeg.EOGChannelCount    = 1; 
cfg.eeg.RecordingType      = 'continuous';
cfg.eeg.HeadCircumference  = 58; %% einbauen in stim structure?
cfg.eeg.EEGPlacementScheme = '10-10';

cfg.elec                   = elecs;
cfg.coordsystem.EEGCoordinateSystem = 'RAS';
cfg.coordsystem.EEGCoordinateUnits  = 'mm';

alltable.truth    = cellstr(alltable.truth);
alltable.language = cellstr(alltable.language);
alltable.visual   = cellstr(alltable.visual);
cfg.events = alltable;%cfgevt.event;

data2bids(cfg);

