
% Written by: Adam Wright
% Email: adam.wright303@gmail.com

%Example implementation of TRACC-PHYSIO. Solving for a cardiac Peak
%CorrCoeff and TimeDelay.

%Time delay of 200 ms, can be adjusted.

appliedTimeDelay = 0.2; %200 ms.
appliedHR = 70; %bpm
appliedHRV = 60; %This will generate a HRV SDNN around 40-50 ms.
appliedRR = 12; %bpm
appliedRRV = 600; %This will generate a RRV SDNN around 500 ms.

%The T_fast>t_slow so that when timeshifting fast the no data will need to be zeroed...
%%% Parameters %%%
Fs_fast = 400;           % Sampling frequency (Hz)
T_fast = 600;            % Duration (seconds)
N_fast = Fs_fast * T_fast;        % Number of samples
f_fast = (0:N_fast-1)*(Fs_fast/N_fast);  % Frequency vector
t_fast = (0:N_fast-1)/Fs_fast; %time vector

%Solving cardiac
shifts_to_apply = -170:170; % with HR at 70 bpm (1/2 T = 428.5 ms, which is 171*2.5)

%If solving for resp apply more shifts (slower physiological period)
%shifts_to_apply = -856:856; % with RR at 14 rpm (1/2 T = 2140 ms, which is 856*2.5)

shifts_in_time = shifts_to_apply*1/Fs_fast; %Real time (s)

%MR simulated time is 6 minutes
T_slow = 360;

%Imaging speed
TR = 1;

%Image quality
SNR_dB = 20; %SNR of imaging

%MR signal composition
appliedCardiac_amp = 2;
appliedResp_amp = 1;

%MR sampling
Fs_slow = 1/TR;
N_slow = Fs_slow * T_slow;
f_slow = (0:N_slow-1)*(Fs_slow/N_slow); 

%Sample the mr signal 5 seconds after the start of the 10 minute simulated mixed
%physiology signal (this avoids issues when longer lags are applied to have
%a non defined physiological signal). In real data the physiological signal
%recordings are recorded before and aftet the MR acquition, if this isn't
%the case the edge effects need to be accounted for properly.
t_start = ceil(5/TR); %start at 5 seconds in the middle of the longer fast waveform 
t_slow = (t_start:N_slow+t_start-1)/Fs_slow;

idx_in_fast = [];
%The indices of the fast signal so it can be downsampled -- I was
%getting a weird error on this without adding the super small tolerance
%Writing the idx out to the known sampling rates is probably better and
%should be implemented when time permits.
[~,idx_in_fast] = ismembertol(t_slow, t_fast,0.00000001);

%Generate simulated signals   
[mixed_signal,pulse,resp] = generatePhysiologicalSignal(appliedHR, appliedHRV, appliedRR, appliedRRV,appliedCardiac_amp,appliedResp_amp,T_fast,Fs_fast);

%Shift the fast signal and then shift time -- Note, the time shouldn't match the smaller time vector...
%ideally the PPG is measured slightly before the MR begins and after the MR ends (basically a padded signal)
samples_to_shift_cardiac = round(appliedTimeDelay / (1/Fs_fast));

%Shifted timeseries
time_series_shift = circshift(pulse, samples_to_shift_cardiac);

%Downsample the signal
time_series_slow_tmp= mixed_signal(idx_in_fast);

% Add noise with a certain SNR.
signal_power = mean(time_series_slow_tmp.^2);
noise_power = signal_power / (10^(SNR_dB / 10)); %Noise power needed for a certain SNR
noise = sqrt(noise_power) * randn(size(time_series_slow_tmp)); %Generate noise

%Writing as a tmp to save memory.
tmp_series_slow_noise = time_series_slow_tmp + noise;

%Run TRACC-PHYSIO
[r,corr_coeff,TimeDelay] = physio_traccc(tmp_series_slow_noise,time_series_shift,shifts_to_apply,idx_in_fast,Fs_fast,1);

%Example plot
h = figure('Color','w', 'Visible', 'on');
set(h, 'Position', [400 212 621 466]);
plot(shifts_to_apply*2.5,r,'LineWidth',2)
xlabel('Time [ms]')
ylabel('CorrCoeff')
xlim([-400 400])
ylim([-1 1])
grid on
set(gca,'FontSize',12)
title(['Peak CorrCoeff = ', num2str(round(corr_coeff,2)), '; TimeDelay = ', num2str(round(TimeDelay*1000)) , ' ms ; Applied TimeDelay = ' ,num2str(round(appliedTimeDelay*1000)) , ' ms' ])


