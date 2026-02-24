
% Written by: Adam Wright
% Email: adam.wright303@gmail.com

%This function outputs the normalized cross-correlation an MR signals and physiological signal.
% 
% Inputs:
% mr_signal -- single voxel MR_signal
% physiological_signal -- physiological signal at its native sampling
% shifts_to_apply -- index of shifts to apply (in indices and not real time) i.e. fs = 400 Hz 1 shift = 2.5 ms.
% idx_in_physio -- the index for the physiological signal that matches the MR sampling times (i.e. downsampled physiolgoical signal)
% fs_physio -- sampling rate of physio in Hz
% polarity_fix -- set to search for a positive (1) or negative (-1) peal CorrCoeff -- only to be used with well established physiology influence on MR signal

function [r,corr_coeff,TimeDelay] = physio_traccc(mr_signal,physio_signal,shifts_to_apply,idx_in_physio,fs_physio,polarity_fix)

    if length(mr_signal) >= length(physio_signal)
        error('The physio signal can not be longer than MR signal')
    end

    if nargin < 6
        polarity_fix = 0;
    end

    N = length(mr_signal);
    r = NaN(length(shifts_to_apply),1);
    
    %MR autocorrelation at lag 0
    mr_autocorr = sum(mr_signal.^2);

    %Note: I should probably zero-padded the physiology signal -- skipping
    %for now because I already made it much longer (in both directions)
    %than the MR signal.
    running_idx = 1;
    for i = shifts_to_apply

        %Shfit the physio signal by one sample
        shifted_physio_signal = physio_signal(idx_in_physio+i);

        %Physio autocorrelation at lag 0
        physio_autocorr = sum(shifted_physio_signal.^2);

        %Raw correlation between shifted and undersampled physio signal and MR signal
        tmp_corr = sum(mr_signal.*shifted_physio_signal);
    
        %Normalize by auto-correlation
        tmp_norm_corr = tmp_corr/sqrt(mr_autocorr*physio_autocorr);

        r(running_idx) = tmp_norm_corr;
        
        running_idx = running_idx + 1;
    end

    % fixing polarity to match the expected corrleation peak -- this can be
    % determined by plotting group mean TRACC-waveforms.
    if polarity_fix > 0
        [~,idx_peak] = max(r);
    elseif polarity_fix < 0
        [~,idx_peak] = min(r);
    elseif polarity_fix == 0
        [~,idx_peak] = max(abs(r));
    end

    corr_coeff = r(idx_peak);
    TimeDelay = shifts_to_apply(idx_peak)*1/fs_physio;
end