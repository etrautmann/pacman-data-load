

% 1) set code paths and switches
save_results = true;
loadNeural = false;

% setenv('DATA_ROOT',sprintf('/Volumes/emt_ssd_6/data/'))
setenv('DATA_ROOT',sprintf('/Users/erictrautmann/data/'))
setenv('FIG_ROOT','/Users/erictrautmann/Dropbox/columbia/figures/pacman/cousteau/')
codeRoot = '~/Dropbox/shenoy_lab/code/';
figPath = fullfile(getenv('FIG_ROOT'),'pacman-gain-switch',date);
mkdir(figPath)


% 2) set parameters for a given session
% Example parameters for a given recording session
subject = 'cousteau';
date = '2021-03-18';
protocol = 'pacman-task';
gNum = 0;
tNum = 0;
imecNums = 0;
padDuration = [1, 1];
saveTags = [0];
syncChan = 3;    
syncBit = 8;


% subject = 'cousteau';
% date = '2021-03-24';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [1,1];
% saveTags = [0:100];
% syncChan = 2;    
% syncBit = 8;

% subject = 'cousteau';
% date = '2021-03-29';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [1,1];
% saveTags = [0:100];
% syncChan = 2;    
% syncBit = 8;

% subject = 'cousteau';
% date = '2021-05-25';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.5,.5];
% saveTags = [2];
% syncChan = 2;    
% syncBit = 8;

% 
% subject = 'cousteau';
% date = '2021-08-09';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.5, .5];
% saveTags = [1];
% syncChan = 3;    
% syncBit = 8;


% subject = 'cousteau';
% date = '2021-08-11';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.5, .5];
% saveTags = [0:5];
% syncChan = 3;    
% syncBit = 8;


% subject = 'igor';
% date = '2022-12-02';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.75, .75];
% saveTags = [0:5];
% syncChan = 3;    
% syncBit = 8;

% subject = 'igor';
% date = '2022-12-05';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.75, .75];
% saveTags = [0:100];
% syncChan = 3;    
% syncBit = 8;

% subject = 'igor';
% date = '2022-12-07';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.75, .75];
% saveTags = [0:100];
% syncChan = 3;    
% syncBit = 8;

% subject = 'igor';
% date = '2022-12-09';
% protocol = 'pacman-task';
% gNum = 0;
% tNum = 0;
% imecNums = 0;
% padDuration = [.75, .75];
% saveTags = [0:100];
% syncChan = 3;    
% syncBit = 8;


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

% 0.2) add dependent libraries to path
addpath(genpath(fullfile(codeRoot,'npy-matlab')));          % https://github.com/kwikteam/npy-matlab
addpath(genpath(fullfile(codeRoot,'spikes')));              % https://github.com/cortex-lab/spikes
addpath(genpath(fullfile(codeRoot,'sortingQuality')));      % https://github.com/cortex-lab/sortingQuality
addpath(genpath(fullfile(codeRoot,'neuropixel-utils')));    % https://github.com/djoshea/neuropixel-utils
addpath(genpath(fullfile(codeRoot,'matlab-utils')));        % https://github.com/djoshea/matlab-utils     % 2023-08-16 EMT: only using isstringlike, can likely remove this dependency
% EMT 2023-04-18 - the following are likely not needed so commenting them
% out as dependencies for now
% addpath(genpath(fullfile(codeRoot,'trial-data')));          % https://github.com/djoshea/trial-data



% 0.3) setup data paths
paths = pacmanPaths(getenv('DATA_ROOT'), protocol, subject, date, gNum, tNum, imecNums, 'pathWarningsOn', false);
% paths = pacmanPaths(data_root, protocol, subject, date, gNum, tNum, imecNum)



% Main data load and synchronization function
[Task, Tsync, ks, metrics, stats, centroids_good ] = import_pacman_data(subject, date, paths, ...
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







%% debug script version of import_pacman_data. Can ignore
% uncomment to step through components to debug components as necessary 


% 
% % return
% 
% % 1) load behavior data
% 
% tic
% 
% T = loadsession(fullfile(paths.sgDataPath, paths.prefixBehavior));
% fprintf('Session loaded: %d trials \n',size(T,1))
% 
% 
% % attempt to load EMG data
% % nsx = openNSx(paths.brDataPath,'uv');
% 
% timing = [];
% timing.behaviorLoad = toc
% 
% 
% %% 2) load kilosort output
% 
% 
% if (loadNeural == 1)
%     [spikeIdxMat, clusterID, clusterLabels] = ksResults2spikeMat(paths.ksResultsPath);
%     fprintf('Spike Times loaded %.1f \n', toc)
%     spikeIdxMat_orig = spikeIdxMat;
%     
%     timing.spikeMatCreated = toc
%     
%     % 3) convert spiketimes from imec headstage sample indices into NIDAQ indices:
%     niMeta = readSpikeGLXmeta(paths.nidaqMetaPath);
%     FsNi = niMeta.sRateHz;
%     
%     apMeta = readSpikeGLXmeta(paths.npixApMetaPath);
%     FsImec = apMeta.sRateHz;
%     
%     spikeIdxMatNi = convertSpikeTimeIndices(spikeIdxMat, FsImec, FsNi);
%     size(spikeIdxMatNi)
%     
%     timing.spikeTimesConverted = toc
%     
%     % 4) sync spike times with behavior
%     [Tsync, Times] = syncSpeedgoatNidaq(paths.nidaqPath, T, 'spikes',spikeIdxMatNi,'SGsyncChan',syncChan, 'SGsyncBit',syncBit);
%     fprintf('Spike Times synced: %.1f sec\n',toc)
%     
%     timing.nidaqSynced = toc
% else
%     Tsync = T; 
% end
% 
% %% 5) Calculate condition info 
% 
% 
% Task = paccond_gain_switch( Tsync,'neuropixels','saveTags',saveTags,'padDur',padDuration, 'alignTrials',false, 'errThr',2);
% fprintf('Task struct created: %.1f sec\n', toc)
% 
% timing.taskConditionTable = toc
% 
% 
% %% 6) Export Task in .mat file (generally for Python)
% 
% 
% saveTaskTable = 1;
% if saveTaskTable
%     exportTaskTable(Task, paths.taskTableOutputPath)
%     timing.taskDataSaved = toc
% end



