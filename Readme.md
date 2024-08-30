# Artifacts Evaluation - README - Usenix Security 2024

## For Paper: Cascade: CPU Fuzzing via Intricate Program Generation

### Overview

Welcome to the artifacts for Cascade!
This repository will help you reproduce the results presented in our paper, and will get you started with Cascade without worrying too much about setting up the context.
For more information about Cascade, visit https://comsec.ethz.ch/cascade.
Most of the fuzzing code is located here https://github.com/cascade-artifacts-designs/cascade-meta.

The repository is structured as follows.
First, we indicate a few requirements.
Second, we provide a step-by-step guide to reproduce the results in our paper.

We recommend using the provided Docker image to reproduce the results.
All experiments, except the Questasim experiment, run inside a Docker container.
The Questasim experiment is optional as its only purpose is to compare the simulator coverage of Cascade and TheHuzz.

### Requirements

Some experiments require 64 cores, however, it can be run with less cores, we do not expect a big difference in the results.

One optional experiment, which will be explicitly marked, requires access to Questasim (a commercial RTL simulator).
No other experiment depends on these results, hence non-Questasim users can safely ignore this experiment and run the rest of the artifacts.

### Step-by-step guide

#### Obtain the Docker image. (Human time: 1 minute. Computer time: up to some hours.)

If you are willing to use the Docker image, here is how to proceed.
Else, we recommend to mimic the structure of the repositories as described in the Dockerfile.

```
docker pull docker.io/ethcomsec/cascade-artifacts
```

#### Start a container using the Docker image. (Human time: some minutes, on and off. Computer time: some minutes.)

All relevant experiments have already been reproduced inside this image.
We made the steps explicit in the Dockerfile.
The Dockerfile is hence also a convenient reference on how to run each experiment.

First, start a new container with the image:

```
docker run -it docker.io/ethcomsec/cascade-artifacts
```

This procedure assumes you don't want to rebuild everything from scratch, although you can re-run commmands that are presented in the Dockerfile.


Instead, if you would like to rebuild the Docker image, simply run `make build` in the current repository, which will re-build the whole Docker image from scratch.
This will take many hours to execute.

In this Docker container, we limited the computation for Figure 16 to 30 seconds per point to finish in reasonable time.
The value used in the paper is 1200 seconds, which may require multiple days to run, on a 64-core machine.
The duration of 30 seconds is sufficient to support the claim made in the paper that longer programs tend to be more efficient at finding bugs.
This timeout can be modified by adapting the line `ENV TIMEOUT_SECONS_PER_BUG=30` in the Dockerfile with a value of your choice.

The following error messages are expected, and can be safely ignored:
```
SIMLEN environment variable not set.
make: *** [Makefile:129: run_vanilla_notrace] Error 1
```

#### Re-running individual experiments

You can re-run individual experiments by re-executing lines of the Dockerfile in the docker container.

Make sure that your Verilator version in the Docker container is correct.
If you get the following error:

```
ERROR: %Error: Unknown warning specified: -Wno-EOFNEWLINE
```

Then please reinstall the newer version of Verilator:
```
rm -rf verilator && git clone https://github.com/verilator/verilator && cd verilator && git checkout v5.006 && autoconf && ./configure && make -j 200 && make install
```

#### Plots

All plots, except for the Questasim experiment, are stored in the `/cascade-meta/figures` directory inside the Docker container, and have been generated as indicated in the Dockerfile.

##### Extracting plots from the Docker container

You must first run a container, for example using the command `make run`.
You can then see the container id, for example, from the command prompt that you get after running `make run`, for example, `root@ac674f329a7b:/#` signifies that the container id is `ac674f329a7b`.

You can now copy out the figures from the container to your host machine, for example, using the following commands:
```
mkdir -p figures
docker cp <container_id>:/cascade-meta/figures/bug_categories.png            figures
docker cp <container_id>:/cascade-meta/figures/cascade_dependencies.png      figures
docker cp <container_id>:/cascade-meta/figures/cascade_prevalences.png       figures
docker cp <container_id>:/cascade-meta/figures/difuzzrtl_completions.png     figures
docker cp <container_id>:/cascade-meta/figures/difuzzrtl_coverage.png        figures
docker cp <container_id>:/cascade-meta/figures/difuzzrtl_dependencies.png    figures
docker cp <container_id>:/cascade-meta/figures/difuzzrtl_prevalences.png     figures
docker cp <container_id>:/cascade-meta/figures/reduction_perf.png            figures
docker cp <container_id>:/cascade-meta/figures/rfuzz.png                     figures
docker cp <container_id>:/cascade-meta/figures/security_implications.png     figures
docker cp <container_id>:/cascade-meta/figures/bug_timings_curves.png        figures
docker cp <container_id>:/cascade-meta/figures/execperf_programlength.png    figures
docker cp <container_id>:/cascade-meta/figures/fuzzperf_programlength.png    figures
docker cp <container_id>:/cascade-meta/figures/genduration_programlength.png figures
docker cp <container_id>:/cascade-meta/figures/fuzzperf.png                  figures
```

##### Mapping to the paper's figures

Mapping to the paper's figures:

