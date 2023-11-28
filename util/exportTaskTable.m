function [TS] = exportTaskTable(Task, fileName, varargin)
%
% EMT / HSC 2021-04-01
%
% 

p = inputParser();
p.addRequired('Task');
p.addRequired('fileName', @isstringlike);
p.addParameter('includeSingleTrials',true, @islogical);

p.KeepUnmatched = false;    
p.parse(Task, fileName, varargin{:});
% /input parsing


% Conditions
conds = table2struct(Task.Conditions);

% Target force
targetForces = makerow(Task.targetForce);

% Beh forces
forces = {Task.Force.data};

% Beh force labels
forceLabels = {Task.Force.variableLabels};
forceLabels = forceLabels{1};

cursorPositions = makerow(Task.cursorPosition);

% Alignment indices
alignIdxs = {Task.Force.alignIndex};

% Spikes
spikes = {Task.MU.spikes};

% Single trial
rates = {Task.MU.rate};

% PSTH (trial average)
psths = cellfun(@(x) squeeze(x(:,:,1)), {Task.MU.psth}, 'UniformOutput', false);    % keep mean, strip variance

% mask out specific conditions:
% 2023-08-22: EMT: figure out if this condition masking is still necessary 
condMask = cellfun(@(x) size(x,3) > 1, forces);
    
conds = conds(condMask);
targetForces = targetForces(condMask);
forces = forces(condMask);
cursorPositions = cursorPositions(condMask);
alignIdxs = alignIdxs(condMask);
spikes = spikes(condMask);
rates = rates(condMask);
psths = psths(condMask);

n_conds = length(conds);

sprintf("saving data to: %s",fileName)

if p.Results.includeSingleTrials
    save(fileName, 'n_conds','conds','targetForces','forces','forceLabels','cursorPositions','alignIdxs','spikes','rates','psths', '-v7.3')
else
    save(fileName, 'n_conds','conds','targetForces','forces','forceLabels','cursorPositions','alignIdxs','psths', '-v7.3')
end
