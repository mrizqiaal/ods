%boundary bermasalah.

function main
    clc; close all; clear;
    img = imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Representation\coba\a.jpg');
    if (size(img, 3) == 3)
        img = rgb2grayscale(img);
    end
    otsu1T = otsu1threshold(img);
    thImage = segmen1threshold(img, otsu1T);
    boundaryObj = getBoundary(thImage);
    imshow(uint8(boundaryObj));
end

%mengubah citra rgb ke citra grayscale.
function grayscale = rgb2grayscale(img)
    [row, col, ch] = size(img);
    grayscale = zeros(row,col);
    for x=1:row
        for y=1:col
            grayscale(x,y) = 0.2989*img(x,y,1) + 0.587*img(x,y,2) + 0.114*img(x,y,3);
        end
    end
end

%membuat list yang berisi frekuensi dari intensitas setiap pixel.
function hst = hstgram(imgGray)
    hst = zeros(1,256);
    [row, col] = size(imgGray);
    for x=1:row
        for y=1:col
            pixelValue=imgGray(x,y);
            hst(pixelValue+1) = hst(pixelValue+1)+1;
        end
    end
end

%menghitung rata-rata dalam kisaran range tertentu pada histogram.
function hstMean = histMean(hist, startI, endI)
    mean = 0.0;
    n = 0.0;
    for i = startI:endI
        mean = mean + (hist(i)*i);
        n = n + hist(i);
    end
    if n <= 0
        hstMean = 0;
    else
        hstMean = mean/n;
    end
end

%menghitung varian dalam kisaran range tertentu pada histogram.
function hstVar = histVariance(img, hist, startI, endI)
    [row, col] = size(img);
    var = 0.0;
    n = 0.0;
    mean = histMean(hist, startI, endI);
    for i = startI:endI
        var = var + (((i-mean)^2)*hist(i));
        n = n + hist(i);
    end
    weight = n/(row*col);
    if n <= 0
        hstVar = 0;
    else
        hstVar = var/n * weight;
    end
end

%mencari nilai optimum threshold suatu citra.
function otsu1T = otsu1threshold(img)
    varList = [];
    double(varList);
    hist = hstgram(img);
    for i=1:255
        varLeft = histVariance(img, hist, 1, i);
        varRight = histVariance(img, hist, i+1, 256);
        varList(i) = varLeft + varRight;
    end
    minVar = varList(1);
    otsu1T = 2;
    for i=1:254
        if minVar > varList(i)
            minVar = varList(i);
            otsu1T = i+1;
        end
    end
end

%penerapan nilai optimum threshold ke dalam citra.
function thImage = segmen1threshold(img, th)
    [row, col] = size(img);
    thImage = zeros(row,col);
    for x=1:row
        for y=1:col
            pixelValue = img(x,y);
            if pixelValue < th
                thImage(x,y) = 0;
            else
                thImage(x,y) = 255;
            end
        end
    end
end

function firstObj = getP0(img)
    [row, col] = size(img);
    for x=1:row
        for y=1:col
            if img(x,y) == 0
                firstObj = [x y];
            end
        end
    end
end

function mooreMat2 = getMooreMat(mooreMat, p, b)
    idx = 1;
    for i=1:8
        px = [p(1)+mooreMat(i,1), p(2)+mooreMat(i,2)];
        if px == b
            break;
        end
        idx = idx + 1;
    end
    mooreMat2 = mooreMat(idx+1:8,1:2);
    mooreMat2 = [mooreMat2; mooreMat(1:idx,1:2)];
end

function nextPixel = getFirstNeighbor(img, p, mooreMat2)
    [row, col] = size(img);
    for i=1:8
        nextPixel = [p(1)+mooreMat2(i,1), p(2)+mooreMat2(i,2)];
        if img(nextPixel(1),nextPixel(2)) == 0
            break;
        end
    end
end

function boundaryObj = getBoundary(img)
    mooreMat = [-1 0; -1 1; 0 1; 1 1; 1 0; 1 -1; 0 -1; -1 -1];
    [row, col] = size(img);
    boundaryObj = zeros(row,col);
    p0 = getP0(img);
    b = [p0(1), p0(2)-1];
    p = [p0(1), p0(2)];
    while(true)
       boundaryObj(p(1),p(2)) = 255;
       mooreMat2 = getMooreMat(mooreMat, p, b);
       b = getFirstNeighbor(img, p, mooreMat2);
       ptemp = p;
       p = b;
       b = ptemp;
       if p == p0
           break;
       end
    end
end

function centroid = getCentroid(img)
    [row, col] = size(img);
    xC = 0;
    yC = 0; 
    n = 0.0;
    centroid = zeros(1,2);
    for x=1:row
        for y=1:col
            if img(x,y)==0
                xC = xC + x;
                yC = yC + y;
                n = n + 1.0;
            end
        end
    end
    centroid(1) = round(xC / n);
    centroid(2) = round(yC / n);
end

function distanceAngle = getDistanceAngle(img, centroid, alpha)
    [row, col] = size(img);
    xVal = centroid(1);
    yVal = centroid(2);
    pts0 = centroid(1);
    pts1 = centroid(2);
    distanceAngle = 0;
    isBoundary = checkBoundary(img, pts0, pts1);
    while img(pts0,pts1)==255 && isBoundary == false
        isBoundary = checkBoundary(img, pts0, pts1);
        xVal = xVal -sin(deg2rad(alpha));
        yVal = yVal + cos(deg2rad(alpha));
        pts0 = ceil(xVal);
        pts1 = ceil(yVal);
        distanceAngle = distanceAngle + 1;
    end
    distanceAngle = distanceAngle - 1;
end

function signature = getSignature(img, centroid, delta)
    alpha = 0.0;
    signature = [];
    while alpha < 360.0
        distanceAngle = getDistanceAngle(img, centroid, alpha);
        signature = [signature; distanceAngle];
        alpha = alpha + delta;
    end
end

function normalized = getNormalization(signature, th)
    [maxSig idxMax] = max(signature);
    minSig = min(signature);
    idxTotal = numel(signature);
    sorted = signature(idxMax:idxTotal,1);
    sorted = [sorted; signature(1:idxMax-1,1)];
    normalized = [];
    for i=1:idxTotal
        distance = (sorted(i)-minSig)/(maxSig-minSig)*th;  
        normalized = [normalized; round(distance)];
    end
end
