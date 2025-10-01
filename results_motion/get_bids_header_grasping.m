function [hdr] = get_bids_header_grasping(infile)

tmp     = jsondecode(fileread(infile)); 

hdr = [];
hdr.Fs = tmp.SamplingFrequency;
hdr.nChans = tmp.MotionChannelCount;
hdr.nSamples = single(tmp.RecordingDuration*hdr.Fs);
hdr.nSamplesPre = 0;
hdr.nTrials = 1;
hdr.label   = {'T_pos_x', 'T_pos_y', 'T_pos_z', ...  % thumb
        'F_pos_x', 'F_pos_y', 'F_pos_z', ...  % Fovea radialis, between thumb and index finger
        'I_pos_x', 'I_pos_y', 'I_pos_z'}';
hdr.chantype = cellstr(repmat('POS', 9,1)); 
hdr.chanunit = cellstr(repmat('cm', 9,1));

%   hdr.Fs          = sampling frequency
%   hdr.nChans      = number of channels
%   hdr.nSamples    = number of samples per trial
%   hdr.nSamplesPre = number of pre-trigger samples in each trial
%   hdr.nTrials     = number of trials
%   hdr.label       = Nx1 cell-array with the label of each channel
%   hdr.chantype    = Nx1 cell-array with the channel type, see FT_CHANTYPE
%   hdr.chanunit    = Nx1 cell-array with the physical units, see FT_CHANUNIT
end
