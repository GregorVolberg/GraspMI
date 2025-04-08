function [vp, starting_condition, color_mapping, msf_colors, msf_text] = get_experimentInfo()

  vp = input('\nParticipant (three characters, e.g. S01)? ', 's');
    if length(vp)~=3 
       error ('Wrong input: Use three characters.'); end
   starting_condition = str2num(input('\nStarting condition?\n1: movement \n2: imagery\n', 's'));    
      if ~ismember(starting_condition, [1, 2])
        error('\nUnknown starting condition!'); end
   color_mapping = str2num(input('\nColor mapping (mouth, shoulder, forward)?\n1: red, green, blue\n2: green, blue, red\n3: blue, red, green\n', 's'));    
      if ~ismember(color_mapping, [1, 2, 3])
        error('\nUnknown color mapping!'); end
   
     switch color_mapping
     case  1
         msf_colors = {[255 0 0], [0 255 0], [51 171 240]}; % use light blue
         msf_text   = {'mouth = red'; 'shoulder = green'; 'forward = blue'};
     case  2
         msf_colors = {[0 255 0], [51 171 240], [255 0 0]};
         msf_text   = {'mouth = green'; 'shoulder = blue'; 'forward = red'};
     case 3
         msf_colors = {[51 171 240], [255 0 0], [0 255 0]};
         msf_text   = {'mouth = blue'; 'shoulder = red'; 'forward = green'};
     end

end

    

