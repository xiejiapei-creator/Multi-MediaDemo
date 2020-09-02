//
//  AVPlayerViewControllerDemo.m
//  VideoRecordingDemo
//
//  Created by 谢佳培 on 2020/9/2.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AVPlayerViewControllerDemo.h"
#import <AVKit/AVKit.h>

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@implementation RotationScreen

// 切换横竖屏
+ (void)forceOrientation:(UIInterfaceOrientation)orientation
{
    // setOrientation: 私有方法强制转屏
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
    {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        NSInteger val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

// 是否是横屏
+ (BOOL)isOrientationLandscape
{
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end

@interface AVPlayerViewControllerDemo ()

@property (nonatomic,strong) AVPlayerViewController *playerViewController; //视频播放控制器
@property (nonatomic,strong) UIView * Playerview;// 播放视图

@end

@implementation AVPlayerViewControllerDemo

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubviews];
}

- (void)createSubviews
{
    // 播放框
    [self.Playerview addSubview:self.playerViewController.view];
    
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(50, 500, 300, 100)];
    [button setTitle:@"全屏播放" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blackColor];
    [button addTarget:self action:@selector(playerAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark - Events

- (void)playerAction
{
    // 旋转视频
    if ([RotationScreen isOrientationLandscape])// 如果是横屏
    {
        [RotationScreen forceOrientation:(UIInterfaceOrientationPortrait)];// 切换为竖屏
    }
    else
    {
        [RotationScreen forceOrientation:(UIInterfaceOrientationLandscapeRight)];// 否则，切换为横屏
    }
    
    [self presentViewController:self.playerViewController animated:YES completion:^{
        //这样就可以进入页面缓冲完便立刻播放
        [self.playerViewController.player play];
    }];
}

#pragma mark - Private Methods

//  取得本地文件路径
- (NSURL *)getFileUrl
{
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"The New Look.mp4" ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:urlStr];
    return url;
}

// 取得网络文件路径
- (NSURL *)getNetworkUrl
{
    NSString *urlStr = @"http://v.cctv.com/flash/mp4video6/TMS/2011/01/05/cf752b1c12ce452b3040cab2f90bc265_h264818000nero_aac32-1.mp4";
    NSURL *url = [NSURL URLWithString:urlStr];
    return url;
}

#pragma mark - Getter/Setter

- (AVPlayerViewController *)playerViewController
{
    if (!_playerViewController)
    {
        _playerViewController = [[AVPlayerViewController alloc] init];
        NSURL *url = [self getNetworkUrl];
        _playerViewController.player = [AVPlayer playerWithURL:url];
        _playerViewController.view.frame = CGRectMake(0, 0, WIDTH, 400);
        _playerViewController.showsPlaybackControls = YES;
    }
    return _playerViewController;
}

-(UIView*)Playerview
{
    if (!_Playerview)
    {
        _Playerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 400)];
        _Playerview.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:_Playerview];
    }
    return _Playerview;
}

@end
