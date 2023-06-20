% Clear the Command Window and remove all variables from the workspace
clc;
clear all;

%% Running spike detector
% Import spike data from the 'signal_example.mat' file
test_data_spike = importdata('signal_example.mat');
signal_all = test_data_spike.signal; % time samples*N channels
fs = test_data_spike.fs; % sampling frequency

settings = '-bl 10 -bh 60 -h 60 -jl 3.65 -dec 200'; % default settings of Janca detector
out = spike_detector_hilbert_v25(signal_all,fs,settings);

%% Post-processing spike detections
out_pp = postprocessing(out,fs,size(signal_all,2))';

%% Here we show an example for identifying gamma activty before a single spike on a single channel
% Please iterate the follwoing steps for each channel, each spike and determine the event rates
% Computing spike-gamma for spike i in channel #i
chIdx = 1;
%   5    18    30    31    35    36
spIdx = 18;

spikeLocations = round(out_pp{chIdx}(spIdx));
signal = signal_all(:,chIdx);

%% Filtering data to estimate spike boundaries
% Create Butterworth bandpass filters to preprocess the data
[b, a] = butter(4, [0.3 500] * 2/fs, 'bandpass');
[b_gm, a_gm] = butter(4, [30 100] * 2/fs, 'bandpass');

% Create a notch filter to remove power line noise
wo = 60/(fs/2);
bw = wo/500;
[bn, an] = iirnotch(wo, bw);

% Apply the notch filter and bandpass filters to the spike data
signal = filtfilt(bn, an, signal);
signal_bp = filtfilt(b, a, signal);
signal_gm = filtfilt(b_gm, a_gm, signal);

%% Spike-gamma script: Performs preprocessing operations on spike data

% Define the time window for the spike segment
onset = 75e-3 * fs;
offset = 225e-3 * fs;

spike_onset = spikeLocations - onset;
spike_offset = spikeLocations + offset;

% Extract the spike segment from the filtered signal
spike_segment = signal_bp(spike_onset : spike_offset);

% Compute spike boundaries
[P1, N1, N2] = compute_spike_boundary(spike_segment, fs);

% Adjust spike boundaries based on spike onset
N1 = spike_onset + N1;
P1 = spike_onset + P1;
N2 = spike_onset + N2;

% Set the new onset and offset for spike boundaries
onset = 1 * fs;
offset = 1 * fs;

ref = N1 - onset;
P1 = P1 - ref;
N2 = N2 - ref;

% Define the new time window and extract the spike and gamma signal
window = round(N1 - onset : N1 + offset)';
t = window'/fs;
spike = signal_bp(window);
gamma_signal = signal_gm(window);

% Compute gamma activity within the spike segment
% This returns a non-zero vector if gamma activity is detected
spikeGamma = compute_gamma(spike, fs, P1, N2)

% Plot spike boundaries and corresponding gamma signal
figure;
set(gcf,'Units','normalized',"outerposition",[0 0 .8 .5])
movegui('center');

subplot(2,2,1);
plot(t, spike, 'k-', 'LineWidth', 1); hold on;
plot(t(P1), spike(P1), 'ro', 'LineWidth', 2)
plot(t(onset), spike(onset), 'rx', 'LineWidth', 2)
plot(t(N2), spike(N2), 'rs', 'LineWidth', 2)
rectangle('Position',[t(P1)-0.5 min(spike) 0.5 max(spike)-min(spike)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor',[0 0 0 0.5])
rectangle('Position',[t(N2) min(spike) 0.5 max(spike)-min(spike)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor',[0 0 0 0.5])
xlim([t(1) t(end)])
ylim([min(spike) max(spike)])
subtitle('Spike segment')
xlabel('Time (sec)')
ylabel('Voltage (\mu V)')

subplot(2,2,3);
plot(t, gamma_signal, 'color', [1 0 0 0.5], 'LineStyle', '-'); hold on;
plot(t(P1), gamma_signal(P1), 'ro')
plot(t(onset), gamma_signal(onset), 'rx')
plot(t(N2), gamma_signal(N2), 'ro')
rectangle('Position',[t(P1)-0.5 min(gamma_signal) 0.5 max(gamma_signal)-min(gamma_signal)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor',[0 0 0 0.5])
rectangle('Position',[t(N2) min(gamma_signal) 0.5 max(gamma_signal)-min(gamma_signal)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor',[0 0 0 0.5])
xlim([t(1) t(end)])
ylim([min(gamma_signal) max(gamma_signal)])
subtitle('Gamma filtered segment (30-100Hz)')
xlabel('Time (sec)')
ylabel('Voltage (\mu V)')

subplot(2,2,[2 4])
fb = cwtfilterbank('SignalLength',2*fs,'SamplingFrequency',fs,'FrequencyLimits',[30 100],'VoicesPerOctave',40);  
[tf,tf_freqs]=wt(fb,spike(1:end-1));
gamma_sig=abs(tf);

colormap('jet');
h = pcolor(t(1:end-1),tf_freqs,gamma_sig);
set(h, 'EdgeColor', 'none');
rectangle('Position',[t(P1)-0.5 30 0.5 70],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .5],'EdgeColor',[0 0 0 1]);
rectangle('Position',[t(N2) 30 0.5 70],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .5],'EdgeColor',[0 0 0 1]);
subtitle('Time frequency representation of the spike segment')
xlabel('Time (sec)')
ylabel('Frequency (Hz)')
