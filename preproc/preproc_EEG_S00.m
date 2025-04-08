%% paths and files
ftPath   = '../../../m-lib/fieldtrip/';
rawPath  = '../../data/raw/';
bidsPath = '../../data/bids/';
orgPath  = '../../org/';
funcPath = '../func'; % constum functions

layoutFile = [orgPath, '63equidistant_GreenleeLab_lay.mat'];
vpcode     = 'sub-S01'; % pilot run
%eegFile    = [rawPath vpcode, '_GraspMI.vhdr'];
eegfilebids = './data/bids/sub-S01/eeg/sub-S01_task-Grasping_eeg.vhdr';

%% set paths, load files
addpath(ftPath, orgPath, funcPath); ft_defaults;
lay = importdata(layoutFile);


%ftPath  = 'C:\Users\LocalAdmin\Documents\m-lib\fieldtrip-20220228';
%rootDir = 'Y:\Volberg\cred\';

%path to fieldtrip und root directory --> Data
ftPath  = 'X:\Volberg\m-lib\fieldtrip';

vpcode  = 'S00';

%rawPath   = [rootDir, 'raw\']; 
%cleanPath = [rootDir, 'clean\']; 
%orgPath   = [rootDir, 'org\']; 

% add paths
% hier wird path geaddet, und settings für fieldtrip?
addpath(ftPath); ft_defaults;
%addpath(orgPath);
%addpath('../func');

EEGcode   = {'cred', '.vhdr'}; % oneBack
RTcode    = '-GRK-Cred-oneBack-*.mat'; % oneBack

%tmp    = [rawPath, EEGcode{1},vpcode, EEGcode{2}];
oneBackEEG = 'S00.vhdr'%;[rawPath, EEGcode{1},vpcode, EEGcode{2}];
tmp    = dir([rawPath, vpcode, RTcode]);
oneBackRT  = [tmp.folder, '\', tmp.name]; 
clear tmp EEGcode RTcode

layout = load ([orgPath, '63equidistant_GreenleeLab_lay.mat']);

%% define segments
cfg = [];
cfg.trialdef.eventtype = 'Stimulus';
cfg.trialdef.prestim   = 0.1; 
cfg.trialdef.poststim  = 0.9;
cfg.dataset            = oneBackEEG;
cfg.representation = 'table';
%cfg.datasetRT          = oneBackRT;
%cfg.trialfun           = 'trialfun_oneBack';
cfg = ft_definetrial(cfg);


%% preproc; Ã¼bernimmt die cfg-datei
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
cfg.layout     = layout.lay;
ft_databrowser(cfg, ic);

cfg = [];
cfg.component  = [1];
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
cfg.layout     = layout.lay;
%cfg.lpfilter   = 'yes';
%cfg.lpfreq     = 30;
cfgartifact  = ft_databrowser(cfg, icCorrected);

icCorrected2 =  ft_rejectartifact(cfgartifact, icCorrected);
clean = icCorrected2

%% optionally interpolate noisy channels
badchannel = {'C54', 'C57', 'C58'};
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
cfg.layout      = layout.lay;
cfg.interactive = 'yes';
ft_multiplotER(cfg, bsl);

%% if OK, save
save([cleanPath, vpcode, '-cred-clean.mat'], 'clean');
fprintf('Rejected %i trials with artifacts.\n', length(preproc.trial) - length(clean.trial));
