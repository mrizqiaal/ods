# -*- coding: utf-8 -*-
"""
Created on Thu Nov 17 16:37:26 2016

@author: Kadek
"""

import numba as nb
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import cv2 as cv
import timeit as exe


def getP0(img):
   row, col = img.shape
   
   for x in range(0,row):
      for y in range(0,col):
         if (img[x,y] == 0):
            return [x,y]


def getMooreMat(mooreMat, p, b):
   idx = 0
   
   for i in mooreMat:
      px = [p[0] + i[0], p[1] + i[1]]
      if (px == b):
         break
      idx += 1
      
   mooreMat2 = mooreMat[idx+1:]
   mooreMat2.extend(mooreMat[0:idx+1])
   
   return mooreMat2

   
def getFirstNeighboor(img, p, mooreMat2):
   row, col = img.shape
   
   for i in mooreMat2:
      px = [p[0] + i[0], p[1] + i[1]]
      if ((px[0] >= 0 and px[0] < row) and (px[1] >= 0 and px[1] < col)):
         if (img[px[0],px[1]] == 0):
            return px

            
def boundary(img):
   mooreMat = [[-1,0],[-1,1],[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1]]
   row, col = img.shape
   img2 = np.zeros_like(img)
   p0 = getP0(img)
   b = [p0[0],p0[1]-1]
   p = [p0[0],p0[1]]

   while (True):
      #print(p)
      img2[p[0],p[1]] = 255
      mooreMat2 = getMooreMat(mooreMat, p, b)
      b = getFirstNeighboor(img, p, mooreMat2)
      ptemp = p
      p = b
      b = ptemp
      
      if (p == p0):
         break
   
   print(img2)
   return img2
   
   
def getCentroid(img):
   row, col = img.shape
   
   xVal = 0
   yVal = 0
   n = 0.0
   
   for x in range(0,row):
      for y in range(0,col):
         if (img[x,y] == 0):
            xVal += x
            yVal += y
            n += 1.0
            
   xVal /= n
   yVal /= n
   
   return [np.int64(np.round(xVal)),np.int64(np.round(yVal))]


@nb.jit(nb.typeof(np.matrix([[],[]],np.uint8))(nb.typeof(np.matrix([[],[]],np.uint8)), nb.typeof([1,1]), nb.float64))
def createLine(img, centroid, alpha):
   img2 = np.copy(img)
   row, col = img.shape
   
   xVal = np.float64(centroid[0])
   yVal = np.float64(centroid[1])
   
   distance = -1
   distanceTemp = 0
   
   while ((xVal >= 0 and xVal < row) and (yVal >=0 and yVal < col)):
      #print(xVal,yVal)
      img2[np.int64(np.floor(xVal)),np.int64(np.floor(yVal))] = 100
      if (img[np.int64(np.floor(xVal)),np.int64(np.floor(yVal))] == 0):
         distance += distanceTemp + 1
         distanceTemp = 0
      else:
         distanceTemp += 1
      #xVal += np.int64(np.round(-np.sin(alpha*np.pi/180.0)))
      xVal += (-np.sin(np.deg2rad(alpha)))
      #yVal += np.int64(np.round(np.cos(alpha*np.pi/180.0)))
      yVal += (np.cos(np.deg2rad(alpha)))
      
   return img2
   
   
@nb.jit(nb.int64(nb.typeof(np.matrix([[],[]],np.uint8)), nb.typeof([1,1]), nb.float64))
def getDistanceAngle(img, centroid, alpha):
   row, col = img.shape
   xVal = np.float64(centroid[0])
   yVal = np.float64(centroid[1])
   
   distance = -1
   distanceTemp = 0
   
   while ((xVal >= 0 and xVal < row) and (yVal >=0 and yVal < col)):
      if (img[np.int64(np.floor(xVal)),np.int64(np.floor(yVal))] == 0):
         distance += distanceTemp + 1
         distanceTemp = 0
      else:
         distanceTemp += 1
      #xVal += np.int64(np.round(-np.sin(alpha*np.pi/180.0)))
      xVal += (-np.sin(np.deg2rad(alpha)))
      #yVal += np.int64(np.round(np.cos(alpha*np.pi/180.0)))
      yVal += (np.cos(np.deg2rad(alpha)))
   
   return distance
   
   
