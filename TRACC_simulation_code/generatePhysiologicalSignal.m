
% Written by: Adam Wright
% Email: adam.wright303@gmail.com

% Inputs
% HR -- heart rate (normal range 60-80 bpm)
% HRV -- heart rate variability in SDNN (msec), (normal range 20 - 100 ms,
% inputing 90 to 120 ended up best.
% RR -- respiration rate (normal range: 12-20 rpm)
% RRV -- respiration rate variability in SDNN -- msec (the normal range isnt well documented: used between 400-600 msec)
% cardiac_amp - cardiac amplitude
% resp_amp - respiration amplitude
% T -- total time of signal
% fs -- sampling freq

% Example Call -- this gets a physiological signal at 400 Hz with 1:1
% cardiac to resp.
% [mixed_signal,pulse,resp] = generatePhysiologicalSignal(70, 100, 14, 600, 1, 1, 360, 400)

function [mixed_signal,pulse,resp] = generatePhysiologicalSignal(HR, HRV, RR, RRV, cardiac_amp, resp_amp, T, fs)
    
    %This could be implemented to be variable
    %fs = 400;
    T_sim = T+10; %Making it 610 and then cutting to 600, the end isn't perfect each time... (i.e the resp signal flat lines and then it is just cardiac)
    T_keep = T;
    N = T_keep*fs;

    %Create pulse signal
    pulse = pulse_generation(HR,HRV,T_sim,fs);
    pulse = pulse(1:N); %The output of the true ppg signal.
    
    %Create respiratory signal
    resp = respiration_generation(RR,RRV,T_sim,fs);
    resp = resp(1:N); %The output of the true resp signal

    %resp is inverted so the maximum correlation is negative.
    mixed_signal = cardiac_amp*pulse + resp_amp*-resp; %The output of the mixed signal without noise

    %Debug plot
%     Fs_fast = fs;           % Sampling frequency (Hz)
%     T_fast = T;            % Duration (seconds)
%     N_fast = Fs_fast * T_fast;        % Number of samples
%     f_fast = (0:N_fast-1)*(Fs_fast/N_fast);  % Frequency vector
%     t_fast = (0:N_fast-1)/Fs_fast; %time vector

    % %Calculate frequency spectrum
    % fft_fast = abs(fft(mixed_signal) / N_fast);
    % fft_fast(2:N_fast/2) = 2*fft_fast(2:N_fast/2); 
    % 
    % figure
    % subplot(211)
    % plot(t_fast, mixed_signal)
    % xlim([T-10 T]), ylim([-4 4])
    % subplot(212)
    % plot(f_fast(2:N_fast/2),fft_fast(2:N_fast/2))
    % xlim([0 3])

end