//
//  ViewController.m
//  GLSL纹理图片加载
//
//  Created by 谢佳培 on 2021/1/6.
//

#import "ViewController.h"
#import "View.h"

@interface ViewController ()

@property(nonnull,strong) View *imageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    View *weekView = [[View alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:weekView];
}

@end
