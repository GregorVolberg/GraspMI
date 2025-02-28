%% Cleaning Movement Data
% 1. get the data while moving
% 2. set initial position as [0,0,0]
% 3. 3 standard deviations removement (maximum value of x (sensor1))
% 4. 3 standard deviations removement (length of the trial)
% 5. save export data
% 6. show movement graph (x: timeline, y: x(fig1) or y(fig2) or z(fig3))

clear;

%% read experiment info
datapath = './data/';
outpath = './data/cleaned/';

load(fullfile(datapath, './cleaned/cleaned_Movement_S1.mat'));
expInfo = readtable(fullfile(datapath, 'S1.csv'));

frameRate = 240;
taskFilter = expInfo.task == 0;

mouthIdx = find(taskFilter & strcmp(expInfo.movementType, 'Mouth'));
shoulderIdx = find(taskFilter & strcmp(expInfo.movementType, 'Shoulder'));
forwardIdx = find(taskFilter & strcmp(expInfo.movementType, 'Forward'));
movementIndices = {mouthIdx, shoulderIdx, forwardIdx};

fields = fieldnames(MovData);

%% remove the data while not moving, and set the default position as [0,0,0]
for i = 1:numel(fields)
    trial_data = MovData.(fields{i}); 

    positionData = trial_data(:, [8:10, 20:22, 32:34]);
    positionData = table2array(positionData);

    trialLength = trial_data(:,2); %height(trial_data);
    sensor1Position = trial_data(:, 8:10);
    sensor1Position = table2array(sensor1Position);

    velocity = sqrt(sum(diff(sensor1Position).^2, 2));
    
    threshold = 0.01;
    moving = velocity > threshold;

    movement_start = find(diff([0; moving]) == 1);
    movement_stop = find(diff([moving; 0]) == -1);
    for j = 1:length(movement_start)
        if movement_start(j) > 1080
            start_index = movement_start(j);
            start_time = start_index/frameRate;
            startTimeList(i) = start_time;
            break;
        end
    end

    for k = 0:length(movement_stop)-1
        if movement_stop(length(movement_stop)-k) < start_index + 725
            stop_index = movement_stop(length(movement_stop)-k);
            stop_time = stop_index/frameRate;
            stopTimeList(i) = stop_time;
            break;
        end
    end
%   start_index = movement_start(1);
%   stop_index = movement_stop(end);
%     start_index(1:48) = 1080;
%     stop_index(1:48) = 2040;

    movementData = positionData(start_index:stop_index, :);
    allMovementData{i} = movementData;

    % set initial position as  [0,0,0]
    initialPosition = positionData(1, :);
    fixedPosition = movementData - initialPosition;
    allFixedMovementData{i} = fixedPosition;
end

%% save start/end point
expData.trialNum = 1:48;
expData.trialNum = expData.trialNum.';
expData.ISI = expInfo.fix_time(1:48);
expData.movement = expInfo.movementType(1:48);
expData.startTime = startTimeList.';
expData.stopTime = stopTimeList.';
expData.movementTime = stopTimeList.' - startTimeList.'; % time length of the movement
expData.TimeToStartMovement = startTimeList.' - expInfo.fix_time(1:48) - 2.5; % time to start moving (after the hand sign showed)
expData.TimeMovementSignal = expInfo.fix_time(1:48) + 2.5;
expData = struct2table(expData);

%% Remove trials with maximum x value of sensor 1 beyond 3 standard deviations
validTrials = true(size(allFixedMovementData));

for m = 1:numel(movementIndices)
    idx = movementIndices{m};
    if isempty(idx)
        continue;
    end
    maxValues = cellfun(@(data) max(data(:,1)), allFixedMovementData(idx)); % change here to set y,z as well 
    mu_max = mean(maxValues);
    sigma_max = std(maxValues);

    outlierSubset = (maxValues < (mu_max - 3 * sigma_max)) | (maxValues > (mu_max + 3 * sigma_max));
    outlierFlags_xMax(idx) = outlierSubset;
