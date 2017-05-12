//
//  Utilities.m
//  OpenCV-3D
//
//  Created by Okaylens-Ares on 05/05/2017.
//  Copyright © 2017 Okaylens-Ares. All rights reserved.
//

#include <iostream>
#include "opencv2/core/core.hpp"
//#include "opencv2/nonfree/nonfree.hpp"
#include "opencv2/features2D/features2D.hpp"

#import <opencv2/highgui/cap_ios.h>
#import <opencv2/opencv.hpp>
#import <opencv2/legacy/legacy.hpp>
#import "Utilities.h"

using namespace cv;
using namespace std;

@implementation Utilities

+ (void)reconstruction {
    NSArray *imageAry = [NSArray arrayWithObjects:
                         [UIImage imageNamed:@"templeSR0001.png"],
                         [UIImage imageNamed:@"templeSR0002.png"],
                         [UIImage imageNamed:@"templeSR0003.png"],
                         [UIImage imageNamed:@"templeSR0004.png"],
                         [UIImage imageNamed:@"templeSR0005.png"],
                         [UIImage imageNamed:@"templeSR0006.png"],
                         [UIImage imageNamed:@"templeSR0007.png"],
                         [UIImage imageNamed:@"templeSR0008.png"],
                         [UIImage imageNamed:@"templeSR0009.png"],
                         [UIImage imageNamed:@"templeSR0010.png"],
                         [UIImage imageNamed:@"templeSR0011.png"],
                         [UIImage imageNamed:@"templeSR0012.png"],
                         [UIImage imageNamed:@"templeSR0013.png"],
                         [UIImage imageNamed:@"templeSR0014.png"],
                         [UIImage imageNamed:@"templeSR0015.png"],
                         [UIImage imageNamed:@"templeSR0016.png"],
                         nil];
    
    vector<string> imagesVector;
    for (UIImage *image in imageAry) {
        if (image) {
            NSData *dataImg = [NSData dataWithData:UIImagePNGRepresentation(image)];
            NSString *imageString = [[NSString alloc] initWithData:dataImg encoding:NSUTF8StringEncoding];
            string stringToC = [imageString cStringUsingEncoding:[NSString defaultCStringEncoding]];
            imagesVector.push_back(stringToC);
        }else {
            NSLog(@"fetching images error!!!");
        }
    }
    float f = 800;
    float cx = 400;
    float cy = 225;
    
    Matx33d K = Matx33d(f, 0, cx,
                        0, f, cy,
                        0, 0,  1);
    
    bool is_projective = true;
    vector<Mat> Rs_est, ts_est, points3d_estimated;
    reconstruct(imagesVector, Rs_est, ts_est, K, points3d_estimated, is_projective);
    
    // Create the pointcloud
    cout << "Recovering points  ... ";
    
    // recover estimated points3d
    vector<Vec3f> point_cloud_est;
    for (int i = 0; i < points3d_estimated.size(); ++i)
        point_cloud_est.push_back(Vec3f(points3d_estimated[i]));
    cout << "[DONE]" << endl;
    cout << "Recovering cameras ... ";
    
    vector<Affine3d> path;
    for (size_t i = 0; i < Rs_est.size(); ++i)
        path.push_back(Affine3d(Rs_est[i],ts_est[i]));
    cout << "[DONE]" << endl;
    if ( point_cloud_est.size() > 0 )
    {
        cout << "Rendering points   ... ";
        viz::WCloud cloud_widget(point_cloud_est, viz::Color::green());
        window.showWidget("point_cloud", cloud_widget);
        cout << "[DONE]" << endl;
    }
    else
    {
        cout << "Cannot render points: Empty pointcloud" << endl;
    }
    if ( path.size() > 0 )
    {
        cout << "Rendering Cameras  ... ";
        window.showWidget("cameras_frames_and_lines", viz::WTrajectory(path, viz::WTrajectory::BOTH, 0.1, viz::Color::green()));
        window.showWidget("cameras_frustums", viz::WTrajectoryFrustums(path, K, 0.1, viz::Color::yellow()));
        window.setViewerPose(path[0]);
        cout << "[DONE]" << endl;
    }
    else
    {
        cout << "Cannot render the cameras: Empty path" << endl;
    }
    cout << endl << "Press 'q' to close each windows ... " << endl;
    window.spin();
}


#pragma mark - Image Convert

- (Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
