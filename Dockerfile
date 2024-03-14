# Copyright 2023 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl gnupg apt-utils && \
    apt-get install -y apt-transport-https curl gnupg git perl python3 make autoconf g++ flex bison ccache libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlib1g zlib1g-dev \
    autoconf automake autotools-dev libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
    bison flex texinfo gperf libtool patchutils bc zlib1g-dev git perl python3 python3.10-venv make g++ libfl2 \
    libfl-dev zlib1g zlib1g-dev git autoconf flex bison gtkwave clang \
    tcl-dev libreadline-dev jq libexpat-dev device-tree-compiler vim \
    software-properties-common default-jdk default-jre gengetopt patch diffstat texi2html subversion chrpath wget libgtk-3-dev gettext python3-pip python3.8-dev rsync libguestfs-tools expat \
    libexpat1-dev libusb-dev libncurses5-dev cmake help2man && \
    apt-get install apt-transport-https curl gnupg -yqq

RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get install -y openjdk-8-jre && update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 111111 && \
    apt-get install -y openjdk-8-jdk && update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac 111111 && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import && \
    chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg && \
    apt-get update && apt-get install sbt

# Install oh my zsh and some convenience plugins
RUN apt-get install -y zsh && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
RUN sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' /root/.zshrc

# Install RISC-V toolchain
RUN apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build
ENV RISCV="/opt/riscv"
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && git checkout 2023.06.09 && ./configure --prefix=/opt/riscv --enable-multilib && make -j 200
ENV PATH="$PATH:/opt/riscv/bin"

# Install spike
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git
RUN cd riscv-isa-sim && mkdir build && cd build && ../configure --prefix=$RISCV && make -j 200 && make install

RUN git clone https://github.com/cascade-artifacts-designs/cascade-yosys /cascade-yosys
RUN cd cascade-yosys && make -j 200 && make install

# Some environment variables
ENV PREFIX_CASCADE="$HOME/prefix-cascade"
ENV CARGO_HOME=$PREFIX_CASCADE/.cargo
ENV RUSTUP_HOME=$PREFIX_CASCADE/.rustup

ENV RUSTEXEC="$CARGO_HOME/bin/rustc"
ENV RUSTUPEXEC="$CARGO_HOME/bin/rustup"
ENV CARGOEXEC="$CARGO_HOME/bin/cargo"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Morty
RUN $CARGOEXEC install --force morty --root $PREFIX_CASCADE

# Install Bender
RUN $CARGOEXEC install --force bender --root $PREFIX_CASCADE

# Install fusesoc
RUN pip3 install fusesoc

# Install stack
RUN curl -sSL https://get.haskellstack.org/ | sh

# Install sv2v
RUN git clone https://github.com/zachjs/sv2v.git && cd sv2v && git checkout v0.0.11 && make -j 200 && mkdir -p $PREFIX_CASCADE/bin/ && cp bin/sv2v $PREFIX_CASCADE/bin

# Install some Python dependencies
RUN pip3 install tqdm

# Install makeelf
RUN git clone https://github.com/flaviens/makeelf && cd makeelf && git checkout finercontrol && python3 setup.py install

# Install miniconda
RUN mkdir -p miniconda && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda/miniconda.sh \
		&& cd miniconda/ && bash miniconda.sh -u -b -p $PREFIX_CASCADE/miniconda \
		&& $PREFIX_CASCADE/miniconda/bin/conda update -y -n base -c defaults conda \
		&& $PREFIX_CASCADE/miniconda/bin/conda config --add channels conda-forge \
		&& $PREFIX_CASCADE/miniconda/bin/conda config --set channel_priority strict

# Install Verilator
RUN git clone https://github.com/verilator/verilator && cd verilator && git checkout v5.006 && autoconf && ./configure && make -j 200 && make install

##
# Design repositories
##

RUN echo "Cloning the repositories!"

RUN git clone https://github.com/cascade-artifacts-designs/cascade-picorv32
RUN git clone https://github.com/cascade-artifacts-designs/cascade-kronos
RUN git clone https://github.com/cascade-artifacts-designs/cascade-vexriscv --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-cva6 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-chipyard


# Initialize the chipyard repository
RUN bash -c "cd cascade-chipyard && git branch stable && CASCADE_JOBS=250 scripts/init-submodules-no-riscv-tools.sh -f"

# Design repositories with embedded bugs
RUN git clone https://github.com/cascade-artifacts-designs/cascade-cva6-c1 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-cva6-y1 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-chipyard-b1

# Make sure to fix the BOOM bug
RUN sed -i 's/r_buffer_fin.rm := io.fcsr_rm/r_buffer_fin.rm := Mux(ImmGenRm(io.req.bits.uop.imm_packed) === 7.U, io.fcsr_rm, ImmGenRm(io.req.bits.uop.imm_packed))/' /cascade-chipyard/generators/boom/src/main/scala/exu/execution-units/fdiv.scala

