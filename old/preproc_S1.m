% movement extension of BIDS:
% https://www.nature.com/articles/s41597-024-03559-8 and https://www.fieldtriptoolbox.org/example/other/bids_motion/


%% paths and files
ftPath   = '../m-lib/fieldtrip/';
rawPath  = './data/'; 
orgPath  = './org/';
funcPath = './func'; % constum functions

layoutFile = [orgPath, '63equidistant_GreenleeLab_lay.mat'];
vpcode     = 'sub-S01'; % pilot run
%eegFile    = [rawPath vpcode, '_GraspMI.vhdr'];
eegfilebids = './data/bids/sub-S01/eeg/sub-S01_task-Grasping_eeg.vhdr';

%% set paths, load files
addpath(ftPath, orgPath, funcPath); ft_defaults;
lay = importdata(layoutFile);

%tst = ft_read_event(eegFile);

%% define segments
cfg = [];
cfg.trialdef.eventtype  = 'Stimulus';
cfg.trialdef.eventvalue = 'S  5'; % on/offset
cfg.dataset            = eegfilebids;
cfg.protocol = './data/S1.csv';  % PTB script
%cfg.trialfun = 'trialfun_onsetColorPatch'; % segment length is defined in trialfun
cfg.timeline = './data/S1_timeline.csv'; % Polhemus Viper data
cfg.trialfun = 'trialfun_onsetMovement'; % segment length is defined in trialfun
cfg = ft_definetrial(cfg);

%% preproc
cfg.channel   = 'all'; % C1 through C62
cfg.detrend   = 'yes';
cfg.demean    = 'yes';
preproc       = ft_preprocessing(cfg);

%% ICA
cfg = [];
cfg.channel = 'all';
ic          = ft_componentanalysis(cfg, preproc);

cfg = [];
cfg.viewmode   = 'component';
cfg.continuous = 'no';
cfg.layout     = lay;
ft_databrowser(cfg, ic);

cfg = [];
cfg.component  = [1, 2, 3, 4, 5];
icCorrected    = ft_rejectcomponent(cfg, ic);

%% preview
% cfg = [];
% cfg.method   = 'summary';
% cfg.channel  = 'all';
% cfg.trials   = 'all';
% cfg.latency  = [-0.1 0.9];
% ft_rejectvisual(cfg, icCorrected);

%% identify noisy channels from IC topographies and amplitude waveforms
cfg = [];
cfg.continuous = 'no';
cfg.layout     = lay;
%cfg.lpfilter   = 'yes';
%cfg.lpfreq     = 30;
cfgartifact  = ft_databrowser(cfg, icCorrected);
cfgartifact  = rmfield(cfgartifact, 'trl');
icCorrected2 =  ft_rejectartifact(cfgartifact, icCorrected);
clean = icCorrected2;

%% optionally interpolate noisy channels
badchannel = {'C27', 'C28', 'C29', 'C2', 'C62', 'C8'};
%badtrials  = []; % 'all';
if ~isempty(badchannel)
    cfgrep            = [];
    cfgrep.badchannel = badchannel; 
    cfgrep.method     = 'spline';
    cfgrep.elecfile   = '63equidistant_elec_GV.mat';
    icRepaired        = ft_channelrepair(cfgrep, icCorrected2);
    else
    icRepaired        = icCorrected2;   
end
clean = icRepaired;
% %% visual inspection, use rectified amplitudes
% cfg = [];
% cfg.method   = 'summary';
% cfg.rectify  = 'yes';
% clean        = ft_rejectvisual(cfg, icRepaired);

%% test plot
cfg = [];
cfg.reref      = 'yes';
cfg.refchannel = 'all';
cfg.lpfilter   = 'yes';
cfg.lpfreq     = 30;
clean_avg = ft_preprocessing(cfg, clean); 

cfg  = [];
test = ft_timelockanalysis(cfg, clean_avg);           

cfg = [];
cfg.baseline   = [-0.1 0];
bsl            = ft_timelockbaseline(cfg, test);

% multiplot
cfg = [];
cfg.layout      = lay;
cfg.interactive = 'yes';
ft_multiplotER(cfg, bsl);

%% if OK, save
save(['./data/cleaned/', vpcode, '_task-Grasping_eeg_cleaned.mat'], 'clean');
fprintf('Rejected %i trials with artifacts.\n', length(preproc.trial) - length(clean.trial));

% use as:
% cfg = [];
% cfg.trials = find(clean.trialinfo(:,4) == 0); %0 is for movement
% cfg.offset = -clean.trialinfo(:, 8) * clean.fsample; % align to movement start
% clean_new = ft_redefinetrial(cfg, clean);
% 
% cfg = [];
% cfg.toilim = [-0.5 3.5];
% c_n = ft_redefinetrial(cfg, clean_new);

%tdfread('./data/bids/sub-S01/eeg/sub-S01_task-Grasping_events.tsv');
%writetable(table(duration, onset), 'test.tsv', 'FileType', 'text', 'Delimiter', '\t')

