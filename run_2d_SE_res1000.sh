#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=184G
#SBATCH --cpus-per-task=1
#SBATCH --time=03:00:00
#SBATCH --job-name=2d_res1000
#SBATCH --mail-type=ALL
#SBATCH --mail-user=celia.hein@mail.utoronto.ca
#SBATCH --output=./outfiles/2d_res1000_%A_%a.out
#SBATCH --error=./errfiles/2d_res1000_%A_%a.err
#SBATCH --array=0-8


module load StdEnv/2023
module load gcc/12.3
module load r/4.4.0
module load gdal/3.9.1
module load proj/9.4.1
module load geos/3.12.0
module load udunits/2.2.28
module load julia/1.11.3

#Define parameter values
thetas=(0.1 0.5 0.75)
alphas=(0.02 0.067 0.091)

# Total number of values
num_thetas=${#thetas[@]}
num_alphas=${#alphas[@]}

# Get the index of theta and alpha based on SLURM_ARRAY_TASK_ID
theta_index=$((SLURM_ARRAY_TASK_ID / num_alphas))
alpha_index=$((SLURM_ARRAY_TASK_ID % num_alphas))

theta=${thetas[$theta_index]}
alpha=${alphas[$alpha_index]}

echo "Running job ID $SLURM_ARRAY_TASK_ID with theta=$theta and alpha=$alpha"

# Run the script 
julia ./code/func_SE.jl $theta $alpha
wait

#: "walltime: $SECONDS seconds"
