#!/bin/bash
# -*- coding: utf-8 -*-
# info: compiles torch with MPI backend using (mini)Conda
# author: ei
# version: 221006a
# notes: load the same modules, source and activate conda in start script
# test: python3 -c "import torch; print(torch.distributed.is_mpi_available())"
# todo: NVHPC/22.7 could also work, test if needed

# needed jureca-dc modules
ml --force purge
ml Stages/2022 GCC/11.2.0 ParaStationMPI/5.5.0-1 NCCL/2.12.7-1-CUDA-11.5
ml cuDNN/8.3.1.22-CUDA-11.5 libaio/0.3.112 mpi-settings/CUDA CMake/3.21.1
ml Ninja-Python/1.10.2

# CUDA version in the system
CUDA_ver="$(echo $EBVERSIONCUDA 2>&1 | tr -d .)"

# miniconda
if [ -d "$PWD/miniconda3" ];then
   echo "miniconda3 is already installed!"
   source $PWD/miniconda3/etc/profile.d/conda.sh
   conda activate
else
   # compile
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh -p $PWD/miniconda3 -b
   source $PWD/miniconda3/etc/profile.d/conda.sh
   conda activate

   # get std libs
   conda install -y astunparse numpy pyyaml mkl mkl-include setuptools cffi \
           typing_extensions future six requests dataclasses Pillow --force-reinstall

   # get cuda support (v11.5)
   conda install -c pytorch -y magma-cuda$CUDA_ver --force-reinstall
   conda install -y pkg-config libuv --force-reinstall
fi
echo 'part 1 done!'

# PyTorch with mpi support (following https://github.com/pytorch/pytorch#from-source)
if [ -d "$PWD/pytorch/build" ];then
   echo 'PyTorch is already installed!'
else
   git clone --recursive https://github.com/pytorch/pytorch pytorch
   pushd pytorch
   git submodule sync
   git submodule update --init --recursive

   # install pytorch with custom flags
   export CMAKE_PREFIX_PATH=${CONDA_PREFIX:-"$(dirname $(which conda))/../"}
   mkdir tmp
   export TMPDIR=$PWD/tmp
   export CUDA_HOME=$CUDA_HOME
   python setup.py clean
   CMAKE_C_COMPILER=$(which mpicc) CMAKE_CXX_COMPILER=$(which mpicxx) \
           USE_DISTRIBUTED=ON USE_MPI=ON CUDA_ROOT_DIR=$EBROOTCUDA USE_CUDA=ON \
           NCCL_ROOT_DIR=$EBROOTNCCL USE_NCCL=ON USE_GLOO=ON \
           CUDNN_ROOT=$EBROOTCUDNN USE_CUDNN=ON \
           python setup.py install
   popd
fi
echo 'part 2 done!'

# libstdc++.so.6.0.29 lib is missing from conda libs
# fix 1. copy and link libstdc++.so.6.0.29 to conda
# fix 2. export LD_LIBRARY_PATH="$EBROOTGCC/lib64:$LD_LIBRARY_PATH"
# (if fix 2 fails) rm -f $CONDA_PREFIX/lib/libstdc++.so.6
cp $EBROOTGCC/lib64/libstdc++.so.6.0.29 $CONDA_PREFIX/lib/
pushd $CONDA_PREFIX/lib/
ln -s libstdc++.so.6.0.29 libstdc++.so.6
popd

#eof
