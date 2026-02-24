# TRACC_PHYSIO
This repository has code to complete TRACC_PHYSIO -- TRACC-PHYSIO performs a cross-correlation between a dynamic MRI signal  and a simultaneously recorded physiological signal with a much higher sampling rate to quantify coupling strength and a TimeDelay that reflects the relative arrival time of the physiological impulse.

The folder TRACC_simulation_code contains the code and examples for simulated physiological finger PPG, respiratory belt, and MR signal generation.
Running the script: simulated_signal_examples_wFigure.m will output simulated PPG, Resp, and MR signals along with a plot.

Running the script Example_TRACC_Cardiac_simulation.m will run an example simulation of TRACC-Cardiac and output a figure showing the TRACC-Cardiac waveform, along with a Peak CorrCoeff and TimeDelay.

The folder TRACC_realData_code has code to run TRACC-Cardiac with real fMRI data. The data is too large to share on GitHub, so it is available to download on Zenodo (10.5281/zenodo.18762411).

Using the TRACC_realData_code and data on Zenodo an example of TRACC-Cardiac can be run. 

The example is for the finger PPG coupling (TRACC-Cardiac). I have only run this with Siemens data, so it may need some adjustments to work with other vendors' physiological data. 

Pipeline:
1. Run fsl brain extraction BET (code provided) below.
2. run script: save_physio.m (this is the physiology file from siemens and it has the real time slice timings)
3. run main_TRACC_Cardiac.m

The two main output files are:
PeakCorrCoeff_Map_window_-300_to_300_ms.nii.gz.
TimeDelay_Map_window_-300_to_300_ms.nii.gz

The demo data has all the files as if they were processed, so you have a reference of what the outputs should look like. You can test running the code by just starting with ‘fMRI.nii.gz’ and the physiology file in PhysioLog folder.

When running this code, use unprocessed fMRI data. You don’t want to slice time correct, spatially smooth, or motion correct before running this. This is because the timing alignment relies on the real-time slice timings, and this processing will mess up the slice timing. This is the main limitation of this method, that it is very senstive to motion and corrections to motion can not be done at this time.

The PeakCorrCoeff will have more negative values near the large vessels and relatively low correlations everywhere else in the brain.
The TimeDelay_Map will look pretty noisy throughout the brain. The values in the large vessels will have the highest PeakCorrCoeff and are the most accurate measures.
The vessel regions can be visualized with the provided masks, within the data folder are two segmentations called ‘mask_artery.nii.gz’ and ‘mask_SSSl.nii.gz’. These are data-driven segmentations of the large vessels using a pipeline that we published here: https://royalsocietypublishing.org/doi/10.1098/rsfs.2024.0024
