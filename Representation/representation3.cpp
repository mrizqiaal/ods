#include <iostream>
#include <fstream>
#include <cmath>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#define PI 3.1415927
#define RAD(A) (PI*((double)(A)/180.0))

using namespace std;
using namespace cv;

struct point{
    int x;
    int y;
};

point getCentroid(Mat);
double* getSignatures(Mat, point, double);
double getDistanceBoundary(Mat, point, double);
double getDistance(Mat, point, double);
Mat getBoundary(Mat);
int** getMoore(int**, point, point);
point getFirstNeighbor(Mat, point, int**);
Mat getMedianFilter(Mat image);
void insertionSort(int filter[]);

int main(){
    Mat image, boundary;
    double degrees;
    string name,path, sourcename, filename;
    ofstream fileSignature;
    char lagi = 'n';

    do{
        cout<<"Nama file gambar : ";
        cin>>name;
        path = "E:\\UDINUS\\Semester 5\\Pengolahan Citra Digital\\Tugas\\Tugas Akhir\\image\\result\\" + name;
        image = imread(path, CV_LOAD_IMAGE_GRAYSCALE);

        if(image.data){
            sourcename = "";
            for(int i = 0; i < name.length(); i++){
                if(!(name[i] == '.')){
                    sourcename += name[i];
                }else{
                    break;
                }
            }
            boundary = getBoundary(image);

            cout<<"Interval derajat : ";
            cin>>degrees;

            point centroid = getCentroid(image);
            cout<<"X : "<<centroid.x<<", Y : "<<centroid.y<<endl;
            int n = 360/degrees;
            double* signatures = new double[n];
            signatures = getSignatures(image, centroid, degrees);

            filename = "E:\\UDINUS\\Semester 5\\Pengolahan Citra Digital\\Tugas\\Tugas Akhir\\signature\\" + sourcename + ".txt";
            const char *filechar = filename.c_str();
            fileSignature.open(filechar, ios::trunc);
            for(int i = 0; i < n; i++){
                fileSignature<<i<<" ";
                fileSignature<<signatures[i]<<endl;
            }

            fileSignature.close();
            namedWindow("Boundary Image", CV_WINDOW_AUTOSIZE);
            imshow("Boundary Image", boundary);
            waitKey();
        }
        else{
            cout<<"File tidak bisa dibuka"<<endl;
        }
        cout<<"Lakukan operasi lagi? (Y/N) : ";
        cin>>lagi;
    }while(lagi == 'y' || lagi == 'Y');
    return 0;
}

point getCentroid(Mat image){
    point centroid;
    int accX = 0, accY = 0, n = 0;
    for(int i = 0; i < image.rows; i++){
        for(int j = 0; j < image.cols; j++){
            if(image.at<uchar>(i,j) == 0){
                accX += i;
                accY += j;
                n++;
            }
        }
    }

    centroid.x = accX/n;
    centroid.y = accY/n;
    return centroid;
}

double* getSignatures(Mat image, point centroid, double degrees){
    int n = 360/degrees;
    double* signatures = new double[n];
    double* temp = new double[n];
    for(int i = 0; i < n; i++){
        temp[i] = getDistance(image, centroid, i*degrees);
        cout<<getDistance(image, centroid, i*degrees)<<endl;
    }

    //Mencari nilai maksimum dan minimum
    int imaks;
    double maks = temp[0];
    double mins = temp[0];
    imaks = 0;
    for(int i = 1; i < n; i++){
        if(temp[i] > maks){
            //cout<<"Maks : "<<maks<<endl;
            maks = temp[i];
            imaks = i;
        }
        else if(temp[i] < mins){
            //cout<<"Mins : "<<mins<<endl;
            mins = temp[i];
        }
    }

    cout<<"Maks : "<<maks<<endl;
    cout<<"Mins : "<<mins<<endl;
    //normalisasi rotasi
    if(imaks != 0){
        int it = imaks;
        int j = 0;
        do{
            if(it >= n){
                it = 0;
            }
            signatures[j] = temp[it];
            it++;
            j++;
        }while(it != imaks);
    }else{
        signatures = temp;
    }

    //normalisasi skala
    if(maks != mins){
        for(int i = 0; i < n; i++){
            cout<<signatures[i]<<" - "<<mins<<" / "<<maks<<" - "<<mins<<" = "<<round((signatures[i] - mins)/(maks - mins)*100)<<endl;
            signatures[i] = round(((signatures[i] - mins)/(maks - mins))*100);
        }
    }
    else{
        for(int i = 0; i < n; i++){
            signatures[i] = 100;
        }
    }

    return signatures;
}

