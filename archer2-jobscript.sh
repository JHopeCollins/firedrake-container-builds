#!/bin/bash
#
#SBATCH --account=e781
#SBATCH --partition=standard
#SBATCH --qos=standard

#SBATCH --job-name=baroclinic_wave_nc6_nl4_dt100_tm008_p1

#SBATCH --output=results/slurm-%x-%j.out
#SBATCH --error=results/slurm-%x-%j.out
#
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
####SBATCH --switches=1
#
#SBATCH --distribution=block:block
#
#SBATCH --hint=nomultithread
#
#SBATCH --exclusive
#SBATCH --requeue
#
#SBATCH --time 01:30:00
#SBATCH --mail-type=ALL

# print commands
set -x

### === ---
### === --- User inputs --- === ###
### === ---

JOBCODE=${SLURM_JOB_NAME}-${SLURM_JOB_ID}
JOBDIR=results/${JOBCODE}
mkdir -p ${JOBDIR}

ERRLOG=${JOBDIR}/err-${JOBCODE}.log

# jobscript.sh must be submitted from the top level asQ/ directory

### --- scripts

export GUSTO_LOG_LEVEL="DEBUG"
export GUSTO_PARALLEL_LOG="FILE"

python_script="dry_baroclinic_sphere.py"
script_args="--ncell_per_edge=6 --nlayers=4 --dt=100 --tmax=300 --dumpfreq=10 --dirname=${JOBDIR}"
# Ulrich 2014 resolution
# script_args="--ncell_per_edge=30 --nlayers=10 --dt=1200 --tmax=864000 --dumpfreq=10 --dirname=${JOBDIR}"

### --- script arguments which are used by multiple scripts
# e.g. output directories

flamelog_file="${JOBDIR}/flamelog-${JOBCODE}.txt"

extra_script_args="--show_args -log_view :${flamelog_file}:ascii_flamegraph -options_left 0"

### --- srun configuration

# Only use $l3cores cores per L3 cache (up to 4 cores/cache).
l3cores=2

# any extra arguments to srun
srun_args=""

# Change this to select e.g. real or complex firedrake containers
singularity_container="$SIFDIR/firedrake-archer2-gusto.sif"

### === --- You should not need to change anything below this line in most cases --- === ###

### === ---
### === --- Default inputs --- === ###
### === ---

# where are the singularity files?
export SIFDIR="/work/e781/shared/firedrake-singularity"
singularity_container_path="${SIFDIR}/${singularity_container}"

# L3 cache is the lowest level of shared memory, with 4 cores per cache
# and 32 L3 caches per node. Using fewer than 4 cores/L3 cache may improve
# strong scaling performance for memory bound applications.
# The ntasks-per-node value must be 32*l3cores.
nodesize=128
l3size=4
cpu_map=$(python3 -c "print(','.join(map(str,filter(lambda i: i%${l3size}<${l3cores}, range(${nodesize})))))")

# cpu mapping for L3 cache usage and make sure we do not use any shared memory/hyperthreading
default_srun_args="--hint=nomultithread --cpu_bind=map_cpu:${cpu_map}"

# mount the current directory with read-write access in the container
singularity_args="--bind $PWD:/home/firedrake/work --home $PWD"

# use the container python
python_cmd="/home/firedrake/firedrake/bin/python"

### === ---
### === --- Some job info for debugging --- === ###
### === ---

set +x
echo -e "Job started at " `date`
echo -e "\n"

echo "What job is running?"
echo SLURM_JOB_ID          = $SLURM_JOB_ID
echo SLURM_JOB_NAME        = $SLURM_JOB_NAME
echo SLURM_JOB_ACCOUNT     = $SLURM_JOB_ACCOUNT
echo -e "\n"

echo "Where is the job running?"
echo SLURM_CLUSTER_NAME    = $SLURM_CLUSTER_NAME
echo SLURM_JOB_PARTITION   = $SLURM_JOB_PARTITION
echo SLURM_JOB_QOS         = $SLURM_JOB_QOS
echo SLURM_SUBMIT_DIR      = $SLURM_SUBMIT_DIR
echo -e "\n"

echo "What are we running on?"
echo SLURM_DISTRIBUTION    = $SLURM_DISTRIBUTION
echo SLURM_NTASKS          = $SLURM_NTASKS
echo SLURM_NTASKS_PER_NODE = $SLURM_NTASKS_PER_NODE
echo SLURM_JOB_NUM_NODES   = $SLURM_JOB_NUM_NODES
echo SLURM_JOB_NODELIST    = $SLURM_JOB_NODELIST
echo -e "\n"

# set up the modules and environment
set -x
source $SIFDIR/singularity_setup.sh

# module load craype-network-ucx
# module load cray-mpich-ucx

### === ---
### === --- Check the rank layout --- === ###
### === ---

export MPICH_ENV_DISPLAY=1
set +x
echo module load xthi
module load xthi
set -x
srun $default_srun_args $srun_args xthi > ${JOBDIR}/xthi.log 2>&1
unset MPICH_ENV_DISPLAY

### === ---
### === --- Run the script --- === ###
### === ---

tmp_script="${JOBCODE}.py"

cp $python_script ./$tmp_script

set +x
echo -e "Script start time: " `date`
echo -e "\n"

set -x
srun $default_srun_args $srun_args \
   singularity run $singularity_args $singularity_container_path \
   $python_cmd -Wignore ./$tmp_script $extra_script_args $script_args

rm ./$tmp_script

set +x
echo -e "\nScript end time: " `date`
