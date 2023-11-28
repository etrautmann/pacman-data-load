function success = pacman_matlab_pipeline(subject, dataRoot, figRoot, date, gNum, tNum, imecNums, padDuration, saveTags, syncChan, syncBit, loadNeural, loadMetrics)
% highest level function to run the matlab pacman import pipeline
% Note, if loading a single dataset, you may prefer to start with
% demo_run_load_neural_and_behavior.m. 
%
% This function overlaps somewhat, but encapsulates all required
% functionality for calling the pipeline from python (for example)
%
% EMT 2023-07-12
%
% requires the following libraries on the path:
% addpath(genpath(fullfile(srcPath,'pacman-analysis')));
% addpath(genpath(fullfile(srcPath,'npy-matlab')));          % https://github.com/kwikteam/npy-matlab
% addpath(genpath(fullfile(srcPath,'spikes')));              % https://github.com/cortex-lab/spikes
% addpath(genpath(fullfile(srcPath,'sortingQuality')));      % https://github.com/cortex-lab/sortingQuality
% addpath(genpath(fullfile(srcPath,'neuropixel-utils')));    % https://github.com/djoshea/neuropixel-utils
% addpath(genpath(fullfile(srcPath,'trial-data')));          % https://github.com/djoshea/trial-data
% addpath(genpath(fullfile(srcPath,'matlab-utils')));        % https://github.com/djoshea/matlab-utils

% example single session data:
% subject = 'igor';
% date = '2022-05-19';
% gNum = 0;
% tNum = 0;
% imecNums = 1;
% padDuration = [.5, .5];
% saveTags = [0:10];
% syncChan = 3;
% syncBit = 8;


%%

% loadNeural = true;
channelMapFile = which('neuropixels_NHP_channel_map_dev_staggered_v1.mat');
assert(~isempty(channelMapFile),'Channel map not found on path')

protocol = 'pacman-task';

% 0.3) setup paths
paths = pacmanPaths(dataRoot, protocol, subject, date, gNum, tNum, imecNums, 'figRoot', figRoot);

%% Main function  to load behavioral data from Speedgoat and sync spike-sorted
% neural data recorded using neuropixels


channelMapFile = which('neuropixels_NHP_channel_map_dev_staggered_v1.mat');
assert(~isempty(channelMapFile),'Channel map not found on path')

clc


% manually override taskTableOutputPath (if you want to specify where to store processed task data)
% paths.taskTableOutputPath = fullfile(getenv('DATA_ROOT'), subject, 'processed', date, 'mergedTaskData', [paths.prefix '_taskdata.mat']);
% makeContainingFolder(paths.taskTableOutputPath)

[Task, Tsync, ks, metrics, stats, centroids_good, neuron_snrs] = import_pacman_data(subject, date, paths, ...
    'gNum', gNum, ...
    'tNum', tNum, ...
    'imecNums', imecNums, ...
    'channelMapFile', channelMapFile, ...
    'padDuration', padDuration, ...
    'saveTags', saveTags, ...
    'syncChan', syncChan, ...
    'syncBit', syncBit, ...
    'loadNeural', loadNeural, ...
    'loadMetrics',loadMetrics, ...
    'verbose',false); %#ok


% #TODO: create meaningful success metric for return value
if length(Task) > 1
    success = true;
else
    success = false;
end
