//
//  VideoFilterViewController.m
//  GPUImage
//
//  Created by 谢佳培 on 2021/1/9.
//

#import "VideoFilterViewController.h"
#import "NoticeView.h"
#import "VideoManager.h"
#import <AVKit/AVKit.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface VideoFilterViewController ()

// 文件存储路径
@property (nonatomic, copy) NSString *filePath;
// 视频播放视图
@property (nonatomic,strong) UIView *videoView;
// 播放器
@property (nonatomic,strong) AVPlayerViewController *player;
// 视频录制管理者
@property (nonatomic,strong) VideoManager *manager;

@end

@implementation VideoFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupUI];
    [self setupVideoMananger];
}

#pragma mark - 控制按钮

- (void)setupVideoMananger
{
    _manager = [[VideoManager alloc] init];
    _manager.delegate = self;
    [_manager showWithFrame:CGRectMake(20, 120, kScreenWidth-40, kScreenHeight/2-1) superView:self.view];
    _manager.maxTime = 30.0;
}

- (void)startRecord
{
    [_manager startRecording];
}

- (void)endRecordd
{
    [_manager endRecording];
}

- (void)playVideo
{
    _player = [[AVPlayerViewController alloc] init];
    _player.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:_filePath]];
    _player.videoGravity = AVLayerVideoGravityResizeAspect;
    [self presentViewController:_player animated:NO completion:nil];
}

#pragma mark - 委托方法

- (void)didStartRecordVideo
{
    [self.view addSubview:[NoticeView message:@"开始录制..." delaySecond:2]];
}

- (void)didCompressingVideo
{
    [self.view addSubview:[NoticeView message:@"视频压缩中..." delaySecond:2]];
}

- (void)didEndRecordVideoWithTime:(CGFloat)totalTime outputFile:(NSString *)filePath
{
    _filePath = filePath;
    NSLog(@"文件路径为：%@",filePath);
    [self.view addSubview:[NoticeView message:[NSString stringWithFormat:@"视频录制完毕，时长: %f",totalTime] delaySecond:4]];
}

#pragma mark - 创建视图

- (void)setupUI
{
    self.title = @"视频";
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.frame = CGRectMake(0, 64, kScreenWidth/2, 44);
    startButton.backgroundColor = [UIColor yellowColor];
    [startButton setTitle:@"录制视频" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
    
    UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    stopButton.backgroundColor = [UIColor redColor];
    [stopButton setTitle:@"停止录制" forState:UIControlStateNormal];
    [stopButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    stopButton.frame = CGRectMake(kScreenWidth/2, 64, kScreenWidth/2, 44);
    [stopButton addTarget:self action:@selector(endRecordd) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopButton];
    
    self.videoView = [[UIView alloc] initWithFrame:CGRectMake(10, kScreenHeight/2, kScreenWidth-20, kScreenHeight/2)];
    self.videoView.userInteractionEnabled = YES;
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(0, kScreenHeight-60, kScreenWidth, 50);
    [playButton setTitle:@"播放" forState:UIControlStateNormal];
    [playButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];

}




@end
