function [output]=compute_gamma(segment,fs,p1,n2)
% compute_gamma - Detects preceding gamma activity in a spike segment.
%
% Syntax: 
%   [output] = compute_gamma(segment, fs, p1, n2)
%
% Inputs:
%   segment: 2-second [30-100] Hz filtered spike segment with the spike peak at
%            the center. The spike segment can have an arbitrary length, but it
%            should have at least 500 ms before and after the spike. Any
%            preprocessing steps like artifact rejection and notch filtering
%            should be applied before extracting the segment.
%   fs: Sampling frequency in Hz.
%   p1: Onset of the spike in samples with respect to the 'segment'.
%   n2: End of the spike in samples with respect to the 'segment'.
%
% Outputs:
%   output: A 3-element array containing the maximum gamma power, the gamma frequency
%           corresponding to the maximum power, and the duration of the gamma
%           activity in milliseconds. If no gamma activity is detected, it
%           returns [0, 0, 0].
%
% Author: John Thomas
% Contact: john007@e.ntu.edu.sg
% Date Created: 01-July-2021
% 
% Reference:
%   Ren, L., Kucewicz, M.T., Cimbalnik, J., Matsumoto, J.Y., Brinkmann, B.H.,
%   Hu, W., Marsh, W.R., Meyer, F.B., Stead, S.M. and Worrell, G.A., 2015.
%   Gamma oscillations precede interictal epileptiform spikes in the seizure
%   onset zone. Neurology, 84(6), pp.602-608.


output=[];

%% START
% Define a filterbank 
win=fs;
fb = cwtfilterbank('SignalLength',2*win,'SamplingFrequency',fs,'FrequencyLimits',[30 100],'VoicesPerOctave',40);       
f_gamma = segment(1:end-1);

% Compute Morse Wavelet on signal using filterbank
[tf,tf_freqs]=wt(fb,f_gamma);
gamma_sig=abs(tf);

% We only consider 500 ms before P1 and  500 ms after N2 for the analysis.
todelete = [1:p1-fs/2-1 floor(p1):ceil(n2) n2+fs/2+1:size(gamma_sig,2)];
gamma_baseline=gamma_sig;
gamma_baseline(:,todelete)=[]; % We remove the extra segments

% The threshold for gamma is defined as mean+2 stds.
% We use 2 SD instead of 3 since this is a bipolar montage
gamma_mean = mean(gamma_baseline,2);
pow_thresh = 2*std(gamma_baseline,[],2); 
gamma_thresh = gamma_mean + pow_thresh;

% Now we identify the sefments with gamma power > threshold
gamma_2sd=gamma_sig>gamma_thresh;

% We only conside the gamma increase for 500 ms before P1. Therefore, we
% make the other values zero.
gamma_2sd(:,[1:ceil(p1-fs/2) p1:end])=0;  

% Calculate the duration for each frequency in samples. We only conisder gamma
% activity which lasts atleast 3 cycles.
dur_thresh = 3*ceil((1./tf_freqs)*fs);

gamma_dur = nan(length(tf_freqs),1); 
gamma_pow = nan(length(tf_freqs),1); 
gamma_max=[]; gamma_f=[];

% For each frequency identify significant gamma activity that lasts atleast
% 3 cycles and store them.
for i_freq =1:length(tf_freqs)
    % Find the locations at which the gamma activity was significant as
    % [start end] in samples
    pass = [0 gamma_2sd(i_freq,:) 0];
    segs=find(diff(pass));
    
    if ~isempty(segs)
        % if there is atleast one significant gamma activity, compute the
        % duration of the activity
        pairs=reshape(segs,2,length(segs)/2)';
        seglen= pairs(:,2)-pairs(:,1);
        
        % for each pair to [start end] of gamma acitivty, check whether the
        % activity is within 190 ms of P1 (value taken from Ren et al.,
        % Nueorlogy, 2015). If the activity is within 190 ms and has a
        % duration of 3 cycles, record these values.
        for i_seg = 1:size(pairs,1)
            if (p1-pairs(i_seg,2)<=0.19*fs)
                dur_thresh_pass = seglen(i_seg) >= dur_thresh(i_freq);
                if dur_thresh_pass
                    gamma_dur(i_freq)=seglen(i_seg);
                    gamma_pow(i_freq)=mean(gamma_sig(i_freq,pairs(i_seg,1)+1:pairs(i_seg,2)));
                else
                    gamma_2sd(i_freq,pairs(i_seg,1)+1:pairs(i_seg,2))=0;
                    gamma_dur(i_freq) = nan;
                    gamma_pow(i_freq) = nan;
                end
            else
                gamma_2sd(i_freq,pairs(i_seg,1)+1:pairs(i_seg,2))=0;
            end
        end
    end
end

% If gamma acitivity is detected in multiple frequecnies, consider the
% highest frequency. 
if ~all(isnan(gamma_pow))
    [gamma_max,gamma_f]=max(gamma_pow);
end

% Store the output
output=[gamma_max tf_freqs(gamma_f) 1000*gamma_dur(gamma_f)/fs];

% If gamma activity was not detected, return [0 0 0]
if isempty(output)==1
output=[0 0 0];
end
end
