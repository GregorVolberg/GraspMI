function [] = get_ICs()
%% paths and files
ftPath   = '../../../m-lib/fieldtrip/';
addpath(ftPath); ft_defaults;

bidsPath      = '../../bids/';

layoutFile = 'EEG1010.lay';    % contained in fieldtrip template folder
elecsFile  = 'easycapM10.mat'; % contained in fieldtrip template folder

tmp = ft_read_tsv([bidsPath, 'participants.tsv']);
subjects     = extractAfter(tmp.participant_id, 4); clear tmp

for n = 1:numel(subjects)
    vp             = subjects{n};    
    eegfilebids    = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_eeg.vhdr'];
    eventsfile     = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_events.tsv'];
    componentsfile = [bidsPath, 'derivates/independent_components_', vp, '.mat'];
    
%% set path, load files
    addpath(ftPath); ft_defaults;
    events   = readtable(eventsfile, 'FileType', 'text', 'Delimiter', '\t');

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
    %cfg.max_RT             = 2; % only real-movment trials with RTs <= 2 s
    % later with ft_selectdata
    cfg = ft_definetrial(cfg);

%% add pre-processing options to cfg and perform pre-processing
    cfg.channel   = {'all', '-VEOG', '-HEOG'}; % C1 through C62
    cfg.demean    = 'yes';
    cfg.hpfilter = 'yes';
    cfg.hpfreq   = 1;
    cfg.lpfilter = 'yes';
    cfg.lpfreq   = 40;

    preproc = ft_preprocessing(cfg);

%% manually remove elec information on VEOG and HEOG (interferes with ft_channelrepair)
    EOG = ismember(preproc.elec.label, {'VEOG', 'HEOG'});
    preproc.elec.label(EOG) = [];
    preproc.elec.elecpos(EOG,:) = [];

%% read bad channels
    bad_channels     = strsplit(events.bad_channels{1}, ','); 

    %% run ICA
    cfg = [];
    cfg.channel    = setdiff(preproc.elec.label, bad_channels);
    cfg.randomseed = 7; % set seed for replicable results
    ic             = ft_componentanalysis(cfg, preproc);
    
    save(componentsfile, 'ic');

end
end