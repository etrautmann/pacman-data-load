function [paths] = pacmanPaths(data_root, protocol, subject, date, gNum, tNum, imecNum, varargin)
% generates paths for neuropixels data files assuming the following folder

% structure:
% - data_root  (e.g,. /Users/erictrautmann/data/)
% 	- protocol (e.g. pacman-task
%       - subject
% 			- date
% 				- speedgoat
% 				- neuropixels
%                   - recording gNum folder
%                       - nidq.bin
%                  	    - nidq.meta
%       				- probe0 folder
%                       	- file.ap.bin
%                       	- file.lf.bin
%                       	- file.ap.meta
%                       	- file.lf.meta
%                       	- (all other ks output and intermediate files)
%                       - probe1 folder
%                       	- file.ap.bin
%                       	- file.lf.bin
%                       	- file.ap.meta
%                       	- file.lf.meta
%                       	- (all other ks output and intermediate files)
% 
% 
% example path: /Users/erictrautmann/data/pacman-task/cousteau/2021-03-18/neuropixels/pacman-task_c_210318_neu_g0/pacman-task_c_210318_neu_g0_imec0
% 
% EMT 2021-03-08
% updated 2023-02-14 to include new definitions for
%   paths.tSyncOutputPath, paths.taskTableOutputPathMatlab, paths.taskTableOutputPathExport


P = inputParser;
addRequired(P,'data_root')
addRequired(P,'protocol', @isstringlike)
addRequired(P,'subject', @isstringlike)
addRequired(P,'date', @isstringlike)
addRequired(P,'gNum', @isnumeric)
addRequired(P,'tNum', @isnumeric)
addRequired(P,'imecNum', @isnumeric)

addParameter(P,'figRoot','',@isstringlike)
addParameter(P,'pathWarningsOn',false,@islogical)

parse(P, data_root, protocol, subject, date, gNum, tNum, imecNum, varargin{:})
pathWarningsOn = P.Results.pathWarningsOn;

% use environment variable, and then EMT default location if fig_root
% not provided
figRoot = P.Results.figRoot;
if isempty(figRoot)
    figRoot = getenv('FIG_ROOT');
    if isempty(figRoot)
        figRoot = '/Users/erictrautmann/Dropbox/columbia/figures/pacman/';
    end
end

paths.figRoot = figRoot;

figPath = fullfile(figRoot,'pacman-gain-switch',date);
warning('off', 'MATLAB:MKDIR:DirectoryExists')
mkdir(figPath)
paths.figPath = figPath;

% 0) *** prefixes

paths.date = date;
paths.dateShort = date([3,4,6,7,9,10]);

subject = lower(subject);  % paths should have subject name all lowercase. If not, fix on disk

prefix = ['pacman-task_' subject(1) '_' date([3,4,6,7,9,10])];
paths.prefix = prefix;

prefixBehavior = [prefix '_beh'];
paths.prefixBehavior = prefixBehavior;

prefixNpix = ['pacman-task_' subject(1) '_' date([3,4,6,7,9,10]) '_neu'];
paths.prefixNpix = prefixNpix;

% 1) *** behavioral data via speedgoat
sgDataPath = fullfile(data_root, protocol, subject, date, 'speedgoat');
warnIfNotExist(sgDataPath)
paths.sgDataPath = sgDataPath;


% 2) *** Neuropixels data files (see folder structure above for documentation of expected paths)]

gNumFolder = [prefixNpix '_g' num2str(gNum)];
probeFolder = [prefixNpix '_g' num2str(gNum) '_imec' num2str(imecNum)];  % #TODO: add support for multiple probes here


% build paths
recordingRoot = fullfile(data_root, protocol, subject, date, 'neuropixels', gNumFolder); 
warnIfNotExist(recordingRoot)
paths.recordingRoot = recordingRoot;


% Probe path
nPixProbePath = fullfile(recordingRoot, probeFolder);        % #TODO: add support for multiple probes here
warnIfNotExist(nPixProbePath)

