//
//  ViewController.m
//  GLSL金字塔
//
//  Created by 谢佳培 on 2021/1/6.
//

#import "ViewController.h"
#import "View.h"

@interface ViewController ()

@property(nonatomic, strong) View *glslView;

@end

@implementation ViewController
{
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.glslView = [[View alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 700)];
    [self.view addSubview:self.glslView];
    
    [self createSubview];
}

- (void)xbuttonClicked
{
    // 开启定时器
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bX = !bX;
    self.glslView.bX = bX;
}

- (void)ybuttonClicked
{
    // 开启定时器
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bY = !bY;
    self.glslView.bY = bY;
}

- (void)zbuttonClicked
{
    // 开启定时器
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bZ = !bZ;
    self.glslView.bZ = bZ;
}

- (void)reDegree
{
    [self.glslView reDegree];
}

- (void)createSubview
{
    UIButton *xbutton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 820.f, 100, 50.f)];
    [xbutton addTarget:self action:@selector(xbuttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [xbutton setTitle:@"绕X轴旋转" forState:UIControlStateNormal];
    [xbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    xbutton.layer.cornerRadius = 5.f;
    xbutton.clipsToBounds = YES;
    xbutton.layer.borderWidth = 1.f;
    xbutton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:xbutton];
    
    UIButton *ybutton = [[UIButton alloc] initWithFrame:CGRectMake(170.f, 820.f, 100, 50.f)];
    [ybutton addTarget:self action:@selector(ybuttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [ybutton setTitle:@"绕Y轴旋转" forState:UIControlStateNormal];
    [ybutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    ybutton.layer.cornerRadius = 5.f;
    ybutton.clipsToBounds = YES;
    ybutton.layer.borderWidth = 1.f;
    ybutton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:ybutton];
    
    UIButton *zbutton = [[UIButton alloc] initWithFrame:CGRectMake(290.f, 820.f, 100, 50.f)];
    [zbutton addTarget:self action:@selector(zbuttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [zbutton setTitle:@"绕Z轴旋转" forState:UIControlStateNormal];
    [zbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    zbutton.layer.cornerRadius = 5.f;
    zbutton.clipsToBounds = YES;
    zbutton.layer.borderWidth = 1.f;
    zbutton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:zbutton];
}

@end
