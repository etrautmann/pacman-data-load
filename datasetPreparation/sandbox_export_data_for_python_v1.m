%% Sandbox pacman - single trial behavior predictions

addpath(genpath('/home/etraut/code/npy-matlab'))

% DATE = '2020-03-09';
% DATE = '2020-03-11';

DATE = '2020-12-16';


setPathPacmanVomer

padDuration = 1800


%% process datasets

% run sandbox_import_behavior_vomer to create the task object which is loaded below
% #TODO: refactor and clean up the import code


%% load data

tic
load(outputPath)
toc

%% reshape data for regression analysis

set = 3;
conditionSets = {[1,3]; [2,4]; [5,6]; [7,9]; [8,10]};

ST = {Task.MU.rate};
ST = ST(conditionSets{set});

TA = {Task.MU.psth};
TA = TA(conditionSets{set});
TA = cellfun(@(x) x(:,:,1), TA,'uniformOutput',false);

Forces = {Task.Force.data};
Forces = Forces(conditionSets{set});
Forces = cellfun(@(x) squeeze(x(:,1,:)), Forces, 'UniformOutput', false);

% restrict time points to equal length for all trials
minTPts = min(cellfun(@(x) size(x,1), TA))
for ii = 1:length(ST)    
    ST{ii} = ST{ii}(1:minTPts,:,:);
    TA{ii} = TA{ii}(1:minTPts,:);        
    Forces{ii} = Forces{ii}(1:minTPts,:);           
end

% create time vector
tvec = (1:length(Forces{1})) - padDuration;


% trim to equal number of trials
minTr = min(cellfun(@(x) size(x,3), ST))
trialNum = [];
for jj = 1:length(ST)
    ST{ii} = ST{ii}(:,:,1:minTr);       
    Forces{ii} = Forces{ii}(:,1:minTr);
    trialNum(jj) = minTr;
end
    
ST
TA
Forces


%% Save output for Python below

ST = makecol({Task.MU.rate})
Forces = makecol({Task.Force.data});
Forces = makecol(cellfun(@(x) squeeze(x(:,1,:)), Forces, 'UniformOutput', false)) % strip variance and only keep mean


%%
% unpack variables - do this the dumb and explicit way for now
condition_1 = ST{1};
condition_2 = ST{2};
condition_3 = ST{3};
condition_4 = ST{4};
condition_5 = ST{5};
condition_6 = ST{6};
condition_7 = ST{7};
condition_8 = ST{8};
condition_9 = ST{9};
condition_10 = ST{10};

force_1 = Forces{1};
force_2 = Forces{2};
force_3 = Forces{3};
force_4 = Forces{4};
force_5 = Forces{5};
force_6 = Forces{6};
force_7 = Forces{7};
force_8 = Forces{8};
force_9 = Forces{9};
force_10 = Forces{10};

% setup output path
[filePathIn,fileName,~] = fileparts(outputPath);
[filePathIn,~,~] = fileparts(filePathIn);   % to strip off the ../mergedTaskData

filePathOut = fullfile(filePathIn, 'python_data');
mkdir(filePathOut)
        
fileNameOut = fullfile(filePathOut, [fileName '_python.mat']);
tic
save(fileNameOut, 'condition_1','condition_2','condition_3','condition_4','condition_5', 'condition_6', 'condition_7', 'condition_8', 'condition_9', 'condition_10')
save(fileNameOut, 'force_1', 'force_2', 'force_3', 'force_4', 'force_5', 'force_6', 'force_7', 'force_8', 'force_9', 'force_10', '-append')
toc



%% Regress Neural activity at timepoint 1) against 





%% Regress force against neural activity, single time point

tPt = 0
tInd = find(tvec==tPt)

iC = 1
X = squeeze(ST{iC}(tInd,:,:))'
y = makecol(squeeze(Forces{iC}(tInd,:)))


% try filtering neural activity by std
unitMask = (std(X)./mean(X)) > 1;
X = X(:,unitMask)

size(X)
size(y)
%
mdl = fitlm(X,y)
    


%% Regress force against neural activity, all time points at once


X = []
y = []
for tInd = 1:25:length(tvec)
    tInd
    X = [X; squeeze(ST{iC}(tInd,:,:))'];
    y = [y; makecol(squeeze(Forces{iC}(tInd,:)))];
end

size(X)
size(y)

mdl = fitlm(X,y)


%% Sweep time lags:

Xfull = ST{iC}(:,:,:);
yfull = squeeze(Forces{iC}(:,:));

size(Xfull)
size(yfull)



%%
clc
lags = 10:50:300;

mdls = {}
for iL = 1:length(lags)
    iL
    thisLag = lags(iL);
    
    % create a mask to remove timepoints from each timeseries where they don't overlap
    tMask = true(size(tvec));
    tMask(end-thisLag : end) = false;
    
    % create shortened versions of data
    tvecShort = tvec(tMask);    
    Xshort = Xfull(tMask,:,:);
    yshort = yfull(fliplr(tMask), :);
        
    
    % loop time and construct regression inputs    
    X = [];
    y = [];
    for tInd = 1:25:length(tvecShort)
        X = [X; squeeze(Xshort(tInd,:,:))'];
        y = [y; makecol(yshort(tInd,:))];
    end
    
    size(X)
    size(y)
        
    mdl = fitlm(X,y);
    mdls{iL} = mdl;
    
end

%%

rs = []
for iL = 1:length(mdls)
    rs(iL) = mdls{iL}.Rsquared

    
end



%%




% 
% 
%     Xtmp = squeeze(ST{iC}(:,:,:));
%     Xtmp(1:thisLag, :, :) = [];
%     X = [X; Xtmp];
%     
%     ytmp = makecol(squeeze(Forces{iC}(:,:)));
%     ytmp(end-thisLag : end) = [];
%     y = [y; tmp];
%     
% 
% 






%%  OLD - Extract forces from condition set

% Forces = {Task.Force.data}
% Forces = Forces(conditionSets{set})   

% strip off variance)
Forces = cellfun(@(x) squeeze(x(:,1,:)), Forces, 'UniformOutput', false)


figure(1); clf;
iSet = 2
padDuration = 1800
colors = pacmanColors;
plotPacmanForces(Task, conditionSets{iSet}, padDuration, colors)


