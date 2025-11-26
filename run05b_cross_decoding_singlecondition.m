function [] = run05_cross_decoding()
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
smoothing_window = 0.3; % in s
target_times     = -0.8:0.02:3;
tt_on            = target_times + smoothing_window * -0.5; % target times onset
target_frequencies = {[11 14]; ...
                       [20 30]};
conditions = {'mouth' ,'shoulder'; ...
              'mouth' ,'forward'; ...
              'forward' ,'shoulder'};
conditions2 = {'mouth' ,'shoulder', 'forward'};

parpool(8);

%% loop over frequencies
cell_freqs = cell(2, 1);
for t_freqs = 1:numel(target_frequencies)
%t_freqs = 1;
cfgpp = [];
cfgpp.bpfilter = 'yes';
cfgpp.reref = 'yes';
cfgpp.refchannel = 'all';
cfgpp.bpfreq = target_frequencies{t_freqs}; % mu or beta

%participants = cell(numel(filelist),1);
parfor file_nr = 1:numel(filelist)
%file_nr = 1;
eeg = importdata(filelist{file_nr});

% filter real movement conditions at target freqencies

eeg = ft_preprocessing(cfgpp, eeg);

%% loop over conditions
permformance_per_condition = nan(numel(target_times), numel(target_times), size(conditions, 1), size(conditions, 1));
for c_number      = 1:size(conditions, 1)
for c2_number = 1:numel(conditions2)
% c_number = 1;
% c2_number = 1;
% get trials for conditions
trials_real    = ismember(eeg.trialinfo.movtype, 'real') & ...
                  eeg.trialinfo.mov_onset <= 3;
trials_imag    = ismember(eeg.trialinfo.movtype, 'imagined');
trials_con1_1  = ismember(eeg.trialinfo.movement, conditions{c_number, 1});
trials_con2_1  = ismember(eeg.trialinfo.movement, conditions{c_number, 2});
trials_con3    = ismember(eeg.trialinfo.movement, conditions2{c2_number});
%trials_con2_2  = ismember(eeg.trialinfo.movement, conditions{c2_number, 2});

% subset EEG
cfg            = [];
cfg.trials     = find(trials_real & (trials_con1_1 | trials_con2_1)); 
cfg.keeptrials = 'yes';
training_set   = ft_timelockanalysis(cfg, eeg); 
clabel_1       = ismember(training_set.trialinfo.movement, conditions{c_number, 1})+1;

% subset EEG II
cfg            = [];
cfg.trials     = find(trials_imag & trials_con3);%find(trials_table.real_forward + (trials_table.real_mouth * 2));
cfg.keeptrials = 'yes';
test_set       = ft_timelockanalysis(cfg, eeg); 
clabel_2       = ismember(test_set.trialinfo.movement, conditions2{c2_number});

% zscoreing and set csp parameters; pseudo-trial averaging not necessary: trial dimension is point in CSP
zparam     = mv_get_preprocess_param('zscore');
[~, Xz,  ~] = mv_preprocess_zscore(zparam, training_set.trial, clabel_1);
[~, Xz2, ~] = mv_preprocess_zscore(zparam, test_set.trial, clabel_2);

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
tp_on   = arrayfun(@(x) nearest(training_set.time, x), tt_on); % target times to target points
tpoints = [tp_on' tp_on' + smoothing_window * eeg.fsample];

rng(23);
perf = nan(numel(target_times), numel(target_times));

for tp1 = 1:size(tpoints, 1)
    %on_off = target_times(tp1) + (smoothing_window * [-0.5, 0.5]);
    %on_off_indices = nearest(training_set.time, on_off);
for tp2 = 1:size(tpoints, 1)
    %on_off2 = target_times(tp2) + (smoothing_window * [-0.5, 0.5]);
    %on_off_indices2 = nearest(training_set.time, on_off2);
    
    %perf(tp) = mv_classify(cfg, Xz(:,:,on_off_indices(1):on_off_indices(2)), clabel_1);
    perf(tp1, tp2) = mv_classify(cfg, Xz(:, :, tpoints(tp1, 1):tpoints(tp1, 2)), clabel_1, ...
                                Xz2(:, :, tpoints(tp2, 1):tpoints(tp2, 2)), clabel_2);

    %perf(tp1, tp2) = mv_classify(cfg, Xz(:,:,on_off_indices(1):on_off_indices(2)), clabel_1, ...
    %                            Xz2(:,:,on_off_indices2(1):on_off_indices2(2)), clabel_2);
end % end time points
end
permformance_per_condition(:, :, c_number, c2_number) = perf;
end % end conditions2
end % end conditions1
if t_freqs == 1
    fnameout = [resdir, subjects{file_nr}, '_cross_classification_mu.mat']; 
else
    fnameout = [resdir, subjects{file_nr}, '_cross_classification_beta.mat'];
end
%perf_s = struct('permformance_per_condition', permformance_per_condition);
%save(fnameout, "-fromstruct", perf_s); % parfor needs -fromstruct for saving
parsave(fnameout, permformance_per_condition); % see https://de.mathworks.com/matlabcentral/answers/135285-how-do-i-use-save-with-a-parfor-loop-using-parallel-computing-toolbox
%participants{file_nr} = permformance_per_condition;
end % end participants
%cell_freqs{t_freqs} = participants;
end

% decoding_real = [];
% decoding_real.mu   = cell_freqs{1};
% decoding_real.beta = cell_freqs{2};
% decoding_real.time = training_set.time;
% decoding_real.conditions = conditions;
% decoding_real.participants = filelist;
end

function parsave(fname, x)
  save(fname, 'x')
end
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

