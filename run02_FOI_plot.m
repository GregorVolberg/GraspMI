function[] = run02_FOI_plot()
% ===============================================
% Identify suitable frequencies for classification
% ===============================================

%% set bids path, ft path, mvpa path
bidsPath = '../bids/';
ftPath   = '../../m-lib/fieldtrip/';
mvpath   = '../../m-lib/MVPA-Light/startup';
resultspath = '../res/';
addpath(ftPath); ft_defaults;
addpath(mvpath); startup_MVPA_Light;

%% get participant codes and eeg file list
tmp      = ft_read_tsv([bidsPath, 'participants.tsv']);
subjects = extractAfter(tmp.participant_id, 4); clear tmp
subjects = sort(setdiff(subjects, {'S03', 'S06', 'S13'}));
filelist = cellstr(strcat(bidsPath, 'derivates/eeg_hp_1_lp_40_', char(subjects),'.mat'));

%% time - frequency decomposition
cfgtfr = [];
cfgtfr.output     = 'pow';
cfgtfr.method     = 'mtmconvol';
cfgtfr.taper      = 'hanning';
cfgtfr.foi        = 4:1:40; % 4 to 40 Hz
cfgtfr.t_ftimwin  = 5./cfgtfr.foi;
cfgtfr.toi        = -0.8:0.05:3;%
cfgtfr.pad        = 'nextpow2';
cfgtfr.keeptrials = 'no';

% loop over files
tfr = cell(numel(filelist), 1);
for file_nr = 1:numel(filelist)
    eeg = importdata(filelist{file_nr});
    cfgtfr.trials     = ismember(eeg.trialinfo.movtype, 'real') & eeg.trialinfo.mov_onset <= 3;
    tfr{file_nr} = ft_freqanalysis(cfgtfr, eeg);
end

%% baseline correction
cfgbsl = [];
cfgbsl.baseline      = [-0.8 -0.2];
cfgbsl. baselinetype = 'relchange';
for k = 1:numel(tfr)
    tfr_bsl{k} = ft_freqbaseline(cfgbsl, tfr{k});
end

%% averaging
cfgavg = [];
cfgavg.keepindividual = 'no';
tfr_avg = ft_freqgrandaverage(cfgavg, tfr_bsl{:});

%% TFR plot at C3 and C4
cfgplt = [];
cfgplt.channel = {'C3', 'C4'};
cfgplt.zlim    = [-0.3 0.3];
ft_singleplotTFR(cfgplt, tfr_avg)
title('Power change relative to baseline (C3 and C4)');
xlabel('Time (s)');
ylabel('Frequency (Hz)');
set(gcf, 'Color', 'white');
fig = gcf;
print(fig, [resultspath, './Overall_power_FOI.svg'],'-dsvg');
print(fig, './md_images/Overall_power_FOI.png','-dpng');
close(gcf);

%% topoplot
cfgtopo = [];
cfgtopo.layout     = 'EEG1010.lay';
cfgtopo.parameter  = 'powspctrm';      
cfgtopo.xlim       = [0 3];    
cfgtopo.ylim       = [20 30];
cfgtopo.zlim       = [-0.25 0.25];
cfgtopo.comment    = 'no';
ft_topoplotTFR(cfgtopo, tfr_avg);
colorbar();
title('Beta Power (20 - 30 Hz)');
set(gcf, 'Color', 'white');
fig = gcf;
print(fig, [resultspath, './Power_FOI_beta_topo.svg'],'-dsvg');
print(fig, './md_images/Power_FOI_beta_topo.png','-dpng');
close(gcf);

cfgtopo.ylim       = [11 14];
ft_topoplotTFR(cfgtopo, tfr_avg);
colorbar();
title('Mu Power (11 - 14 Hz)');
set(gcf, 'Color', 'white');
fig = gcf;
print(fig, [resultspath, './Power_FOI_mu_topo.svg'],'-dsvg');
print(fig, './md_images/Power_FOI_mu_topo.png','-dpng');
close(gcf);

end