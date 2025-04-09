% =======================
% function[] = graspMI_experiment()
% Six runs with 39 trials each
% ========================
function[] = graspMI_experiment()

%clear all
test_run = 0;

%% set up paths, responses, monitor, ...
addpath('./func'); 
rawdir = ['./'];

[vp, starting_condition, color_mapping, msf_colors, msf_text] = get_experimentInfo;
MonitorSelection = 4; % 6 in EEG
MonitorSpecs = getMonitorSpecs(MonitorSelection); % subfunction, gets specification for monitor

%% PTB         
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 0); % Sync test will not work with Windows 10
Screen('Preference', 'TextRenderer', 0); 
%PsychImaging('PrepareConfiguration');
%PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
%PsychImaging('FinalizeConfiguration');    

%% Prepare ViewPixx marker write-out
topLeftPixel = [0 0 1 1];
VpixxMarkerZero = @(windowPointer) Screen('FillRect', windowPointer, [0 0 0], topLeftPixel); % viewpixx 
setVpixxMarker  = @(windowPointer, value) Screen('FillRect', windowPointer, [value 0 0], topLeftPixel); % viewpixx 

%% Response buttons
KbName('UnifyKeyNames');
%TastenCodes  = KbName({'y', 'x', 'c', 'v', 'ESCAPE'}); % [89, 88, 67, 86, 27]
TastenCodes  = KbName({'m', ',<', '.>', '-_', 'ESCAPE'}); % 77   188   190   189    27
TastenVector = zeros(1,256); TastenVector(TastenCodes) = 1;

%% Stimulus
FixCrossSize  = 2; % in degrees visual angle
FixCrossPixel = (FixCrossSize * MonitorSpecs.PixelsPerDegree) - ...
                 mod((FixCrossSize * MonitorSpecs.PixelsPerDegree), 2); % in pixels, make it an even number
FixCross      = [-FixCrossPixel/2, FixCrossPixel/2, 0, 0;
                 0, 0, -FixCrossPixel/2, FixCrossPixel/2]; % coordinates for drawing
FixCrossWidth = 10; % line width, in pixels             

%% Colors
colorBlack = [0 0 0];
colorWhite = [255 255 255];
textSize = 30;
textSizeQuestionMark = 60;

%% Timing of presentation
if test_run == 0
 ISI      = [2 3]; % inter-stimulus interval (s); 
 CueTime  = 1.5;   % cue presentation time (s); 180 frames @ 120 Hz
 TaskTime = 3;     % target (go signal for movement / imagery) presentation time (s); 360 frames @ 120 Hz 
 timeOut  = 2;     % question mark or blank presentation time (s), also time-out for reponse; 240 frames @ 120 Hz
 BreakBetweenBlocks = 30; % pause between blocks (s)
 W = inf;          % wait time for kbQueueWait
elseif test_run == 1
 ISI      = [0.2 0.8]; 
 CueTime  = 0.5;
 TaskTime = 0.5;
 timeOut  = 0.5;
 BreakBetweenBlocks = 5;
 W = 1;
end

%% results file
GraspMI      = [];
timeString    = datestr(clock,30);  
outfilename   = ['sub-', vp, '_task-Grasping.mat'];

%% messages
msgEnd = 'Experiment Ended!\n\nPlease wait until the researcher turned off the recordings.';
msgBreak = 'Take a break (30 s)';

try
    Priority(1);
    HideCursor;
    [win, MonitorDimension] = Screen('OpenWindow', MonitorSpecs.ScreenNumber, 127); 
    %Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize', win, 18);
    if isfield(MonitorSpecs, 'gammaTable')
        Screen('LoadNormalizedGammaTable', win, MonitorSpecs.gammaTable); % correct gamma
    end   
    [xCenter, yCenter] = RectCenter(MonitorDimension);
    hz = Screen('NominalFrameRate', win);
    frame_s = (1/hz);
    
    % prepare runs
    numBlocks                 = 6;  % must be even-numbered due to the blocking movement/imagery
    RepsPerBlock              = 13; % number of repetitions per block (mouth, shoulder, forward)
    noRepetitionAtStartAndEnd = 3;
    noMoreThanXRepetitions    = 2;
    Runs = get_graspBlocks(noRepetitionAtStartAndEnd, noMoreThanXRepetitions, starting_condition,...
                           ISI, frame_s, numBlocks, RepsPerBlock);
    
    % compute fliptimes (subtract half frame)
    PTBCueTime  = CueTime - (frame_s * 0.7); % 
    PTBTaskTime = TaskTime - (frame_s * 0.7);  

    % Construct and start response queue
    KbQueueCreate([],TastenVector);
    KbQueueStart;
    
    % show startup screen and wait for key press (investigator)
    KbQueueFlush;        
    Screen('TextSize', win, textSize);
    msg = 'The researcher is turning on the EEG and motion tracker recordings.\n\n The experiment will start soon!';
    DrawFormattedText(win, msg, 'center', 'center', [255 255 255]);
    VpixxMarkerZero(win);
    Screen('Flip', win);
    KbQueueWait([],[], GetSecs + W);

     % show blank for smooth transition to next page
     VpixxMarkerZero(win);
     Screen('Flip', win);
     WaitSecs(1);
     
