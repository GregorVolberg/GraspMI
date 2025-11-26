function [] = run08_cross_decoding_corr_plot()

%% set bids path, ft path, mvpa path
bidsPath = '../bids/';
ftPath   = '../../m-lib/fieldtrip/';
resdir   = '../res/';
addpath(ftPath); ft_defaults; %mke sure FT is on the path

%% get participant codes and eeg file list
tmp      = ft_read_tsv([bidsPath, 'participants.tsv']);
subjects = extractAfter(tmp.participant_id, 4); clear tmp
subjects = sort(setdiff(subjects, {'S03', 'S06', 'S13'}));

filelist{1} = strcat(resdir, subjects, '_cross_classification_mu_prob.mat');
filelist{2} = strcat(resdir, subjects, '_cross_classification_beta_prob.mat');

%% CSP
target_times          = -0.8:0.02:3;
target_frequencies    = {[11 14]; ...
                          [20 30]};
conditions = {'mouth' ,'shoulder'; ...
              'mouth' ,'forward'; ...
              'forward' ,'shoulder'};

cbPalette     = {"#999999"; "#E69F00"; "#56B4E9"; ...
                 "#009E73"; "#F0E442"; "#0072B2"; ...
                 "#D55E00"; "#CC79A7"};

%% loop over frequencies
corrs = cell(numel(target_frequencies), 2);
for t_freqs = 1:numel(target_frequencies)
    for participant = 1:numel(filelist{t_freqs})
    data = importdata(filelist{t_freqs}{participant});
    % col1:= time, col2:= condition, col3:= class label, col4:= p for label
    % == 1, col5:= p for respective label, col6:= imagery rating
    for condition = 1:size(data, 2)
        for time_point = 1:size(data, 1)
        tmp_mat = data{time_point, condition};
        [rho, p] = corr(tmp_mat(:,5), tmp_mat(:,6), 'Rows', 'pairwise', 'Type', 'Spearman');
        res_rho(participant, time_point, condition) = rho;
        res_p(participant, time_point, condition)   = p;
        end
    end
    end
    corrs{t_freqs, 1} = res_rho;
    corrs{t_freqs, 2} = res_p;
end

% transform to fisher zr for averaging, then transform back (atanh, tanh)
fisherzr   = atanh(corrs{1,1});
meanfzr    = squeeze(mean(fisherzr));
z_mu       = sqrt((size(corrs{1,1},1)-3)/1.06) * meanfzr; % for p
meanr_mu   = tanh(meanfzr);
fisherzr   = atanh(corrs{2,1});
meanfzr    = squeeze(mean(fisherzr));
z_beta     = sqrt((size(corrs{1,1},1)-3)/1.06) * meanfzr; % for p
meanr_beta = tanh(meanfzr);
s_mu = nan(size(z_mu));
s_mu(normcdf(z_mu) < .05) = 1;
s_beta = nan(size(z_beta));
s_beta(normcdf(z_beta) < .05) = 1;

legend_labels = [char(conditions(:,1)), [' vs. '; ' vs. ';' vs. '], char(conditions(:,2)),];  
figure; 
set(gcf, 'Position', [560 320 700 220], 'Color', 'white');
subplot(1,2,1);
for nline = 1:3
plot(target_times, meanr_mu(:,nline), 'LineWidth', 2, 'Color', cbPalette{nline});hold on
plot(target_times, s_mu(:,nline)*nline*0.01, 'LineWidth', 1, 'Color', cbPalette{nline});hold on
end
ylabel('Spearman r');
xlabel('Time (s)');
ylim ([-0.12 0.12]);
title ('mu');
legend(legend_labels, 'Location','southwest')
legend('boxoff')


subplot(1,2,2);
for nline = 1:3
plot(target_times, meanr_beta(:,nline), 'LineWidth', 2, 'Color', cbPalette{nline});hold on
plot(target_times, s_beta(:,nline)*nline*0.01, 'LineWidth', 1, 'Color', cbPalette{nline});hold on
end
ylabel('Spearman r');
xlabel('Time (s)');
ylim ([-0.12 0.12]);
title ('beta');

fig = gcf;
print(fig, [resdir, './cross_decoding_corr.svg'],'-dsvg');
print(fig, './md_images/cross_decoding_corr.png','-dpng');
close(gcf);
end