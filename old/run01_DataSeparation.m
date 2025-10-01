% get motionData
ftPath   = '../../../m-lib/fieldtrip/';
rawPath  = '../../data/raw/';
bidsPath = '../../data/bids/';
orgPath  = '../../org/';
funcPath = '../func'; % constum functions

layoutFile = [orgPath, '63equidistant_GreenleeLab_lay.mat'];
vpcode     = 'sub-S01'; % pilot run
%eegFile    = [rawPath vpcode, '_GraspMI.vhdr'];
eegfilebids = './data/bids/sub-S01/eeg/sub-S01_task-Grasping_eeg.vhdr';



datapath = './data/';
outpath = './data/cleaned/';
motionData = readtable(fullfile(datapath, 'S1_Motion.csv'));
expInfo = readtable(fullfile(datapath, 'S1.csv'));

% trial and session
numTrial = 24;
numSession = 4;
wholeTrial = numTrial*numSession;
halfTrial = wholeTrial./2;

% get the timestamp 0/1
AO_col = 41;  % Sensor4 btn1
AO = motionData{:, AO_col};

% find 0 -> 1 or 1 -> 0
changeIdx = find(diff(AO) ~= 0) + 1;

% set the index
startIdx = [1; changeIdx]; 
endIdx = [changeIdx - 1; height(motionData)];

% create segment list
allSegments = cell(length(startIdx), 1);
for i = 1:length(startIdx)
    allSegments{i} = motionData(startIdx(i):endIdx(i), :);
end

% remove first two segments (the motionData before the experiment)
if length(allSegments) > 2
    allSegments(1:3) = [];
end

% remove odd number segments (trial start sign)
filteredSegments = allSegments(2:2:end);

% remove break/session ended segments
skipIdx = numTrial+1:numTrial+1:length(filteredSegments);
finalSegments = filteredSegments;
finalSegments(skipIdx) = [];

% save in structure
segments = struct();
for i = 1:length(finalSegments)
    segName = sprintf('trial_%d', i);
    segments.(segName) = finalSegments{i};
end

% display data
disp(segments);


% get the timestamp 0/1
AO_col = 41;  % Sensor4 btn1
AO = motionData{:, AO_col};

% find 0 -> 1 or 1 -> 0
changeIdx = find(diff(AO) ~= 0) + 1;

% set the index
startIdx = [1; changeIdx]; 
endIdx = [changeIdx - 1; height(motionData)];

% create segment list
allSegments = cell(length(startIdx), 1);
for i = 1:length(startIdx)
    allSegments{i} = motionData(startIdx(i):endIdx(i), :);
end

% remove first two segments (the data before the experiment)
if length(allSegments) > 2
    allSegments(1:3) = [];
end

% remove odd number segments (trial start sign)
filteredSegments = allSegments(2:2:end);

% remove break/session ended segments
skipIdx = numTrial+1:numTrial+1:length(filteredSegments); 
finalSegments = filteredSegments;
finalSegments(skipIdx) = []; 

% create structure
segments = struct();
for i = 1:length(finalSegments)
    segName = sprintf('trial_%d', i);
    segments.(segName) = finalSegments{i};
end
% disp(segments);

% separte between movement task and imaging task, and save
for i = 1:halfTrial
    segName = sprintf('trial_%d', i);
    aSegments.(segName) = finalSegments{i};
end

for j = (halfTrial+1):wholeTrial
    segName = sprintf('trial_%d', j-halfTrial);
    bSegments.(segName) = finalSegments{j};
end

firstTask = expInfo.task(1);
    MovName = 'cleaned_Movement_S';
    ImgName = 'cleaned_Imaging_S';

if firstTask == 1
    MovData = bSegments;
    ImgData = aSegments;
else
    ImgData = bSegments;
    MovData = aSegments;
end

fileName = [outpath, MovName, '1', '.mat'];
save(fileName, "MovData");

fileName = [outpath, ImgName, '1', '.mat'];
save(fileName, "ImgData");
