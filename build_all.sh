#!/bin/bash
set -x

NONROOT_USER=joshua
FIREDRAKE_TAG=archer2-ch4ofi
PETSC_TAG=archer2-ch4ofi

# docker containers is name:tag format
PETSC_CONTAINER=petsc:${PETSC_TAG}
FIREDRAKE_CONTAINER=firedrake:${FIREDRAKE_TAG}

# strings we can use for files without ":"
PETSC_STR=petsc-${PETSC_TAG}
FIREDRAKE_STR=firedrake-${FIREDRAKE_TAG}

time docker build \
   --no-cache \
   --build-arg BUILD_ARCH=x86-64 \
   --build-arg BUILD_MAKE_NP=30 \
   --build-arg BUILD_DEBUG=0 \
   --build-arg MPICH_DOWNLOAD_VERSION=3.4.3 \
   --build-arg MPICH_DOWNLOAD_DEVICE=ch4:ofi \
   --build-arg EXTRA_PACKAGES="" \
   --build-arg PETSC_EXTRA_ARGS="" \
   --build-arg PETSC_SCALAR_TYPE="real" \
   --tag=petsc:latest \
   --tag=${PETSC_CONTAINER} \
   --file=dockerfile.petsc-env emptydir \
   | tee build-logs/${PETSC_STR}_docker-build.log

time docker build \
   --no-cache \
   --build-arg FIREDRAKE_BRANCH="JDBetteridge/update_caching" \
   --build-arg FIREDRAKE_EXTRA_ARGS="--package-branch PyOP2 JDBetteridge/remove_comm_hash --pip-install siphash24" \
   --build-arg PETSC_CONTAINER=${PETSC_CONTAINER} \
   --tag=firedrake:latest \
   --tag=${FIREDRAKE_CONTAINER} \
   --file=dockerfile.firedrake emptydir \
   | tee build-logs/${FIREDRAKE_STR}_docker-build.log

time singularity build --force \
   --sandbox ./${FIREDRAKE_STR}_singularity \
   docker-daemon://${FIREDRAKE_CONTAINER} \
   | tee build-logs/${FIREDRAKE_STR}_singularity-sandbox-build.log

time singularity build --force \
   ${FIREDRAKE_STR}.sif \
   ./${FIREDRAKE_STR}_singularity \
   | tee build-logs/${FIREDRAKE_STR}_singularity-image-build.log

# this script must be run as root so the log files are root owned unless we do this
chown -R ${NONROOT_USER}:${NONROOT_USER} build-logs/

set +x
