%% paths and files
vp       = 'S23';

ftPath      = '../../../m-lib/fieldtrip/';
bidsPath    = '../../bids/';
eegfilebids = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_eeg.vhdr'];
eventsfile  = [bidsPath, 'sub-', vp, '/eeg/sub-', vp, '_task-graspingMotorImagery_events.tsv'];
componentsfile  = [bidsPath, 'derivates/independent_components_', vp, '.mat'];

%% set paths, load files
addpath(ftPath); ft_defaults;

%% read events file
allevents        = readtable(eventsfile, 'FileType', 'text', 'Delimiter', '\t');
if ismember(allevents.bad_channels(1), 'n/a')
    bad_channels = [];
else
bad_channels     = strsplit(allevents.bad_channels{1}, ',');
end

if isnumeric(allevents.component_number)
    component_number = allevents.component_number(1);
else
component_number = str2double(strsplit(allevents.component_number{1}, ','));
end


%% define trials II (trial selection)
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
if ismember(allevents.bad_channels(1), 'n/a')
cfg.channel   = {'all', '-VEOG', '-HEOG'}; 
else
cfg.channel   = [{'all', '-VEOG', '-HEOG'}, strcat('-', bad_channels)]; 
end
cfg.demean    = 'yes';
cfg.hpfilter  = 'yes';
cfg.hpfreq    = 1;
cfg.lpfilter  = 'yes';
cfg.lpfreq    = 40;
preproc  = ft_preprocessing(cfg);
allelecs = preproc.elec;

%% again with EOG channels
cfg.channel   = {'VEOG', 'HEOG'}; 
eogs = ft_preprocessing(cfg);

%% manually remove elec information for VEOG and HEOG (interferes with ft_channelrepair)
EOG = ismember(preproc.elec.label, {'VEOG', 'HEOG'});
preproc.elec.label(EOG) = [];
preproc.elec.elecpos(EOG,:) = [];

%% read components file
ic = importdata(componentsfile);

%% reject components
cfg = [];
cfg.component  = component_number;
icCorrected    = ft_rejectcomponent(cfg, ic, preproc);

%% repair bad channels
cfg = [];
cfg.template = 'elec1010_neighb.mat'; % contain in fieldtrip template folder
cfg.method   = 'template';
neighb = ft_prepare_neighbours(cfg);

if ~isempty(bad_channels)
    cfgrep            = [];
    cfgrep.missingchannel = bad_channels; 
    cfgrep.neighbours     = neighb;
    cfgrep.method  = 'average';
    icRepaired        = ft_channelrepair(cfgrep, icCorrected);
    else
    icRepaired        = icCorrected;   
end

%% append EOG channels to EEG data
cfg = [];
cfg.keepsampleinfo = 'yes';
eeg = ft_appenddata(cfg, icRepaired, eogs);
eeg.elec = allelecs;

%% manually mark remaininig artifacts in databrowser
cfg = [];
cfg.channel      = 'all';
cfg.continuous   = 'no';
cfg.allowoverlap = 'yes';
cfg = ft_databrowser(cfg, eeg);

%% identify trial index for artifacts
artifacts = num2cell(cfg.artfctdef.visual.artifact(:,1));
row_indx  = cellfun(@(x) find(and(x >= eeg.sampleinfo(:,1), x <= eeg.sampleinfo(:,2))), artifacts);
artefact_2ndpass = zeros(size(allevents, 1), 1); 
bad_trials       = eeg.trialinfo.trialnum(row_indx) + ((eeg.trialinfo.blocknum(row_indx) - 1) * max(allevents.trialnum));
artefact_2ndpass(bad_trials) = 1;

%% add column with bad trials marked to events file
if ismember('artefact_2ndpass', allevents.Properties.VariableNames)
    allevents.artefact_2ndpass = artefact_2ndpass; % overwrite
else
    allevents = [allevents, table(artefact_2ndpass)]; % add
end

writetable(allevents, eventsfile, 'FileType', 'Text', 'Delimiter', '\t');

