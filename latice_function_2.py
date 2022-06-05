import numpy as np
from numpy import arange, linalg as LA
import matplotlib.pyplot as plt
import scipy.io
path=r"C:\Users\thyan\Documents\Swetha my love- files\lattice files\\"
mat = scipy.io.loadmat(path+'lattice2.mat')
lattice1_data = np.array(mat['lattice2'])
n = len(lattice1_data)
distance = np.zeros((n,n))
for i in range(n):
    for j in range(n):
        distance[i,j] = LA.norm(lattice1_data[i] -lattice1_data[j])

n_bins = 100
new_distance = np.reshape(distance,(n*n))
n_r, bin_edges = np.histogram(new_distance, bins=n_bins)
bin_edges
bin_len = bin_edges[2] - bin_edges[1]
r = (bin_edges[1:] + bin_edges[:-1])/2
denom = (2*3.14*bin_len*n)*r
g_r = np.divide(n_r, denom)
n_r, bins, patches = plt.hist(x=new_distance, bins=n_bins, color='#0504aa', rwidth=0.9)
plt.grid(axis='y', alpha=0.75)
plt.xlabel('Value')
plt.ylabel('Frequency')
plt.title('My Very Own Histogram')
maxfreq = n_r.max()
print(bins)
# Set a clean upper y-axis limit.
plt.ylim(ymax=np.ceil(maxfreq / 10) * 10 if maxfreq % 10 else maxfreq + 10)
plt.show()

