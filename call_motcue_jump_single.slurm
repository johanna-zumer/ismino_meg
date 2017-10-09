#!/bin/bash
#SBATCH --ntasks 7
#SBATCH --qos bbdefault
#SBATCH --job-name mc_ca
#SBATCH --mem 16G # 4GB
#SBATcH --mem-per-cpu 16G
#SBATCH --time 1:00:00
#SBATCH --mail-type=NONE  #ALL
#SBATCH --get-user-env
#SBATCH --export=NONE
#SBATCH --account=zumerj01

# Because --export=NONE is set, we need to unset
# SLURM_EXPORT_ENV, otherwise multi-node MPI jobs will fail

unset SLURM_EXPORT_ENV
set -e
module purge; module load bluebear
module load apps/matlab/r2016a

matlab -nodisplay -r "motcue_jump($SUBID)"

