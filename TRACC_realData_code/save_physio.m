
cd('~/Desktop/demo_Data/PhysioLog/')
physio = readCMRRPhysio('fMRI_2.dcm');
cd('..')
save('physio.mat','physio');