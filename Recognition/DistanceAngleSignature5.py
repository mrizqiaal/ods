# -*- coding: utf-8 -*-
"""
Created on Thu Nov 24 20:40:39 2016

@author: Kadek
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import cv2 as cv
import timeit as exe
import json
import pymysql as sql


db = sql.connect("localhost", "root", "admin", "dbcoba")
cursor = db.cursor()


def insertTable(name, columns, values):
   # Function for insert data to a table
   # insertTable("signature", "", "('xyz', 'def')")
   # insertTable("signature", "(sigID, objectType)", "('xyza', 'def')")
   global db, cursor
   
   query = "insert into " + name + " " + columns + " values " + values
   try:
      cursor.execute(query)
      db.commit()
   except:
      db.rollback()
      
      
def readTable(name, columns, param, fetchAll):
   # Function for read data from a table
   # res = readTable("signature", "*", "", True)
   # res = readTable("signature", "sigID, objectType", "where sigID = 'abc'", True)
   global cursor
   
   query = "select " + columns + " from " + name + " " + param
   cursor.execute(query)
   if (fetchAll == True):
      res = cursor.fetchall()
   else:
      res = cursor.fetchone()
      
   return res
   
   
def getP0(img):
   # Get the first object's pixel
   row, col = img.shape
   
   for x in range(0,row):
      for y in range(0,col):
         if (img[x,y] == 0):
            return [x,y]


def getMooreMat(mooreMat, p, b):
   # Modify Moore Matrix Neighborhood to determine
   # the first neighbor to be checked
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
   # Get the next pixel boundary
   row, col = img.shape
   
   for i in mooreMat2:
      px = [p[0] + i[0], p[1] + i[1]]
      if (img[px[0],px[1]] == 0):
         return px

            
def boundary(img):
   # Main function for create a boundary of object
   mooreMat = [[-1,0],[-1,1],[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1]]
   row, col = img.shape
   img2 = np.zeros_like(img)
   p0 = getP0(img)
   b = [p0[0],p0[1]-1]
   p = [p0[0],p0[1]]

   while (True):
      img2[p[0],p[1]] = 255
      mooreMat2 = getMooreMat(mooreMat, p, b)
      b = getFirstNeighboor(img, p, mooreMat2)
      ptemp = p
      p = b
      b = ptemp
      
      if (p == p0):
         break
   
   return img2


def getCentroid(img):
   # Find object centroid
   
   row, col = img.shape
   
   xVal = 0
   yVal = 0
   n = 0.0
   
   for x in range(0,row):
      for y in range(0,col):
         if (img[x,y] == 255):
            xVal += x
            yVal += y
            n += 1.0
            
   xVal /= n
   yVal /= n
   
   return [np.int64(np.round(xVal)),np.int64(np.round(yVal))]


def checkBoundary(img, p):
   # Check whether there is a pixel boundary in neighbor of p
   mooreMat = [[-1,0],[-1,1],[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1]]
   row, col = img.shape
   
   for i in mooreMat:
      px = [p[0] + i[0], p[1] + i[1]]
      if (img[px[0],px[1]] == 255):
         return True
            
   return False
   
   
def getDistanceAngle(img, centroid, alpha):
   # Compute distance from centroid to boundary with specified angle
   
   row, col = img.shape
   
   xVal = np.float64(centroid[0])
   yVal = np.float64(centroid[1])
   x = centroid[0]
   y = centroid[1]
   xInc = (-np.sin(np.deg2rad(alpha)))
   yInc = (np.cos(np.deg2rad(alpha)))
   r = 0
   
   while ((img[x,y] == 0) and (checkBoundary(img, [x,y]) == False)):
      xVal += xInc
      yVal += yInc
      x = np.int64(xVal)
      y = np.int64(yVal)
      
      r += 1
      
   return r-1
   

def getSignature(img, centroid, delta):
   # Get signature of object
   
   alpha = 0.0
   signature = []
   
   while (alpha < 360.0):
      signature.append(getDistanceAngle(img, centroid, alpha))
      alpha += delta
      
   return signature
   
   
def normalization(signature, th):
   # Perform normalization to object signature
   # Deal with object rotation and scaling
   
   # Deal with object rotation
   # Find maximum value in signature
   # Split and merge signature
   # Maximum value moved to the first place
   maxIdx = np.argmax(signature)
   sortSig = signature[maxIdx:]
   sortSig.extend(signature[0:maxIdx])
   
   # Deal with object scaling
   # Find maximum and minimum value
   # Rescale each value to the maximum range (th -> threshold)
   normSig = []
   
   maxSig = np.max(sortSig)
   minSig = np.min(sortSig)
   
   for s in sortSig:
      distTemp = ((s + minSig) / (maxSig + minSig)) * th
      distance = np.int64(np.round(distTemp))
      normSig.append(distance)
      
   return normSig
   
   
def countDifference(sig1, sig2):
   # Compute cumulative difference between signature 1 and signature 2
   diff = 0
   
   for i in range(len(sig1)):
      diff += np.abs(sig1[i] - sig2[i])
      
   return diff
   
   
def classifyObject(sig1):
   # Main function for determine the class of an object
   res = readTable("signature", "*", "", True)
   diff = []

   for i in range(len(res)):
      diff.append(countDifference(sig1, json.loads(res[i][0])))
      
   minDiff = np.argmin(diff)
   print(diff)
   
   return res[minDiff][1]


def addObject():
   # Add objects signature to the database
   global db
   
   img = []
   # kayu
   img.append(cv.imread("IMG_20161117_191705.jpg"))
   # gatsby
   img.append(cv.imread("IMG_20161117_202201.jpg"))
   # dompet
   img.append(cv.imread("IMG_20161117_202102.jpg"))
   # cartridge
   img.append(cv.imread("cartridge.jpg"))
   # palu
   img.append(cv.imread("pnormal.jpg"))
   
   objectName = ["Kayu", "Gatsby", "Dompet", "Cartridge", "Palu"]
   centroid = []
   signature = []
   normalized = []

   for i in range(len(img)):
      img[i] = cv.cvtColor(img[i], cv.COLOR_BGR2GRAY)
      th, otsu = cv.threshold(img[i], 0, 255, cv.THRESH_OTSU)
      img[i] = otsu
      img[i] = cv.copyMakeBorder(img[i],1,1,1,1,cv.BORDER_CONSTANT,value=255)
      img[i] = boundary(img[i])
      centroid.append(getCentroid(img[i]))
      signature.append(getSignature(img[i], centroid[i], 10.0))
      normalized.append(normalization(signature[i], 100.0))
      print(normalized[i])
      insertTable("signature", "", "('" + str(normalized[i]) + "', '" + objectName[i] + "')")
      img[i][centroid[i][0],centroid[i][1]] = 100

   plt.imshow(img[0], cmap = cm.Greys_r)
   db.close()


def getObjectClass():
   # Check class of objects
   global db
   
   img = []
   # kayu
   img.append(cv.imread("IMG_20161117_191721.jpg"))
   img.append(cv.imread("IMG_20161117_192655.jpg"))
   # gatsby
   img.append(cv.imread("IMG_20161117_202213.jpg"))
   img.append(cv.imread("IMG_20161117_202232.jpg"))
   # dompet
   img.append(cv.imread("IMG_20161117_202113.jpg"))
   img.append(cv.imread("IMG_20161117_202128.jpg"))
   # cartridge
   img.append(cv.imread("cartridge-rotate.jpg"))
   img.append(cv.imread("cartridge-scale1.jpg"))
   # palu
   img.append(cv.imread("protate.jpg"))
   img.append(cv.imread("pscale.jpg"))
   
   centroid = []
   signature = []
   normalized = []
   objectClass = []

   for i in range(len(img)):
      img[i] = cv.cvtColor(img[i], cv.COLOR_BGR2GRAY)
      th, otsu = cv.threshold(img[i], 0, 255, cv.THRESH_OTSU)
      img[i] = otsu
      img[i] = cv.copyMakeBorder(img[i],1,1,1,1,cv.BORDER_CONSTANT,value=255)
      img[i] = boundary(img[i])
      centroid.append(getCentroid(img[i]))
      signature.append(getSignature(img[i], centroid[i], 10.0))
      normalized.append(normalization(signature[i], 100.0))
      objectClass.append(classifyObject(normalized[i]))
      print(objectClass[i])
      img[i][centroid[i][0],centroid[i][1]] = 100

   plt.imshow(img[0], cmap = cm.Greys_r)
   db.close()
   
   
start = exe.default_timer()
#addObject()
getObjectClass()
end = exe.default_timer()
exeTime = end - start
print(exeTime)