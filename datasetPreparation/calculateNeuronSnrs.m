function [unitSnr] = calculateNeuronSnr(Task)
% calculate unit SNR 
%
% 
%
% EMT 2023-08-22

psth = cellfun(@(x) squeeze(x(:,:,1)), {Task.MU.psth}, 'UniformOutput', false);    % keep mean, strip variance
psthStack = cell2mat(makecol(psth));

stds = cellfun(@(x) squeeze(x(:,:,2)), {Task.MU.psth}, 'UniformOutput', false);    % keep mean, strip variance
stdsStack = cell2mat(makecol(stds));
maxStd = max(stdsStack,[],1);

range = max(psthStack,[],1) - min(psthStack,[],1);
unitSnr = range./maxStd;

% other ways of calculating
% unitSnr2 = std(psthStack,1)./maxStd;
% unitSnr2 = std(psthStack,1)./mean(stdsStack,1);
% unitSnr2 = range./mean(stdsStack,1);

% Note, experimenting with this on 2021-03-18 dataset shows that there's a
% clearer separation at the low SNR end using range/max(std) compared with
% std(mean)/mean(std), which has most of the mass towards the low end of
% the distribution, making it much more sensitive to the selection of a
% cutoff threshold. 



% % plots comparing to method 2: range / max(std)

% figure(1); clf;
% subplot(211)
% histogram(unitSnr,0:.1:10)
% subplot(212)
% histogram(unitSnr2,0:.5:40)
% 
% figure(2); clf;
% plot(unitSnr, unitSnr2, 'o')
% % xlim([0 25])
% % ylim([0 25])
% % axis equal
% 
% figure(3); clf;
% mask = (unitSnr > 22) & (unitSnr2 < 4);
% subplot(211)
% plot(psthStack(:,mask))
% subplot(212)
% plot(stdsStack(:,mask))
% 
% figure(4); clf;
% mask = (unitSnr < 22) & (unitSnr2 < 4);
% subplot(211)
% plot(psthStack(:,mask))
% subplot(212)
% plot(stdsStack(:,mask))
% 


