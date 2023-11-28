function [Task, Tsync, ks, metrics, stats, centroids_good, neuron_snrs] = import_pacman_data(subject, date, paths, varargin)
% import raw neural and behavioral data for pacman task / Rig J
% EMT 2023-02-13
%
% 2023-02-13 Note: this script is intended to be a function that replaces the
% functionality of the script run_load_neural_and_behavior.m, so we can
% call this from python or more simply automate processing of multiple
% datasets.
%
% dependencies:
%   spikes:             https://github.com/cortex-lab/spikes
%   sortingQuality:     https://github.com/cortex-lab/sortingQuality
%   neuropixel-utils:   https://github.com/djoshea/neuropixel-utils
%   matlab-utils:       https://github.com/djoshea/matlab-utils
%   npy-matlab:         https://github.com/kwikteam/npy-matlab

p = inputParser();
p.addRequired('subject', @isstringlike);
p.addRequired('date', @isstringlike);
p.addRequired('paths', @isstruct);
p.addParameter('gNum',0, @isnumeric);
p.addParameter('tNum',0, @isnumeric);
p.addParameter('imecNums',0, @isnumeric);
p.addParameter('padDuration', [.5, 1], @isnumeric);
p.addParameter('saveTags',0:20, @isnumeric);
p.addParameter('syncChan',3, @isnumeric);
p.addParameter('syncBit',8, @isnumeric);
p.addParameter('channelMapFile','neuropixNHPv1_kilosortChanMap_v1.mat', @isstringlike);
p.addParameter('loadNeural',true, @islogical);
p.addParameter('loadMetrics',true, @islogical);
p.addParameter('includeMultiUnit',true, @islogical);
p.addParameter('alignTrials', false, @islogical);  % align based on behavior - generally not desired except for Najja's motor Unit recordings
p.addParameter('saveTaskTable',true, @islogical);
p.addParameter('runConnectivityAnalysis',false,@islogical)
p.addParameter('saveResults', true, @islogical);
p.addParameter('debugPlots', true, @islogical);
p.addParameter('verbose', false, @islogical);
% p.addParameter('use_cached', true, @islogical);     % if analysis has already run with saved results, load these instead of recomputing

p.KeepUnmatched = false;    
p.parse(subject, date, paths, varargin{:});

subject = p.Results.subject;
date = p.Results.date;
gNum = p.Results.gNum;
tNum = p.Results.tNum;
imecNums = p.Results.imecNums;

% /input parsing


 % check that environment variables are set
% assert(~strcmp(getenv('DATA_ROOT'),''),'environment variable "DATA_ROOT" must be set')
% assert(~strcmp(getenv('FIG_ROOT'),''),'environment variable "DATA_ROOT" must be set')

% figPath = fullfile(getenv('FIG_ROOT'),'pacman-gain-switch',date);
% mkdir(figPath)

% manually override taskTableOutputPath (if you want to specify where to store processed task data)
% paths.taskTableOutputPath = fullfile(getenv('DATA_ROOT'), subject, 'processed', date, 'mergedTaskData', [paths.prefix '_taskdata.mat']);
% paths.taskTableOutputPath = paths.recordingRoot; 
% makeContainingFolder(paths.taskTableOutputPath)


%% 1) load behavior data

tic

if p.Results.verbose
    disp(fullfile(paths.sgDataPath, paths.prefixBehavior))
end 
T = loadsession(fullfile(paths.sgDataPath, paths.prefixBehavior));

if p.Results.verbose
    disp(sprintf('Session loaded: %d trials \n',size(T,1)))
end

if p.Results.debugPlots
    figh = figure(1); clf;
    plot(T.saveTag)
    xlabel('Trial')
    ylabel('SaveTag')
    set(figh,'color','w');
    set(figh,'windowstyle','normal')
    set(figh,'position',[0 0 500 300])

    fname = fullfile(paths.figPath,[paths.prefix '__savetags.pdf']);
    print(figh, fname,'-dpdf','-painters','-bestfit')
    
end

% attempt to load EMG data
% nsx = openNSx(paths.brDataPath,'uv');

timing = [];
timing.behaviorLoad = toc;


%% 2) load kilosort output


if (p.Results.loadNeural == 1)
    [spikeIdxMat, clusterLabels] = ksResults2spikeMat(paths.ksResultsPath, 'includeMultiUnit', p.Results.includeMultiUnit);
    
    if p.Results.verbose
        disp(sprintf('Spike Times loaded %.1f \n', toc))
    end

    spikeIdxMat_orig = spikeIdxMat;
    
    timing.spikeMatCreated = toc;
    
    % 3) convert spiketimes from imec headstage sample indices into NIDAQ indices:
    niMeta = readSpikeGLXmeta(paths.nidaqMetaPath);
    FsNi = niMeta.sRateHz;
    
    apMeta = readSpikeGLXmeta(paths.npixApMetaPath);
    FsImec = apMeta.sRateHz;
    
    spikeIdxMatNi = convertSpikeTimeIndices(spikeIdxMat, FsImec, FsNi);
    % size(spikeIdxMatNi)
    
    timing.spikeTimesConverted = toc;
    
    % 4) sync spike times with behavior
    [Tsync, Times] = syncSpeedgoatNidaq(paths.nidaqPath, T, ...
        'spikes',spikeIdxMatNi, ...
        'SGsyncChan',p.Results.syncChan, ...
        'SGsyncBit', p.Results.syncBit, ...
        'saveTags',p.Results.saveTags);

    if p.Results.verbose
        disp(sprintf('Spike Times synced: %.1f sec\n',toc))
    end

    timing.nidaqSynced = toc;
