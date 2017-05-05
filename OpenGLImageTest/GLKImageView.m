//
//  GLKImageView.m
//  OpenGLImageTest
//
//  Created by luomj on 2017/5/5.
//  Copyright © 2017年 luomj. All rights reserved.
//

#import "GLKImageView.h"

#pragma mark 自己用

@interface GLKImageView()
@property (nonatomic, strong) EAGLContext *eaglContent;
@end

@implementation GLKImageView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (EAGLContext *)eaglContent {
    if (! _eaglContent) {
        _eaglContent = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //opengl es 2.0
        [EAGLContext setCurrentContext:_eaglContent]; //设置为当前上下文。
    }
    return (_eaglContent);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}



- (void)setup {
    self.context = self.eaglContent;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    
    if (_image == nil) {
        [self _deleteMainTexture];
        return;
    }
    
    // Create an RGBA bitmap context
    CGImageRef CGImage = image.CGImage;
    GLint width = (GLint)CGImageGetWidth(CGImage);
    GLint height = (GLint)CGImageGetHeight(CGImage);
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    // Invert vertically for OpenGL
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), CGImage);

    
    [self setContentSize:CGSizeMake(width, height)];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    [self didDrawImageViaGLKView:image inFrame:self.bounds imageBounds:CGSizeMake(width, height)];
}

- (void)_deleteMainTexture
{
    [self clearsContextBeforeDrawing];
}

- (void)didDrawImageViaGLKView:(UIImage *)image inFrame:(CGRect)rect imageBounds:(CGSize) imageSize {
    // 创建OpenGL视图
    [self bindDrawable];
    

    float imageAspect = imageSize.height / imageSize.width;
    float bounsScale = rect.size.height/rect.size.width;


    //   y / x
    CGSize size = [self scale:bounsScale andImageAspect:imageAspect];
    float scaleX = size.width;
    float scaleY = size.height;
    
    GLfloat vertices[] = {
        -1 * scaleX, -1* scaleY,//左下
        1* scaleX, -1* scaleY,//右下
        -1* scaleX, 1* scaleY,//左上
        1* scaleX, 1* scaleY,//右上
    };
    glEnableVertexAttribArray(GLKVertexAttribPosition); // 启用position
    // glVertexAttribPointer:加载vertex数据
    // 参数1:传递的顶点位置数据GLKVertexAttribPosition, 或顶点颜色数据GLKVertexAttribColor
    // 参数2:数据大小(2维为2, 3维为3)
    // 参数3:顶点的数据类型
    // 参数4:指定当被访问时, 固定点数据值是否应该被归一化或直接转换为固定点值.
    // 参数5:指定连续顶点属性之间的偏移量, 用于描述每个vertex数据大小
    // 参数6:指定第一个组件在数组的第一个顶点属性中的偏移量, 与GL_ARRAY_BUFFER绑定存储于缓冲区中
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    
    static GLfloat colors[] = {
        1,1,1,1,
        1,1,1,1,
        1,1,1,1,
        1,1,1,1
    };
    glEnableVertexAttribArray(GLKVertexAttribColor); // 启用颜色
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, colors);
    
    static GLfloat texCoords[] = {
        0, 0,//左下
        1, 0,//右下
        0, 1,//左上
        1, 1,//右上
    };
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); // 启用vertex贴图坐标
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    
    // 因为读取图片信息的时候默认是从图片左上角读取的, 而OpenGL绘制却是从左下角开始的.所以我们要从左下角开始读取图片数据.
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(YES), GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:nil];
    
    GLKBaseEffect *baseEffect = [[GLKBaseEffect alloc] init];
    // 创建一个二维的投影矩阵, 即定义一个视野区域(镜头看到的东西)
    // GLKMatrix4MakeOrtho(float left, float right, float bottom, float top, float nearZ, float farZ)
    //GLKMatrix4MakeOrtho(-1, 1, -1, 1, -1, 1)
    baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1, 1, -1, 1, -1, 1);
    baseEffect.texture2d0.name = textureInfo.name;
    [baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribColor);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [self display];
}

- (CGSize)scale:(float) boundAspect andImageAspect:(float) imageAspect {
    
    // 因OpenGL只能绘制三角形, 则该verteices2数组与glDrawArrays的组合要认真仔细.
    // 如glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)是两个三角形:(左下,右下,右上)与(右下,右上,左上).
    // 而glDrawArrays(GL_TRIANGLE_STRIP, 1, 3)是一个三角形:(右下,右上,左上)
    // 若将vertices中的右上与左上互换, 则glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)刚好绘制出一片白板(两个三角形拼接).·
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    
    float aspect = boundAspect/imageAspect;
    
    if (self.contentMode == UIViewContentModeScaleAspectFit) {
        if (aspect > 1) {
            scaleY *= 1.0 * aspect;
        } else {
            scaleX *= 1.0 * aspect;
        }
    } else if (self.contentMode == UIViewContentModeScaleAspectFill) {
        if (aspect > 1) {
            scaleY *= 1.0 /aspect;
        } else {
            scaleX *= aspect;
        }
    } else if (self.contentMode == UIViewContentModeScaleToFill) {
        
    }

    return CGSizeMake(scaleX, scaleY);
}

@end

