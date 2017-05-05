//
//  GLKImageView.h
//  OpenGLImageTest
//
//  Created by luomj on 2017/5/5.
//  Copyright © 2017年 luomj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface GLKImageView : GLKView
@property (nonatomic, strong) UIImage *image;
@property (assign, nonatomic) GLKMatrix4 contentTransform;
@property (assign, nonatomic) CGSize contentSize; // Content size used to compute the contentMode transform. By default it can be the texture size.
@end
