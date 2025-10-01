# GraspMI
EEG study on ...
## Stimuli and Procedure
6 runs with 39 trials each
alternating runs with real movement and imagined movement (starting condition balanced across participants)
three movement randomized within each block: mouth, shoulder, forward. Indicated by red, green or blue color of a fixation cross as a cue. Color mapping was balanced across participants. 

## Analysis
### Preprocessing
Per participant, the EEG and motion data were converted to BIDS format. As a part of the data transform, trial information was gathered from protocol files and added to event files. The motion data was used to identify  actual movement onsets in trials were real movements were required. Moreover, trials where movements occurred in the imagery conditions, or no movement occurred in the real movement condition were marked as invalid. These information were added to the EEG event files and were later used for epoching and selection of trials.

The EEG synchronization markers reflect the presentation onset of cues that instructed participants to (a) start the movement in real movement trials and (b) start imagining the movement in imagery trials. In real movement trials, the onsets were re-defined to the actual movement onsets according to the motion data files. 

For artifact correction, first pass, the data was epoched and visually inspected for bad channels and irregular artefacts. Artefacts related to blinks and eye movements were spared out. Information about bad epoch (i. e., bad trials) were added to the EEG event files, and information about bad channels were saved for later use.

To account for indiosyncratic raw data (e. g. different EEG marker values) and to allow for a visual inspection of the data, preprocessing steps were done with individual scripts. E. g., for participant S01: 
- *./preproc/convEEG2bids_S01.m*:  convert raw Brain Vision EEG data to BIDS
- *./preproc/convCSV2bids_S01.m*: convert raw Polhemus motion data to BIDS
- *./preproc/add_motion_onset_S01.m*: add motion onsets to EEG data
- *./preproc/firstpass_EEGartefact_S01.m*: filter 1 - 40Hz, epoch -0.5 - 3s, identify bad epochs and channels and write to events file
- *./preproc/get_ICs.m*: loop over all participants, get ICs using only good epochs and channels, save ICs
- *./preproc/identify_bad_components_S01.m*: identify bad components and write to events file
- *./preproc/secondpass_EEGartefact_S01.m*: remove bad components, interpolate bad channels, identify remaining bad epochs and write to events file

- complete preprocessing without user intervention can be performed from src/run01_preprocessing.m

Protocol 1st pass artifact
S09, many single-electrode artefacts
S10, second pass, FC electrodes almost flat
S11, strong hf noise at frontal electrodes in some trials, mainly first half of experiment
S12, noisy
S13, very noisy, six broken channels, remove from data set (even more broken channels in 2nd pass)
S15, excessive eye movements and blinks, not well removed from EEG data after ICA
S16, noisy
S18, slow drifts, otherwise OK
S23, slow drifts, otherwise fine
