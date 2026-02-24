
cd('~/Desktop/demo_Data/')
artery = loadData('mask_artery.nii.gz');
SSS = loadData('mask_SSS.nii.gz');

curves = loadData('CorrCoeff_4D_Map.nii.gz')/1000; %was mutliplied by 1000 before saving

lags = (-120:120)*2.5;

mean_artery_curve = mean(curves(:,find(artery(:))),2);
mean_SSS_curve = mean(curves(:,find(SSS(:))),2);

figure
plot(lags,mean_artery_curve), hold on
plot(lags,mean_SSS_curve)

[max_value,idx] = max(abs(mean_artery_curve));
timeDelay_artery = lags(idx);

[max_value,idx] = max(abs(mean_SSS_curve));
timeDelay_SSS = lags(idx);

AV_delay = timeDelay_artery-timeDelay_SSS;