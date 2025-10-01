function analyze_bids_movement_data(data_file)
    % BIDS Bewegungsdaten Analyse und Visualisierung
    % Einlesen, 3D-Plot und Bewegungsbeginn-Erkennung
    %
    % Eingabe:
    %   data_folder - Pfad zum Ordner mit BIDS-Bewegungsdaten (optional)
    %                 Wenn nicht angegeben, wird aktueller Ordner verwendet
    
    % for test purpose:


    % Parameter für Bewegungsbeginn-Erkennung
    acceleration_threshold = 0.1;  % Beschleunigungsschwelle [m/s²]
    position_threshold = 0.01;     % Positionsschwelle [m] - Abstand vom Ursprung
    
           
    % Ergebnis-Vektor für alle Durchgänge
    movement_onset_results = [];
    
    movement_data = tlb.trial;
    
        % Koordinaten extrahieren
        X = movement_data(:, 4);
        Y = movement_data(:, 5);
        Z = movement_data(:, 6);
        
        % Bewegungsbeginn ermitteln
        movement_start_idx = detect_movement_onset(X, Y, Z, acceleration_threshold, position_threshold);
        
        % 3D Plot erstellen
        figure('Name', sprintf('Durchgang %d/%d: %s - 3D Visualisierung', trial_count, length(tsv_files), filename), ...
               'Position', [100, 100, 800, 600]);
        
        % Hauptplot der Trajektorie
        plot3(X, Y, Z, 'b-', 'LineWidth', 2);
        hold on;
        
        % Erstes Sample (roter Punkt)
        plot3(X(1), Y(1), Z(1), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'red', 'LineWidth', 2);
        
        % Bewegungsbeginn (schwarzer Punkt)
        if ~isempty(movement_start_idx)
            plot3(X(movement_start_idx), Y(movement_start_idx), Z(movement_start_idx), ...
                  'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'black', 'LineWidth', 2);
        end
        
        % Ursprung markieren
        plot3(0, 0, 0, 'gx', 'MarkerSize', 12, 'LineWidth', 3);
        
        % Plot formatieren
        xlabel('X [m]', 'FontSize', 12);
        ylabel('Y [m]', 'FontSize', 12);
        zlabel('Z [m]', 'FontSize', 12);
        title(sprintf('Durchgang %d/%d: %s - 3D Trajektorie', trial_count, length(tsv_files), filename), 'FontSize', 14);
        grid on;
        axis equal;
        
        % Legende
        legend_entries = {'Trajektorie', 'Erstes Sample', 'Ursprung (0,0,0)'};
        if ~isempty(movement_start_idx)
            legend_entries = {'Trajektorie', 'Erstes Sample', 'Bewegungsbeginn', 'Ursprung (0,0,0)'};
        end
        legend(legend_entries, 'Location', 'best');
        
        % Ansicht optimieren
        view(45, 30);
        
        % Informationen ausgeben
        fprintf('\n--- Bewegungsanalyse Durchgang %d/%d ---\n', trial_count, length(tsv_files));
        fprintf('Datei: %s\n', filename);
        fprintf('Gesamtanzahl Samples: %d\n', length(X));
        fprintf('Erstes Sample: X=%.4f, Y=%.4f, Z=%.4f\n', X(1), Y(1), Z(1));
        
        if ~isempty(movement_start_idx)
            fprintf('Bewegungsbeginn bei Sample %d: X=%.4f, Y=%.4f, Z=%.4f\n', ...
                    movement_start_idx, X(movement_start_idx), Y(movement_start_idx), Z(movement_start_idx));
        else
            fprintf('Kein Bewegungsbeginn mit den gewählten Schwellenwerten erkannt.\n');
        end
        
        % Zusätzliche Statistiken
        total_distance = calculate_total_distance(X, Y, Z);
        max_distance_from_origin = max(sqrt(X.^2 + Y.^2 + Z.^2));
        
        fprintf('Gesamtdistanz der Trajektorie: %.4f m\n', total_distance);
        fprintf('Maximale Entfernung vom Ursprung: %.4f m\n', max_distance_from_origin);
        
        % Benutzereingabe für Validierung
        fprintf('\n--- BENUTZEREINGABE ERFORDERLICH ---\n');
        fprintf('Ist der ermittelte Bewegungsbeginn korrekt?\n');
        if ~isempty(movement_start_idx)
            fprintf('Erkannter Bewegungsbeginn: Sample %d\n', movement_start_idx);
        else
            fprintf('Kein Bewegungsbeginn erkannt.\n');
        end
        
        while true
            user_input = input('Bewegungsbeginn akzeptieren? (y/n): ', 's');
            user_input = lower(strtrim(user_input));
            
            if strcmp(user_input, 'y')
                if ~isempty(movement_start_idx)
                    movement_onset_results(trial_count) = movement_start_idx;
                    fprintf('Bewegungsbeginn akzeptiert: Sample %d\n', movement_start_idx);
                else
                    movement_onset_results(trial_count) = NaN;
                    fprintf('Kein Bewegungsbeginn erkannt - NaN gespeichert.\n');
                end
                break;
            elseif strcmp(user_input, 'n')
                movement_onset_results(trial_count) = NaN;
                fprintf('Bewegungsbeginn abgelehnt - NaN gespeichert.\n');
                break;
            else
                fprintf('Ungültige Eingabe. Bitte "y" oder "n" eingeben.\n');
            end
        end
        
        fprintf('Aktueller Ergebnisvektor: [%s]\n', ...
                strjoin(arrayfun(@(x) sprintf('%.0f', x), movement_onset_results, 'UniformOutput', false), ', '));
        fprintf('\n');
    %end
    
    % Finale Ergebnisse
    fprintf('\n=== FINALE ERGEBNISSE ===\n');
    fprintf('Anzahl analysierter Durchgänge: %d\n', length(tsv_files));
    fprintf('Ergebnisvektor: [%s]\n', ...
            strjoin(arrayfun(@(x) sprintf('%.0f', x), movement_onset_results, 'UniformOutput', false), ', '));
    
    % Ergebnistabelle
    fprintf('\nDetaillierte Ergebnisse:\n');
    fprintf('%-15s %-25s %-15s\n', 'Durchgang', 'Datei', 'Bewegungsbeginn');
    fprintf('%-15s %-25s %-15s\n', '---------', '----', '---------------');
    for i = 1:length(tsv_files)
        if isnan(movement_onset_results(i))
            result_str = 'NaN';
        else
            result_str = sprintf('Sample %d', round(movement_onset_results(i)));
        end
        fprintf('%-15d %-25s %-15s\n', i, trial_filenames{i}, result_str);
    end
    
    % Statistiken
    valid_results = movement_onset_results(~isnan(movement_onset_results));
    fprintf('\nStatistiken:\n');
    fprintf('Gültige Ergebnisse: %d/%d (%.1f%%)\n', ...
            length(valid_results), length(tsv_files), 100*length(valid_results)/length(tsv_files));
    if ~isempty(valid_results)
        fprintf('Durchschnittlicher Bewegungsbeginn: Sample %.1f\n', mean(valid_results));
        fprintf('Standardabweichung: %.1f\n', std(valid_results));
        fprintf('Min/Max: Sample %d / Sample %d\n', min(valid_results), max(valid_results));
    end
    
    % Ergebnisvektor im Workspace speichern
    assignin('base', 'movement_onset_results', movement_onset_results);
    assignin('base', 'trial_filenames', trial_filenames);
    fprintf('\nErgebnisse wurden im Workspace gespeichert:\n');
    fprintf('- movement_onset_results: Vektor mit Bewegungsbeginn-Samples\n');
    fprintf('- trial_filenames: Cell-Array mit Dateinamen\n');
    
    fprintf('\nUmgebungsparameter:\n');
    fprintf('  - Beschleunigungsschwelle: %.4f m/s²\n', acceleration_threshold);
    fprintf('  - Positionsschwelle: %.4f m\n', position_threshold);
    fprintf('  - Analysierter Ordner: %s\n', data_file);
    
end

function movement_start_idx = detect_movement_onset(X, Y, Z, acc_threshold, pos_threshold)
    % Bewegungsbeginn basierend auf Beschleunigung und Position erkennen
    
    n_samples = length(X);
    movement_start_idx = [];
    
    if n_samples < 3
        return;
    end
    
    % Geschwindigkeit berechnen (erste Ableitung)
    dt = 1; % Annahme: 1 Zeiteinheit zwischen Samples
    
    vx = gradient(X) / dt;
    vy = gradient(Y) / dt;
    vz = gradient(Z) / dt;
    
    % Beschleunigung berechnen (zweite Ableitung)
    ax = gradient(vx) / dt;
    ay = gradient(vy) / dt;
    az = gradient(vz) / dt;
    
    % Gesamtbeschleunigung
    acceleration_magnitude = sqrt(ax.^2 + ay.^2 + az.^2);
    
    % Abstand vom Ursprung
    distance_from_origin = sqrt(X.^2 + Y.^2 + Z.^2);
    
    % Bewegungsbeginn suchen
    for i = 2:n_samples
        % Prüfen ob beide Kriterien erfüllt sind
        if acceleration_magnitude(i) > acc_threshold && distance_from_origin(i) > pos_threshold
            movement_start_idx = i;
            break;
        end
    end
    
end

function total_dist = calculate_total_distance(X, Y, Z)
    % Gesamtdistanz der Trajektorie berechnen
    
    if length(X) < 2
        total_dist = 0;
        return;
    end
    
    % Distanz zwischen aufeinanderfolgenden Punkten
    dx = diff(X);
    dy = diff(Y);
    dz = diff(Z);
    
    segment_distances = sqrt(dx.^2 + dy.^2 + dz.^2);
    total_dist = sum(segment_distances);
    
end

% Beispiel-Aufrufe:
% analyze_bids_movement_data();                    % Aktueller Ordner
% analyze_bids_movement_data('/path/to/data/');    % Spezifischer Ordner