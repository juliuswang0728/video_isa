clear;
clc;

ABNORMAL = [2 4 16 18 20];
SURVEILLANCE = [1 3 5 9];
CROWD = [8 10 12 14 21];
MOVING = [6 19 22 24];
NOISE = [7 11 13 15 17 23];
VIDEOS{1}.name = 'ABNORMAL';
VIDEOS{1}.video_idx = ABNORMAL;
VIDEOS{2}.name = 'SURVEILLANCE';
VIDEOS{2}.video_idx = SURVEILLANCE;
VIDEOS{3}.name = 'CROWD';
VIDEOS{3}.video_idx = CROWD;
VIDEOS{4}.name = 'MOVING';
VIDEOS{4}.video_idx = MOVING;
VIDEOS{5}.name = 'NOISE';
VIDEOS{5}.video_idx = NOISE;

%tpsizes = [5 7 9 11];
tpsizes = [7];

for i=1:length(tpsizes)
    tpsize = tpsizes(i);
    fprintf('tpsizes = (%d, %d)\n', tpsize, tpsize);
    for j=1:length(VIDEOS)
        disp(VIDEOS{j}.name);
        cc = zeros(length(VIDEOS{j}.video_idx), 1);
        nss = zeros(length(VIDEOS{j}.video_idx), 1);
        auroc = zeros(length(VIDEOS{j}.video_idx), 1);
        kldiv = zeros(length(VIDEOS{j}.video_idx), 1);
        for k=1:length(VIDEOS{j}.video_idx)
            video_idx = VIDEOS{j}.video_idx(k);
            mat_filename = sprintf('experiments/cb_video%d_tp_%d_%d_sigma_1e-02_metrics.mat', ...
                video_idx, tpsize, tpsize);
            load(mat_filename);
            cc(k) = mean(CC);
            nss(k) = mean(NSS);
            auroc(k) = mean(AUROC);
            kldiv(k) = mean(KLDIV);
        end
        cc_mean_std(1) = mean(cc);
        cc_mean_std(2) = std(cc);
        nss_mean_std(1) = mean(nss);
        nss_mean_std(2) = std(nss);
        auroc_mean_std(1) = mean(auroc);
        auroc_mean_std(2) = std(auroc);
        kldiv_mean_std(1) = mean(kldiv);
        kldiv_mean_std(2) = std(kldiv);
        cc_mean_std
        nss_mean_std
        auroc_mean_std
        kldiv_mean_std
    end
    fprintf('------------------\n');
end