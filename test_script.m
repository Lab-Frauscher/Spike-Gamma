% Clear the Command Window and remove all variables from the workspace
clc;
clear all;

%% Test script: Performs preprocessing operations on spike data

% Import spike data from the 'signal_example.mat' file
test_data_spike = importdata('signal_example.mat');

% Set the sampling frequency to 2000 Hz
fs = 2000;

% Create Butterworth bandpass filters to preprocess the data
[b, a] = butter(4, [0.3 500] * 2/fs, 'bandpass');
[b_gm, a_gm] = butter(4, [30 100] * 2/fs, 'bandpass');

% Create a notch filter to remove power line noise
wo = 60/(fs/2);
bw = wo/500;
[bn, an] = iirnotch(wo, bw);

% Apply the notch filter and bandpass filters to the spike data
signal = filtfilt(bn, an, test_data_spike.signal);
signal_bp = filtfilt(b, a, signal);
signal_gm = filtfilt(b_gm, a_gm, signal);

% Calculate the spike locations based on the spike data and sampling frequency
% Selecting spike (out of 2)
i = 2;
spikeLocations = test_data_spike.spikeLocations(i) * fs;

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

%% Plot spike boundaries and corresponding gamma signal
figure;
set(gcf,'Units','normalized',"outerposition",[0 0 .8 .5])
movegui('center');

subplot(2,2,1);
plot(t, spike, 'k-', 'LineWidth', 1); hold on;
plot(t(P1), spike(P1), 'ro', 'LineWidth', 2)
plot(t(onset), spike(onset), 'rx', 'LineWidth', 2)
plot(t(N2), spike(N2), 'rs', 'LineWidth', 2)
rectangle('Position',[t(P1)-0.5 min(spike) 0.5 max(spike)-min(spike)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor','none')
rectangle('Position',[t(N2) min(spike) 0.5 max(spike)-min(spike)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor','none')
xlim([t(1) t(end)])
ylim([min(spike) max(spike)])
subtitle('Spike segment')

subplot(2,2,3);
plot(t, gamma_signal, 'color', [1 0 0 0.5], 'LineStyle', '-'); hold on;
plot(t(P1), gamma_signal(P1), 'ro')
plot(t(onset), gamma_signal(onset), 'rx')
plot(t(N2), gamma_signal(N2), 'ro')
rectangle('Position',[t(P1)-0.5 min(gamma_signal) 0.5 max(gamma_signal)-min(gamma_signal)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor','none')
rectangle('Position',[t(N2) min(gamma_signal) 0.5 max(gamma_signal)-min(gamma_signal)],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .1],'EdgeColor','none')
xlim([t(1) t(end)])
ylim([min(gamma_signal) max(gamma_signal)])
subtitle('Gamma filtered segment (30-100Hz)')

subplot(2,2,[2 4])
fb = cwtfilterbank('SignalLength',2*fs,'SamplingFrequency',fs,'FrequencyLimits',[30 100],'VoicesPerOctave',40);  
[tf,tf_freqs]=wt(fb,spike(1:end-1));
gamma_sig=abs(tf);

colormap('jet');
h = pcolor(t(1:end-1),tf_freqs,gamma_sig);
set(h, 'EdgeColor', 'none');
rectangle('Position',[t(P1)-0.5 30 0.5 70],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .5],'EdgeColor','none');
rectangle('Position',[t(N2) 30 0.5 70],'Curvature',0.2, 'FaceColor',[.5 .5 .5 .5],'EdgeColor','none');
subtitle('Time frequency representation of the spike segment')
%% Compute gamma activity within the spike segment
spikeGamma = compute_gamma(spike, fs, P1, N2);