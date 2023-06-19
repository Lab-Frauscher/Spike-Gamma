# Spike-Gamma

The spike-gamma implemntation steps are as follows:

1. Run Janca spike detector and get spike peak locations for a single bipolar SEEG channel. (spike_detector_hilbert_v25.m)
2. Run postprocessing code on the spike detections to remove artefacts and spindles. (postprocessing.m)
3. For each spike detection, extract the spike as a 300 ms [0.3 500] Hz filtered segment, and determine the endpoints P1 and N2. P1 is the onset and N2 is the end of the spike. (compute_spike_boundary.m)
4. Using these boundaries, extract the spike as a 2000 ms [30 100] Hz filtered segment, and compute if gamma activity precedes this spike. (compute_gamma.m).
5. 



![Spike-gamma example](example.png)


Please provide appropriate credits:

