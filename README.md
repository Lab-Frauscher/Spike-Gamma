# Spike-Gamma

The spike-gamma implimentation steps are as follows:

1. Run the Janca spike detector to obtain spike peak locations for a single bipolar SEEG channel. (spike_detector_hilbert_v25.m)
2. Apply postprocessing to the spike detections, removing artifacts and spindles. (postprocessing.m)
3. Extract each spike as a 300 ms segment filtered between [0.3 500] Hz, and determine the onset (P1) and end (N2) points. (compute_spike_boundary.m)
4. Utilize these boundaries to extract the spike as a 2000 ms segment filtered between [30 100] Hz, and determine if there is preceding gamma activity. (compute_gamma.m)
5. For each spike, obtain the results as a 3-element array consisting of the maximum gamma power, the corresponding gamma frequency, and the duration of the gamma activity in milliseconds. If no gamma activity is detected, the array returns [0, 0, 0].
6. Repeat steps 3-5 for each spike, and obtain the spike-gamma location and event rates.
7. A detailed example of the above steps are provided in test_script.m.

An example of the spike-gamma is given below:

![Spike-gamma example](example.png)


### Credits

When using this Spike-Gamma implementation, please cite the following papers:

Thomas, J., Kahane, P., Abdallah, C., Avigdor, T., Zweiphenning, W.J., Chabardes, S., Jaber, K., Latreille, V., Minotti, L., Hall, J. and Dubeau, F., 2023. A subpopulation of spikes predicts successful epilepsy surgery outcome. Annals of Neurology, 93(3), pp.522-535.

Janca, R., Jezdik, P., Cmejla, R., Tomasek, M., Worrell, G.A., Stead, M., Wagenaar, J., Jefferys, J.G., Krsek, P., Komarek, V. and Jiruska, P., 2015. Detection of interictal epileptiform discharges using signal envelope distribution modelling: application to epileptic and non-epileptic intracranial recordings. Brain topography, 28, pp.172-183.

### Research License
This repository is licensed under a research license. The code and resources provided are intended for academic and research purposes only. For any commercial or non-academic use, please contact the respective authors.

### Disclaimer
Please note that the authors of this repository take no responsibility for any consequences or damages arising from the use of this code. Users are advised to use it at their own risk and to thoroughly evaluate its suitability for their specific purposes.