| Figure in paper | Figure in artifacts       |
| --------------- | ------------------------- |
| 1               | difuzzrtl_completions     |
| 2               | difuzzrtl_prevalences     |
| 3               | -                         |
| 4               | -                         |
| 5               | -                         |
| 6               | fuzzperf                  |
| 7               | execperf_programlength    |
| 8               | genduration_programlength |
| 9               | fuzzperf_programlength    |
| 10              | cascade_prevalences       |
| 11              | difuzzrtl_dependencies    |
| 12              | cascade_dependencies      |
| 13              | difuzzrtl_coverage        |
| 14              | rfuzz                     |
| 15              | [optional -- modelsim]    |
| 16              | bug_timings_curves        |
| 17              | bug_categories            |
| 18              | bug_detection_timings     |
| 19              | security_implications     |
| 20              | reduction_perf            |

#### Re-producing the register coverage of Cascade and DifuzzRTL

For convenience, we provide the logs of the execution of Cascade and DifuzzRTL as `.log.tgz` files.
To reproduce the results, we kindly redirect you to [the dedicated repository](https://github.com/cascade-artifacts-designs/cascade-difuzzrtl-verilator/#cascade-artifacts-regarding-the-collection-of-the-difuzzrtl-coverage-metric).

#### Questasim experiment (Optional)

The Questasim experiment, optional, is the only experiment that must be partially run outside of the Docker container.
The experiment requires the presence of the executables `vsim`, `vlog` and `vcover` in the PATH.

You will also require fusesoc, as also installed in the Dockerfile.
```
pip3 install fusesoc
```

You will need to clone `cascade-meta` and `cascade-chipyard` (containing the Rocket core) locally.
If potential requirements are missing, ensure to reproduce the first line of the Dockerfile, directly on your machine.

To initialize cascade-chipyard, please run, like done in the Dockerfile:
```
source /path/to/cascade-meta && cd /path/to/cascade-chipyard && git branch stable && CASCADE_JOBS=250 scripts/init-submodules-no-riscv-tools.sh -f
```
Then, build the Rocket core for the Questasim simulation:
```
source /path/to/cascade-meta && cd /path/to/cascade-chipyard/cascade && make build_vanilla_notrace_modelsim && make rerun_vanilla_notrace_modelsim
```

You may have to adapt the `rocket` entry in the local `cascade_meta/design_processing/design_repos.json` for running the experiment.

To run the Questasim experiment, first start a new container with the image and generate the ELF files for DifuzzRTL and Cascade (this may take some hours).
Note that we could have done this in the Dockerfile but the resulting Docker image would be very large.
You must also choose a local directory where the ELFs directory will be mounted (make sure to have the proper permissions); alternatively, instead of mounting using the `-v` flag, you could copy out the ELFs by using `docker ps` and then `docker cp`.
All this can be done, for example, as follows:
```
DIFUZZRTL_FUZZER_DIR_PATH_CANDIDATE=<path_to_the_Fuzzer> docker run -v /path/to/some/mount/directory:/cascade-mountdir -it cascade-artifacts bash -c "source /cascade-meta/env.sh && python3 /cascade-meta/fuzzer/do_genelfs_for_questa.py"
```

Ensure that you have the Python requirements installed by the Dockerfile on your host machine.
Please install any additional Python requirement that would be requested during the course of the experiment, for instance:
```
pip3 install matplotlib numpy tqdm filelock
```

Finally, run the experiment, first indicating where the ELFs are now located (the directory you mounted):
```
export CASCADE_PATH_TO_DIFUZZRTL_ELFS_FOR_MODELSIM=/path/to/some/mount/directory
cd <path_to_cascade_meta>/fuzzer && python3 do_compare_cascade_difuzzrtl_modelsim.py
```

The experiment may take many hours and can be divided in two parts:
1. Running the fuzzer. This can be done in parallel.
2. Merging the coverage results. This must be done sequentially to get the coverage achieved at each step.
The result is stored in the file `modelsim.png` in the local `cascade-meta/figures` directory.

![cascade logo](https://github.com/comsec-group/cascade-artifacts/assets/28906668/0fbbf474-4479-4bf9-96df-43c520f3ae8e)

### Additional information

#### Description of detailed steps

In `step_descriptions.md`, we provide a mapping of the overview figure from the paper (Figure 3).

#### A minimal running example

To run a minimal example, you can follow the following steps:

First, adapt `descriptor` in `cascade-meta/fuzzer/do_fuzzsingle.py` to the parameters of your choice in terms of memory size, target design, random seed, maximal number of basic blocks and inclusion of privileged instructions.
Second, run this script through `python3 cascade-meta/fuzzer/do_fuzzsingle.py`.
This will execute all steps until and including the DUT run.
If you would like, instead, to fuzz with many programs, use `python3 cascade-meta/fuzzer/do_fuzzdesign.py` instead. Please check the file header comments on which are the command-line parameters.

Assuming that this run raises a non-termination or mismatch, you can then run the reduction step through `python3 cascade-meta/fuzzer/do_reducesingle.py`, after setting its `descriptor` variable to the same value as in the fuzzing step.
This will execute all steps from the reduction step onwards and produce two executable files, whose difference reveals the head and tail instructions.

#### Incorporating a new design

To incorporate a new design and fuzz it with Cascade, please take the two following steps:
- Create a design repository, based on the existing design examples. In particular, create a `<design-repo>/cascade/meta` directory that a few essential configuration information for Cascade. You will have to create the `make run_vanilla_notrace`. You may, but do not have to, adapt `cascade-meta/fuzzer/cascade/fuzzsim.py` according to your needs.
- Add an entry with the name of your choice in `cascade-meta/design-processing/design_repos.json`.
