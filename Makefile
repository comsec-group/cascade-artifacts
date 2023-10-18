# Copyright 2023 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

DOCKER_CASCADE_MOUNTDIR = /cascade-mountdir
# Wherever you want to mount the cascade-mountdir to share the files with the Docker container
LOCAL_CASCADE_MOUNTDIR ?= /scratch/flsolt/dockerrungenelf/cascade-mountdir

IMAGE_TAG ?= ethcomsec/cascade-artifacts

out_rocket_state_cascade.log:
	tar -xzf out_rocket_state_cascade.log.tgz
out_rocket_state.log:
	tar -xzf out_rocket_state.log.tgz

build: out_rocket_state_cascade.log out_rocket_state.log
	# docker build -t $(IMAGE_TAG) .
	docker build -t $(IMAGE_TAG) . 2>&1 | tee build.log

run:
	docker run -it $(IMAGE_TAG)

rungenelf:
	docker run -v $(LOCAL_CASCADE_MOUNTDIR):/$(DOCKER_CASCADE_MOUNTDIR) -it $(IMAGE_TAG) bash -c "source /cascade-meta/env.sh && python3 /cascade-meta/fuzzer/do_genelfs_for_questa.py"

push:
	docker login registry-1.docker.io
	docker push $(IMAGE_TAG)
