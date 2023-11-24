#!/bin/bash
# PhyDLL installation to JURECA-DC
# PhyDLL source can be found at https://gitlab.com/cerfacs/phydl

# get phydll 0.2.0
git clone https://gitlab.com/cerfacs/phydll -b release/0.2
pushd phydll

# create installation folder
mkdir -p ../PHYDLL
export BUILD=$(realpath ../PHYDLL)

# load modules (here is for JURECA-DC)
ml GCC OpenMPI Python CMake mpi4py MPI-settings/CUDA
ml
export CC=mpicc

# create python env
python3 -m venv envPL
source $PWD/envPL/bin/activate

# install PhyDLL
make CC=$CC BUILD=../PHYDLL ENABLE_PYTHON=ON 

# test PhyDLL (skip this, or use modified MakeFile)
# make CC=$CC BUILD=../PHYDLL ENABLE_PYTHON=ON install

# copy tutorials
cp -r ./test/t0_nc ../tutorial

# link missing lib to the envPL
popd 
ln -s $PWD/PHYDLL/src/python/pyphydll $PWD/envPL/lib/python3.11/site-packages

pushd tutorial

# eof
