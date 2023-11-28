

% 1) set code paths and switches
save_results = true;
loadNeural = true;   % time consuming, can skip if only looking at behavior

% change these to wherever you saved code, data, and wherever you want to save figures
setenv('CODE_ROOT','/Users/erictrautmann/Dropbox/shenoy_lab/code/')
setenv('DATA_ROOT','/Users/erictrautmann/data/')
setenv('FIG_ROOT','/Users/erictrautmann/Dropbox/columbia/figures/pacman/cousteau/')
figPath = fullfile(getenv('FIG_ROOT'),'pacman-gain-switch',date);
mkdir(figPath)

% load a lookup table of parameters specific to each recording session
dataset_list_file = fullfile(getenv('CODE_ROOT'),'pacman-data-load','pacman_dataset_list.csv');
dataset_list = readtable(dataset_list_file);
dataset_list.date.Format = 'yyyy-MM-dd'


%% unpack some data from the dataset_list

% manually specify a dataset
ind = 1;
% ind = find(dataset_list.date == '2021-03-18');

date = char(dataset_list.date(ind));
subject = dataset_list.subject{ind};
protocol = 'pacman-task';
gNum = dataset_list.g_num(ind);
tNum = dataset_list.t_num(ind);
imecNums = dataset_list.imec_num(ind);
padDuration = [dataset_list.pad_start(ind), dataset_list.pad_end(ind)];
saveTags = dataset_list.savetags(ind);
syncChan = dataset_list.sync_chan(ind);
syncBit = dataset_list.sync_bit(ind);

% example parameters required to load a dataset:

% subject = '';
% date = '';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.5, 1]; % data padding on front and back end of a trial. Cannot be too long, typically not more than [4, 1] might not work
% saveTags = [0:100];   % typically only 0-5 used, but can use a wide range to ensure all savetags are loaded
% syncChan = 3;         % 2 for some datasets, if there's an issue with syncing try either 2 or 3.
% syncBit = 8;          


%% ======================================================================== 
% Main script to load behavioral data from Speedgoat and sync spike-sorted
% neural data recorded using neuropixels
% =========================================================================

clc

channelMapFile = which('neuropixels_NHP_channel_map_dev_staggered_v1.mat');
assert(~isempty(channelMapFile),'Channel map not found on path')

% 0.2) add dependent libraries to path. 
% TODO: trim cruft, not all of these likely necessary anymore
addpath(genpath(fullfile(getenv('CODE_ROOT'),'pacman-data-load'))); 
addpath(genpath(fullfile(getenv('CODE_ROOT'),'npy-matlab')));          % https://github.com/kwikteam/npy-matlab
addpath(genpath(fullfile(getenv('CODE_ROOT'),'spikes')));              % https://github.com/cortex-lab/spikes
addpath(genpath(fullfile(getenv('CODE_ROOT'),'sortingQuality')));      % https://github.com/cortex-lab/sortingQuality
addpath(genpath(fullfile(getenv('CODE_ROOT'),'neuropixel-utils')));    % https://github.com/djoshea/neuropixel-utils
addpath(genpath(fullfile(getenv('CODE_ROOT'),'matlab-utils')));        % https://github.com/djoshea/matlab-utils     % 2023-08-16 EMT: only using isstringlike, can likely remove this dependency

% 0.3) setup data paths
paths = pacmanPaths(getenv('DATA_ROOT'), protocol, subject, date, gNum, tNum, imecNums, 'pathWarningsOn', false);

% Main data load and synchronization function
[Task, Tsync, ks, metrics, stats, centroids_good ] = importPacmanData(subject, date, paths, ...
    'gNum', gNum, ...
    'tNum', tNum, ...
    'imecNums', imecNums,...
    'padDuration', padDuration, ...
    'saveTags', saveTags, ...
    'syncChan', syncChan, ...
    'syncBit', syncBit, ...
    'channelMapFile', channelMapFile, ...
    'loadNeural', loadNeural, ...
    'loadMetrics',false, ...
    'saveResults', save_results, ...
    'debugPlots',true, ...
    'verbose',false);

