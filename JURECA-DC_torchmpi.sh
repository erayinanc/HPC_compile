09:10:50 → inanc2 → /p/scratch/raise-ctp2/inanc2 → cat createEnv_MPI.sh
#!/bin/bash
# -*- coding: utf-8 -*-
# info: compiles torch with MPI backend using (mini)Conda
# author: ei
# version: 221117a
# notes: load the same modules, source and activate conda in start script
# test: python3 -c "import torch; print(torch.distributed.is_mpi_available())"
# todo: NVHPC/22.7 failed, try later

# needed jureca-dc modules
ml GCC/11.2.0 OpenMPI/4.1.2 NCCL/2.15.1-1-CUDA-11.5
ml cuDNN/8.3.1.22-CUDA-11.5 libaio/0.3.112
ml Ninja-Python/1.10.2 ccache CMake/3.21.1

# get CUDA version in the system
CUDA_ver="$(echo $EBVERSIONCUDA 2>&1 | tr -d .)"

# miniconda
download=false
if [ -d "$PWD/miniconda3" ];then
  echo "miniconda3 already installed!"
else
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash Miniconda3-latest-Linux-x86_64.sh -p $PWD/miniconda3 -b
  download=true
fi

# enable Conda env
source $PWD/miniconda3/etc/profile.d/conda.sh
conda activate

# conda get external libraries
if [ "$download" = true ] ; then
  # std libs
  conda install -y astunparse numpy pyyaml mkl mkl-include setuptools cffi \
          typing_extensions future six requests dataclasses Pillow --force-reinstall

  # cuda support (v11.5)
  conda install -c pytorch -y magma-cuda$CUDA_ver --force-reinstall
  conda install -y pkg-config libuv --force-reinstall

  # libstdc++.so.6.0.29 lib is missing from conda libs
  # fix 1. copy and link libstdc++.so.6.0.29 to conda
  # fix 2. export LD_LIBRARY_PATH="$EBROOTGCC/lib64:$LD_LIBRARY_PATH"
  # (if fix 2 fails) rm -f $CONDA_PREFIX/lib/libstdc++.so.6
  cp $EBROOTGCC/lib64/libstdc++.so.6.0.29 ${CONDA_PREFIX}/lib/
  pushd ${CONDA_PREFIX}/lib/
  rm -f libstdc++.so.6
  ln -s libstdc++.so.6.0.29 libstdc++.so.6
  popd
fi
echo 'miniconda3 part done!'

# set env variables
export CMAKE_PREFIX_PATH=${CONDA_PREFIX:-"$(dirname $(which conda))/../"}
mkdir -p $PWD/tmp
export TMPDIR=$PWD/tmp
export CUDA_HOME=$CUDA_HOME

# Torch with mpi support (following https://github.com/pytorch/pytorch#from-source)
if [ -d "$PWD/pytorch/build" ];then
   echo 'torch already installed!'
else
   if [ -d "$PWD/pytorch" ];then
      echo 'torch folder found!'
   else
      git clone --recursive https://github.com/pytorch/pytorch torch
   fi
   pushd torch
   ${CONDA_PREFIX}/bin/python3 setup.py clean
   CMAKE_C_COMPILER=$(which mpicc) CMAKE_CXX_COMPILER=$(which mpicxx) \
           USE_DISTRIBUTED=ON USE_MPI=ON CUDA_ROOT_DIR=$EBROOTCUDA USE_CUDA=ON \
           NCCL_ROOT_DIR=$EBROOTNCCL USE_NCCL=ON USE_GLOO=ON \
           CUDNN_ROOT=$EBROOTCUDNN USE_CUDNN=ON \
           ${CONDA_PREFIX}/bin/python3 setup.py install
   popd
fi
echo 'torch part done!'

# TorchVision
if [ -d "$PWD/torchvision/build" ];then
   echo 'torchvision already installed!'
else
   # clone torchvision
   if [ -d "$PWD/torchvision" ];then
      echo 'torchvision folder found!'
   else
      git clone --recursive https://github.com/pytorch/vision.git torchvision
   fi
   pushd torchvision
   ${CONDA_PREFIX}/bin/python3 setup.py clean
   CMAKE_C_COMPILER=$(which mpicc) CMAKE_CXX_COMPILER=$(which mpicxx) FORCE_CUDA=ON \
           ${CONDA_PREFIX}/bin/python3 setup.py install
   popd
fi
echo 'torchvision part done!'

echo 'end'
#eof
