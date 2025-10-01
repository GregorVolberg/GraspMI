%% paths and files
vp       = 'S19';

ftPath   = '../../../m-lib/fieldtrip/';
bidsPath = '../../bids/';

eegfilebids     = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_eeg.vhdr'];
eventsfile      = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_events.tsv'];

%% set path
addpath(ftPath); ft_defaults;

%% define segments
cfg                    = [];
cfg.trialfun           = 'ft_trialfun_bids_graspmi'; % custom trialfun, see ./preproc/ft_trialfun_bids_graspmi.m
cfg.trialdef.prestim   = 0.5; 
cfg.trialdef.poststim  = 3;
cfg.dataset            = eegfilebids;
cfg.representation     = 'table';

cfg = ft_definetrial(cfg);

%% add preprocessing options and databrowser options to cfg
cfg.preproc.lpfilter = 'yes';
cfg.preproc.lpfreq   = 40;
cfg.preproc.hpfilter = 'yes';
cfg.preproc.hpfreq   = 1;
cfg.preproc.demean   = 'yes';
cfg.continuous   = 'no';
cfg.channel      = 'all';

%% manually mark artifacts in data browser and write down bad channels
cfg = ft_databrowser(cfg);

badchans = {'PO3', 'TP10', 'P5', 'TP9'}; % enter 'n/a' if no bad channels

%% reject bad trials (i.e. modify field trl in cfg)
cfg = ft_rejectartifact(cfg);

%% get artefact trial numbers (i. e., set difference between old and new trl)
trlold = cfg.trlold.trialnum + ((cfg.trlold.blocknum - 1) * max(cfg.trlold.trialnum));
trlnew = cfg.trl.trialnum + ((cfg.trl.blocknum - 1) * max(cfg.trl.trialnum));
bad_trials = setdiff(trlold, trlnew);

artefact_1stpass = zeros(size(trlold));
artefact_1stpass(bad_trials) = 1;

%% add column with bad trials, and bad channels, to events file
allevents = readtable(eventsfile, 'FileType', 'text', 'Delimiter', '\t');

if ismember('artefact_1stpass', allevents.Properties.VariableNames)
    allevents.artefact_1stpass = artefact_1stpass; % overwrite
else
    allevents = [allevents, table(artefact_1stpass)]; % add
end

bad_channels = repmat(strjoin(badchans, ','), size(allevents, 1), 1);
if ismember('bad_channels', allevents.Properties.VariableNames)
    allevents.bad_channels = bad_channels; % overwrite
else
    allevents = [allevents, table(bad_channels)]; % add
end

writetable(allevents, eventsfile, 'FileType', 'Text', 'Delimiter', '\t');

