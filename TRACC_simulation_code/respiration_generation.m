
% Written by: Adam Wright
% Email: adam.wright303@gmail.com

function resp = respiration_generation(RR,RRV,T,fs)

% Generate one full respiration cycle starting and ending at 0
n = 100; % number of samples per cycle
t = linspace(0, 1, n); % normalized time from 0 to 1

% One full respiration cycle (sinusoid, optionally asymmetric)
base = sin(2 * pi * t);  % one full cycle
asymmetry = 0.15 * sin(4 * pi * t); % optional second harmonic to make it asymmetric
resp_base = base + asymmetry;

% Normalize to unit amplitude
resp_base = resp_base / max(abs(resp_base));

% % Customize respiratory parameters
% RR = 14;      % Respiration rate (breaths per minute)
% RRV = 600;    % Respiratory variability in milliseconds (SD of inter-breath interval)
% T = 610;      % Duration in seconds

% Simulate respiration signal
resp = simulate_resp(RR, RRV, T, resp_base,fs);
time = (0:length(resp)-1) * 1/fs;

% % Plot
% figure;
% plot(time, resp);
% xlabel('Time (s)');
% ylabel('Respiration amplitude');
% title('Simulated Respiratory Belt Signal');

end

%% Function to simulate respiratory signal
function resp = simulate_resp(RR, RRV, T, respbase,fs)
    %fs = 400; % Sampling frequency in Hz
    mean_IBI_ms = 60000 / RR; % Mean inter-breath interval (ms)
    total_samples = round(T * fs);
    resp = zeros(1, total_samples);

    % Total breaths
    num_breaths = round(RR * T / 60);

    % Create IBI vector with variability
    IBI_ms = mean_IBI_ms + RRV * randn(1, num_breaths);
    IBI_ms = max(IBI_ms, 1500); % Clamp to min ~1.5 sec
    IBI_samples = round((IBI_ms / 1000) * fs);

    idx = 1;
    for i = 1:num_breaths
        dur = IBI_samples(i);
        if idx + dur - 1 > total_samples
            dur = total_samples - idx + 1; % Shorten breath to fit remaining space
            if dur <= 1
                break; % Not enough room
            end
        end

    % Interpolate base waveform
    resampled = interp1(1:length(respbase), respbase, ...
                        linspace(1, length(respbase), dur), 'linear');
    
    % Add sinusoid to signal
    resp(idx:idx + dur - 1) = resp(idx:idx + dur - 1) + resampled;
    idx = idx + dur;
    end
end