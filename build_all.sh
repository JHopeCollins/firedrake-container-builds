#!/bin/bash
set -x

NONROOT_USER=joshua
FIREDRAKE_TAG=archer2
PETSC_TAG=archer2

# # # --- Do not usually need changing --- # # #
# docker containers have name:tag format
PETSC_CONTAINER=petsc:${PETSC_TAG}
FIREDRAKE_CONTAINER=firedrake:${FIREDRAKE_TAG}

# strings we can use for files without ":"
PETSC_STR=petsc-${PETSC_TAG}
FIREDRAKE_STR=firedrake-${FIREDRAKE_TAG}
# # # ------------------------------------ # # #

# --no-cache makes sure that the docker containers are always
# rebuilt even if the dockerfile hasn't changed. This is so
# that we still pick up changes to the remote git repos.

# Each container is given a second tag "latest" as well as the
# specific tag so if wanted we can just use the last one built
# instead of having to specify a particular one each time.

# An empty directory is given as the environment otherwise we
# risk mopping up everything in $PWD into the container.

date; time docker build \
   `# configure with these args` \
   --build-arg BUILD_ARCH=x86-64 \
   --build-arg BUILD_MAKE_NP=30 \
   --build-arg BUILD_DEBUG=0 \
   --build-arg MPICH_DOWNLOAD_VERSION=3.4.3 \
   --build-arg MPICH_DOWNLOAD_DEVICE=ch4:ofi \
   --build-arg EXTRA_PACKAGES="" \
   --build-arg PETSC_EXTRA_ARGS="" \
   --build-arg PETSC_SCALAR_TYPE="real" \
   `# shouldn't need to change these args` \
   --no-cache  `# force rebuild` \
   --tag=${PETSC_CONTAINER} \
   --tag=petsc:latest \
   --file=dockerfile.petsc-env \
   emptydir  `# empty build context` \
   2>&1| tee build-logs/${PETSC_STR}_docker-build.log

date; time docker build \
   `# configure with these args` \
   --build-arg FIREDRAKE_BRANCH="master" \
   --build-arg FIREDRAKE_EXTRA_ARGS="--mpi4py-version=3.1.6 --pip-install siphash24 --no-vtk" \
   `# shouldn't need to change these args` \
   --no-cache  `# force full rebuild` \
   --build-arg PETSC_CONTAINER=${PETSC_CONTAINER} \
   --tag=${FIREDRAKE_CONTAINER} \
   --tag=firedrake:latest \
   --file=dockerfile.firedrake \
   emptydir `# empty build context` \
   2>&1| tee build-logs/${FIREDRAKE_STR}_docker-build.log

# # # --- Does not usually need changing --- # # #
date; time singularity build --force \
   ${FIREDRAKE_STR}.sif \
   docker-daemon://${FIREDRAKE_CONTAINER} \
   2>&1| tee build-logs/${FIREDRAKE_STR}_singularity-build.log
# # # ------------------------------------ # # #

# this script must be run as root for the docker builds
# so the log files are root owned unless we do this.
chown -R ${NONROOT_USER}:${NONROOT_USER} build-logs/

set +x
