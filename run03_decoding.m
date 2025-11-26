function [] = run03_decoding()
%% decoding
%% set bids path, ft path, mvpa path
bidsPath = '../bids/';
ftPath   = '../../m-lib/fieldtrip/';
%ftPath   = '~/loctmp/data/vog20246/NASSY/m-lib/fieldtrip'
mvpath   = '../../m-lib/MVPA-Light/startup';
resdir   = '../res/';
addpath(ftPath); ft_defaults; %mke sure FT is on the path
addpath(mvpath); startup_MVPA_Light;

%% get participant codes and eeg file list
tmp      = ft_read_tsv([bidsPath, 'participants.tsv']);
subjects = extractAfter(tmp.participant_id, 4); clear tmp
subjects = sort(setdiff(subjects, {'S03', 'S06', 'S13'}));
filelist = cellstr(strcat(bidsPath, 'derivates/eeg_hp_1_lp_40_', char(subjects),'.mat'));

%% CSP
smooting_window = 0.3; % in s
target_times    = [-0.8:0.01:3];
target_frequencies = {[11 14]; ...
                       [20 30]};
conditions = {'mouth' ,'shoulder'; ...
              'mouth' ,'forward'; ...
              'forward' ,'shoulder'};

cfgpp = [];
cfgpp.bpfilter = 'yes';
cfgpp.reref = 'yes';
cfgpp.refchannel = 'all';


%% loop over frequencies
cell_freqs = cell(2, 1);
for t_freqs = 1:numel(target_frequencies)
%t_freqs = 1;

participants = cell(numel(filelist),1);
for file_nr = 1:numel(filelist)
%file_nr = 1;
eeg = importdata(filelist{file_nr});

% filter real movement conditions at target freqencies
cfgpp.bpfreq = target_frequencies{t_freqs}; % mu or beta
eeg = ft_preprocessing(cfgpp, eeg);


%% loop over conditions
permformance_per_condition = nan(numel(target_times), size(conditions, 1));
for c_number = 1:size(conditions, 1)
%c_number = 1;
% get trials for conditions
trials_real  = ismember(eeg.trialinfo.movtype, 'real') & ...
               eeg.trialinfo.mov_onset <= 3;
%trials_imag  = ismember(eeg.trialinfo.movtype, 'imagined');
trials_con1  = ismember(eeg.trialinfo.movement, conditions{c_number, 1});
trials_con2  = ismember(eeg.trialinfo.movement, conditions{c_number, 2});

% subset EEG
cfg            = [];
cfg.trials     = find(trials_real & (trials_con1 | trials_con2));%find(trials_table.real_forward + (trials_table.real_mouth * 2));
cfg.keeptrials = 'yes';
training_set   = ft_timelockanalysis(cfg, eeg); 
clabel         = ismember(training_set.trialinfo.movement, conditions{c_number, 1})+1;

% zscoreing and set csp parameters; pseudo-trial averaging not necessary: trial dimension is point in CSP
zparam     = mv_get_preprocess_param('zscore');
[~, Xz, ~] = mv_preprocess_zscore(zparam, training_set.trial, clabel);

cspparam = mv_get_preprocess_param('csp');
cspparam.calculate_variance = 1; % this is a power estimate
cspparam.n = 2;
cspparam.calculate_log = 1;

% decoding configuration
cfg = [];
cfg.classifier          = 'lda';
cfg.k                   = 5;
cfg.repeat              = 100;
cfg.preprocess          = 'csp';
cfg.preprocess_param    = cspparam;
cfg.feature_dimension   = [cspparam.feature_dimension, cspparam.target_dimension];
cfg.flatten_features    = 0;  % make sure the feature dimensions do not get flattened

% select time range, sliding window 
rng(23);
perf = nan(numel(target_times), 1);
for tp = 1:numel(target_times)
    on_off = target_times(tp) + (smooting_window * [-0.5, 0.5]);
    on_off_indices = nearest(training_set.time, on_off);
    perf(tp) = mv_classify(cfg, Xz(:,:,on_off_indices(1):on_off_indices(2)), clabel);
end % end time points
permformance_per_condition(:, c_number) = perf;
end % end conditions
participants{file_nr} = permformance_per_condition;
end % end participants
cell_freqs{t_freqs} = participants;
end

decoding_real = [];
decoding_real.mu   = cell_freqs{1};
decoding_real.beta = cell_freqs{2};
decoding_real.time = training_set.time;
decoding_real.conditions = conditions;
decoding_real.participants = filelist;

save([resdir, 'decoding_real.mat'], 'decoding_real');
end
%exit

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

%cross classification???



%============ end

