ftPath   = '../../../m-lib/fieldtrip/';
addpath(ftPath); ft_defaults;

% file paths
participant = 'S04';
bidsPath = '../../bids/';
task        = '_task-Grasping';
tracksys    = '_tracksys-PolhemusViper';
jsn  = [bidsPath, 'sub-', participant, '/motion/sub-', participant, task, tracksys, '_motion.json'];
evts = [bidsPath, 'sub-', participant, '/motion/sub-', participant, task, tracksys, '_events.tsv'];
mdat = [bidsPath, 'sub-', participant, '/motion/sub-', participant, task, tracksys, '_motion.tsv'];

% trail definition
prestim  = 0.2;
poststim = 5;

% read_motion data
mot = get_motion_bids(jsn, evts, mdat, prestim, poststim);

% basline correction

% % manually reject data
% cfg          = [];
% cfg.preproc.demean = 'yes';
% cfg.preproc.baselinewindow = [-0.2 0];
% %cfg.method   = 'trial';
% %cfg.ylim     = [-1e-12 1e-12];
% artfct        = ft_databrowser(cfg, mot);

% see dummy.artfctdef.visual.artifact

% get condition average
conditions = {'chin', 'forward', 'mouth'};

cfg =[];
cfg.keeptrials = 'no';

cfgb = [];
cfgb.baseline     = [-0.2 0];

for m = 1:numel(conditions)
cfg.trials = ismember(mot.trialinfo.type, 'real') & ismember(mot.trialinfo.movement, conditions(m));
tl = ft_timelockanalysis(cfg, mot);
tlb = ft_timelockbaseline(cfgb, tl);
mot3{m} = tlb;
end

figure;
for k = 1:3
subplot(3,1,k);
hold on;
grid on;
xlabel('X Position'); ylabel('Y Position'); zlabel('Z Position');
title(['Sensor Movement ', conditions{k}]);
view(3);
plot3(mot3{k}.avg(4,:), mot3{1}.avg(5,:), mot3{1}.avg(6,:)); hold on;
plot3(mot3{k}.avg(4,1), mot3{1}.avg(5,1), mot3{1}.avg(6,1), 'Marker', 'o')
xlim([-5 25]); ylim([0 8]); zlim([0 8]); 
colormap(jet(numel(mot3{k}.avg(4,:))));
end

% y is forward (pos) / backward (neg)? ca 6
% z is up (pos) down (neg), ca. 6? 
% x is ca. 15?



% for k = 1:numel(mot3)
% cfg = [];
% cfg.channel = tlb.label(6+k);
% cfg.title   = tlb.label(6+k);
% ft_singleplotER(cfg, mot3{:}); 
% legend(conditions)
% end