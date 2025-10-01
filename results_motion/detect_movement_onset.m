function [movement_start_idx, velocity_magnitude,distance_from_origin] = detect_movement_onset(X, Y, Z, velo_threshold, pos_threshold, Fs)
    % Bewegungsbeginn basierend auf Geschwindigkeit und Position erkennen
    
    n_samples = length(X);
    movement_start_idx = [];
    
    if n_samples < 3
        return;
    end
    
    % Geschwindigkeit berechnen (erste Ableitung)
    dt = 1; % 1 Sample
    
    vx = gradient(X) / dt * Fs;
    vy = gradient(Y) / dt * Fs;
    vz = gradient(Z) / dt * Fs;
    
    % Gesamtgeschwindigkeit
    velocity_magnitude = sqrt(vx.^2 + vy.^2 + vz.^2);
    
    % Abstand vom Ursprung
    distance_from_origin = sqrt(X.^2 + Y.^2 + Z.^2);
    
    % Bewegungsbeginn suchen
    velocity_filtered   = medfilt1(velocity_magnitude, 5);
    distance_1st_sample = min(find(distance_from_origin > pos_threshold));
    % prüfe, ob velocity bei position_threshold > velocity_threshold ist
    if velocity_filtered(distance_1st_sample) > velo_threshold
        % falls ja, gehe rückwärts, so lange velocity_filtered >    velo_threshold
        for j = distance_1st_sample:-1:3
          if velocity_filtered(j) <=  velo_threshold
              movement_start_idx = j; break
          end
        end
    else % falls nein, NaN
        movement_start_idx = [];
    end
    
%     % Alternativ: kombiniertes Amplituden- und Beschleunigungsmaß
%     for i = 2:n_samples
%         % Prüfen ob beide Kriterien erfüllt sind
%         if velocity_magnitude(i) > velo_threshold && distance_from_origin(i) > pos_threshold
%             movement_start_idx = i;
%             break;
%         end
%     end
    
end