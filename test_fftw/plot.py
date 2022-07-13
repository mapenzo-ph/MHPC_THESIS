import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt("arrays.txt")
plt.xlabel('x')
plt.plot(data[:,0], data[:,1], label='myfun')
plt.plot(data[:,0], data[:,2], label='exact')
plt.plot(data[:,0], data[:,3], label='myder')
plt.legend(loc='upper right')
plt.tight_layout()
plt.show()