else
    Tsync = T; 
end

%% load neural metrics
if p.Results.loadMetrics
    [ks, metrics, stats, centroids_good] = loadKsMetrics(paths.ksResultsPath, p.Results.channelMapFile);
else
    ks = [];
    metrics = [];
    stats = [];
    centroids_good = [];
end


%% 5) Calculate condition info 


[Task, nGlitch, AlignStats, alignIndices, condID] = paccond_gain_switch(Tsync,'neuropixels','saveTags',p.Results.saveTags,'padDur',p.Results.padDuration, 'alignTrials',p.Results.alignTrials, 'errThr',2);

if p.Results.verbose
    disp(sprintf('Task struct created: %.1f sec\n', toc))
end

if p.Results.debugPlots
    figh = figure(2); clf;

    subplot(211)
    plot(condID, 'o')
    xlabel('Trial')
    ylabel('conditionID')

    subplot(212)
    histogram(condID,1:max(condID))
    xlabel('conditionID')
    ylabel('Count')

    set(figh,'color','w');
    set(figh,'windowstyle','normal')
    set(figh,'position',[0 0 500 500])

    fname = fullfile(paths.figPath,[paths.prefix '__conditionIDs.pdf']);
    print(figh, fname,'-dpdf','-painters','-bestfit')

end

timing.taskConditionTable = toc;

%% calculate SNR using calculated trial averaged firing rates

if p.Results.loadNeural
    neuron_snrs = calculateNeuronSnrs(Task);   
    cluster_labels = clusterLabels; % python variable naming 
else
    neuron_snrs = [];
    cluster_labels = [];
end


%% 6) Export Task in .mat file (generally for Python)

if p.Results.saveResults
    sprintf('saving results to %s',paths.taskTableOutputPathMatlab)

    % % export Tsync table (for reloading in matlab)
    % save(paths.tSyncOutputPath,'Tsync','neuron_snrs','cluster_id','cluster_labels','-v7.3')
    % 
    % % export Task table (for reloading in matlab)
    % save(paths.taskTableOutputPathMatlab,'Task','neuron_snrs','cluster_id','cluster_labels','-v7.3')
    % 

    % export Task table data without single trials (for reading in python, much faster)
    exportTaskTable(Task, paths.taskTableOutputPathExportTrialAverage, 'includeSingleTrials', false)
    save(paths.taskTableOutputPathExportTrialAverage, 'neuron_snrs','cluster_labels','-append')

    % export Task table data (for reading in python)
    exportTaskTable(Task, paths.taskTableOutputPathExport, 'includeSingleTrials', true)
    save(paths.taskTableOutputPathExport, 'neuron_snrs','cluster_labels','-append')

    timing.taskDataSaved = toc;
    
end


%% #TODO run functional connectivity analysis 

if p.Results.runConnectivityAnalysis
    warning('runConnectivityAnalysis not implemented')


% % the code below was drawn from run_connected_pairs_analysis_v1 and needs
% adaptation but should be correct 2023-02-13

%     ks.load(loadFeatures=false, loadBatchwise=true);
%     ks.mask_clusters(ks.clusters_good);
%     if numel(ks.clusters_good) < 50
%         warning('only %d good clusters found in dataset: \n%s\nHas manual curation been performed?',numel(ks.clusters_good), ks.pathLeaf)
%         return
%     end
% 
%     % 1) cluster de-duplication preprocessor
%     ntPerBatch = 65536;
%     nBatches = ceil(double(max(ks.spike_times + uint64(100))) / ntPerBatch);
%     ks.batch_sort_order = (1:nBatches)';
%     ks.batch_starts = (uint64(1) : ntPerBatch : (ntPerBatch*uint64(ks.nBatches-1) + uint64(1)))';
% 
%     cda = ClusterDeduplicationAnalysis(ks, ks.clusters_good)
% 
%     delete(gcp('nocreate'))
%     parpool(4); % or some reasonable number of cores, typically I don't use more than 8.
%     cda.detect_duplicates
% 
%     % mask out duplicated clusters
%     keep_clusters = ks.clusters_good(~ismember(ks.clusters_good, cda.remove_duplicate_cluster_ids));
%     ks.mask_clusters(keep_clusters);
% 
%     % 2) run Connected pairs analysis
%     cpa = NHPPixel.ConnectedPairsAnalysis(ks, [],'jitter_reps', p.Results.jitter_reps);
% 
%     % Compute metrics
%     cpa.computeSmoothedCCGs();
%     cpa.findConnectedPairs;
end


end







