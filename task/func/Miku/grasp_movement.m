clear; 

%% set up paths
addpath('./func');
outPath = 'results/';

%% get monitor info
MonitorSelection = 6;
MonitorSpecs = getMonitorSpecs(MonitorSelection); % subfunction, gets specification for monitor

%% PTB  
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1); % Sync test will not work with Windows 10
Screen('Preference', 'TextRenderer', 0);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
PsychImaging('FinalizeConfiguration');
% Screen('Preference', 'Verbosity', 10);
% Screen('Preference', 'VisualDebugLevel', 3);
% Screen('Preference', 'SuppressAllWarnings', 0);

%% set variables
% experiment
numSubject = 24; % amount of subject, change if it changed
numSession = 4;
numTrials = 24; %24;
nTrial = 0;
numViper = 0;

% time
timeMinFix = 2;
timeMaxFix = 3;
stepSize = 0.01;
timeStim = 1;
timeThink = 1.5;
timeMove = 3;
timeBeep = 0.1;
timeAnswer = 3;
timeBreak = 60;
frameSignal = 2;

% colors, icons and text
colorBack = [150 150 150];
colorFore = 34/255;
colorRed = [255 0 0];
colorBlue = [0 0 255];
colorGreen = [0 255 0];
textSize = 30;
topLeftPixel = [0 0 1 1];
figScale = 0.2;

% message
msgColorInstruction = 'Introduction';
msgTask0 = 'Task Type: Moving';
msgTask1 = 'Task Type: Imaging';
msgStart = 'Press Enter to Start the Session!';
msgEnd = 'Experiment Ended!';
msgSessionEnd = 'Session Eneded!';
msgBreak = 'Take a break!';
msgAnswer = '?';

%% setup arduino 
% % check connection
% a = arduino(); %connection test
% % set pins
% sensorPin = 'D2';
% viperPin = 'D7';
% senseValue = 0;
% lastSenseValue = 0;
% counter = 0;

%% get subjectNumber
%subjectNo = getSubjectInfo();
subjectNo = 1;

%% controlled setting
switch rem(subjectNo, 6)
    case 0 % 6,12,18,24
        msgRed = 'Shoulder';
        msgBlue = 'Mouth';
        msgGreen = 'Forward';
    case 1 % 1,7,13,19
        msgRed = 'Shoulder';
        msgBlue = 'Forward';
        msgGreen = 'Mouth';
    case 2 % 2,8,14,20
        msgRed = 'Mouth';
        msgBlue = 'Forward';
        msgGreen = 'Shoulder';
    case 3 % 3,9,15,21
        msgRed = 'Mouth';
        msgBlue = 'Shoulder';
        msgGreen = 'Forward';
    case 4 % 4,10,16,22
        msgRed = 'Forward';
        msgBlue = 'Shoulder';
        msgGreen = 'Mouth';
    case 5 % 5,11,17,23
        msgRed = 'Forward';
        msgBlue = 'Mouth';
        msgGreen = 'Shoulder';
end
% 
if subjectNo <= numSubject/2
    task = 0; % movement
else
    task = 1; % imaging
end
% task = 0 % for manual setting

