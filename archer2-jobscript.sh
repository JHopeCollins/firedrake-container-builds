#!/bin/bash
#
#SBATCH --account=e781
#SBATCH --partition=standard
#SBATCH --qos=short
#####SBATCH --array=2-8

#SBATCH --job-name=lswe_ref4_nt00002_dt025
#SBATCH --output=results/tests/slurm-%x-%j.out
#SBATCH --error=results/tests/slurm-%x-%j.out
#
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
####SBATCH --switches=1
#
#SBATCH --distribution=block:block
#
#SBATCH --hint=nomultithread
#
#SBATCH --exclusive
#SBATCH --requeue
#
#SBATCH --time 00:10:00
#SBATCH --mail-type=ALL

# print commands
set -x

### === ---
### === --- User inputs --- === ###
### === ---

JOBCODE=${SLURM_JOB_NAME}-${SLURM_JOB_ID}
JOBDIR=results/tests/${JOBCODE}
mkdir -p ${JOBDIR}

# jobscript.sh must be submitted from the top level asQ/ directory

### --- scripts

python_script="linear_gravity_bumps.py"
script_dir="case_studies/shallow_water"
script_args="--ref_level=4 --dt=0.25 --slice_length=1 --nslices=2"

### --- script arguments which are used by multiple scripts
# e.g. output directories

flamelog_file="${JOBDIR}/flamelog-${JOBCODE}.txt"

script_extra_args="--show_args --metrics_dir ${JOBDIR} -log_view :${flamelog_file}:ascii_flamegraph -options_left 0"

### --- python arguments
# e.g. -Wignore, -u
python_extra_args=""

### --- srun configuration

# Only use $l3cores cores per L3 cache (up to 4 cores/cache).
l3cores=2

# any extra arguments to srun
srun_extra_args=""

### --- singularity configuration

singularity_container="firedrake-archer2.sif"
singularity_extra_args=""

### === --- You should not need to change anything below this line in most cases --- === ###

### === ---
### === --- Default inputs --- === ###
### === ---

# where are the singularity files?
export SIFDIR="/work/e781/shared/firedrake-singularity"

# L3 cache is the lowest level of shared memory, with 4 cores per cache
# and 32 L3 caches per node. Using fewer than 4 cores/L3 cache may improve
# strong scaling performance for memory bound applications.
# The ntasks-per-node value must be 32*l3cores.
nodesize=128
l3size=4
cpu_map=$(python3 -c "print(','.join(map(str,filter(lambda i: i%${l3size}<${l3cores}, range(${nodesize})))))")

# cpu mapping for L3 cache usage and make sure we do not use any shared memory/hyperthreading
srun_args="--hint=nomultithread --cpu_bind=map_cpu:${cpu_map} ${srun_extra_args}"

# mount the current directory with read-write access in the container
singularity_args="--home $PWD:/home/firedrake/work ${singularity_extra_args}"

# concatenate python arguments
script_args="${script_extra_args} ${script_args}"

# full python arguments. Just the user provided ones but this means
# we can easily add defaults later.
python_args="${python_extra_args}"

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
set -x

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
srun $srun_args xthi > ${JOBDIR}/xthi.log 2>&1
unset MPICH_ENV_DISPLAY

### === ---
### === --- Copy files to nodes --- === ###
### === ---

set +x
echo -e "Start copying files to nodes: " `date`
echo -e "\n"
set -x

tmp_script=${JOBCODE}-${python_script}

# save script to job directory
cp $script_dir/$python_script ${JOBDIR}/${tmp_script}
cp $script_dir/$python_script ./${tmp_script}

sbcast --compress=none ${SIFDIR}/$singularity_container /tmp/${singularity_container}

### === ---
### === --- Run the script --- === ###
### === ---

set +x
echo -e "Script start time: " `date`
echo -e "\n"

set -x
srun $srun_args \
   singularity run $singularity_args /tmp/$singularity_container \
   python ${python_args} ./$tmp_script $script_args

rm ./$tmp_script

set +x
echo -e "\nScript end time: " `date`
