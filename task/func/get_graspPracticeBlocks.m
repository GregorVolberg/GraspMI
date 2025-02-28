function [runs] = get_graspPracticeBlocks(noRepStartEnd, noMoreThanXRepetitions, starting_condition, ISI)
% 3 x 2 conditions
% in 2 blocks with 12 trials each
% i. e. 4 repetitions per block, 24 trials

protoBlock = repmat([1:3], 1, 4);    % three conditions, 13 repetitions within one block
if starting_condition == 1
    condition_marker = [5 6]; % use 5 and 6 as marker values, works with Polhemus Viper
   elseif starting_condition == 2
    condition_marker = [6 5]; % use 5 and 6 as marker values, works with Polhemus Viper
end

for run = 1:2
goodBlock = 0;
while ~goodBlock
    t1 = Shuffle(protoBlock);
    repeated = [0 diff(t1) == 0];
    numOfRepetitons = tabulate(bwlabel(repeated));
    criterion1 = all(numOfRepetitons(2:end,2) <= (noMoreThanXRepetitions-1));
    criterion2 = all(repeated([1:noRepStartEnd, (length(repeated) - noRepStartEnd):length(repeated)])==0);
    goodBlock = criterion1 & criterion2;
end
cmarker = repmat(condition_marker(run), 1, length(protoBlock));
actualISI = randsample([ISI(1):1/120:ISI(2)],length(protoBlock), true) - (1/120)/2; % frame exact at 120 Hz
runs{run} = [t1; cmarker; actualISI]';
end

end