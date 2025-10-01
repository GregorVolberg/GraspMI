conditions = struct2table(tdfread("sub-S02_task-Grasping_tracksys-PolhemusViper_events.tsv"));
data = struct2array(tdfread("sub-S02_task-Grasping_tracksys-PolhemusViper_motion.tsv"));

conditions.sample_point = round(conditions.onset *240 + 1/240);

segment_length = 3; % in Sekunden
trial = 50; % Trial 50, real movement
segm = data(conditions.sample_point(trial):(conditions.sample_point(trial) + segment_length * 240),:);

% nur Daumen
plt3D = segm(:,1:3)';

figure;
hold on;
grid on;
xlabel('X Position'); ylabel('Y Position'); zlabel('Z Position');
title('Sensor Movement');
view(3);
plot3(plt3D(1,:), plt3D(2,:), plt3D(3,:));

%% Analyse der Bewegungsrichtungen (Sensor 1)
% Autor: Philip
% Datum: automatisch generiert
% Beschreibung: Überprüft, ob die X/Y/Z-Koordinaten den experimentellen Erwartungen entsprechen

clear; clc;

%% Parameter
fs = 240;  % Sampling rate (Hz)
segment_duration = 3;  % in Sekunden
segment_length = segment_duration * fs;

%% Dateien laden
events = struct2table(tdfread("sub-S02_task-Grasping_tracksys-PolhemusViper_events.tsv"));
motion = struct2array(tdfread("sub-S02_task-Grasping_tracksys-PolhemusViper_motion.tsv"));

% Berechne Samplepunkte
events.sample_point = round(events.onset * fs + 1/fs);

n_trials = height(events);

%% Bewegung pro Trial analysieren (nur Sensor 1)
movement_summary = table('Size', [n_trials, 7], ...
    'VariableTypes', {'string','double','double','double','double','double','double'}, ...
    'VariableNames', {'condition','dx','dy','dz','maxX','maxY','maxZ'});

for trial = 1:n_trials
    % hole Condition
    cond = string(events.condition(trial));  % evtl. anpassen bei anderer Spaltenbezeichnung

    % hole Daten
    sp = events.sample_point(trial);

    % Vermeide Indexüberschreitung am Dateiende
    if (sp + segment_length - 1) > size(motion,1)
        continue;
    end

    segment = motion(sp:(sp + segment_length - 1), 1:3);  % Sensor 1: x,y,z

    % Baseline-Korrektur
    segment = segment - segment(1,:);

    % Start-End-Verschiebung
    delta = segment(end,:) - segment(1,:);

    % Maximalwerte
    max_vals = max(segment);

    % abspeichern
    movement_summary.condition(trial) = cond;
    movement_summary.dx(trial) = delta(1);
    movement_summary.dy(trial) = delta(2);
    movement_summary.dz(trial) = delta(3);
    movement_summary.maxX(trial) = max_vals(1);
    movement_summary.maxY(trial) = max_vals(2);
    movement_summary.maxZ(trial) = max_vals(3);
end

%% Ergebnisüberblick
disp('Mittlere Bewegungsrichtung (Endpunkt - Startpunkt) pro Condition:');
summary = groupsummary(movement_summary, 'condition', 'mean', {'dx','dy','dz'});
disp(summary);

%% Boxplots: Bewegung in X, Y, Z pro Condition
figure('Name','Boxplots Bewegungsrichtungen','Position',[100 100 1200 400]);
subplot(1,3,1); boxplot(movement_summary.dx, movement_summary.condition); title('ΔX (mean)');
ylabel('X-Verschiebung');
subplot(1,3,2); boxplot(movement_summary.dy, movement_summary.condition); title('ΔY (mean)');
ylabel('Y-Verschiebung');
subplot(1,3,3); boxplot(movement_summary.dz, movement_summary.condition); title('ΔZ (mean)');
ylabel('Z-Verschiebung');

%% Optional: 3D-Plots pro Bedingung (Bewegungspfad)
conds = unique(movement_summary.condition);

for i = 1:length(conds)
    figure('Name', ['3D Pfade – ' conds(i)]);
    hold on; grid on; view(3);
    title(['3D-Pfade der Bedingung: ' conds(i)]);
    xlabel('X'); ylabel('Y'); zlabel('Z');

    for trial = 1:n_trials
        if movement_summary.condition(trial) == conds(i)
            sp = events.sample_point(trial);
            if (sp + segment_length - 1) > size(motion,1)
                continue;
            end
            segment = motion(sp:(sp + segment_length - 1), 1:3);
            segment = segment - segment(1,:);  % Baseline
            plot3(segment(:,1), segment(:,2), segment(:,3), '-', 'Color', [0.2 0.5 1 0.3]);
        end
    end
end

%% Analyse der Bewegungsrichtungen (Sensor 1)
% Autor: Philip
% Datum: automatisch generiert
% Beschreibung: Überprüft, ob die X/Y/Z-Koordinaten den experimentellen Erwartungen entsprechen

clear; clc;

%% Parameter
fs = 240;  % Sampling rate (Hz)
segment_duration = 3;  % in Sekunden
segment_length = segment_duration * fs;

%% Dateien laden
events = struct2table(tdfread("sub-S02_task-Grasping_tracksys-PolhemusViper_events.tsv"));
motion = struct2array(tdfread("sub-S02_task-Grasping_tracksys-PolhemusViper_motion.tsv"));
disp(events.Properties.VariableNames);