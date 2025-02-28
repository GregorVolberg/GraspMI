%    Datapixx('Open');
%    Datapixx('DisablePixelMode');
%    Datapixx('RegWr');

%Screen('Preference', 'SkipSyncTests', 1);

% set up paths, responses, monitor, ...
addpath('./func'); 
MonitorSelection = 6;
MonitorSpecs = getMonitorSpecs(MonitorSelection); % subfunction, gets specification for monitor

%gammaTableFile = '.\org\gammaNEC.mat'; % ?? CHECK!
%% PTB  
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1); % Sync test will not work with Windows 10
Screen('Preference', 'TextRenderer', 0); 
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
PsychImaging('FinalizeConfiguration');


try
    Priority(1);
    HideCursor;
    [win, MonitorDimension] = Screen('OpenWindow', MonitorSpecs.ScreenNumber, 127); 
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xCenter, yCenter] = RectCenter(MonitorDimension);
    hz = Screen('NominalFrameRate', win);
    
%    Screen('gluDisk', win, [0 0 0], xCenter, yCenter, 20);
%    Screen('FillRect', win, [0 0 0], [0 0 20 20]);
%    Screen('Flip', win);
%    WaitSecs(1);
WaitSecs(2);

topLeftPixel = [0 0 1 1];
markerColor = [1 0 0];

%Screen('FillRect', win, [0 0 0], topLeftPixel);
%Screen('Flip', win);
WaitSecs(2);
instructionText  = 'Hit key to start!'; 
DrawFormattedText(win, markerText, 'center', 'center', markerColor);
Screen('FillRect', win, [0 0 0], topLeftPixel);
Screen('Flip', win);
KbQueueFlush();
[~, ~, ~] = KbStrokeWait();

for k = 1:4%128 %size(markerColor,1)
    %markerColor = repmat(mm(k), 1, 3);
    %markerColor = [250 0 0];
    markerText  = ['Pixel marker color: ', num2str(markerColor)]; 
    Screen('FillRect', win, markerColor, topLeftPixel);%markerColor(k,:)
    DrawFormattedText(win, markerText, 'center', 'center', markerColor);
    Screen('Flip', win);
    WaitSecs(1);
    Screen('FillRect', win, [0 0 0], topLeftPixel);
    Screen('Flip', win);
    WaitSecs(1);
end
%[0 1 0] ist8
% 4:7 0 0 ist 1
% 8:15 0 0 ist 0 
% 16  0 0 ist 2
% 24 0 0 ist 3
% 65 ist 4
% 69 ist 5
% 80 ist 6
% 127 ist 7
% [0 1 0] ist 8


catch
sca;
end
sca;
