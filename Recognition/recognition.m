function main
    clc; close all; clear;
    tic();
    trainSet = getTrainingSet();
    testSet = getTestSet();
    pattern = patternRecognition(trainSet, testSet)
    classObj = learnModel(pattern);
    toc();
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

%membuat boundary object, namun fungsi ini hanya untuk citra dengan hasil
%segmentasi yg bersih(tanpa noise).
function boundaryObj = getBoundary(img)
    [row, col] = size(img);
    boundaryObj = zeros(row,col);
    for x=1:row
        for y=1:col
            if img(x,y)==0
                if  x==1||y==1||x==row||y==col||img(x-1,y-1)==255||img(x-1,y)==255||img(x-1,y+1)==255||img(x,y-1)==255||img(x,y+1)==255||img(x+1,y-1)==255||img(x+1,y)==255||img(x+1,y+1)==255 
                     boundaryObj(x,y) = 255;
                end
        	end
        end
    end
end

%mencari pusat(centroid) dari suatu objek.
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

%menghitung jarak dari pusat(centroid) ke boundary dengan sudut tertentu.
function distAngle = getDistance(img, centroid, alpha)
    [row, col] = size(img);
    xC = centroid(1); yC = centroid(2);
    x0 = centroid(1); y0 = centroid(2);
    x1 = x0; y1 = y0;
    distAngle = 0.0;
    boundary = false;
    while (xC>=1&&xC<row) && (yC>=1&&yC<col) && boundary==false
        xTemp = round(xC); yTemp = round(yC);
        if img(xTemp, yTemp)==0
            x1 = xTemp; y1 = yTemp;
        else
            boundary = true;
        end
        xC = xC + sin(deg2rad(alpha));
        yC = yC - cos(deg2rad(alpha));
    end
    distAngle = sqrt((x1-x0)^2+(y1-y0)^2);
end

%mencari signature dari suatu objek.
function signature = getSignature(img, centroid, delta)
    alpha = 0.0;
    signature = [];
    while alpha < 360.0
        distAngle = getDistance(img, centroid, alpha);
        signature = [signature, distAngle];
        alpha = alpha + delta;
    end
end

%melakukan normalisasi terhadap signature dari objek untuk mengatasi
%permasalahan rotasi dan skala.
function features = getNormalization(signature, th)
    [maxSig idxMax] = max(signature);
    minSig = min(signature);
    idxTotal = numel(signature);
    sorted = signature(1,idxMax:idxTotal);
    sorted = [sorted, signature(1,1:idxMax-1)];
    features = [];
    for i=1:idxTotal
        distance = (sorted(i)+minSig)/(maxSig+minSig)*th;  
        features = [features, floor(distance)];
    end
end

%menampung signature data training set ke dlm array trainSet.
function trainSet = getTrainingSet()
    trainSet = [];
    dataTraining = [imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\train\charger.jpg')];
    dataTraining = [dataTraining; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\train\dompet.jpg')];
    dataTraining = [dataTraining; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\train\gelas.jpg')];
    dataTraining = [dataTraining; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\train\palu.jpg')];
    dataTraining = [dataTraining; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\train\pulpen.jpg')];
    idx = 1;
    for i=1:5
        %semua citra berukuran 520x520.
        img = dataTraining(idx:520*i,1:520);
        if (size(img, 3) == 3)
            img = rgb2grayscale(img);
        end
        otsu1T = otsu1threshold(img);
        thImage = segmen1threshold(img, otsu1T);
        boundaryObj = getBoundary(thImage);
        centroid = getCentroid(thImage);
        signature = getSignature(boundaryObj, centroid, 10.0);
        features = getNormalization(signature, 100.0);
        trainSet = [trainSet; features];
        idx = idx + 520;
    end
end

%menampung signature data testing set ke dlm array testSet.
function testSet = getTestSet()
    testSet = [];
    dataTesting = [imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test1.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test2.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test3.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test4.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test5.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test6.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test7.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test8.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test9.jpg')];
    dataTesting = [dataTesting; imread('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\test\test10.jpg')];
    idx = 1;
    for i=1:10
        img = dataTesting(idx:520*i,1:520);
        if (size(img, 3) == 3)
            img = rgb2grayscale(img);
        end
        otsu1T = otsu1threshold(img);
        thImage = segmen1threshold(img, otsu1T);
        boundaryObj = getBoundary(thImage);
        centroid = getCentroid(thImage);
        signature = getSignature(boundaryObj, centroid, 10.0);
        features = getNormalization(signature, 100.0);
        testSet = [testSet; features];
        idx = idx + 520;
    end
end

function diff = getDifference(sig1, sig2)
    diff = 0;
    for i=1:numel(sig1)
        diff = diff + abs(sig1(i)-sig2(i));
    end
end

function pattern = patternRecognition(trainSet, testSet)
    [row, col] = size(trainSet);
    [row2, col2] = size(testSet);
    pattern = [];
    for i=1:row2
        temp = [];
        for j=1:row
            diff = getDifference(testSet(i,:), trainSet(j,:));
            temp = [temp, diff];
            if j==row
                pattern = [pattern; temp];
            end
        end
    end
end

function classObj = learnModel(pattern)
    [row, col] = size(pattern);
    classObj = cell(row,2);
    for i=1:row
        [val idx] = min(pattern(i,:));
        if idx==1
            class = 'charger';
        elseif idx==2
            class = 'dompet';
        elseif idx==3
            class = 'gelas';
        elseif idx==4
            class = 'palu';
        else
            class = 'pulpen';
        end
        classObj{i,1} = i; classObj{i,2} = class;
    end
    f = fopen('D:\STUDY\Semester 5\Pengolahan Citra Digital\Tugas\Distance-Angle Signature\Recognition\classObj.txt', 'w');
    format = 'test%d -> %s\n';
    for i=1:row
        fprintf(f,format,classObj{i,:});
    end
    fclose(f);
end