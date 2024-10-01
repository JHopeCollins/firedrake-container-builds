cat <<EOF >.gitconfig
[safe]
   directory = *
EOF

# set environment variables inside the Singularity container for firedrake et al.
export SINGULARITYENV_OMP_NUM_THREADS=1
# echo ""

export SINGULARITYENV_PYOP2_CC=/home/firedrake/firedrake/bin/mpicc
export SINGULARITYENV_PYOP2_CXX=/home/firedrake/firedrake/bin/mpicxx
# echo ""

# create caches in the directory that the container is run from,
# assuming `--bind $PWD:/home/firedrake/work` was passed to `singularity run`
export SINGULARITYENV_PYOP2_CACHE_DIR=/home/firedrake/work/.cache/pyop2
export SINGULARITYENV_FIREDRAKE_TSFC_KERNEL_CACHE_DIR=/home/firedrake/work/.cache/tsfc
