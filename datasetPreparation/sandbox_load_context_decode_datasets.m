% Notes:
% 2022-07-18: Created this script to generate output for python import that
% filters the task table by the previous trial's gain context. It turned
% out to be simpler to do this this way than to filter down trials from the
% xarray data structure in python, although this is inelegant.


user = 'eric';
% user = 'andrew';

saveTaskTable = false


subject = 'cousteau';
date = '2021-03-18';
gNum = 0;
tNum = 0;
imecNum = 0;
padDuration = [3.5, 1];
SAVE_TAG = [0];
syncChan = 3;
syncBit = 8;

% Main script to load behavioral data from Speedgoat and sync spike-sorted
% neural data recorded using neuropixels


%% 

% 0.1) Set data root location
switch user
    case 'eric'
%         setenv('DATA_ROOT','/Volumes/emt_ssd_2/data/pacman-task/')
%         setenv('DATA_ROOT','/Volumes/emt_ssd_3/data/pacman-task/')
        setenv('DATA_ROOT','/Users/erictrautmann/data/pacman-task/')
        setenv('FIG_ROOT','/Users/erictrautmann/Dropbox/columbia/figures/pacman-decisions/cousteau/')
        srcPath = '~/Dropbox/shenoy_lab/code/';
    
    case 'andrew'
        setenv('DATA_ROOT','');       % local path for data
        setenv('FIG_ROOT','');                  % local path for saved figures
        srcPath = '~/Dropbox/shenoy_lab/code/'; % local path for pacman-analysis repo
end

figPath = fullfile(getenv('FIG_ROOT'),'pacman-gain-switch',date);
mkdir(figPath)


% 0.2) add libraries to path

addpath(genpath(fullfile(srcPath,'pacman-analysis')));
addpath(genpath(fullfile(srcPath,'npy-matlab')));          % https://github.com/kwikteam/npy-matlab
addpath(genpath(fullfile(srcPath,'spikes')));              % https://github.com/cortex-lab/spikes
addpath(genpath(fullfile(srcPath,'sortingQuality')));      % https://github.com/cortex-lab/sortingQuality
addpath(genpath(fullfile(srcPath,'neuropixel-utils')));    % https://github.com/djoshea/neuropixel-utils
addpath(genpath(fullfile(srcPath,'trial-data')));          % https://github.com/djoshea/trial-data
addpath(genpath(fullfile(srcPath,'matlab-utils')));        % https://github.com/djoshea/matlab-utils
addpath(genpath(fullfile(srcPath,'esNPMK')));                % https://github.com/BlackrockMicrosystems/NPMK

% 0.3) setup paths
paths = pacmanPaths(getenv('DATA_ROOT'), subject, date, gNum, tNum, imecNum);
% manually override taskTableOutputPath (if you want to specify where to store processed task data)
paths.taskTableOutputPath = fullfile(getenv('DATA_ROOT'), subject, 'processed', date, 'mergedTaskData', [paths.prefix '_taskdata.mat']);
makeContainingFolder(paths.taskTableOutputPath)


%% 1) load behavior data

tic

T = loadsession(fullfile(paths.sgDataPath, paths.prefixBehavior));
fprintf('Session loaded: %d trials \n',size(T,1))

% attempt to load EMG data
% nsx = openNSx(paths.brDataPath,'uv');

timing = [];
timing.behaviorLoad = toc

% pg = cellfun(@x(x.previous))

%%

gain = cell2mat(T.gain);
prevGain = cell2mat(T.previousGain);
trialMask = prevGain>0;
% 
% T_pg_pos = T(pg > 0,:)
% T_pg_neg = T(pg < 0,:)

T_pg_pos_cg_pos = T((prevGain > 0 & gain > 0),:)
T_pg_neg_cg_neg = T((prevGain < 0 & gain < 0),:)

%% 2) load kilosort output

[spikeIdxMat, clusterID, clusterLabels] = ksResults2spikeMat(paths.ksResultsPath);
fprintf('Spike Times loaded %.1f \n', toc)
spikeIdxMat_orig = spikeIdxMat;

timing.spikeMatCreated = toc

%% 3) convert spiketimes from imec headstage sample indices into NIDAQ indices:

niMeta = readSpikeGLXmeta(paths.nidaqMetaPath);
FsNi = niMeta.sRateHz;

apMeta = readSpikeGLXmeta(paths.npixApMetaPath);
FsImec = apMeta.sRateHz;

spikeIdxMatNi = convertSpikeTimeIndices(spikeIdxMat, FsImec, FsNi);
size(spikeIdxMatNi)

timing.spikeTimesConverted = toc

%% 4) sync spike times with behavior

[Tsync_pg_pos_cg_pos, ~] = syncSpeedgoatNidaq(paths.nidaqPath, T_pg_pos_cg_pos, 'spikes',spikeIdxMatNi,'SGsyncChan',syncChan, 'SGsyncBit',syncBit);
fprintf('Spike Times synced: %.1f sec\n',toc)

[Tsync_pg_neg_cg_neg, ~] = syncSpeedgoatNidaq(paths.nidaqPath, T_pg_neg_cg_neg, 'spikes',spikeIdxMatNi,'SGsyncChan',syncChan, 'SGsyncBit',syncBit);
fprintf('Spike Times synced: %.1f sec\n',toc)

timing.nidaqSynced = toc


%% 5) Calculate condition info 


Task_pg_pos_cg_pos = paccond_gain_switch(Tsync_pg_pos_cg_pos,'neuropixels','saveTags',SAVE_TAG,'padDur',padDuration, 'alignTrials',false);
fprintf('Task struct created: %.1f sec\n', toc)

Task_pg_neg_cg_neg = paccond_gain_switch(Tsync_pg_neg_cg_neg,'neuropixels','saveTags',SAVE_TAG,'padDur',padDuration, 'alignTrials',false);
fprintf('Task struct created: %.1f sec\n', toc)

timing.taskConditionTable = toc


%% 6) Export Task in .mat file (generally for Python)


ttoutpath = paths.taskTableOutputPath;
[rootpath,filename,ext] = fileparts(ttoutpath)


saveTaskTable = 1;
if saveTaskTable
    exportTaskTable(Task_pg_pos_cg_pos, fullfile(rootpath, [filename '_pg_pos_cg_pos' ext]))
    timing.taskDataSaved = toc
    exportTaskTable(Task_pg_neg_cg_neg, fullfile(rootpath, [filename '_pg_neg_cg_neg' ext]))
    timing.taskDataSaved = toc
end



