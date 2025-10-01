function analyze_bids_movement_data(tlb, velocity_threshold, position_threshold)
    % BIDS Bewegungsdaten Analyse und Visualisierung
    
    % Parameter für Bewegungsbeginn-Erkennung
    %velocity_threshold = 5;  % Beschleunigungsschwelle [m/s²]
    %position_threshold = 0.75;     % Positionsschwelle [cm] - Abstand vom Ursprung
               
    % Ergebnis-Vektor für alle Durchgänge
    movement_onset_results = [];
    movement_data = tlb.trial;

    % Achsenlimits
    xlim_range = [-15, 15];
    ylim_range = [-15, 15];
    zlim_range = [-15, 15];
    
    % Plot-Beschriftungen
    title_text = 'Trajecory';
    xlabel_text = 'X (cm)';
    ylabel_text = 'Y (cm)';
    zlabel_text = 'Z (cm)';

    %% Initialisierung der Figur
    h  = figure('Name', 'Artefact correction', 'Position', [100, 400, 1200, 400]);
    
    % Erstelle leeren Plot
    subplot(1,3,1);
    h_plot  = plot3(0, 0, 0, 'b-', 'LineWidth', 2); hold on;
    h2_plot = plot3(0, 0, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
    title(title_text, 'FontSize', 14, 'FontWeight', 'bold');
    xlabel(xlabel_text, 'FontSize', 12);
    ylabel(ylabel_text, 'FontSize', 12);
    zlabel(zlabel_text, 'FontSize', 12);
    grid on;
    axis equal;
    view(45, 30); % Standardansicht
    ax = gca;
    ax.XLim = [xlim_range];
    ax.YLim = [ylim_range];
    ax.ZLim = [zlim_range];

    % Erstelle leeren Plot
    p_axis  = subplot(1,3,2);
    p_plot  = plot(tlb.time, ones(length(tlb.time),1), 'b-', 'LineWidth', 2); hold on;
    p_plot2 = scatter(0, 0, 20, [1 0 0], 'MarkerFaceColor', 'r'); 
    title('Position', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Distance from origin (cm)', 'FontSize', 12);
    set(p_axis, 'YLim', [0 30]);
    set(p_axis, 'XLim', [tlb.time(1) tlb.time(end)]);
    
    % Erstelle leeren Plot
    v_axis = subplot(1,3,3);
    v_plot = plot(tlb.time, ones(length(tlb.time),1), 'b-', 'LineWidth', 2); hold on;
    v_plot2 = scatter(0, 0, 20, [1 0 0], 'MarkerFaceColor', 'r'); 
    title('Velocity', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Velocity (cm/s)', 'FontSize', 12);
    set(v_axis, 'YLim', [0 80]);
    set(v_axis, 'XLim', [tlb.time(1) tlb.time(end)]);
    
    %% loop through trials
    for trial_count = 1:size(movement_data, 1)
        
        % Koordinaten extrahieren
        X = squeeze(movement_data(trial_count, 4,:));
        Y = squeeze(movement_data(trial_count, 5,:));
        Z = squeeze(movement_data(trial_count, 6,:));
        X0 = 0;
        Y0 = 0;
        Z0 = 0;
        
        set(h_plot, 'XData', X, 'YData', Y, 'ZData', Z)
        
        % Bewegungsbeginn ermitteln
        [movement_start_idx, velo, disto] = detect_movement_onset(X, Y, Z, velocity_threshold, position_threshold, tlb.Fs);
        
        set(p_plot, 'XData', tlb.time, 'YData', disto);
        set(v_plot, 'XData', tlb.time, 'YData', velo);
                
        if isempty(movement_start_idx)
            mov_on = NaN;
            pos_on = NaN;
            velo_on = NaN;
        else
            mov_on  = tlb.time(movement_start_idx);
            pos_on  = disto(movement_start_idx);
            velo_on = velo(movement_start_idx);
        end
        set(p_plot2, 'XData', mov_on, 'YData', pos_on);
        set(v_plot2, 'XData', mov_on, 'YData', velo_on);
        
        % Aktualisiere Titel
        current_title = sprintf('Trial %d/%d, %s, %s, onset %.3f seconds', trial_count, size(movement_data, 1), ...
            char(tlb.trialinfo.movement(trial_count)), char(tlb.trialinfo.type(trial_count)), mov_on);
        sgtitle(current_title, 'FontSize', 14, 'FontWeight', 'bold');
        
        % aktualisiere Daten
        drawnow;
        
        if ~isempty(movement_start_idx)
            fprintf('Bewegungsbeginn bei Zeitpunkt %.4f s.', tlb.time(movement_start_idx));
        else
            fprintf('Kein Bewegungsbeginn mit den gewählten Schwellenwerten erkannt.');
        end
        figure(h); % Figure to the foreground

        % wait for keypress
        validkey = false;
        while ~validkey
        w = waitforbuttonpress;
        if w
               p = get(gcf, 'CurrentCharacter');
               switch p
                   case 'y'
                       fprintf(' Angenommen.\n');
                       validkey = true;
                       movement_onset_results(trial_count) = mov_on;
                       movement_trial_valid{trial_count}   = 'yes';
                   case 'n'
                       fprintf(' Abgelehnt.\n');
                       validkey = true;
                       movement_onset_results(trial_count) = mov_on;
                       movement_trial_valid{trial_count}   = 'no';
                   case 'q'
                       fprintf('\n\nQuit.\n');
                       delete(h)
               end
        end
        end

    
        
        
    end
    tmp = table(movement_onset_results', movement_trial_valid');
    tmp.Properties.VariableNames={'mov_onset','valid_movement'};
    writetable(tmp, [tlb.code, '_movement_onsets.csv']);
    delete(h);
    close all
end



