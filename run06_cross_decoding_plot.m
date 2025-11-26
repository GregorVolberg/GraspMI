function [] = run06_cross_decoding_plot()
%% paths and files
bidsPath = '../bids/';
ftPath   = '../../m-lib/fieldtrip/';
resdir   = '../res/';
addpath(ftPath); ft_defaults; 

tmp      = ft_read_tsv([bidsPath, 'participants.tsv']);
subjects = extractAfter(tmp.participant_id, 4); clear tmp
subjects = sort(setdiff(subjects, {'S03', 'S06', 'S13'}));
mu_files   = strcat(resdir, subjects, '_cross_classification_mu.mat');
beta_files = strcat(resdir, subjects, '_cross_classification_beta.mat');
res_files  = {mu_files, beta_files};

%% data matrix dimensions (as in run05_cross_decoding.m)
% time  x time x condition x condition
target_times = -0.8:0.02:3;
conditions   = {'mouth' ,'shoulder'; ...
                'mouth' ,'forward'; ...
                'forward' ,'shoulder'};
tdata_name   = {'mu', 'beta'};

%% plot settings
% ticks at 0:3
xtick      = find(ismember(target_times, [0, 1, 2, 3]));
xticklabel = [0, 1, 2, 3];
ytick      = find(ismember(fliplr(target_times), [0, 1, 2, 3]));
yticklabel = fliplr([0, 1, 2, 3]);
gray       = [.5 .5 .5];

%% actual data
perm_alpha = 0.05; % one-sided
alpha_1stlevel = 0.05; % two-sided
for freq_band = 1:numel(res_files)
    data_cells = res_files{freq_band};
    for participant = 1:numel(data_cells)
        data(participant, :,:,:,:) = importdata(data_cells{participant});
    end
    fdata{freq_band} = data;
    for ddim1 = 1:size(data, 4)
        for ddim2 = 1:size(data, 5)
            SEM      = squeeze(std(squeeze(data(:,:,:,ddim1, ddim2))))/sqrt(size(data,1)); % standard error of mean
            ci_upper  = SEM * norminv(1-(alpha_1stlevel/2));
            ci_lower  = SEM * norminv(alpha_1stlevel/2);
            orig      = (squeeze(mean(data(:, :,:, ddim1, ddim2), 1)) + ci_lower) > .5;
            bw_matrix = bwlabeln(orig);
            bw_bins   = histcounts(bw_matrix, (1:(max(bw_matrix(:))+1))-0.5); % do not count zeros
            bw_matrix_cell{freq_band, ddim1, ddim2} = bw_matrix;
            bw_bins_cell{freq_band, ddim1, ddim2}   = bw_bins;
        end
    end
end

%% permutation procedure
nperm     = 5000; 
perm_dist = nan(numel(res_files),nperm);
n_crit    = nan(numel(res_files), 1);
rng(12); % set random number generator for replicable results
for freq_band = 1:numel(res_files)
    data = fdata{freq_band};
    for rnd = 1:nperm
    rand_subject    = randperm(size(data, 1))';
    rand_condition1 = randsample(size(data, 4), size(data_cells,1), 'true');
    rand_condition2 = randsample(size(data, 5), size(data_cells,1), 'true');
    rand_data       = cell2mat(arrayfun(@(x, y, z) data(x,:,:,y,z), rand_subject, rand_condition1, rand_condition2, 'UniformOutput', false));
    SEM       = squeeze(std(rand_data))/sqrt(size(rand_data,1)); % standard error of mean
    ci_upper  = SEM * norminv(1-(alpha_1stlevel/2));
    ci_lower  = SEM * norminv(alpha_1stlevel/2);
    perm      = (squeeze(mean(rand_data, 1)) + ci_lower) > .5;
    rand_nums = bwlabeln(perm);
    rand_bins = histcounts(rand_nums, (1:(max(rand_nums(:))+1))-0.5); % do not count zeros
    perm_dist(freq_band, rnd) = max(rand_bins);
    end
    n_crit(freq_band) = quantile(perm_dist(freq_band,:), 1-perm_alpha);
end

%% idea_ use perm_dist for calculating p, show p as alpha map
for ffreq = 1:size(bw_bins_cell,1)
    fdat = squeeze(bw_bins_cell(ffreq,:,:));
for ddim1 = 1:3
    for ddim2 = 1:3
        erg{ffreq, ddim1, ddim2} = find(fdat{ddim1,ddim2} > n_crit(ffreq));
    end
end
end


%% loop over results
for freq_band = 1:numel(res_files)
    data_cells = res_files{freq_band};
    %data = nan([numel(data_cells), size(data_cells{1})]);
    figure;
    set(gcf, 'Position', [560 320 700 620], 'Color', 'white');
    %sgtitle([tdata_name{freq_band}, ' frequencies)']);
    for participant = 1:numel(data_cells)
        data(participant, :,:,:,:) = importdata(data_cells{participant});
    end
        mdata = squeeze(mean(data, 1));
        for ddim1 = 1:size(mdata, 3)
            for ddim2 = 1:size(mdata, 4)
            subplot(size(mdata, 3), size(mdata, 4), size(mdata, 4) * (ddim1-1) + ddim2);    
            imagesc(flipud(squeeze(mdata(:, :, ddim1, ddim2))), [0.45 0.55]);
            set(gca, 'XTick', xtick, 'XTickLabel', xticklabel);
            set(gca, 'YTick', ytick, 'YTickLabel', yticklabel); % same for Y-axis
            hold on;
            line([0, size(mdata, 1)], [size(mdata, 1), 0], 'Color', gray, 'LineWidth', 2);
            % if ddim1 == 1
            % title([char(conditions{ddim2, 1}), ' vs. ', char(conditions{ddim2, 2})]);
            % end
            % if ddim2 == 1
            % title([char(conditions{ddim2, 1}), ' vs. ', char(conditions{ddim2, 2})], 'HorizontalAlignment', 'left');
            % end
            if ddim1 == 3
            xlabel({'Real Movement Time (s)'; [char(conditions{ddim2, 1}), ' vs. ', char(conditions{ddim2, 2})]; });    
            end
            if ddim2 == 1
            ylabel({[char(conditions{ddim1, 1}), ' vs. ', char(conditions{ddim1, 2})]; 'Imag. Movement Time (s)'});
%            ylabel('test\Imag. Movement Time (s)');
            end
            if ddim1 == 2 && ddim2 == 1
             annotation(gcf,'textarrow', [0 0], [0.5 1], ...
            'String', ['Models trained on real movements (', tdata_name{freq_band}, ' frequencies)'], ...
            'HeadStyle', 'none', 'LineStyle', 'none',...
            'FontSize',12, 'color','k', 'FontWeight','bold', 'TextRotation',90);
            end
            if ddim1 == 1 && ddim2 == 2
             annotation(gcf,'textarrow', [0.78 1], [0.98 1], ...
            'String', ['Test on imagined movements (', tdata_name{freq_band}, ' frequencies)'], ...
            'HeadStyle', 'none', 'LineStyle', 'none',...
            'FontSize',12, 'color','k', 'FontWeight','bold', 'TextRotation', 0);
            end

            end % ddim2
        end % ddim1
fig = gcf;
print(fig, [resdir, './Cross_decoding_accuracy_', tdata_name{freq_band}, '.svg'],'-dsvg');
print(fig, ['./md_images/Cross_decoding_accuracy_', tdata_name{freq_band}, '.png'],'-dpng');
close(gcf);
end % freq_band

end