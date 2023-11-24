#!/bin/bash

#SBATCH --job-name=phydll
#SBATCH --partition=dc-gpu-devel
#SBATCH --time=00:05:00
#SBATCH --account=<account>
#SBATCH --output=job.out
#SBATCH --error=job.err
#SBATCH --nodes=2
#SBATCH --gres=gpu:1

# LOAD MODULES ##########
ml GCC OpenMPI Python mpi4py MPI-settings/CUDA
ml
source $PWD/envPL/bin/activate
#########################

# NUMBER OF TASKS #######
export PHY_TASKS_PER_NODE=2
export DL_TASKS_PER_NODE=2
export TASKS_PER_NODE=$(($PHY_TASKS_PER_NODE + $DL_TASKS_PER_NODE))
export NP_PHY=$(($SLURM_NNODES * $PHY_TASKS_PER_NODE))
export NP_DL=$(($SLURM_NNODES * $DL_TASKS_PER_NODE))
#########################

# compile c part
PHYDLL=$PWD/../PHYDLL
mpicc ./phy_main.c -o ./phy.exe -I$PHYDLL/include -L$PHYDLL/lib -lphydll -Wl,-rpath=$PHYDLL/lib

# ENABLE PHYDLL #########
export ENABLE_PHYDLL=TRUE
#########################

# PLACEMENT FILE ########
python $PWD/../phydll/scripts/placement4mpmd.py --Run srun --NpPHY $NP_PHY --NpDL $NP_DL --PHYEXE 'phy.exe' --DLEXE 'python dl_main.py'
machinefile=machinefile_$SLURM_NNODES-$NP_PHY-$NP_DL
chmod +x phydll_mpmd*
chmod +x machinefile*
#########################

# MPMD EXECUTION ########
export SLURM_HOSTFILE=$machinefile
srun -l --kill-on-bad-exit -m arbitrary --multi-prog ./phydll_mpmd_$SLURM_NNODES-$NP_PHY-$NP_DL.conf

#########################
