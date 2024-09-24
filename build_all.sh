#!/bin/bash
set -x

NONROOT_USER=joshua
FIREDRAKE_NAME=firedrake-archer2-gusto
PETSC_NAME=petsc-env

time docker build \
   --no-cache \
   --build-arg BUILD_ARCH=x86-64 \
   --build-arg BUILD_MAKE_NP=30 \
   --build-arg BUILD_DEBUG=0 \
   --build-arg MPICH_DOWNLOAD_VERSION=3.4.3 \
   --build-arg MPICH_DOWNLOAD_DEVICE=ch3:nemesis \
   --build-arg EXTRA_PACKAGES="" \
   --build-arg PETSC_EXTRA_ARGS="" \
   --build-arg PETSC_SCALAR_TYPE="real" \
   --tag=${PETSC_NAME} \
   --file=dockerfile.petsc-env emptydir \
   | tee build-logs/${PETSC_NAME}-docker-build.log

time docker build \
   --no-cache \
   --build-arg FIREDRAKE_BRANCH="JDBetteridge/update_caching" \
   --build-arg PETSC_CONTAINER=${PETSC_NAME} \
   --build-arg FIREDRAKE_EXTRA_ARGS="--package-branch PyOP2 JDBetteridge/remove_comm_hash --install gusto" \
   --tag=${FIREDRAKE_NAME} \
   --file=dockerfile.firedrake emptydir \
   | tee build-logs/${FIREDRAKE_NAME}-docker-build.log

time singularity build --force \
   --sandbox ./${FIREDRAKE_NAME}-singularity \
   docker-daemon://${FIREDRAKE_NAME}:latest \
   | tee build-logs/${FIREDRAKE_NAME}-singularity-sandbox-build.log

time singularity build --force \
   ${FIREDRAKE_NAME}.sif \
   ./${FIREDRAKE_NAME}-singularity \
   | tee build-logs/${FIREDRAKE_NAME}-singularity-image-build.log

# this script must be run as root so the log files are root owned unless we do this
chown -R ${NONROOT_USER}:${NONROOT_USER} build-logs/

set +x
