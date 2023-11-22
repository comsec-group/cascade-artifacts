## Mapping of the steps in the paper's Figure 3 to the artifact code

The fuzzer code is present in the [cascade-meta](https://github.com/cascade-artifacts-designs/cascade-meta).

### High-level overview

The function `run_rtl` from `cascade.fuzzfromdescriptor` regroups all steps until and including the DUT run.
The function `reduce_program` from `cascade.reduce` regroups the remaining steps, which concern program reduction.

### Step 1: CPU params & calibration

This step is twofold.

#### Parameters

For each design, a small set of parameters such as the supported RISC-V extensions, are exposed by each design repository in the respective `cascade/meta/cfg.json` file, for example [here](https://github.com/cascade-artifacts-designs/cascade-kronos/blob/master/cascade/meta/cfg.json).

#### Calibration

The calibration step aims at (a) calibrating the spike speed to estimate an expected upper bound of valid executions, and (b) finding which delegation bits are supported by the design.
These two steps can be 

The first calibration step (a) is performed by the function `calibrate_spikespeed()`.
The second calibration step (b) is performed by the function `profile_get_medeleg_mask(design_name)`.

### Step 2: Basic block generation

The basic block generation step is performed by the function `gen_basicblocks(fuzzerstate)`, where fuzzerstate is a freshly instantiated `FuzzerState` object.
This function returns the list of basic blocks that is used for the intermediate program in the asymmetric ISA pre-simulation.

### Steps 3 & 4: Asymmetric ISA pre-simulation

The asymmetric ISA pre-simulation is performed by the function `spike_resolution(fuzzerstate)`, where fuzzerstate is the state of the fuzzer after the basic block generation step.
This function is mainly composed of two parts, which represent the steps 3 and 4 of the paper's Figure 3.

#### Step 3: ISS run

The ISS run is itself composed of two main parts.
First, the function `gen_regdump_reqs(fuzzerstate)` generates the register dump requests for the basic blocks in the intermediate program, that will be provided to the ISS for scheduling the architectural dumps at the key points of the program execution. 
Second, the function `run_trace_regs_at_pc_locs()`, based on the register dump requests generated by the previous function, runs the ISS and dumps the architectural register values at the key points of the program execution.

#### Step 4: Feedback integration

Once the feedback is acquired, the function `_feed_regdump_to_instrs(fuzzerstate, regdumps)` is called to integrate the feedback into the program, effectively constructing the ultimate program.

### Step 5: DUT run

The function `runtest_simulator` from `cascade.fuzzsim` runs the ultimate program on the DUT.

### Steps 6+: Analysis

The function `reduce_program` from `cascade.reduce` performs the analysis steps, which are the steps 6+ of the paper's Figure 3.
This function reuses functions used in previous steps, and mostly uses the following functions that reduce the program on both sides: `_find_failing_bb`, `_find_pillar_bb`, `_find_failing_instr_in_bb`, `_find_pillar_instr` .