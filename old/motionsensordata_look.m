% structure of motion sensor data

orig  = readtable('./data/S1_Motion.csv');
clean = importdata('./data/cleaned/cleaned_Imaging_S1.mat');

names = clean.trial_1.Properties.VariableNames;

Sample = orig.Frame;
Fs = 1/120; % Sampling Rate 120 Hz

% the four (three plus marker) sensors are table headers

%'Sensor'    % one small black spacer:  Thumb? 
%'Sensor_1'  % two small black spacers: joint (bone) between index finger
%and thumb
%'Sensor_2'  % three small black spacers: index finger
%'Sensor_3'
% corresponing XYZ values are 'X', 'Y', 'Z'; 'X_1', 'Y_1', 'Z_1' etc
% 