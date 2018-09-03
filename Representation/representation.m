function main
    clc; close all; clear;
    img = imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\coba\a2.jpg');
    if (size(img, 3) == 3)
        img = rgb2grayscale(img);
    end
    
    otsu1T = otsu1threshold(img);
    thImage = segmen1threshold(img, otsu1T);
    boundaryObj = getBoundary(thImage);
    centroid = getCentroid(thImage);
    signature = getSignature(boundaryObj, centroid, 10.0);
    normalized = getNormalization(signature, 100.0);
    for i=1:numel(normalized)
        fprintf('%d, ', normalized(i));
    end
    %imshow(uint8(thImage));
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

function boundaryObj = getBoundary(img)
    [row, col] = size(img);
    boundaryObj = zeros(row,col);
    for x=1:row
        for y=1:col
            if x==1 || y==1 || x == row || y == col
                boundaryObj(x,y) = img(x,y);
            else
                if img(x,y) == 0
                    if img(x-1,y-1) == 255 || img(x-1,y) == 255 || img(x-1,y+1) == 255 || img(x,y-1) == 255 || img(x,y+1) == 255 || img(x+1,y-1) == 255 || img(x+1,y) == 255 || img(x+1,y+1) == 255 
                        boundaryObj(x,y) = 255;
                    end
                end
            end
        end
    end
end

function centroid = getCentroid(img)
    [row, col] = size(img);
    xC = 0; yC = 0; n = 0;
    for x=1:row
        for y=1:col
            if img(x,y)==0
                xC = xC + x;
                yC = yC + y;
                n = n + 1;
            end
        end
    end
    centroid = [floor(xC / n), floor(yC / n)];
end

function distAngle = getDistance(img, centroid, alpha)
    [row, col] = size(img);
    xC = centroid(1); yC = centroid(2);
    x0 = centroid(1); y0 = centroid(2);
    x1 = x0; y1 = y0;
    distAngle = 0.0;
    boundary = false;
    while (xC>=1 && xC<row) && (yC>=1 && yC<col) && boundary == false
        xTemp = round(xC);
        yTemp = round(yC);
        if img(xTemp, yTemp) == 0
            x1 = xTemp;
            y1 = yTemp;
        else
            boundary = true;
        end
        xC = xC + sin(deg2rad(alpha));
        yC = yC - cos(deg2rad(alpha));
    end
    distAngle = sqrt((x1-x0)^2+(y1-y0)^2);
end

function signature = getSignature(img, centroid, delta)
    alpha = 0.0;
    signature = [];
    while alpha < 360.0
        distAngle = getDistance(img, centroid, alpha);
        signature = [signature, distAngle];
        alpha = alpha + delta;
    end
end

function normalized = getNormalization(signature, th)
    [maxSig idxMax] = max(signature);
    minSig = min(signature);
    idxTotal = numel(signature);
    sorted = signature(1,idxMax:idxTotal);
    sorted = [sorted, signature(1,1:idxMax-1)];
    normalized = [];
    for i=1:idxTotal
        distance = (sorted(i)+minSig)/(maxSig+minSig)*th;  
        normalized = [normalized, floor(distance)];
    end
end