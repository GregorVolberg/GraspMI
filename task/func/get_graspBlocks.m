function [runs] = get_graspBlocks(noRepStartEnd, noMoreThanXRepetitions, starting_condition, ISI, frame_s, numBlocks, RepsPerBlock)
% six runs with 39 trials each, 3 x 2 conditions 
% motor and imagery conditions blocked and interleaved
% 13 repetitions per block, 234 trials

if mod(numBlocks, 2) 
    error('Number of runs must be even.');
end

protoBlock = repmat([1:3], 1, RepsPerBlock);    % three conditions, 13 repetitions within one block
if starting_condition == 1
    condition_marker = repmat([5 6], 1, numBlocks/2); % use 5 and 6 as marker values, works with Polhemus Viper
   elseif starting_condition == 2
    condition_marker = repmat([6 5], 1, numBlocks/2); % use 5 and 6 as marker values, works with Polhemus Viper
end

for run = 1:numBlocks
goodBlock = 0;
while ~goodBlock
    t1 = Shuffle(protoBlock);
    repeated = [0 diff(t1) == 0];
    numOfRepetitons = tabulate(bwlabel(repeated));
    criterion1 = all(numOfRepetitons(2:end,2) <= (noMoreThanXRepetitions-1));
    criterion2 = all(repeated([1:noRepStartEnd, (length(repeated) - noRepStartEnd):length(repeated)])==0);
    goodBlock = criterion1 & criterion2;
end
cmarker = repmat(condition_marker(run), 1, 3 * RepsPerBlock);
actualISI = randsample([ISI(1):frame_s:ISI(2)], 3 * RepsPerBlock, true) - frame_s/2; % frame exact at 120 Hz
runs{run} = [t1; cmarker; actualISI]';
end

end