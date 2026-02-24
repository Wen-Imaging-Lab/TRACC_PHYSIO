% Written by: Adam Wright
% Email: adam.wright303@gmail.com

function pulse = pulse_generation(HR,HRV,T,fs)

%% Generate pulse shape for one cycle (pulsebase)
n = 100; % Number of points in the vector
cycles = 2; % Number of sine wave cycles
t = linspace(0, cycles, n); % Time vector (normalized to 2 cycles)
base_wave = sin(pi * cycles * t);
 
% Add asymmetry to mimic a cardiac pulse
asymmetry = 0.5 * sin(2 * pi * cycles * t); % Higher frequency modulation
pulse = base_wave + asymmetry; pulse = pulse/max(pulse);
pulsebase = pulse(42:91);
 
% customize parameters
%HR = 60; % bpm
%HRV = 50; % SDNN in ms
%T = 610; % duration in seconds
 
pulse = simulate_pulse(HR,HRV, T, pulsebase,fs);
%figure,plot([1:length(pulse)]*0.0025,pulse),xlabel('time (sec)')

end

function pulse = simulate_pulse(HR, HRV, T, pulsebase, fs)

% SIMULATE_PULSE Simulate a realistic pulse signal
%
% Inputs:
%   HR        - Mean heart rate in bpm
%   HRV       - Heart rate variability (SDNN) in milliseconds
%   T         - Total duration in seconds
%   pulsebase - 1xN vector representing the shape of one cardiac cycle
%
% Output:
%   pulse     - Simulated pulse signal
 
    %fs = 400; % Sampling frequency in Hz
    mean_IBI_ms = 60000 / HR; % Mean inter-beat-interval (IBI) in ms
    total_samples = round(T * fs);
    pulse = zeros(1, total_samples);
 
    % Total beats expected
    num_beats = round(HR * T / 60);
 
    % Generate inter-beat-interval (IBI) series in ms with added HRV
    IBI_ms = mean_IBI_ms + HRV * randn(1, num_beats);
    IBI_ms = max(IBI_ms, 300); % clamp to physiological min IBI (300ms)
    IBI_samples = round((IBI_ms / 1000) * fs);
 
    % Insert interpolated pulsebase for each beat
    idx = 1;
    for i = 1:num_beats
        dur = IBI_samples(i);
        if idx + dur - 1 > total_samples
            dur = total_samples - idx + 1; % Truncate to fit
            if dur <= 1
                break; % Not enough room to add a beat
            end
        end
 
        % Interpolate pulsebase to match this IBI duration
        resampled = interp1(1:length(pulsebase), pulsebase, ...
                            linspace(1, length(pulsebase), dur), 'linear');
 
        % Add resampled pulse to signal
        pulse(idx:idx + dur - 1) = pulse(idx:idx + dur - 1) + resampled;
        idx = idx + dur;
    end
end
