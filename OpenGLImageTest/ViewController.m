//
//  ViewController.m
//  OpenGLImageTest
//
//  Created by luomj on 2017/5/5.
//  Copyright © 2017年 luomj. All rights reserved.
//

#import "ViewController.h"
#import "GLKImageView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLKImageView *imageView = [[GLKImageView alloc] initWithFrame:CGRectMake(0, 100, 200, 320)];

    [self.view addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image =[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"timg" ofType:@"jpg"]];
        imageView.image = image;
    });
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
