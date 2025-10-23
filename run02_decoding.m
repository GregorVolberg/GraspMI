%% decoding
%% set bids path, ft path, mvpa path
bidsPath = '../bids/';
ftPath   = '../../m-lib/fieldtrip/';
mvpath   = '../../m-lib/MVPA-Light/startup';
addpath(ftPath); ft_defaults;
addpath(mvpath); startup_MVPA_Light;

%% get participant codes and eeg file list
tmp      = ft_read_tsv([bidsPath, 'participants.tsv']);
subjects = extractAfter(tmp.participant_id, 4); clear tmp
subjects = sort(setdiff(subjects, {'S03', 'S06', 'S13'}));
filelist = cellstr(strcat(bidsPath, 'derivates/eeg_hp_1_lp_40_', char(subjects),'.mat'));

%% CSP
%=========  for file_nr = 1:numel(filelist)
file_nr = 1;
eeg = importdata(filelist{file_nr});

% filter at target freqs, e. g. 8 - 30 Hz (also try filter bank CSP)
cfg = [];
cfg.bpfilter = 'yes';
cfg.bpfreq = [10 13];%[8 30];
cfg.baselinewindow = [-0.2 0]; 
cfg.demean = 'yes'; % perfoms baseline correction within baselinewindow
cfg.reref = 'yes';
cfg.refchannel = 'all';
eeg = ft_preprocessing(cfg, eeg);

% select data range 
% what time scale? from onset to offset of movement? how long did movement
% take?
cfg = [];
cfg.latency = [0 2];
eeg = ft_selectdata(cfg, eeg);

% conditions table
trials_real  = ismember(eeg.trialinfo.movtype, 'real') & ...
               eeg.trialinfo.mov_onset <= 3;
trials_imag  = ismember(eeg.trialinfo.movtype, 'imagined');
trials_table = table(trials_real & ismember(eeg.trialinfo.movement, 'forward'), ...
                     trials_real & ismember(eeg.trialinfo.movement, 'mouth'), ...
                     trials_real & ismember(eeg.trialinfo.movement, 'shoulder'), ...
                     trials_imag & ismember(eeg.trialinfo.movement, 'forward'), ...
                     trials_imag & ismember(eeg.trialinfo.movement, 'mouth'), ...
                     trials_imag & ismember(eeg.trialinfo.movement, 'sholder'), ...
                     'VariableNames', {'real_forward', 'real_mouth', 'real_shoulder', ...
                                       'imag_forward', 'imag_mouth', 'imag_shoulder'});

% training set
cfg            = [];
cfg.trials     = find(trials_table.real_forward + trials_table.real_mouth);
cfg.keeptrials = 'yes';
training_set   = ft_timelockanalysis(cfg, eeg); 

%% cross dec
% cfg = [];
% cfg.trials = trials_table.real_mouth;
% cfg.keeptrials = 'yes';
% real_mouth   = ft_timelockanalysis(cfg, eeg); 

rng(23);
% pseudo-trial averaging
aparam = mv_get_preprocess_param('average_samples');
aparam.group_size = 5;
[avgparms, X, clabel]   = mv_preprocess_average_samples(aparam, training_set.trial, ~ismember(training_set.trialinfo.movement, 'forward') + 1);
% z-scoring
zparam = mv_get_preprocess_param('zscore');
[zparams, X, lab] = mv_preprocess_zscore(zparam, X, clabel);
% csp
cspparam = mv_get_preprocess_param('csp');
cspparam.calculate_variance = 1; % this is a power estimate
cspparam.n = 2;
cspparam.calculate_log = 1;
[d, X2, lab] = mv_preprocess_csp(cspparam, X, lab);

% decoding
cfg = [];
cfg.classifier          = 'lda';
cfg.k                   = 5;
cfg.repeat              = 100;
%cfg.feature_dimension   = 2;%[cspparam.feature_dimension, cspparam.target_dimension]; % see dimesion
cfg.feature_dimension  = [cspparam.feature_dimension, cspparam.target_dimension]; % see dimesion
cfg.flatten_features    = 0;
[perf, results] = mv_classify(cfg,  X2, lab);

% to do:
% - in object 'd', why 'calculate spatial pattern' = 0? :: can calcutae the spatial pattern outside the classification loop
%  What is the feature dimension? :: is in the preprocessing param
% Can I plot the topography and eigenvalues? yes, see example_CSP
% how to keep the time dimension in CSP representation? :: No time
% dimension. Variance across time points is taken as measure of power
% how do cross decoding?
% is three-way classification possible with CSP? :: 
% multi-bank CSP

% for time resolution, use fixed window and slide across time dimension
% for freq, use either predefined mu/beta range or overall (all real movements) TFR over central
% electrodes





%============ end