%% loop over blocks
     protocol = [];
     for nblock = 1:length(Runs)

      % read block definition  
      trialMat = Runs{nblock}; 

      % show instructions and wait for key press (participant)
      if trialMat(1, 2) == 5 
            msgBlock = 'Task: Motion. Press response key to go!\n';
            msgAnswer = '';
      elseif trialMat(1, 2) == 6
            msgBlock = 'Task: Imagery. Press response key to go!\n';
            msgAnswer = '?';
      end

      msgInstruction = strcat('\n', msf_text);                    
      Screen('TextSize', win, textSize);
      [~, ny, ~,~] = DrawFormattedText(win, msgBlock, 'center', 'center', [255 255 255]);
      for k = 1:3
      [~, ny, ~,~] = DrawFormattedText(win, msgInstruction{k}, 'center', ny+30, msf_colors{k});
      end
      
      VpixxMarkerZero(win);
      KbQueueFlush;    
      Screen('Flip', win);
      KbQueueWait([],[], GetSecs + W);
      
      %% loop over trials    
        for ntrial = 1:size(trialMat, 1)
        
        % show black fixcross (ISI)
        Screen('DrawLines', win, FixCross, FixCrossWidth, colorBlack, [xCenter, yCenter]);
        VpixxMarkerZero(win);
        [TrialStart] = Screen('Flip', win);
       
        switch trialMat(ntrial, 2)
         case 5 % motion
        % show colored fixcross (cue)
        Screen('DrawLines', win, FixCross, FixCrossWidth, msf_colors{trialMat(ntrial,1)}, [xCenter, yCenter]);
        VpixxMarkerZero(win);
        [CueStart] = Screen('Flip', win, TrialStart + trialMat(ntrial, 3));
        
        % show white circle (go signal)
        %Screen('DrawLines', win, FixCross, FixCrossWidth, colorWhite, [xCenter, yCenter]);
        Screen('GluDisk', win, colorWhite, xCenter, yCenter, FixCrossPixel/2);
        setVpixxMarker(win, trialMat(ntrial, 2));
        [TargetStart] = Screen('Flip', win, CueStart + PTBCueTime);

          case 6 % imagery
        % show colored circle (go signal)
        Screen('GluDisk', win, msf_colors{trialMat(ntrial,1)}, xCenter, yCenter, FixCrossPixel/2);
        setVpixxMarker(win, trialMat(ntrial, 2));
        [TargetStart] = Screen('Flip', win, TrialStart + PTBCueTime);
        CueStart      = TrialStart;      
        end

        % show question mark (imagery runs) or blank screen (movement
        % runs); get response key and response time
        Screen('TextSize', win, textSizeQuestionMark);
        DrawFormattedText(win, msgAnswer, 'center', 'center', [255 255 255]);
        VpixxMarkerZero(win);
        [QuestionStart] = Screen('Flip', win, TargetStart + PTBTaskTime);
        [keyCode, responseTime] = get_timeOutResponse(QuestionStart, timeOut);
        if (~isnan(responseTime)) % ensure same trial length in trials with and without responses
            WaitSecs(timeOut - responseTime);
        end
        
        % change key codes [y x c v] to numerical values from 1 to 4
        if (isnan(keyCode) | ~any(ismember(TastenCodes(1:4), keyCode)))
        rating = NaN;
        else
        rating = find(ismember(TastenCodes(1:4), keyCode));
        end
        
        % write condition codes and results into matrix
        protocolMatrix(ntrial, :) = [nblock, ntrial, keyCode, rating, responseTime, trialMat(ntrial, 1:3), ...
                CueStart - TrialStart, TargetStart - CueStart, QuestionStart - TargetStart] 
        checkESC;
        end % end trial loop
        
        % write protocol matrix into cell (per run)
        protocol{nblock} = protocolMatrix;
        
        % show break message
        WaitSecs(1);
        if nblock < numel(Runs)
            Screen('TextSize', win, textSize);
            DrawFormattedText(win, msgBreak, 'center', 'center', colorWhite);
            VpixxMarkerZero(win);
            Screen('Flip', win);
            WaitSecs(BreakBetweenBlocks);
        end
    end % end block loop

% write results and supplementary information to structure
GraspMI.experiment         = 'task-grasping';
GraspMI.participant        = vp;
GraspMI.date               = timeString;
GraspMI.protocol           = cell2mat(protocol');
GraspMI.color_mapping      = color_mapping;
GraspMI.starting_condition = starting_condition;
GraspMI.monitor_refresh    = hz;
GraspMI.MonitorDimension   = MonitorDimension;

msave([rawdir, outfilename], 'GraspMI');

% show ending message
KbQueueFlush; 
Screen('TextSize', win, textSize);
DrawFormattedText(win, msgEnd, 'center', 'center', colorWhite);
VpixxMarkerZero(win);
Screen('Flip', win);
KbQueueWait([],[], GetSecs + W);

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
Screen('CloseAll');
end

