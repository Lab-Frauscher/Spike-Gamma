function [p1 n1 n2]=compute_spike_boundary(spike_ref,fs)
% COMPUTE_SPIKE_BOUNDARY - Function to detect spike endpoints
%
% Syntax:
%   [p1, n1, n2] = compute_spike_boundary(spike_ref, fs)
%
% Inputs:
%   spike_ref - 300 ms [10-60] Hz filtered spike segment with spike peak at
%               75 ms. The spike segment is considered as 75 ms preceding N1
%               and 22 ms succeeding N1.
%   fs - Sampling frequency in Hz.
%
% Outputs:
%   p1 - Onset of the spike.
%   n1 - Peak of the spike predicted by Janca detector.
%   n2 - End of the spike.
%
% Description:
%   This function identifies the onset (p1), peak (n1), and end (n2) of a spike
%   based on the provided spike reference signal and sampling frequency.
%   It utilizes peak detection algorithms to locate the relevant points.
%
% Author(s):
%   John Thomas - john007@e.ntu.edu.sg
%
% Date Created:
%   01-March-2022
%
% Notes:
%   - This code is for research purposes only. Contact the author for reuse
%     and bug reporting.
%   - If downsampling was not performed while running the Janca detector, you
%     can skip the spike peak identification portion.
%   - The code uses the `islocalmin` and `islocalmax` functions for peak detection.
%   - The prominence levels and window sizes are adjusted iteratively until the
%     desired points (p1, n1, n2) are found.

% Identify spike peak in the data without downsampling
% (Skip this portion if not applicable)

% Since there could be a distortion in the spike peak introduced due to 
% downsampling, we re-identify the peak considering a window ± sampling
% ratio around the current peak.
num_samples=(fs*0.3);  % Total number of sample points in the spike segemnt
spike_index=round(num_samples/4)+1; % Ideal spike peak conisdering 75ms
downsample_ratio=2*round(fs/200); % Calculate downsample ratio

% Define the window in which we need to identify the spike peak
start_check=spike_index-downsample_ratio;
stop_check=spike_index+downsample_ratio-1;

% Find the peak as the sample point where we have the highest amplitude,
[val ind]=max(abs(spike_ref(start_check:stop_check)));
ind=ind+start_check-1;
    
% Now leats identify the P1 and P2. We use the peak detection codes in
% MATLAB islocalmin and islocalmax. We start with a prominense level of 20
% and iteratively reduce it, until we find P1 and P2.

prom=22;
array_spike=zeros(1,length(spike_ref));
    
% We start with a prominense of 20, However, this variable allows us to
% switch to 30, 40 or 50 if required.
high_prom=0;

% While we have P1 N1 and P2,
while(sum(array_spike)<3)
    prom=prom-2;
    
    % Check if the psike has a positive or neagtive peak
    if spike_ref(ind)>0 % if spike peak is positive
    local_min = islocalmin(spike_ref,'MinProminence',prom);
    local_left=max(find(local_min(1:ind-1)==1)); 
    local_right=ind+min(find(local_min(ind+1:end)==1)); 
    else % If spike peak is neagtive
    local_min = islocalmax(spike_ref,'MinProminence',prom);
    local_left=max(find(local_min(1:ind-1)==1)); 
    local_right=ind+min(find(local_min(ind+1:end)==1)); 
    end

    % Define an array with P1 N1 and P2
    array_spike=zeros(1,length(spike_ref));
    array_spike([local_left ind local_right])=1;

    % If we have found P1, N1 and P2, we check the follwing:
    % Check if P2-P1>70 ms or <20 ms as per defintion of spike, and if true
    % make restart with a low prominense.
    if sum(array_spike)==3
        if (local_right-local_left)/fs >0.07 | (local_right-local_left)/fs <0.02
            array_spike=zeros(1,length(spike_ref));
        end

        % Check if P2-N1<10 ms or N1-P1<10 ms, and if true, we might be
        % detecting local peak and therefore, have to increase the
        % prominense.
        if (local_right-ind)/fs <0.01 | (ind-local_left)/fs <0.01
            array_spike=zeros(1,length(spike_ref));
            high_prom=high_prom+1;
            switch high_prom
                case 1
                    prom=32;
                case 2
                    prom=42;
                case 3
                    prom=52;
            end
        end

    end
    
    % Finally, if prominense reaches zero, break the loop.
    if prom==0
        break;
    end
end
                    
%% We found P1, N1 and P2. Now lets estimate N2.
p1=local_left;n1=ind;p2=local_right;

% Here we start with a prominense of 0.
prom=2;n2=[];

% We increase the prominense and try to identify N2 under the followng
% conditions: (1) if we did not find N2; (2) If N2-P2<10 ms or (3) If
% N2-P1> 150 ms.
while(isempty(n2) | (n2-p2)/fs<0.01 | (n2-p1)/fs>0.15)
    n2=[];prom=prom+2;
    
    if spike_ref(ind)<0
    local_min = islocalmin(spike_ref,'MinProminence',prom);
    n2=ind+min(find(local_min(p2+1:end)==1)); 
    else
    local_min = islocalmax(spike_ref,'MinProminence',prom);
    n2=ind+min(find(local_min(p2+1:end)==1)); 
    end
     if prom==50
        break;
     end 
end 

% If N2 cannot be estimated, we fix it at P1+150 ms.
if isempty(n2)==1
    n2=p1+fs*0.15;
end
    

end