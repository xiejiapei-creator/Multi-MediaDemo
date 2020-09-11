//
//  AVPlayerDemo.m
//  VideoRecordingDemo
//
//  Created by 谢佳培 on 2020/9/2.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AVPlayerDemo.h"
#import <AVFoundation/AVFoundation.h>

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@interface AVPlayerDemo ()

@property (nonatomic,strong) AVPlayer *player; //播放器对象

@property (strong, nonatomic) UIView *container; //播放器容器
@property (strong, nonatomic) UIProgressView *progress; //播放进度

@end

@implementation AVPlayerDemo

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubviews];
    [self.player play];
}

- (void)createSubviews
{
    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 400)];
    [self.view addSubview:self.container];
    
    // 播放/暂停按钮
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(50, 400, 300, 80)];
    [button setImage:[UIImage imageNamed:@"player_start_iphone_window@3x.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
      
    // 切换视频
    UIButton * button1 = [[UIButton alloc] initWithFrame:CGRectMake(50, 500, 50, 50)];
    [button1 setTitle:@"1" forState:UIControlStateNormal];
    button.tag = 1;
    button1.backgroundColor = [UIColor blueColor];
    [button1 addTarget:self action:@selector(navigationButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton * button2 = [[UIButton alloc] initWithFrame:CGRectMake(120, 500, 50, 50)];
    [button2 setTitle:@"2" forState:UIControlStateNormal];
    button.tag = 2;
    button2.backgroundColor = [UIColor blueColor];
    [button2 addTarget:self action:@selector(navigationButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    self.progress = [[UIProgressView alloc] initWithFrame:CGRectMake(50, 600, 300, 100)];
    self.progress.backgroundColor = [UIColor redColor];
    self.progress.progress = 0;
    [self.view addSubview:self.progress];
    
    // 创建播放器层
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.container.frame;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect; //视频填充模式
    [self.container.layer addSublayer:playerLayer];
}

#pragma mark - Events

// 点击播放/暂停按钮
- (void)playClick:(UIButton *)sender
{
    if(self.player.rate == 0)// 暂停
    {
        [sender setImage:[UIImage imageNamed:@"player_pause_iphone_window@3x.png"] forState:UIControlStateNormal];
        [self.player play];
        NSLog(@"点击了播放");
    }
    else if(self.player.rate == 1)//正在播放
    {
        [self.player pause];
        [sender setImage:[UIImage imageNamed:@"player_start_iphone_window@3x.png"] forState:UIControlStateNormal];
        NSLog(@"点击了暂停");
    }
}

//  切换选集，这里使用按钮的tag代表视频名称
- (void)navigationButtonClick:(UIButton *)sender
{
    [self removeNotification];
    [self removeObserverFromPlayerItem:self.player.currentItem];
    
    AVPlayerItem *playerItem = [self getPlayItem:sender.tag];
    [self addObserverToPlayerItem:playerItem];
    
    // 切换视频
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self addNotification];
}

#pragma mark - Data

-(AVPlayerItem *)getPlayItem:(NSInteger)videoIndex
{
    NSString *urlStr = videoIndex == 1 ? @"http://v.cctv.com/flash/mp4video6/TMS/2011/01/05/cf752b1c12ce452b3040cab2f90bc265_h264818000nero_aac32-1.mp4" : @"http://vjs.zencdn.net/v/oceans.mp4";
    NSURL *url = [NSURL URLWithString:urlStr];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    return playerItem;
}

#pragma mark - 通知

// 给AVPlayerItem添加播放完成通知
-(void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

-(void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)playbackFinished:(NSNotification *)notification
{
    NSLog(@"视频播放完成.");
}

#pragma mark - 监控

// 给播放器添加进度更新
-(void)addProgressObserver
{
    AVPlayerItem *playerItem = self.player.currentItem;
    __weak typeof(self) weakSelf = self;
    
    // 这里设置每秒执行一次
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        NSLog(@"当前已经播放%.2fs.",current);
        
        float total = CMTimeGetSeconds([playerItem duration]);
        if (current)
        {
            [weakSelf.progress setProgress:(current/total) animated:YES];
            NSLog(@"进度条为：%f",current/total);
        }
    }];
}

// 给AVPlayerItem添加监控
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    // 监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"])
    {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
}

#pragma mark - Setter/Getter

-(AVPlayer *)player
{
    if (!_player)
    {
        AVPlayerItem *playerItem = [self getPlayItem:1];
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        [self addProgressObserver];
        [self addObserverToPlayerItem:playerItem];
    }
    return _player;
}


@end
