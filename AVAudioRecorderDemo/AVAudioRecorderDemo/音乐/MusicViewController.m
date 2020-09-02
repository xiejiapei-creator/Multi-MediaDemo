//
//  MusicViewController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/9/1.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "MusicViewController.h"
#import <AVFoundation/AVFoundation.h>
#define kMusicFile @"桜道.mp3"
#define kMusicSinger @"歌手：Jusqu'à Grand-Père"
#define kMusicTitle @"歌曲：桜道"

@interface MusicViewController ()<AVAudioPlayerDelegate>

@property (nonatomic,strong) AVAudioPlayer *audioPlayer; //播放器
@property (strong, nonatomic) UILabel *controlPanel; //控制面板
@property (strong, nonatomic) UIProgressView *playProgress; //播放进度
@property (strong, nonatomic) UILabel *musicSinger; //演唱者
@property (strong, nonatomic) UIButton *playOrPause; //播放/暂停按钮(如果tag为0认为是暂停状态，1是播放状态)

@property (weak ,nonatomic) NSTimer *timer; //进度更新定时器

@end

@implementation MusicViewController

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createSubviews];
}

- (void)createSubviews
{
    self.title = kMusicTitle;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(150, 350, 100, 100);
    button.tag = 0;
    [button setImage:[UIImage imageNamed:@"playing_btn_play_n"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    self.playOrPause = button;
    [self.view addSubview:self.playOrPause];
    
    UILabel *musicSinger = [[UILabel alloc] initWithFrame:CGRectMake(100, 150, 300, 100)];
    musicSinger.text = kMusicSinger;
    self.musicSinger = musicSinger;
    [self.view addSubview:self.musicSinger];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(50, 250, 300, 300)];
    progressView.progress = 0;
    self.playProgress = progressView;
    [self.view addSubview:self.playProgress];
}

#pragma mark - 播放控制

// 播放音频
-(void)play
{
    if (![self.audioPlayer isPlaying])
    {
        [self.audioPlayer play];
        self.timer.fireDate = [NSDate distantPast];//恢复定时器
    }
}

// 暂停播放
-(void)pause
{
    if ([self.audioPlayer isPlaying])
    {
        [self.audioPlayer pause];
        self.timer.fireDate = [NSDate distantFuture];//暂停定时器，注意不能调用invalidate方法，此方法会取消，之后无法恢复
    }
}

// 点击播放/暂停按钮
- (void)playClick:(UIButton *)sender
{
    if(sender.tag)
    {
        sender.tag = 0;
        [sender setImage:[UIImage imageNamed:@"playing_btn_play_n"] forState:UIControlStateNormal];
        [self pause];
    }
    else
    {
        sender.tag = 1;
        [sender setImage:[UIImage imageNamed:@"playing_btn_pause_n"] forState:UIControlStateNormal];
        [self play];
    }
}

// 更新播放进度
-(void)updateProgress
{
    float progress = self.audioPlayer.currentTime / self.audioPlayer.duration;
    [self.playProgress setProgress:progress animated:true];
}

#pragma mark - AVAudioPlayerDelegate

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"音乐播放完成...");
    // 下一首
}


#pragma mark - Setter/Getter

-(NSTimer *)timer
{
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateProgress) userInfo:nil repeats:true];
    }
    return _timer;
}

-(AVAudioPlayer *)audioPlayer
{
    if (!_audioPlayer)
    {
        NSString *urlStr = [[NSBundle mainBundle] pathForResource:kMusicFile ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:urlStr];
        NSError *error = nil;
        
        // 初始化播放器，注意这里的Url参数只能是文件路径，不支持HTTP Url
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        // 设置播放器属性
        _audioPlayer.numberOfLoops = 0; //设置为0不循环播放
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay]; //加载音频文件到缓存
        
        if(error)
        {
            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}
 
@end
