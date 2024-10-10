#!/bin/bash
set -e
# Start the firedrake venv
. /home/firedrake/firedrake/bin/activate

# Set the cache directories if they are not set already
if [ -z ${PYOP2_CACHE_DIR} ]; then
   export PYOP2_CACHE_DIR=${HOME}/.cache/pyop2
fi
if [ -z ${FIREDRAKE_TSFC_KERNEL_CACHE_DIR} ]; then
   export FIREDRAKE_TSFC_KERNEL_CACHE_DIR=${HOME}/.cache/tsfc
fi

# Run in parallel if nprocs is set
if [ ${nprocs} -gt 0 ]; then
   exec mpiexec -np ${nprocs} "$@"
else
   exec "$@"
fi
