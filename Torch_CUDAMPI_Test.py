'''
simple test script to see if Torch-MPI has CUDA support
following: https://github.com/Stonesjtu/pytorch-learning/blob/master/build-with-mpi.md
'''

# libraries
import torch
import torch.distributed as dist

# initialization
dist.init_process_group(backend='mpi')

# tensor to cuda device
t = torch.zeros(5,5).fill_(dist.get_rank()).cuda()

# allReduce t using all ranks
dist.all_reduce(t)

# print something
print(f'rank: {dist.get_rank()}, t: {t}')

#eof
