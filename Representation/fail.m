%distance kurang akurat.

function main
    clc; close all; clear;
    img = imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Representation\coba\c.jpg');
    if (size(img, 3) == 3)
        img = rgb2grayscale(img);
    end
    
    otsu1T = otsu1threshold(img);
    thImage = segmen1threshold(img, otsu1T);
    boundaryObj = getBoundary(thImage);
    centroid = getCentroid(boundaryObj);
    signature = getSignature(boundaryObj, centroid, 10.0);
    normalized = getNormalization(signature, 100.0);
    for i=1:numel(normalized)
        fprintf('%d, ', normalized(i));
    end
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
            if img(x,y)==255
                xC = xC + x;
                yC = yC + y;
                n = n + 1;
            end
        end
    end
    centroid = [round(xC / n), round(yC / n)];
end

function isBoundary = checkBoundary(img, p)
    neighbor = [-1 0; -1 1; 0 1; 1 1; 1 0; 1 -1; 0 -1; -1 -1];
    [row, col] = size(img);
    isBoundary = false;
    for i=1:8
        px = [p(1)+neighbor(i,1), p(2)+neighbor(i,2)];
        if img(px(1),px(2))==255
            isBoundary = true;
            break;
        end
    end
end

function distAngle = getDistance(img, centroid, alpha)
    [row, col] = size(img);
    xVal = centroid(1)*1.0; yVal = centroid(2)*1.0;
    x = centroid(1); y = centroid(2);
    distAngle = 0;
    isBoundary = checkBoundary(img, [x, y]);
    while img(x,y)==0 && isBoundary == false;
        isBoundary = checkBoundary(img, [x, y]);
        xVal = xVal - sin(deg2rad(alpha));
        yVal = yVal + cos(deg2rad(alpha));
        x = uint64(xVal); 
        y = uint64(yVal);
        distAngle = distAngle + 1;
    end
    distAngle = distAngle - 1;
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
        normalized = [normalized, uint64(round(distance))];
    end
end