double getDistanceBoundary(Mat boundary, point centroid, double theta){
    double x = centroid.x;
    double y = centroid.y;
    while(x >= 0 && x < boundary.rows && y >= 0 && y < boundary.cols){
        x += -sin(RAD(theta));
        y += cos(RAD(theta));
        if(boundary.at<uchar>(x,y) == 255){
            break;
        }
    }
    double distance = sqrt(pow((double)centroid.x - x, 2) + pow((double)centroid.y - y, 2));
    return distance;
}

double getDistance(Mat image, point centroid, double theta){
    double x = centroid.x;
    double y = centroid.y;
    while(image.at<uchar>(x,y) == 0){
        x += -sin(RAD(theta));
        y += cos(RAD(theta));
    }
    double distance = sqrt(pow((double)centroid.x - x, 2) + pow((double)centroid.y - y, 2));
    return distance;
}

Mat getBoundary(Mat image){
    point p0;
    Mat result(image.rows, image.cols, CV_8UC1, Scalar(0,0,0));
    //Mengambil titik pertama gambar
    for(int i = 0; i < image.rows; i++){
        for(int j = 0; j < image.cols; j++){
            if(image.at<uchar>(i,j) == 0){
                p0.x = i;
                p0.y = j;
                i = image.rows;
                j = image.cols;
            }
        }
    }
    cout<<"("<<p0.x<<","<<p0.y<<")"<<endl;
    //Inisialisasi Boundary Tracking
    point p;p.x = p0.x;p.y = p0.y;
    point b;b.x = p0.x; b.y = p0.y - 1;

    static int** mooreDef = new int*[8];
    for(int i = 0; i < 8; i++){
        mooreDef[i] = new int[2];
    }
    mooreDef[0][0] = -1;
    mooreDef[0][1] = 0;
    mooreDef[1][0] = -1;
    mooreDef[1][1] = 1;
    mooreDef[2][0] = 0;
    mooreDef[2][1] = 1;
    mooreDef[3][0] = 1;
    mooreDef[3][1] = 1;
    mooreDef[4][0] = 1;
    mooreDef[4][1] = 0;
    mooreDef[5][0] = 1;
    mooreDef[5][1] = -1;
    mooreDef[6][0] = 0;
    mooreDef[6][1] = -1;
    mooreDef[7][0] = -1;
    mooreDef[7][1] = -1;

    while(true){
        //cout<<"X : "<<p.x<<", Y : "<<p.y<<endl;
        result.at<uchar>(p.x, p.y) = 255;
        int** moore = getMoore(mooreDef, p, b);
        b = getFirstNeighbor(image, p, moore);
        point temp = p;
        p = b;
        b = temp;
        if(p.x == p0.x && p.y == p0.y){
            break;
        }
    }
    return result;
}

int** getMoore(int** mooreDef, point p, point b){
    static int** moore = new int*[8];
    for(int i = 0; i < 8; i++){
        moore[i] = new int[2];
    }

    int idx = 0;
    for(int i = 0; i < 8; i++){
        point px;
        px.x = p.x + mooreDef[i][0];
        px.y = p.y + mooreDef[i][1];
        if(px.x == b.x && px.y == b.y){
            break;
        }
        idx++;
    }

    for(int i = 0; i < 8; i++){
        idx++;
        if(idx > 7){
            idx = 0;
        }
        moore[i][0] = mooreDef[idx][0];
        moore[i][1] = mooreDef[idx][1];
    }
    return moore;
}

point getFirstNeighbor(Mat image, point p, int** moore){
    point px;
    for(int i = 0; i < 8; i++){
        px.x = p.x + moore[i][0];
        px.y = p.y + moore[i][1];
        if(px.x >= 0 && px.x < image.rows && px.y >= 0 && px.y < image.cols){
            if(image.at<uchar>(px.x, px.y) == 0){
                break;
            }
        }
    }
    return px;
}
