function [] = run07_cross_decoding_corr()
% decode and get class probabilities for correlation with imagery ratings
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
smoothing_wincell{1}  = 0.56; % in s; corresponds to 7 cycles of center freqency, 1/12.5*7
smoothing_wincell{2}  = 0.28; % in s; corresponds to 7 cycles of center freqency, 1/25*7
target_times          = -0.8:0.02:3;
target_time_model{1}  = 1.66; % 1.66 is max accuracy mu
target_time_model{2}  = 2.23; % 2.23 is center of peak with max accuracy in beta
target_frequencies    = {[11 14]; ...
                         [20 30]};
conditions = {'mouth' ,'shoulder'; ...
              'mouth' ,'forward'; ...
              'forward' ,'shoulder'};
%parpool(8);

%% loop over frequencies
cell_freqs = cell(2, 1);
for t_freqs = 1:numel(target_frequencies)
%t_freqs = 1;
cfgpp = [];
cfgpp.bpfilter = 'yes';
cfgpp.reref = 'yes';
cfgpp.refchannel = 'all';
cfgpp.bpfreq = target_frequencies{t_freqs}; % mu or beta
smoothing_window = smoothing_wincell{t_freqs};

%participants = cell(numel(filelist),1);
for file_nr = 1:numel(filelist)
%file_nr = 1;
eeg = importdata(filelist{file_nr});

% filter real movement conditions at target freqencies

eeg = ft_preprocessing(cfgpp, eeg);

perf = cell(numel(target_times), 3);
alltp_mat = [];
%% loop over conditions
for c2_number = 1:size(conditions, 1)
% get trials for conditions
trials_real    = ismember(eeg.trialinfo.movtype, 'real') & ...
                  eeg.trialinfo.mov_onset <= 3;
trials_imag    = ismember(eeg.trialinfo.movtype, 'imagined');
trials_con1_1  = ismember(eeg.trialinfo.movement, conditions{2, 1}); % always mouth vs forward for model
trials_con2_1  = ismember(eeg.trialinfo.movement, conditions{2, 2}); % always mouth vs forward for model
trials_con1_2  = ismember(eeg.trialinfo.movement, conditions{c2_number, 1});
trials_con2_2  = ismember(eeg.trialinfo.movement, conditions{c2_number, 2});

% subset EEG
cfg            = [];
cfg.trials     = find(trials_real & (trials_con1_1 | trials_con2_1)); 
%cfg.latency    = t_model{t_freqs};
cfg.keeptrials = 'yes';
training_set   = ft_timelockanalysis(cfg, eeg); 
clabel_1       = ismember(training_set.trialinfo.movement, conditions{2, 2})+1; % always mouth vs forward for model
% 1 is mouth, 2 is forward

% subset EEG II
cfg            = [];
cfg.trials     = find(trials_imag & (trials_con1_2 | trials_con2_2));
%cfg.latency    = t_model{t_freqs};
cfg.keeptrials = 'yes';
test_set       = ft_timelockanalysis(cfg, eeg); 
clabel_2       = ismember(test_set.trialinfo.movement, conditions{c2_number, 2})+1;

% zscoreing and set csp parameters; pseudo-trial averaging not necessary: trial dimension is point in CSP
zparam      = mv_get_preprocess_param('zscore');
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
cfg.metric              = 'none';
cfg.repeat              = 100;
cfg.preprocess          = 'csp';
cfg.preprocess_param    = cspparam;
cfg.feature_dimension   = [cspparam.feature_dimension, cspparam.target_dimension];
cfg.flatten_features    = 0;  % make sure the feature dimensions do not get flattened
cfg.output_type         = 'prob';

% select time ranges for test data, sliding window 
tt_on = target_times + smoothing_window * -0.5;
tp_on   = arrayfun(@(x) nearest(training_set.time, x), tt_on); % target times to target points
tpoints = [tp_on' tp_on' + smoothing_window * eeg.fsample];
%tp_on_model   = repmat(nearest(training_set.time, target_time_model{t_freqs}), size(tpoints, 1), 1);
tp_on_model   = nearest(training_set.time, target_time_model{t_freqs});
tpoints_model = [tp_on_model tp_on_model + smoothing_window * eeg.fsample];

rng(23);

times_out = test_set.time(tpoints(:,1))+smoothing_window*0.5;

for tp2 = 1:size(tpoints, 1)
    [~, res] = mv_classify(cfg, Xz(:, :, tpoints_model(1):tpoints_model(2)), clabel_1, ...
                                Xz2(:, :, tpoints(tp2, 1):tpoints(tp2, 2)), clabel_2); % returns probability for clabel == 1
    res_mat = [repmat(times_out(tp2), numel(res.testlabel), 1), repmat(c2_number, numel(res.testlabel), 1), ...
               res.testlabel, res.perf{1}, abs(res.perf{1} - (res.testlabel - 1)), test_set.trialinfo.rating];
    perf{tp2,c2_number} = res_mat;
    alltp_mat = [alltp_mat; res_mat];
end % end time points
end % end conditions2
if t_freqs == 1
    fnameout_mat = [resdir, subjects{file_nr}, '_cross_classification_mu_prob.mat']; 
    fnameout_csv = [resdir, subjects{file_nr}, '_cross_classification_mu_prob.csv']; 
else
    fnameout_mat = [resdir, subjects{file_nr}, '_cross_classification_beta_prob.mat'];
    fnameout_csv = [resdir, subjects{file_nr}, '_cross_classification_beta_prob.csv'];
end
%perf_s = struct('permformance_per_condition', permformance_per_condition);
writematrix(alltp_mat, fnameout_csv);
parsave(fnameout_mat, perf); % see https://de.mathworks.com/matlabcentral/answers/135285-how-do-i-use-save-with-a-parfor-loop-using-parallel-computing-toolbox
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

