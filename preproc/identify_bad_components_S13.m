%% paths and files
vp       = 'S13';

ftPath   = '../../../m-lib/fieldtrip/';
bidsPath = '../../bids/';

layoutFile = 'EEG1010.lay';    % contained in fieldtrip template folder

eventsfile      = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_events.tsv'];
eegfilebids     = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_eeg.vhdr'];
componentsfile  = [bidsPath, 'derivates/independent_components_', vp, '.mat'];

%% set paths, load files
addpath(ftPath); ft_defaults;
oldevents   = readtable(eventsfile, 'FileType', 'text', 'Delimiter', '\t');
allevents   = oldevents;

%% define segments
cfg = [];
cfg.trialfun           = 'ft_trialfun_bids_graspmi'; % custom trialfun, see ./preproc/ft_trialfun_bids_graspmi.m
cfg.trialdef.prestim   = 0.5; 
cfg.trialdef.poststim  = 3;
cfg.dataset            = eegfilebids;
cfg.representation     = 'table';
cfg.trialdef.movement         = {'forward', 'mouth', 'shoulder'};  % see template trialfuns in fieldtrip for syntax
cfg.trialdef.valid_movement   = {'yes'};  
cfg.trialdef.artefact_1stpass = 0;
cfg = ft_definetrial(cfg);

%% add pre-processing options to cfg and perform pre-processing
cfg.channel   = {'VEOG', 'HEOG'}; % eye channels for correlation
cfg.demean    = 'yes';
cfg.hpfilter = 'yes';
cfg.hpfreq   = 1;
cfg.lpfilter = 'yes';
cfg.lpfreq   = 40;
preproc = ft_preprocessing(cfg);

%% read components file
ic = importdata(componentsfile);

eyes = cell2mat(preproc.trial);
ics  = cell2mat(ic.trial);
cors = corrcoef([eyes; ics]');
disp(find(sum(abs(cors(1:2,3:end)) > .4))); % any IC that correlates with eye channels


%% identify and save bad components
cfg              = [];
cfg.viewmode     = 'component';
cfg.continuous   = 'no';
cfg.layout       = layoutFile;
cfg.allowoverlap = 'yes';
ft_databrowser(cfg, ic);

component_number = [1, 4]';
component_number = repmat(strjoin(cellstr(num2str((component_number))), ','), size(oldevents, 1), 1);
component_type   = {'blink', 'eye movement'};
component_type = repmat(strjoin(component_type, ','), size(oldevents, 1), 1);

if ismember('component_number', allevents.Properties.VariableNames)
    allevents.component_number = component_number; % overwrite
else
    allevents = [allevents, table(component_number)]; % add
end

if ismember('component_type', allevents.Properties.VariableNames)
    allevents.component_type = component_type; % overwrite
else
    allevents = [allevents, table(component_type)]; % add
end

writetable(allevents, eventsfile, 'FileType', 'Text', 'Delimiter', '\t');
