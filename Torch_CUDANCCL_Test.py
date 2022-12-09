'''
simple test script to see if Torch-NCCL is working properly
following: ./Torch_CUDAMPI_Test.py
'''

# libraries
import torch
import torch.distributed as dist

# initialization
dist.init_process_group(backend='nccl')

# world info
lwsize = torch.cuda.device_count() # local world size - per node
gwsize = dist.get_world_size()     # global world size - per run
grank = dist.get_rank()            # global rank - assign per run
lrank = dist.get_rank()%lwsize     # local rank - assign per node
print('DEBUG: local ranks:', lwsize, '/ global ranks:', gwsize)

# define device
device = torch.device('cuda')
torch.cuda.set_device(lrank)

# tensor to device
t = torch.zeros(2,2).fill_(grank).to(device)

# allReduce t using all global ranks
dist.all_reduce(t)

# print something
print(f'rank: {grank}, t: {t}\n')

#eof
