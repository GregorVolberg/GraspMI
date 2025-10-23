% example from https://github.com/treder/MVPA-Light/blob/master/examples/understanding_spatial_filters.m#L603-630
% example CSP
mvpath   = '../../m-lib/MVPA-Light/startup';
addpath(ftPath); ft_defaults;
addpath(mvpath); startup_MVPA_Light;

[~, ~, chans] = load_example_data('epoched1');
fs = 256;

cfg = [];
cfg.n_sample = 100;
cfg.n_channel = 30;
cfg.n_time_point = 512;
cfg.fs = fs;
cfg.n_narrow = 4;
cfg.freq = [4 8; 
            8 12; 
            14 24;
            14 24];
cfg.amplitude = [3 3 3 3];
theta1 = zeros(30,1);
alpha1 = zeros(30,1);
beta1 = zeros(30,1);
beta2 = zeros(30,1);
Fz_ix = find(ismember(chans.label,'Fz'));
Oz_ix = find(ismember(chans.label,'Oz'));
C3_ix = find(ismember(chans.label,'C3'));
C4_ix = find(ismember(chans.label,'C4'));
theta1(Fz_ix) = 1;
theta1(ismember(chans.label,{'AF3', 'AF4' 'F3' 'F4' 'FC1' 'FC2'})) = 0.2;
alpha1(Oz_ix) = 1;
alpha1(ismember(chans.label,{'O1' 'O2'})) = 0.2;
beta1(C3_ix) = 1;
beta1(ismember(chans.label,{'FC5' 'FC1' 'CP5' 'CP1'})) = 0.2;
beta2(C4_ix) = 1;
beta2(ismember(chans.label,{'FC4' 'FC6' 'CP6' 'CP2'})) = 0.2;
cfg.narrow_weight = [theta1 alpha1 beta1 beta2];
cfg.n_broad = 30;

cfg.narrow_class = [1 1; 
                    1 1; 
                    1 0;
                    0 1];
[X_sim_csp, clabel_sim_csp] = simulate_oscillatory_data(cfg);
clabel_sim_csp'
pparam = mv_get_preprocess_param('csp');
pparam.n = 2;

% We want to visualize not only the filters but also the corresponding patterns
pparam.calculate_spatial_pattern = true;

% Let's call the function now to calculate the weights and spatial patterns
pparam = mv_preprocess_csp(pparam, X_sim_csp, clabel_sim_csp);

% plot components and eigenvalues
cfg_plot = [];
cfg_plot.outline = chans.outline;
cfg_plot.title = strcat('CSP weights #', {'1' '2' '3' '4'}', arrayfun(@(e) sprintf(' (EV = %2.2f)', e), pparam.eigenvalue, 'UniformOutput', false));
figure
mv_plot_topography(cfg_plot, pparam.W, chans.pos);
colormap jet

% or better: plot spatial patters (result of forward model)
cfg_plot.title = strcat('Spatial pattern #', {'1' '2' '3' '4'});
figure
mv_plot_topography(cfg_plot, pparam.spatial_pattern, chans.pos);
colormap jet

X_signal = zeros(size(X_sim_csp));
for n = 1:size(X_sim_csp,1)
    X_tmp = bandpass(squeeze(X_sim_csp(n,:,:))', [14, 24], fs);
    X_signal(n,:,:) = X_tmp';
end

pparam = mv_get_preprocess_param('csp');
pparam.calculate_variance = 1;
pparam.calculate_log = 1;


cfg = [];
cfg.classifier          = 'lda';
cfg.k                   = 5;
cfg.repeat              = 5;
cfg.preprocess          = 'csp';
cfg.preprocess_param    = pparam;

% We need to be careful with setting the dimensions. Normally we would set
% dimension 2 (channels) as the sole feature dimension, using dimension 3 
% (time) as the dimension to loop over. However, we are now removing 
% dimension 3 because we calculate variance across that dimension. So 
% effectively dimension 3 also serves as a feature dimension. This dimension 
% corresponds to the target_dimension in the preprocessing param. So we can
% set cfg.feature_dimension using the dimensions specified in pparam.
cfg.feature_dimension = [pparam.feature_dimension, pparam.target_dimension];
cfg.flatten_features  = 0;  % make sure the feature dimensions do not get flattened

[perf, result] = mv_classify(cfg, X_signal, clabel_sim_csp);