%% Experiment
try
    Priority(1);
    HideCursor;
    [win, MonitorDimension] = Screen('OpenWindow', MonitorSpecs.ScreenNumber, colorBack); 
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xCenter, yCenter] = RectCenter(MonitorDimension);
    hz = Screen('NominalFrameRate', win);
    WaitSecs(1); 
    Screen('FillRect', win, [0 0 0], topLeftPixel);

    %% Visual Stimuli
    % Blank
    winBlank = Screen('OpenOffscreenWindow', MonitorSpecs.ScreenNumber, colorBack);

    % fixation
    fixCrossDimPix = 30;
    lineWidthPix   = 2;
    xCoords   = [-fixCrossDimPix, fixCrossDimPix, 0, 0];
    yCoords   = [0, 0, -fixCrossDimPix, fixCrossDimPix];
    allCoords = [xCoords; yCoords];              

    winFix = Screen('OpenOffScreenWindow', MonitorSpecs.ScreenNumber, colorBack);
    Screen('CopyWindow', winBlank, win);
    Screen('DrawLines', win, allCoords, lineWidthPix, colorFore, [xCenter, yCenter], 2);
    Screen('CopyWindow', win, winFix);
    
    %squareExplain
    squareSize = 100;
    xLeft = 500;
    yPositions = [yCenter - 200, yCenter, yCenter + 200];
    squareRedRect = [xLeft, yPositions(1), xLeft + squareSize, yPositions(1) + squareSize];
    squareBlueRect = [xLeft, yPositions(2), xLeft + squareSize, yPositions(2) + squareSize];
    squareGreenRect = [xLeft, yPositions(3), xLeft + squareSize, yPositions(3) + squareSize];

    winExplain = Screen('OpenOffScreenWindow', MonitorSpecs.ScreenNumber, colorBack);
    Screen('CopyWindow', winBlank, winExplain);
    Screen('FillRect', winExplain, colorRed, squareRedRect);
    Screen('FillRect', winExplain, colorBlue, squareBlueRect);
    Screen('FillRect', winExplain, colorGreen, squareGreenRect);

    % squareStim
    squareRect = [xCenter - squareSize/2, yCenter - squareSize/2, xCenter + squareSize/2, yCenter + squareSize/2];

    winRed = Screen('OpenOffScreenWindow', MonitorSpecs.ScreenNumber, colorBack);
    Screen('CopyWindow', winBlank, winRed);
    Screen('FillRect', winRed, colorRed, squareRect);
    
    winBlue = Screen('OpenOffScreenWindow', MonitorSpecs.ScreenNumber, colorBack);
    Screen('CopyWindow', winBlank, winBlue);
    Screen('FillRect', winBlue, colorBlue, squareRect);
    
    winGreen = Screen('OpenOffScreenWindow', MonitorSpecs.ScreenNumber, colorBack);
    Screen('CopyWindow', winBlank, winGreen);
    Screen('FillRect', winGreen, colorGreen, squareRect);

    % icons
    [figThink, ~, alpha] = imread("thought.png");
    if ~isempty(alpha)
        figThink = cat(3, figThink, alpha);
    end
    figThink = imresize(figThink, figScale);
    figTexThink = Screen('MakeTexture', win, figThink);

    [figMove, ~, alpha] = imread("hand.png");
    if ~isempty(alpha)
        figMove = cat(3, figMove, alpha);
    end
    figMove = imresize(figMove, figScale);
    figTexMove = Screen('MakeTexture', win, figMove);
    Screen('CopyWindow', winBlank, win);

    %% Experiment Session
    for iSession = 1:numSession
        trialList = [zeros(1,numTrials/3),ones(1,numTrials/3),2*ones(1,numTrials/3)];
        trialList = trialList(randperm(length(trialList)));

        if rem(iSession,2) == 1
            Screen('CopyWindow', winBlank, win);
            Screen('CopyWindow', winExplain, win);
            DrawFormattedText(win, msgColorInstruction, 'center', 150, colorFore);
            if task == 1
                DrawFormattedText(win, msgTask1, 'center', 200, colorFore);
            else
                DrawFormattedText(win, msgTask0, 'center', 180, colorFore);
            end
            DrawFormattedText(win, msgRed, 'center', yPositions(1) + 60, colorFore);
            DrawFormattedText(win, msgBlue, 'center', yPositions(2) + 60, colorFore);
            DrawFormattedText(win, msgGreen, 'center', yPositions(3) + 60, colorFore);
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            Screen('Flip', win);
            KbWait();
            WaitSecs(1);
        end

        for iTrial = 1:numTrials
            nTrial =nTrial + 1;
            Screen('CopyWindow', winBlank, win);
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            % update EEG and Viper time stamp
            % writeDigitalPin(a, viperPin, ~numViper);
            markerColor = [5 0 0];
            %markerText  = ['Pixel marker color: ', num2str(markerColor)];
            Screen('FillRect', win, markerColor, topLeftPixel);%markerColor(k,:)
            %DrawFormattedText(win, markerText, 'center', 'center', markerColor); % for testing
            Screen('Flip', win);
            WaitSecs(0.5);

            Screen('CopyWindow', winBlank, win);
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            Screen('Flip', win);
            WaitSecs(0.5);

            % show experiment stimuli
            % Fix: 2-3 [s]
            fixTimeRange = timeMinFix:stepSize:timeMaxFix;
            timeFix = fixTimeRange(randi(length(fixTimeRange)));

            Screen('CopyWindow', winFix, win);
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            Screen('Flip', win);
            WaitSecs(timeFix);

            % ColorBox: 0.25 [s]
            switch trialList(iTrial)
                case 0 % red
                    Screen('CopyWindow', winRed, win);
                    movement = msgRed;
                case 1 % blue
                    Screen('CopyWindow', winBlue, win);
                    movement = msgBlue;
                case 2 % green
                    Screen('CopyWindow', winGreen, win);   
                    movement = msgGreen;
            end
            Screen('FillRect', win, [7 0 0], topLeftPixel);
            Screen('Flip', win);
            WaitSecs(timeStim);

            % Think: 1.5[s]
            Screen('CopyWindow', winFix, win);
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            Screen('Flip', win);
            WaitSecs(timeThink);

            % Movement: 3.0[s]
            if task == 1
                Screen('DrawTexture', win, figTexThink);
            else 
                Screen('DrawTexture', win, figTexMove);
            end
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            Screen('Flip', win);
            WaitSecs(timeMove);

            % Blank or Question [s]
            if task == 1
                  Screen('CopyWindow', winBlank, win);
                  Screen('FillRect', win, [0 0 0], topLeftPixel);
                  DrawFormattedText(win, msgAnswer, 'center', 'center', colorFore);
                  Screen('Flip', win);
                  starttime =tic;
                  while toc(starttime) < timeAnswer
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        resp = KbName(keyCode);
                        break;
                    else 
                        resp = -1;
                    end
                  end
            else
                  Screen('CopyWindow', winBlank, win);
                  Screen('FillRect', win, [0 0 0], topLeftPixel);
                  Screen('Flip', win);
                  resp = 0;
                  WaitSecs(2);
            end
            % record data
            expData(nTrial).sessionNum = iSession;
            expData(nTrial).trialNum = iTrial;
            expData(nTrial).task = task;
            expData(nTrial).fix_time = timeFix;
            expData(nTrial).movementType = movement;
            expData(nTrial).answer = resp;
        end
        trialList = [];
        % update EEG and Viper time stamp
        % writeDigitalPin(a, viperPin, ~numViper);