RUN git clone https://github.com/cascade-artifacts-designs/cascade-picorv32-p5
RUN git clone https://github.com/cascade-artifacts-designs/cascade-kronos-k1
RUN git clone https://github.com/cascade-artifacts-designs/cascade-kronos-k2

RUN git clone https://github.com/cascade-artifacts-designs/cascade-vexriscv-v1-7 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-vexriscv-v8-9-v15 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-vexriscv-v10-11 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-vexriscv-v12 --recursive
RUN git clone https://github.com/cascade-artifacts-designs/cascade-vexriscv-v13 --recursive

# Initialize the chipyard-b1 repository
RUN bash -c "cd cascade-chipyard-b1 && git branch stable && CASCADE_JOBS=250 scripts/init-submodules-no-riscv-tools.sh -f"

RUN git clone https://github.com/cascade-artifacts-designs/cascade-meta --recursive

# Set the design repo locations correctly for the Docker environment
COPY design_repos.json /cascade-meta/design-processing/design_repos.json

ENV PATH="$PATH:$PREFIX_CASCADE/bin"

# Make sure that the Chipyard will support supervisor mode
RUN sed -i 's/useSupervisor: Boolean = false,/useSupervisor: Boolean = true,/' /cascade-chipyard/generators/boom/src/main/scala/common/parameters.scala
RUN sed -i 's/r_buffer_fin.rm := io.fcsr_rm,/r_buffer_fin.rm := Mux(ImmGenRm(io.req.bits.uop.imm_packed) === 7.U, io.fcsr_rm, ImmGenRm(io.req.bits.uop.imm_packed))/' /cascade-chipyard/generators/boom/src/main/scala/exu/execution-units/fdiv.scala
COPY config-mixins.scala /cascade-chipyard/generators/boom/src/main/scala/common
RUN sed -i 's/useSupervisor: Boolean = false,/useSupervisor: Boolean = true,/' /cascade-chipyard-b1/generators/boom/src/main/scala/common/parameters.scala
COPY config-mixins.scala /cascade-chipyard-b1/generators/boom/src/main/scala/common

# Make all non-instrumented designs for Verilator (and the transparently instrumented for bug Y1)
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/design-processing && python3 -u make_all_designs.py"
# A second time to be sure
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/design-processing && python3 -u make_all_designs.py"

RUN pip3 install numpy matplotlib filelock

##
# Program metrics for Cascade
##

# This generates the plots `cascade_prevalences.png` and `cascade_dependencies.png`.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 -u do_analyze_cascade_elfs.py"

##
# Bug bar plots for Cascade
##

# This generates the plots `bug_categories.png` and `security_implications.png`.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_plot_bug_bars.py"

##
# Program reduction performance for Cascade
##

# Make sure vanilla boom was made correctly.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-chipyard/cascade-boom && make run_vanilla_notrace" || true

# Program reduction performance for Cascade. This generates `reduction_perf.png`.
# In particular, many occurrences of `Failed test_run_rtl_single for params` are expected: they precisely correspond to occurrences of bugs found, during the test case generation and during their reduction.
# The final number in the bash command can be changed to add more repetitions. 
# For unknown reasons, this command may not dump the final `reduction_perf.png` file, so we run do_plotevalreduction.py next.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 -u do_evalreduction.py 10"
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_plotevalreduction.py 10"

##
# Performance microbenchmarks for Cascade
##

# This generates `fuzzperf.png`, the microbenchmark for program construction performance.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_fuzzperf.py"

##
# Microbenchmarks for program lengths
##

# Create perf_ubenchmark_fewinstructions.json
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_performance_ubenchmark_fewinstructions.py 0 60 64"
# From perf_ubenchmark_fewinstructions.json, make the 3 plots

RUN bash -c "apt-get update && apt-get install locales && dpkg-reconfigure locales && pip3 install utf8-locale"

# Locales may pose some difficulties in some machines, and are just here for text pretty-printing
RUN sed -i "s/    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')/#    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')/" /cascade-meta/fuzzer/do_plot_fewinstr_genduration_programlength.py
RUN sed -i "s/    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')/#    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')/" /cascade-meta/fuzzer/do_plot_fewinstr_fuzzperf_programlength.py
RUN sed -i "s/    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')/#    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')/" /cascade-meta/fuzzer/do_plot_fewinstr_execperf_programlength.py

# Generate genduration_programlength.png
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_plot_fewinstr_genduration_programlength.py"
# Generate fuzzperf_programlength.png
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_plot_fewinstr_fuzzperf_programlength.py"
# Generate execperf_programlength.png
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_plot_fewinstr_execperf_programlength.py"


##
# Bug detection performance for Cascade
##

# To reproduce the complete figure, this must be set to 1200 (on 64 cores). But this may take multiple days to complete. This smaller timeout value of 30 seconds is already confirming the trend shown in the paper. Feel free to increase it if you have compute time available.
ENV TIMEOUT_SECONS_PER_BUG=30
# This generates `bug_detection_timings.png`, which corresponds to the time required to find each bug.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_timetobug.py 64 10 $TIMEOUT_SECONS_PER_BUG"

