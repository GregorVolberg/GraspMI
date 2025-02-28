% read experiment info
datapath = './data/';
outpath = './data/cleaned/';

load(fullfile(datapath, './cleaned/cleaned_Movement_S1.mat'));
expInfo = readtable(fullfile(datapath, 'ExpData_pre-S1.csv'));

% Extract XYZ positions
sensor1 = MovData.trial_3(:, 8:10); % XYZ of Sensor 1
sensor2 = MovData.trial_3(:, 20:22); % XYZ of Sensor 2
sensor3 = MovData.trial_3(:, 32:34); % XYZ of Sensor 3

sensor1 = table2array(sensor1);
sensor2 = table2array(sensor2);
sensor3 = table2array(sensor3);


% baseline correction
Fs  = 120;
bsl = 0.4;
bslPoints = 1: round(bsl*Fs);
sensor1bc = sensor1 - mean(sensor1(bslPoints,:),1);
plot3(sensor1bc(:,1), sensor1bc(:,2), sensor1bc(:,3))

% identify start of movement: take diff & amplitude
figure;
subplot(1,2,1); 
z = 1:numel(sensor1bc(:,1)); % time
patch([sensor1bc(:,1); nan],[sensor1bc(:,3); nan],[z nan],[z nan], 'edgecolor', 'interp'); 
xlabel('x'); ylabel('z');
subplot(1,2,2);
patch([sensor1bc(:,2); nan],[sensor1bc(:,1); nan],[z nan],[z nan], 'edgecolor', 'interp'); 
xlabel('y'); ylabel('x');
colorbar;colormap(jet);

subplot(1,2,2); plot(sensor1bc(:,1), sensor1bc(:,2));
xlabel('x'); ylabel('y');

numFrames = size(sensor1, 1);

% Create video writer object
%videoFilename = 'sensor_animation.mp4';
%v = VideoWriter(videoFilename, 'MPEG-4'); 
%v.FrameRate = 60;
%open(v);

% Create figure
figure;
hold on;
grid on;
xlabel('X Position'); ylabel('Y Position'); zlabel('Z Position');
title('Sensor Movement with Connections');
view(3);

h1 = plot3(NaN, NaN, NaN, 'ro-', 'LineWidth', 1.5); % Sensor 1 (Red)
h2 = plot3(NaN, NaN, NaN, 'go-', 'LineWidth', 1.5); % Sensor 2 (Green)
h3 = plot3(NaN, NaN, NaN, 'bo-', 'LineWidth', 1.5); % Sensor 3 (Blue)

line1 = plot3(NaN, NaN, NaN, 'k-', 'LineWidth', 2); % Line between Sensor 1 and 2
line2 = plot3(NaN, NaN, NaN, 'k-', 'LineWidth', 2); % Line between Sensor 2 and 3

legend({'Sensor 1', 'Sensor 2', 'Sensor 3', 'Connections'});

% Animation loop
for i = 800:numFrames
    set(h1, 'XData', sensor1(1:i,1), 'YData', sensor1(1:i,2), 'ZData', sensor1(1:i,3));
    set(h2, 'XData', sensor2(1:i,1), 'YData', sensor2(1:i,2), 'ZData', sensor2(1:i,3));
    set(h3, 'XData', sensor3(1:i,1), 'YData', sensor3(1:i,2), 'ZData', sensor3(1:i,3));
    
    set(line1, 'XData', [sensor1(i,1), sensor2(i,1)], ...
               'YData', [sensor1(i,2), sensor2(i,2)], ...
               'ZData', [sensor1(i,3), sensor2(i,3)]);

    set(line2, 'XData', [sensor2(i,1), sensor3(i,1)], ...
               'YData', [sensor2(i,2), sensor3(i,2)], ...
               'ZData', [sensor2(i,3), sensor3(i,3)]);
    
    pause(0.001);

    frame = getframe(gcf);
    %writeVideo(v, frame);
end

close(v);
hold off;