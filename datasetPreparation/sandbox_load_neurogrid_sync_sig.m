%%


ngSyncPath = '/Users/erictrautmann/data/pacman-task/cousteau/raw/2021-05-28/neurogrid/20210528_NG_AD_210528_152112/digitalin.dat'

fid = fopen(ngSyncPath)


nChan = 2
nSamp = inf
ngSyncSig = fread(fid,[nChan nSamp]);

% strip off first (empty) channel
ngSyncSig = ngSyncSig(1,:);

% convert to binary
ngSyncSig = ngSyncSig > .5;


%%

size(ngSyncSig)

figure(2); clf;
plot(ngSyncSig(1:10000))

ylim([-1 3])


%% save output


ngSyncPath = '/Users/erictrautmann/data/pacman-task/cousteau/raw/2021-05-28/neurogrid/20210528_NG_AD_210528_152112/c2021-05-28_ngSyncSig.mat'
save(ngSyncPath, 'ngSyncSig')

%%

tmp = load(ngSyncPath)
a = tmp.ngSyncSig;

figure(3); clf;
plot(tmp.ngSyncSig(1:1000000))

ylim([-1 3])