function out_ch=postprocessing(out,fs,num_chans)

% POST PROCESSING JANCA DETECTOR DETECTIONS
% @========================================================================
% Authors: Sayeed, John Thomas
% DATE CREATED: 23-April-2021
% DATE MODIFIED: 22-April-2021
% FOR RESEARCH PURPOSES ONLY. KINDLY CONTACT THE AUTHOR FOR REUSE AND BUGS.
% ========================================================================@
% Tasks:
% 1. Intput: 
     %out: Output from the Janca detector.
     %fs: Sampling frequency.
     %num_chans: Number of channels from montage.txt.
% 2. Remove the codections occuring simulatneously in atleast 50% of the
     %channels.
% 3. Remove all the detections that occur within 300 milliseonds defined by
     % 'threshold' within asingle channel.
%4. Return 'out_ch': each cell containing detections in a single channel.
%==========================================================================&
threshold=0.300;% Threshold in seconds

% Execute if there are more than one detections
if length(out.pos)>1
    fields=fieldnames(out);
    outcell=struct2cell(out);

    %% Remove codetections on more than 50% of channels        
    ncooc=histcounts(outcell{1},unique(outcell{1}));
    spks2rem=find(ncooc>ceil(num_chans/2));
    if ~isempty(spks2rem)
    for irm = 1:length(spks2rem)
        id_rem=find(outcell{1}==spks2rem(irm));
        for i_field = 1:length(outcell)
            outcell{i_field}(id_rem)=[];
        end
    end
    end

    %% Burst threshold
    burst_thresh=threshold*fs; %we don't want channels closer than 300ms to each other
    output_cell = cell(1,num_chans); %we will save a cell for each channel
    for ic = 1:num_chans %loop through every channel in the montage
    chan_ind = find(outcell{3}==ic); %find that spikes only in the given channel
    nspks = length(chan_ind);
    output_chan = cell(1,nspks); %We will save a cell for each spike

    spk_pos_in_chan=[];
    for i_str = 1:nspks %loop through every spike in the channel
        spk_pos_in_chan(i_str) = round(outcell{1}(chan_ind(i_str))*fs); %collect the spike positions
        output_chan{i_str}{1} = spk_pos_in_chan(i_str);
        for i_field = 2:length(outcell) %each field of this cell will become a field of the data structure
            output_chan{i_str}{i_field} = outcell{i_field}(chan_ind(i_str)); %collect the other features outputted by the detector
        end
    end

    %here is where I remove the spikes that are closer to their neighbour by 300ms. This is done by finding the differences
    %between each position and the previous (diff.m), and then flipping the vector to get the differences in the other direction.
    if nspks>1
        inter_spike_latency_lr=diff(spk_pos_in_chan); %find the differences between each channel and the next
        inter_spike_latency_lr=[-(spk_pos_in_chan(1)-spk_pos_in_chan(2)) inter_spike_latency_lr]; %add a value for the first spike
        spks_too_close_lr=inter_spike_latency_lr<burst_thresh; %anything closer to the previous spike by 300ms is removed

        inter_spike_latency_rl=-diff(fliplr(spk_pos_in_chan)); %find the differences between each channel and the next
        inter_spike_latency_rl=[-(spk_pos_in_chan(end-1)-spk_pos_in_chan(end)) inter_spike_latency_rl]; %add a value for the first spike
        spks_too_close_rl=fliplr(inter_spike_latency_rl<burst_thresh); %anything closer to the following spike by 300ms is removed

        spks_too_close=[spks_too_close_lr | spks_too_close_rl]; %if a spike was too close to the next one in the forward or reverse direction, we remove it.
        output_chan=output_chan(~spks_too_close);
    end

    output_cell{ic} = output_chan;
    end


    %reaarange output_cell
    out_ch=[];
    for pp=1:length(output_cell)
    temp_output_cell=output_cell{pp};
    store_ch=[];
    for pq=1:length(temp_output_cell)
       temp2=temp_output_cell{pq};
       store_ch(pq)=temp2{1};
    end
    out_ch{pp}=store_ch;
    clear temp_output_cell
    clear store_ch
    end

else
    out_ch{out.chan}=out.pos;
end