function [mot]  = get_motion_bids(motion_json, events_tsv, motion_tsv, prestim, poststim)

hdr       = ft_read_header(motion_json, 'headerformat', 'get_bids_header_grasping'); 
conTable  = ft_read_tsv(events_tsv);
data      = struct2array(tdfread(motion_tsv));

%% build raw data structure
mot       = [];
mot.label = hdr.label;
mot.sampleinfo = [conTable.sample_point - prestim * hdr.Fs, ...
                    conTable.sample_point + poststim * hdr.Fs];
mot.time = repmat({-prestim : 1/hdr.Fs: poststim}, 1, size(mot.sampleinfo,1));
mot.trialinfo  = conTable;
mot.hdr        = hdr;

for k = 1:size(mot.sampleinfo,1)
trial{k} = data(mot.sampleinfo(k,1):mot.sampleinfo(k,2),:)';
end

mot.trial = trial;
end
