#!/usr/bin/env python

import scipy.io
import scipy.stats as stats
import matplotlib.pyplot as plt
import matplotlib 
import pandas as pd
import numpy as np
import pickle
import csv
import sys

from comline import ComLine
from sklearn.covariance import EllipticEnvelope

input = ComLine(sys.argv[1:])

data = input.args.infile

with open(data) as f:
	reader=csv.reader(f, delimiter='\t')
	next(reader, None) #skip headers
	into_pop, from_pop, n, mean, stdev, km = zip(*reader)

outlier_frac = 0.025
ell = EllipticEnvelope(contamination=outlier_frac)
km = np.array(km)
km = km.astype(np.float)
mean = np.array(mean)
mean = mean.astype(np.float)
mean = -1*(np.log(mean))

X1 = np.vstack((km, mean)).T

print X1.shape
print X1
#ell.fit(X1.astype(float))
ell.fit(X1)

#pred = ell.predict(X1.astype(float))
pred = ell.predict(X1)
total = sum(pred == -1)
print total

#print predicted outliers to file
f = open("outliers.txt", 'w')
fpop = open("outlier_pop_list.txt", 'w')
fpop.write("into from\n")
counter=0
for x in pred:
	f.write(str(x))
	f.write("\n")
	if x == -1:
		fpop.write(into_pop[counter])
		fpop.write(" ")
		fpop.write(from_pop[counter])
		fpop.write("\n")
	counter=counter+1
f.close()

# Get the "thresholding" value from the decision function
threshold = stats.scoreatpercentile(ell.decision_function(X1), 100*outlier_frac)
print threshold

# First make a meshgrid for the (x1, x2) feature space
x1s = np.linspace(np.min(X1[:, 0])-100, np.max(X1[:, 0])+100, 15)
x2s = np.linspace(np.min(X1[:, 1])-1, np.max(X1[:, 1])+1, 15)
x1grid, x2grid = np.meshgrid(x1s, x2s) 

# Now make predictions for each point on the grid 
Xgrid = np.column_stack((x1grid.ravel(), x2grid.ravel()))  # Feature matrix containing all grid points
dens = ell.decision_function(Xgrid)
densgrid = dens.reshape(x1grid.shape)  # Reshape the vector of densities back onto the "grid"

# Use the densites as the "z" values in a contour plot on the grid
fig, ax = plt.subplots()
#snp.labs("distance", "rate", "Outlier Decision Function Contours")
ax.contourf(x1grid, x2grid, densgrid, cmap=plt.cm.Blues_r, levels=np.linspace(dens.min(), threshold, 7))
ax.scatter(X1[:, 0], X1[:, 1], s=4, color="g")

# Pot circles around the predicted outliers
ax.scatter(X1[pred == -1, 0], X1[pred == -1, 1],  
           facecolors="none", edgecolors="red", s=80, label="predicted outliers")
ax.legend(loc="lower right")

fig.savefig('outliers.png')
plt.close(fig)

raise SystemExit
