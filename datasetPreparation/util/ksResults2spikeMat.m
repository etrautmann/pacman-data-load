function [spikeIdxMat, clusterLabels] = ksResults2spikeMat(ksResultsPath, varargin)
% Loads spike times from a kilosort results folder and packs them into a [nSample x nUnit] sparse array 
% 
% *** Note: spike times are in units of samples, not time ***
%
% EMT 2021-03-22
%

p = inputParser();
p.addRequired('ksResultsPath', @isstringlike)
p.addParameter('includeMultiUnit', false, @islogical)

p.KeepUnmatched = false;    
p.parse(ksResultsPath, varargin{:});

tSpk = readNPY(fullfile(ksResultsPath,'spike_times.npy'));
clusterId = readNPY(fullfile(ksResultsPath,'spike_clusters.npy'));
label = tdfread(fullfile(ksResultsPath,'cluster_group.tsv'),'\t');

label.group = mat2cell(label.group, ones(size(label.group,1),1), size(label.group,2));
label.group = cellfun(@(x) strtrim(x), label.group, 'uni',false);

goodUnit = cellfun(@(x) strcmp(x,'good'), label.group);
multiUnit = cellfun(@(x) strcmp(x,'mua'), label.group);
% noise = cellfun(@(x) strcmp(x,'noise'), label.group);

% group spikes by unit
if p.Results.includeMultiUnit
    spkIdx = cellfun(@(x) tSpk(clusterId==x), num2cell(label.cluster_id(goodUnit | multiUnit)), 'uni',false);
    clusterMask = cellfun(@(x) strcmp(x,'good') | strcmp(x,'mua'), label.group);
else
    spkIdx = cellfun(@(x) tSpk(clusterId==x), num2cell(label.cluster_id(goodUnit)), 'uni',false);
    clusterMask = cellfun(@(x) strcmp(x,'good'), label.group);
end
% nUnit = nnz(goodUnit | multiUnit );
nSample = max(tSpk);    % find the index of the last spike in the dataset as a proxy for the length of the recording 

spkIdx = cellfun(@unique, spkIdx, 'uni', false);  % not sure why this is here (EMT 2023-10-13)
% spkIdx = cellfun(@(x) double(x), spkIdx, 'uni',false);

% pack [nSample x nUnit] sparse array of spike times 
spikeIdxMat = cell2mat(cellfun(@(idx) sparse(double(idx),1,true,double(nSample),1), spkIdx', 'uni',false));

% for cluster labels
clusterLabels = label;
clusterLabels.cluster_id = clusterLabels.cluster_id(clusterMask);
clusterLabels.group = clusterLabels.group(clusterMask);
