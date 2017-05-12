//
//  ViewController.h
//  OpenCV-3D
//
//  Created by Okaylens-Ares on 05/05/2017.
//  Copyright © 2017 Okaylens-Ares. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController
{
    GLuint vertexBufferID;
}

@property (strong, nonatomic) GLKBaseEffect *baseEffect;

@end

