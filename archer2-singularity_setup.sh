set +x
echo module purge
module purge

echo module load load-epcc-module
module load load-epcc-module

#echo module load cpe/22.12
#module load cpe/22.12
echo module load PrgEnv-gnu
module load PrgEnv-gnu

echo module swap cray-mpich cray-mpich-abi
module swap cray-mpich cray-mpich-abi
echo module load cray-dsmml
module load cray-dsmml
echo module load cray-libsci
module load cray-libsci
echo module load xpmem
module load xpmem

echo module list
module list

set -x
cat <<EOF >.gitconfig
[safe]
   directory = *
EOF
# cat .gitconfig

set +x
# Set the LD_LIBRARY_PATH environment variable within the Singularity container
# to ensure that it used the correct MPI libraries.
export SINGULARITYENV_LD_LIBRARY_PATH="/opt/cray/pe/mpich/8.1.23/ofi/gnu/9.1/lib-abi-mpich:/opt/cray/pe/mpich/8.1.23/gtl/lib:/opt/cray/libfabric/1.12.1.2.2.0.0/lib64:/opt/cray/pe/gcc-libs:/opt/cray/pe/gcc-libs:/opt/cray/pe/lib64:/opt/cray/pe/lib64:/opt/cray/xpmem/default/lib64:/usr/lib64/libibverbs:/usr/lib64:/usr/lib64"
# echo ""

# This makes sure HPE Cray Slingshot interconnect libraries are available
# from inside the container.
export SINGULARITY_BIND="/opt/cray,/var/spool,/opt/cray/pe/mpich/8.1.23/ofi/gnu/9.1/lib-abi-mpich:/opt/cray/pe/mpich/8.1.23/gtl/lib,/etc/host.conf,/etc/libibverbs.d/mlx5.driver,/etc/libnl/classid,/etc/resolv.conf,/opt/cray/libfabric/1.12.1.2.2.0.0/lib64/libfabric.so.1,/opt/cray/pe/gcc-libs/libatomic.so.1,/opt/cray/pe/gcc-libs/libgcc_s.so.1,/opt/cray/pe/gcc-libs/libgfortran.so.5,/opt/cray/pe/gcc-libs/libquadmath.so.0,/opt/cray/pe/lib64/libpals.so.0,/opt/cray/pe/lib64/libpmi2.so.0,/opt/cray/pe/lib64/libpmi.so.0,/opt/cray/xpmem/default/lib64/libxpmem.so.0,/run/munge/munge.socket.2,/usr/lib64/libibverbs/libmlx5-rdmav34.so,/usr/lib64/libibverbs.so.1,/usr/lib64/libkeyutils.so.1,/usr/lib64/liblnetconfig.so.4,/usr/lib64/liblustreapi.so,/usr/lib64/libmunge.so.2,/usr/lib64/libnl-3.so.200,/usr/lib64/libnl-genl-3.so.200,/usr/lib64/libnl-route-3.so.200,/usr/lib64/librdmacm.so.1,/usr/lib64/libyaml-0.so.2"
# echo ""

# set environment variables inside the Singularity container for firedrake et al.
export SINGULARITYENV_OMP_NUM_THREADS=1
# echo ""

export SINGULARITYENV_PYOP2_CC=/home/firedrake/firedrake/bin/mpicc
export SINGULARITYENV_PYOP2_CXX=/home/firedrake/firedrake/bin/mpicxx
# echo ""

# save caches to temporary folder on the node
# export SINGULARITYENV_PYOP2_CACHE_DIR=/tmp/$USER/pyop2
# export SINGULARITYENV_FIREDRAKE_TSFC_KERNEL_CACHE_DIR=/tmp/$USER/tsfc

# create caches in the directory that the container is run from,
# assuming `--bind $PWD:/home/firedrake/work` was passed to `singularity run`
export SINGULARITYENV_PYOP2_CACHE_DIR=/home/firedrake/work/.cache/pyop2
export SINGULARITYENV_FIREDRAKE_TSFC_KERNEL_CACHE_DIR=/home/firedrake/work/.cache/tsfc
# echo ""