#@nb.jit(nb.int64(nb.typeof(np.matrix([[],[]],np.uint8)), nb.typeof([1,1]), nb.float64))
def getDistanceAngle2(img, centroid, alpha):
   row, col = img.shape
   xVal = np.float64(centroid[0])
   yVal = np.float64(centroid[1])
   x1 = centroid[0]
   y1 = centroid[1]

   x2 = x1
   y2 = y1
   
   distance = 0.0
   
   boundary = False
   while ((xVal >= 0 and xVal < row) and (yVal >=0 and yVal < col)):
   #while (boundary == False):
      xTemp = np.int64(xVal)
      yTemp = np.int64(yVal)
      if (img[xTemp,yTemp] == 0):
         x2 = xTemp
         y2 = yTemp
      else:
         boundary = True
      #xVal += np.int64(np.round(-np.sin(alpha*np.pi/180.0)))
      xVal += (-np.sin(np.deg2rad(alpha)))
      #yVal += np.int64(np.round(np.cos(alpha*np.pi/180.0)))
      yVal += (np.cos(np.deg2rad(alpha)))
   
   distance = np.int64(np.round(np.sqrt(np.power(x2 - x1, 2) + np.power(y2 - y1, 2))))
   return distance
   

def getSignature(img, centroid, delta):
   alpha = 0.0
   signature = []
   
   while (alpha < 360.0):
      signature.append(getDistanceAngle2(img, centroid, alpha))
      alpha += delta
      
   return signature
   
   
def normalization(signature, th):   
   maxIdx = np.argmax(signature)
   sortSig = signature[maxIdx:]
   sortSig.extend(signature[0:maxIdx])
   print(sortSig)
   
   normSig = []
   maxSig = np.float64(np.max(signature))
   minSig = np.float64(np.min(signature))

   for s in sortSig:
      distance = ((np.float64(s) - minSig) / (maxSig - minSig)) * th
      normSig.append(distance)
      
   return normSig
   

def saveTxt(signature, name):
   f = open("log.txt", "w")
   f.write(str(signature))
   f.close()
   

def verifySignature(name, signature):
   f = open(name, "r")
   #print(f.read())
   txt = f.read()
   f.close()
   if (str(signature) == txt):
      return True
   else:
      return False
      
      
def main():
   
   #img = cv.imread("C:/Users/Kadek/Documents/MATLAB/leaf.jpg")
   img = cv.imread("cartridge-scale.jpg")
   #img = cv.imread("cartridge-rotate.jpg")
   img = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
   #histEq = cv.equalizeHist(img)
   #img = histEq
   #img = cv.resize(img, (300,200))
   """
   
   img = np.matrix([[1,1,1,1,1,1,1,1,1,1,1],
                    [1,1,1,0,0,0,0,0,1,1,1],
                    [1,1,1,0,0,0,0,0,1,1,1],
                    [1,1,1,0,0,0,0,0,1,1,1],
                    [1,1,1,1,1,1,1,1,1,1,1]
                    ])
   """
   
   #otsu = img
   th, otsu = cv.threshold(img, 0, 255, cv.THRESH_OTSU)
   img = otsu
   img = cv.copyMakeBorder(img,1,1,1,1,cv.BORDER_CONSTANT,value=255)
   img = boundary(otsu)

   centroid = getCentroid(img)
   print(centroid)
   
   signature = getSignature(img, centroid, 40.0)
   normalized = normalization(signature, 100.0)
   #line = createLine(otsu, centroid, 90.0)
   print(signature)
   print(len(signature))
   print(normalized)
   print(len(normalized))
   
   #saveTxt(normalized, "log.txt")
   #print(verifySignature("log.txt", normalized))
   #pk.dump(signature, open("log.txt", "wb"))
   
   otsu[centroid[0],centroid[1]] = 100
   plt.imshow(img, cmap = cm.Greys_r)
   

start = exe.default_timer()
main()
end = exe.default_timer()
exeTime = end - start
print(exeTime)