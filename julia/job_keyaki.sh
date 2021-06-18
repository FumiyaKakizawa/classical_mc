#!/bin/bash
#SBATCH -p defq
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH -J kagome_xy
#SBATCH -o stdout.%J 
#SBATCH -e stderr.%J

module load openmpi/3.1.5/gcc-9.3.0
mpirun -np 1 julia ~/repos/classical_mc/julia/main.jl 2d.ini