% paths for metrics files
paths.ksMetrics = fullfile(nPixProbePath, [prefixNpix '_g' num2str(gNum) '_imec' num2str(imecNum) '_ksMetrics.mat']);
paths.centroidsPath = fullfile(nPixProbePath,[prefixNpix '_g' num2str(gNum) '_imec' num2str(imecNum) '_cluster_centroids.tsv']);

% Raw data paths
npixApPath = fullfile(nPixProbePath, [prefixNpix '_g' num2str(gNum) '_t' num2str(tNum) '.imec' num2str(imecNum) '.ap.bin']);
warnIfNotExist(npixApPath)
paths.npixApPath = npixApPath;

npixApMetaPath = fullfile(nPixProbePath, [prefixNpix '_g' num2str(gNum) '_t' num2str(tNum) '.imec' num2str(imecNum) '.ap.meta']);
warnIfNotExist(npixApMetaPath)
paths.npixApMetaPath = npixApMetaPath;

npixLfpPath  =  fullfile(nPixProbePath, [prefixNpix '_g' num2str(gNum) '_t' num2str(tNum) '.imec' num2str(imecNum) '.lf.bin']);
warnIfNotExist(npixLfpPath)
paths.npixLfpPath = npixLfpPath;

npixLfpMetaPath  =  fullfile(nPixProbePath, [prefixNpix '_g' num2str(gNum) '_t' num2str(tNum) '.imec' num2str(imecNum) '.lf.meta']);
warnIfNotExist(npixLfpMetaPath)
paths.npixLfpMetaPath = npixLfpMetaPath;


% 2.1 NIDAQ I/O
nidaqPath = fullfile(recordingRoot, [prefixNpix '_g' num2str(gNum) '_t' num2str(tNum) '.nidq.bin']);
warnIfNotExist(nidaqPath)
paths.nidaqPath = nidaqPath;

nidaqMetaPath = fullfile(recordingRoot, [prefixNpix '_g' num2str(gNum) '_t' num2str(tNum) '.nidq.meta']);
warnIfNotExist(nidaqMetaPath)
paths.nidaqMetaPath = nidaqMetaPath;


% Manually-sorted kilosort output 
ksResultsPath = fullfile(data_root, protocol, subject, date, 'neuropixels',gNumFolder, probeFolder);
warnIfNotExist(ksResultsPath)
paths.ksResultsPath = ksResultsPath;

% % 3) *** blackrock NSX path
% brDataPath = fullfile(data_root, protocol, subject, date, 'blackrock', ['pacman-task_' subject(1) '_' date([3,4,6,7,9,10]) '_emg_001.ns6']);
% warnIfNotExist(brDataPath)
% paths.brDataPath = brDataPath;


% 4) path for intermediate output data
% paths.taskTableOutputPath = fullfile('/Volumes/churchland-locker/eric', subject, 'processed', date, 'mergedTaskData', [prefix '_taskdata.mat']);
paths.tSyncOutputPath = fullfile(recordingRoot, [paths.prefixNpix '_tsync.mat']);
paths.taskTableOutputPathMatlab = fullfile(recordingRoot, [paths.prefixNpix '_tasktable_matlab.mat']);
paths.taskTableOutputPathExport = fullfile(recordingRoot, [paths.prefixNpix '_tasktable.mat']);
paths.taskTableOutputPathExportTrialAverage = fullfile(recordingRoot, [paths.prefixNpix '_tasktable_TA.mat']);

% 5) export paths as text file for reading in python code/elsewhere
C = [fieldnames(paths), struct2cell(paths)];
filename = fullfile(paths.recordingRoot,[paths.prefix '_data_paths.xml']);
try
    writestruct(paths, filename)
catch
    warning('could not write paths xml file')
    
end




function [] = warnIfNotExist(path)
    if pathWarningsOn
        if exist(path) == 0
            warning([path ' doest not exist'])
        end
    end

end

end





