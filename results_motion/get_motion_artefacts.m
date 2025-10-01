ftPath   = '../../../m-lib/fieldtrip/';
addpath(ftPath); ft_defaults;

% file paths
participant = 'S01';
bidsPath = '../../bids/';
task        = '_task-Grasping';
tracksys    = '_tracksys-PolhemusViper';
jsn  = [bidsPath, 'sub-', participant, '/motion/sub-', participant, task, tracksys, '_motion.json'];
evts = [bidsPath, 'sub-', participant, '/motion/sub-', participant, task, tracksys, '_events.tsv'];
mdat = [bidsPath, 'sub-', participant, '/motion/sub-', participant, task, tracksys, '_motion.tsv'];

% trail definition
prestim  = 0.2;
poststim = 5;

% Parameter für Bewegungsbeginn-Erkennung
velocity_threshold = 5;  % Geschwindigkeitsschwelle (cm/s)
position_threshold = 2;  % Positionsschwelle (cm) - Abstand vom Ursprung
    

% read_motion data
mot = get_motion_bids(jsn, evts, mdat, prestim, poststim);

% basline correction
cfg =[];
cfg.keeptrials = 'yes';
cfgb = [];
cfgb.baseline     = [-0.2 0];

tl          = ft_timelockanalysis(cfg, mot);
tlb         = ft_timelockbaseline(cfgb, tl);

tlb.code    = participant;
tlb.Fs       = mot.hdr.Fs

plot_movementOnset(tlb, velocity_threshold, position_threshold);