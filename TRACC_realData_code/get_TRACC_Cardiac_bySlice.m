% Created by: Qiuting Wen
% Modified by: Adam Wright
% Last Modified: August 29th, 2025
% Email: wrigh595@purdue.edu (adam.wright303@gmail.com)

% This function calculates the correlation between physiology data and the time-curve from a single voxel

%Inputs:
% dataphysio  -- Pulse signal
% dataimg -- all the time series for the given slice of single voxel time series
% SliceMap -- SliceMap is the indexing file for the physio data 
% lagrange -- range of time values to include in the lag calculation
% idx_image -- The idx of the time series that will be used. normally 1-end-1, but theroetically could remove time points with noise.
% sl -- The given slice number (single integer value)

% Outputs:
% corr
% lag

function [corr,lag] = get_TRACC_Cardiac_bySlice(dataphysio,dataimg,SliceMap,lagrange,idx_image,sl)

    % image is a matrix, where each row is temporal data of a voxel.     
    [nv,np] = size(dataimg); 
    corr = NaN(np,length(lagrange)); 
    lag = NaN(length(lagrange),1);
    
    %Physio data with padded zeros -- always cross correlation beyond the
    %time the physio was acquired.
    dataphysiopad = [dataphysio;zeros(length(lagrange),1)];

    pt=1; %Running index
    for p = lagrange
    
        %Shifting the physio data within the lagrange by (p)
        curve_vref = dataphysiopad(p+SliceMap(1,idx_image,sl))';

        %Normalizing the time curve based on the mean of the temporal signal
        curve_vref = (curve_vref - mean(curve_vref))./std(curve_vref);

        %Normalized signal for each voxel based on mean of the time series
        signalNorm = (dataimg - nanmean(dataimg,1))./nanstd(dataimg,1);
        
        %Correlation coefficient of signal with reference curve that was time shifted based on lagrange (p),
        % it is divided by the number of time points in the series.
        %This formula is for Pearson correlation coefficient, the above is also involved in the formula
        nv = size(signalNorm,1);
        corrcoef2vref = nansum(signalNorm.*curve_vref')./(nv-1);
        
        %logging the correlation and lagrange.
        corr(:,pt) = corrcoef2vref;
        lag(pt) = p;
        
        pt = pt+1;       
    end
    % toc
    
    %Debug plot
    if ~isempty(corr)
        % figure(1)
        % plot(lagrange,corr), hold on
    else
        corr = NaN(size(lag,1),1);
    end
end