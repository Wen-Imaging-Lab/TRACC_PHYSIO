
% Written by: Adam Wright
% Email: adam.wright303@gmail.com

% Example generation and plots of physiological signals -- PPG and Resp.

%Generate PPG data
fs = 400; %Hz
HR = 60; %bpm
HRV = 50; %ms -- this will be slightly variable for the SDNN HRV measure
T = 600; %s -- ten minutes of data
N = T/(1/fs);
time = linspace(0,T-1/fs,N);

%Get simulated PPG signal
pulse_sim = pulse_generation(HR,HRV,T,fs);

%Generate Resp data
RR = 12; %bpm
RRV = 500; %ms -- -- this will be slightly variable for the SDNN RRV measure

%Get simulated Resp signal
resp_sim = respiration_generation(RR,RRV,T,fs);

%Simulated MR signal with 2:1 cardiac-respiratory ratio, with a TR of 1
%sec and acquisition time of 360 s.
cardiac_amp = 2;
resp_amp = 1;

%Start with mixed physiological signal with longer acquisition time and no
%noise and fs = 400 Hz
[mixed_physio, ~, ~] = generatePhysiologicalSignal(HR, HRV, RR, RRV, cardiac_amp, resp_amp, T, fs);

TR = 1; %1 sec
T_mr = 360;
fs_mr = 1/TR;
N_mr = fs_mr*T_mr;

%Sample the mr signal 5 seconds after the start of the 10 minute simulated mixed
%physiology signal (this avoids issues when longer lags are applied to have
%a non defined physiological signal). In real data the physiological signal
%recordings are recorded before and aftet the MR acquition, if this isn't
%the case the edge effects need to be accounted for properly.
t_start = ceil(5/TR);
t_mr = linspace(t_start,T_mr+t_start-TR,N_mr);
t_mr_plot = t_mr-t_start;

[~,idx_in_mixed] = ismembertol(t_mr, time, 0.000001);

%Getting the mr signal with proper TR acquisitions
mr_simulated_noNoise = mixed_physio(idx_in_mixed);

% Add noise with a certain SNR.
SNR_dB = 20;
mr_signal_power = mean(mr_simulated_noNoise.^2);
noise_power = mr_signal_power / (10^(SNR_dB / 10)); %Noise power needed for a certain SNR
noise = sqrt(noise_power)* randn(size(mr_simulated_noNoise)); %Generate noise

%mr signal with noise
mr_simulated_wNoise = mr_simulated_noNoise + noise;


%Get freqeuncy spectrums for physiological and MR signals
f_physio = (0:N-1)*(fs/N);
f_mr =(0:N_mr-1)*(fs_mr/N_mr); 

%Calculate the pulse frequency spectrum
fft_pulse = abs(fft(pulse_sim) / N);
fft_pulse(2:ceil(N/2)) = 2*fft_pulse(2:ceil(N/2));

%Calculate the resp frequency spectrum
fft_resp = abs(fft(resp_sim) / N);
fft_resp(2:ceil(N/2)) = 2*fft_resp(2:ceil(N/2));

%Calculate the mr frequency spectrum
fft_mr = abs(fft(mr_simulated_wNoise) / N_mr);
fft_mr(2:ceil(N_mr/2)) = 2*fft_mr(2:ceil(N_mr/2));


fontSize = 12;

%Figure

h = figure('Color','w', 'Visible', 'on');
set(h, 'Position', [173 147 1150 657]);
t = tiledlayout(3, 5, 'TileSpacing', 'loose');
nexttile([1 3])
plot(time,pulse_sim,'LineWidth',2);
xlim([0 10])
ylim([-1.5 1.5])
xlabel('Time [s]')
ylabel('PPG Signal')
title('Simulated PPG Signal')
set(gca, 'FontSize', fontSize)

nexttile([1 2])
plot(f_physio(1:ceil(N/2)),fft_pulse(1:ceil(N/2)),'LineWidth',1.5)
xlim([0 5])
xlabel('Frequency [Hz]')
ylabel('PPG Amplitude')
set(gca, 'FontSize', fontSize)

nexttile([1 3])
plot(time,resp_sim,'LineWidth',2);
xlim([0 30])
ylim([-1.5 1.5])
xlabel('Time [s]')
ylabel('Resp Signal')
title('Simulated Respiration Signal')
set(gca, 'FontSize', fontSize)

nexttile([1 2])
plot(f_physio(1:ceil(N/2)),fft_resp(1:ceil(N/2)),'LineWidth',1.5)
xlim([0 1])
xlabel('Frequency [Hz]')
ylabel('Resp Amplitude')
set(gca, 'FontSize', fontSize)

nexttile([1 3])
plot(t_mr_plot, mr_simulated_wNoise, 'LineWidth',2)
xlim([0 60])
ylim([-4 4])
xlabel('Time [s]')
ylabel('MR Signal')
title('Simulated MR Signal w/Noise (TR = 1s, Acq duration = 360 s)')
set(gca, 'FontSize', fontSize)

nexttile([1 2])
plot(f_mr(1:ceil(N_mr/2)),fft_mr(1:ceil(N_mr/2)),'LineWidth',1.5)
xlim([0 1])
xlabel('Frequency [Hz]')
ylabel('MR Amplitude')
set(gca, 'FontSize', fontSize)
