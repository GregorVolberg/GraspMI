function [] = run04_decoding_plot()
%% plot decoding results

%% set results path
resdir   = '../res/';
resfile = 'decoding_real.mat';
resfile_out = [resdir, 'runlength_encoding_real.txt'];
fid = fopen(resfile_out, 'w');

%% get participant results

resmat = importdata([resdir, resfile]);
mu   = nan([numel(resmat.mu), size(resmat.mu{1})]);
beta = nan([numel(resmat.beta), size(resmat.beta{1})]);
for k = 1:numel(resmat.mu)
    mu(k,:,:)   = resmat.mu{k};
    beta(k,:,:) = resmat.beta{k};
end

target_times  = -0.8:0.01:3; % from run03
ttimes        = [target_times, fliplr(target_times)]; % for polygons
legend_labels = [char(resmat.conditions(:,1)), [' vs. '; ' vs. ';' vs. '], char(resmat.conditions(:,2)),];  
cbPalette     = {"#999999"; "#E69F00"; "#56B4E9"; ...
                 "#009E73"; "#F0E442"; "#0072B2"; ...
                 "#D55E00"; "#CC79A7"};
avg_mu        = squeeze(mean(mu, 1));
avg_beta      = squeeze(mean(beta, 1));
nperm         = 5000; % number of permutations for permutation test
tdata         = {mu, beta};
tdata_name    = {'mu', 'beta'};

%% randomization for time points
% random number of vp sampled from conditions 1 to 3
% random permutation of time points
% write out maximum run length of time points with decoding acccuracy above chance (0.5) with two-sided alpha = .05
perm_alpha = 0.05; % one-sided
alpha_1stlevel = 0.05; % two-sided
rng(12); % set random number generator fpr replicable results
perm_dist = nan(numel(tdata), nperm);
for target_data = 1:numel(tdata)
data = tdata{target_data};
    for num_perm = 1:nperm
        %rand_subject   = randsample(size(data, 1), size(data, 1), 'true');
        rand_subject   = randperm(size(data, 1))';
        rand_condition = randsample(size(data, 3), size(data, 1), 'true');
        rand_data      = cell2mat(arrayfun(@(x,y) squeeze(data(x,:,y)), rand_subject, rand_condition, 'UniformOutput', false));
        SEM_data       = squeeze(std(rand_data))/sqrt(size(rand_data,1)); % standard error of mean
        lower_ci       = mean(rand_data, 1) + (SEM_data * norminv(alpha_1stlevel/2));
        rand_sig_samp  = lower_ci > .5;
        rand_nums      = bwlabeln(rand_sig_samp);
        rand_bins      = histcounts(rand_nums, (1:(max(rand_nums)+1))-0.5); % do not count zeros
        perm_dist(target_data, num_perm)    = max(rand_bins);
    end
end

%% plot
fprintf(fid, 'condition\tfreq-band\tn\tp\ton\toff\n'); % file
fprintf('condition\tfreq-band\tn\tp\ton\toff\n'); % console

figure; 
set(gcf, 'Position', [560 320 700 620], 'Color', 'white');
subplotindex = [1,3,5,2,4,6];
for target_data = 1:numel(tdata)
    data = tdata{target_data};
for condition = 1:size(data, 3)
    SEM            = squeeze(std(data(:,:,condition)))/sqrt(size(data,1)); % standard error of mean
    ci_upper       = SEM * norminv(0.975);
    ci_lower       = SEM * norminv(1-0.975);
    data_ci   = [squeeze(mean(data(:,:,condition))) + ci_upper, ...
                        fliplr(squeeze(mean(data(:,:,condition))) + ci_lower)];
    % get sig bins
    orig      = (squeeze(mean(data(:,:,condition))) + ci_lower) > .5;
    rand_nums = bwlabeln(orig);
    rand_bins = histcounts(rand_nums, [1:(max(rand_nums)+1)]-0.5);
    rand_p    = arrayfun(@(x) sum(perm_dist(target_data,:) > x)./numel(perm_dist(target_data,:)), rand_bins);
    
    mark_plt = nan(1, numel(rand_nums));
    mark_plt(ismember(rand_nums, find(rand_p < .05))) = 0.5;
size(data,3) * (target_data - 1) + condition
    splot = subplotindex(size(data,3) * (target_data - 1) + condition);
    subplot(3, 2, splot); hold on
    ylim([0.45 0.6]);
    xlim([-1,3]);
    ylabel('Decoding accuracy');
    yline(0.5, '--');
    if splot == 1
        title('mu CSP (11-14 Hz)');
    elseif splot == 2
        title('beta CSP (20-30 Hz)');
        elseif (splot == 5 | splot == 6)
        xlabel('Time (s)');
    end
    plot(target_times, squeeze(mean(data(:, :, condition),1)), 'LineWidth', 2, 'Color', cbPalette{condition});
    plot(polyshape(ttimes, data_ci), 'FaceColor', cbPalette{condition}, 'FaceAlpha', 0.3, 'EdgeColor', 'None');
    plot(target_times, mark_plt, 'LineWidth', 2, 'Color', 'black');
    if target_data == 1
        text(-0.8, 0.59, legend_labels(condition,:), 'Color', cbPalette{condition});
    end
    fprintf(fid, '%s\t%s\t%i\t%.3f\t%.3f\t%.3f\n', legend_labels(condition,:), tdata_name{target_data}, ...
                                       rand_bins(rand_p < .05), rand_p(rand_p < .05), ...
                                       min(target_times(~isnan(mark_plt))), ...
                                       max(target_times(~isnan(mark_plt)))); % file

    fprintf('%s\t%s\t%i\t%.3f\t%.3f\t%.3f\n', legend_labels(condition,:), tdata_name{target_data}, ...
                                       rand_bins(rand_p < .05), rand_p(rand_p < .05), ...
                                       min(target_times(~isnan(mark_plt))), ...
                                       max(target_times(~isnan(mark_plt)))); % console
end
end

fclose(fid);
fig = gcf;
print(fig, [resdir, './Decoding_accuracy_real.svg'],'-dsvg');
print(fig, './md_images/Decoding_accuracy_real.png','-dpng');
close(gcf);
end
