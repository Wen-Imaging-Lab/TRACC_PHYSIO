
%Written by: Adam Wright
%Last Modified: 20250829
%Email: wrigh595@purdue.edu (adam.wright303@gmail.com)

%TRACC_PHYSIO implementation of TRACC_Cadiac with an fMRI dataset

% This code will create a data file containting a voxel-wise TravelDelay and
% CorrCoeff map

% The TimeDelay and CorrCoeff will be solved for every voxel within a mask
% I use the brain mask output from fsl bet and I dilate the mask so it is
% overly inclusive incase fsl bet strips too much of the brain.

%Input examples
% scanDir = '/geode2/home/u100/wrighad/Quartz/Desktop/demo_Data';
% filename = 'fMRI.nii.gz';   
% maskFileName = 'brain_mask.nii.gz';

function main_TRACC_Cardiac(scanDir,filename,maskFileName)    
    
    %This can be adjusted to whatever you want to reach T1 steady state.
    dumpSlices = 10; 
    cd(scanDir)

    try
        fMRI = loadData(filename); %This function will load data in t,z,y,x coordinates which is easier to use vectorization
        fMRI = fMRI(dumpSlices+1:end,:,:,:);
        info = niftiinfo(filename);
        TR = info.PixelDimensions(4); %Sec
        fs = 1/TR; %Hz
    catch e
        error(['Unable to load: ' filename])
    end

    %Number of time points (measurements),Number of slices, y-dim, x-dim
    [np,nsl,ny,nx] = size(fMRI);
    st = 1; idx_fmri = st:st+np-1; %Total time points used in analysis (1:end-1)
    
    %Load the mask that will be used to define which voxels will be solved
    %for.. It is a lot faster to only solve for brain voxels instead of the
    %whole volume.
    try
        mask = loadData(maskFileName);
        %mask = true(size(fMRI,[2 3 4])); %Use this if you want to just solve for every voxel
    catch e
        error(['Unable to load: ' maskFileName])
    end
        
    %We slighlty dilate the mask so it includes the SSS in the processing
    dilation_level = 8;
    se = strel('cube',dilation_level);
    mask = imdilate(mask,se);

    %Physio file -- this physio file was created from 
    load('physio.mat','physio');
    %Cut the phyio to deal with the slice dump (not actually dumping slices when dumpSlices = 0)
    physio.SliceMap = physio.SliceMap(1,dumpSlices+1:end,:);
    
    %Smoothing physio data.
    [locs, pulsesmooth] = ppg_analysis(physio);

    %Calculate a voxelwise correlation map for all voxels in the  mask
    % lagrange = -400:400; % -1 sec to +1 sec
    lagrange = -120:120; %-300 to 300 msec (rename files that are saved)
    
    %Allocate CorrCoeff Map, TimeDelay Map and the 4D correlation curve map
    max_corr_map = NaN(size(mask,1),size(mask,2),size(mask,3));
    lag_map = max_corr_map;
    corr_map_4D = NaN(length(lagrange),size(mask,1),size(mask,2),size(mask,3));
    
    % tic
    %Loop through all voxels within the mask one slice at a time
    for i = 1:nsl
        %Find all voxels for a given slice -- this code logic likely has
        %room for improvement.
        mask_idx = find(squeeze(mask(i,:,:)));
        [I2,I3] = ind2sub(size(squeeze(mask(i,:,:))),mask_idx);
        I1 = i*ones(size(I2));
        mask_idx = sub2ind(size(mask),I1,I2,I3);
    
        if isempty(mask_idx)
            disp(['Processed slice ' num2str(i) ' of ' num2str(nsl)])
            continue
        end
    
        %Get a slices worth of data with voxels in the time series (t,voxel #)
        image = fMRI(:,mask_idx);
        %Detrend the signal -- linear detrend
        image = detrend(image,1);

        [corr_tmp,~] = get_TRACC_Cardiac_bySlice(pulsesmooth,image,physio.SliceMap,lagrange,idx_fmri,i);

        %Get the maximum correlation and the lag value -- Peak CorrCoeff and TimeDelay
        tmp_max = []; tmp_idx = []; tmp_lag =[];
        [tmp_max,tmp_idx] = max(abs(corr_tmp),[],2);
        
        %Find the voxels location in the 2D slice
        voxel_idx = sub2ind(size(corr_tmp), 1:size(corr_tmp,1), tmp_idx');

        %Store voxel-wise Peak CorrCoeff and TimeDelay
        max_corr_map(mask_idx) = corr_tmp(voxel_idx); 
        tmp_lag = lagrange(tmp_idx);
        lag_map(mask_idx) = tmp_lag;

        corr_map_4D(:,mask_idx) = double(transpose(corr_tmp));

        disp(['Processed slice ' num2str(i) ' of ' num2str(nsl)])
    end
    % toc
    
    %Convert lags to milliseconds -- TimeDelay in real time (multiple by
    %1/fs of physiological signal).
    lag_map = lag_map*2.5;

    PeakCorrCoeff_Map = permute(max_corr_map,[3 2 1]);
    TimeDelay_Map = permute(lag_map,[3 2 1]);
    info = niftiinfo(maskFileName);
    info.BitsPerPixel = 32; info.Datatype = 'single';

    %These are 3D voxel-wise measures of the Peak CorrCoeff and TimeDelay at
    %the signal absolute max, but the 4D correlation is saved with sign +/-

    %Define the window searched for the peack correlation and TimedDelay
    window_label = ['window_', num2str(min(lagrange*2.5)), '_to_', num2str(max(lagrange*2.5)), '_ms'];
    
    niftiwrite(single(PeakCorrCoeff_Map),['PeakCorrCoeff_Map_',window_label],'info',info,'Compressed',true);
    niftiwrite(single(TimeDelay_Map),['TimeDelay_Map_',window_label],'info',info,'Compressed',true);

    %4D -- correlation curve for each voxel.
    corr_map_4D = permute(corr_map_4D,[4 3 2 1]);
    
    %Multiply corr_map_4D by 1000 to then save as INT16
    corr_map_4D = int16(corr_map_4D*1000);

    %%% Dont save the 4D dataset, unless it is needed for a final analysis (they take up a lot of memory when run for all
    %Get info from a 4D dataset
    info = niftiinfo(filename); info.MultiplicativeScaling = 0.001; info.Datatype = 'int16';
    info.PixelDimensions(4) = 0.0025; info.ImageSize(4) = size(corr_map_4D,4);
    info.raw.dim(5) = size(corr_map_4D,4); info.raw.pixdim(5) = 0.0025;
    niftiwrite(corr_map_4D,'CorrCoeff_4D_Map','info',info,'Compressed',true);

    disp(['Processed subject: ' scanDir])
end