# pacman-data-load

 matlab code for loading pacman behavior and neural data

an example dataset has exactly this folder structure

<data_root> / pacman-task / cousteau / <date> /

and within each date folder:
<date> / neuropixels / <neuropixel_recording_dir>
<date> / speedgoat / <list of files, one per trial>

Example:

neural data: /Users/erictrautmann/data/pacman-task/cousteau/2021-03-18/neuropixels/pacman-task_c_210318_neu_g0
behavioral data: /Users/erictrautmann/data/pacman-task/cousteau/2021-03-18/speedgoat

The raw datasets are enormous and I can't easily reorganize them on my end here without breaking other things, but you can avoid downloading the raw neural data, and just download the behavior (speedgoat) and the processed neural data, inside the kilosort-manually-sorted folder. If this is ridiculously confusing, my apologies.

1) download code for ingestion. Sorry, this piece is legacy matlab (ugh)
<https://github.com/etrautmann/pacman-data-load>

2) try loading a dataset:
demo_run_load_neural_and_behavior.m