%         markerColor = [0 0 0];
%         %markerText  = ['Pixel marker color: ', num2str(markerColor)];
%         Screen('FillRect', win, markerColor, topLeftPixel);%markerColor(k,:)
%         %DrawFormattedText(win, markerText, 'center', 'center', markerColor); % for testing
%         Screen('Flip', win);
%         WaitSecs(1);

        Screen('CopyWindow', winBlank, win);
        Screen('FillRect', win, [6 0 0], topLeftPixel);
        Screen('Flip', win);
        WaitSecs(0.25);

        Screen('CopyWindow', winBlank, win);
        Screen('FillRect', win, [0 0 0], topLeftPixel);
        DrawFormattedText(win,msgSessionEnd,'center','center',colorFore);
        Screen('Flip', win);
        KbWait();
        WaitSecs(1);

        if iSession == numSession/2
            Screen('CopyWindow', winBlank, win);
            Screen('FillRect', win, [6 0 0], topLeftPixel);
            Screen('Flip', win);
            WaitSecs(0.5);
            Screen('CopyWindow', winBlank, win);
            Screen('FillRect', win, [0 0 0], topLeftPixel);
            DrawFormattedText(win,msgBreak,'center','center',colorFore);
            Screen('Flip', win);
            WaitSecs(timeBreak);
            if task == 1
                task = 0;
            else
                task = 1;
            end
        end
    end

    Screen('CopyWindow', winBlank, win);
    Screen('FillRect', win, [0 0 0], topLeftPixel);
    DrawFormattedText(win,msgEnd,'center','center',colorFore);
    Screen('Flip', win);
    KbWait();
    WaitSecs(1);
    % 保存
    fileName = [outPath, 'S', num2str(subjectNo), '.csv'];
    expData = struct2table(expData);
    writetable(expData, fileName);
catch
sca;
end
sca;