##
# Bug detection performance for various program lengths
##

RUN sed -i 's/json.load(open("perf_ubenchmark_fewinstructions.json/json.load(open("bug_timings_curves.json/' /cascade-meta/fuzzer/do_timetobugplot_curves.py

# This generates `bug_timings_curves.png`, which corresponds to the time required to find each bug.
# The parameters must match the parameters given to do_timetobug.py
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_timetobugplot_curves.py 64 10 $TIMEOUT_SECONS_PER_BUG 15"

# Generates bug_detection_timings.png
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_timetobug_boxes.py 64 10"
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_timetobug_boxes_plot.py 64 10"


##
# RFUZZ performance
##

# Prepare the designs to run with the RFUZZ instrumentation and fuzzer.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/design-processing && python3 make_all_designs.py rfuzz && python3 make_all_designs.py drfuzz" || true

# Run the RFUZZ experiment, generates `rfuzz.png`.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_rfuzz.py"

##
# DifuzzRTL
##

# For the control register coverage comparison, we provide the execution trace, since the experiment is very long and generates a large amount of ELFs (in the order of 60000).
# To produce the logs:
# - For DifuzzRTL, run `cd /cascade-difuzzrtl/docker/shareddir/savedockerdifuzzrtl/Fuzzer && make SIM_BUILD=builddir VFILE=RocketTile_state TOPLEVEL=RocketTile NUM_ITER=50000 OUT=outdir_difuzz IS_CASCADE=0 IS_RECORD=0 SPIKE=/opt/riscv/bin/spike`
# - For Cascade, first generate 5000 ELFs using `python3 genmanyelfs.py 5000` in cascade-meta, then apply `python3 cascade_elf_to_hex.py` in cascade-difuzzrtl (by adapting the paths), and finally run `cd /cascade-difuzzrtl/docker/shareddir/savedockerdifuzzrtl/Fuzzer && make SIM_BUILD=builddir VFILE=RocketTile_state TOPLEVEL=RocketTile NUM_ITER=50000 OUT=outdir_cascade IS_CASCADE=1 IS_RECORD=0 SPIKE=/opt/riscv/bin/spike`
# In these "make" recipes, make sure to execute the correct (legacy) versions of cocotb and Verilator
COPY out_rocket_state.log.tgz /
COPY out_rocket_state_cascade.log.tgz /

# Compare the control register coverage. This generates `difuzzrtl_coverage.png`.
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_collect_difuzz_coverage.py"

# Install elf2hex
RUN git clone https://github.com/sifive/elf2hex.git
RUN cd elf2hex && autoreconf -i && ./configure --target=riscv64-unknown-elf && make -j 200 && make install
# Fix some cpp files
RUN sed -i 's/objcopy=""/objcopy="riscv64-unknown-elf-objcopy"/' /usr/local/bin/riscv64-unknown-elf-elf2hex

# Install cocotb
RUN echo "host" | apt install -y make gcc g++ python3 python3-dev python3-pip
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN pip3 install cocotb==1.5.2

# Install verilator-v4.106
RUN rm -rf verilator && git clone https://github.com/verilator/verilator.git && cd verilator && git checkout v4.106 && autoconf && ./configure && make -j200
RUN cd verilator && make install
RUN sed -i 's|#include <utility>|&\n#include <limits>|' /usr/local/share/verilator/include/verilated.cpp

RUN pip3 install psutil sysv_ipc

RUN git clone https://github.com/cascade-artifacts-designs/cascade-difuzzrtl.git

# DifuzzRTL program metrics (Figures 1, 2 and 3)
# Create 500 random ELF files
RUN cd /cascade-difuzzrtl/docker/shareddir/savedockerdifuzzrtl/Fuzzer && make SIM_BUILD=builddir VFILE=RocketTile_state TOPLEVEL=RocketTile NUM_ITER=500 OUT=outdir IS_CASCADE=0 IS_RECORD=1 SPIKE=/opt/riscv/bin/spike

# Analyze the DifuzzRTL program metrics. This generates `difuzzrtl_dependencies.png`, `difuzzrtl_prevalences.png` and `difuzzrtl_completions.png`
RUN bash -c "source /cascade-meta/env.sh && cd /cascade-meta/fuzzer && python3 do_analyze_difuzzrtl_elfs.py 500"

RUN cp /cascade-meta/fuzzer/bug_timings_curves.png /cascade-meta/figures
RUN cp /cascade-meta/fuzzer/execperf_programlength.png /cascade-meta/figures
RUN cp /cascade-meta/fuzzer/fuzzperf_programlength.png /cascade-meta/figures
RUN cp /cascade-meta/fuzzer/genduration_programlength.png /cascade-meta/figures
RUN cp /cascade-data/fuzzperf.png /cascade-meta/figures

# The Questasim results must be generated outside of this container (but using it to generate ELFs), on a machine that has Questasim installed.