end

allFixedMovementData = allFixedMovementData(validTrials);
mouthIdx = mouthIdx(ismember(mouthIdx, find(validTrials)));
shoulderIdx = shoulderIdx(ismember(shoulderIdx, find(validTrials)));
forwardIdx = forwardIdx(ismember(forwardIdx, find(validTrials)));



%% Remove trials with length beyond 3 standard deviations
trialLengths = cellfun(@(x) size(x, 1), allFixedMovementData); 
meanLength = mean(trialLengths);
stdLength = std(trialLengths);
outlierFlags_Length = (trialLengths < (meanLength - 3 * stdLength)) | (trialLengths > (meanLength + 3 * stdLength));

%% save export data
expData.OutlierFlag = (outlierFlags_xMax | outlierFlags_Length).';
writetable(expData, [datapath, 'S1_timeline.csv']);

%% show all graph (x)
% figure;
% hold on;
% grid on;
% xlabel('Time (samples)');
% ylabel('Y Position');
% title('Y Position Over Time');
% 
% for i = 1:numel(allFixedMovementData)
%     movementData = allFixedMovementData{i};
%     timeAxis = (1:size(movementData, 1))'; % Assuming each row is a time step
%     plot(timeAxis, movementData(:,2), 'LineWidth', 1.5); % Y position is in the second column
% end
% 
% legend(arrayfun(@(x) sprintf('Trial %d', x), 1:numel(allFixedMovementData), 'UniformOutput', false));
% hold off;

for j = 1:9 % display the x,y,z position of sensor1
    figure;
    
    %% Show graph for "Mouth"
    subplot(3,1,1); % Create subplot (Row 1 of 3)
    hold on;
    grid on;
    xlabel('Time');
    ylabel('Position');
    title('Mouth');
    for i = 1:numel(mouthIdx)
        trialIdx = mouthIdx(i); 
        if trialIdx <= numel(allFixedMovementData) && expData.OutlierFlag(trialIdx) == 0
            movementData = allFixedMovementData{trialIdx};
            timeAxis = (1:size(movementData, 1))'; 
            plot(timeAxis, movementData(:,j), 'LineWidth', 1.5); 
        end
    end
    
    %legend(arrayfun(@(x) sprintf('Trial %d', x), mouthIdx, 'UniformOutput', false));
    hold off;
    
    %% Show graph for "Shoulder"
    
    subplot(3,1,2); % Create subplot (Row 2 of 3)
    hold on;
    grid on;
    xlabel('Time');
    ylabel('Position');
    title('Shoulder');    
    for i = 1:numel(shoulderIdx)
        trialIdx = shoulderIdx(i); 
        if trialIdx <= numel(allFixedMovementData) && expData.OutlierFlag(trialIdx) == 0
            movementData = allFixedMovementData{trialIdx};
            timeAxis = (1:size(movementData, 1))'; 
            plot(timeAxis, movementData(:,j), 'LineWidth', 1.5); 
        end
    end
        
    %legend(arrayfun(@(x) sprintf('Trial %d', x), shoulderIdx, 'UniformOutput', false));
    hold off;
        
    %% Show graph for "Forward"
    subplot(3,1,3); % Create subplot (Row 3 of 3)
    hold on;
    grid on;
    xlabel('Time');
    ylabel('Position');
    title('Forward');   
    for i = 1:numel(forwardIdx)
        trialIdx = forwardIdx(i); 
        if trialIdx <= numel(allFixedMovementData) && expData.OutlierFlag(trialIdx) == 0
            movementData = allFixedMovementData{trialIdx};
            timeAxis = (1:size(movementData, 1))'; 
            plot(timeAxis, movementData(:,j), 'LineWidth', 1.5); 
        end
    end
        
    %legend(arrayfun(@(x) sprintf('Trial %d', x), forwardIdx, 'UniformOutput', false));
    hold off;

end
