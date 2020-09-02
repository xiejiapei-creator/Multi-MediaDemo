//
//  MusicPlayerController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/9/1.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "MusicPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MusicPlayerController ()<MPMediaPickerControllerDelegate>

@property (nonatomic,strong) MPMediaPickerController *mediaPicker; //媒体选择控制器
@property (nonatomic,strong) MPMusicPlayerController *musicPlayer; //音乐播放器

@end

@implementation MusicPlayerController
 
#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubViews];
}

- (void)createSubViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *buttton1 = [[UIButton alloc]initWithFrame:CGRectMake(20, 100, 100, 40)];
    [buttton1 setTitle:@"选择音乐" forState:UIControlStateNormal];
    [buttton1 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton1 setBackgroundColor:[UIColor yellowColor]];
    [buttton1 addTarget:self action:@selector(selectClick) forControlEvents:UIControlEventTouchUpInside];
    buttton1.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton1];
    
    UIButton *buttton12 = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(buttton1.frame)+20, 100, 100, 40)];
    [buttton12 setTitle:@"播放音乐" forState:UIControlStateNormal];
    [buttton12 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton12 setBackgroundColor:[UIColor yellowColor]];
    [buttton12 addTarget:self action:@selector(playClick) forControlEvents:UIControlEventTouchUpInside];
    buttton12.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton12];
    
    UIButton *buttton2 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton1.frame)+30, 100, 40)];
    [buttton2 setTitle:@"暂停播放" forState:UIControlStateNormal];
    [buttton2 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton2 setBackgroundColor:[UIColor yellowColor]];
    [buttton2 addTarget:self action:@selector(puaseClick) forControlEvents:UIControlEventTouchUpInside];
    buttton2.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton2];
    
    UIButton *buttton3 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton2.frame)+30, 100, 40)];
    [buttton3 setTitle:@"停止播放" forState:UIControlStateNormal];
    [buttton3 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton3 setBackgroundColor:[UIColor yellowColor]];
    [buttton3 addTarget:self action:@selector(stopClick) forControlEvents:UIControlEventTouchUpInside];
    buttton3.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton3];
    
    UIButton *buttton4 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton3.frame)+30, 100, 40)];
    [buttton4 setTitle:@"下一首" forState:UIControlStateNormal];
    [buttton4 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton4 setBackgroundColor:[UIColor yellowColor]];
    [buttton4 addTarget:self action:@selector(nextClick) forControlEvents:UIControlEventTouchUpInside];
    buttton4.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton4];
    
    UIButton *buttton5 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton4.frame)+30, 100, 40)];
    [buttton5 setTitle:@"上一首" forState:UIControlStateNormal];
    [buttton5 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton5 setBackgroundColor:[UIColor yellowColor]];
    [buttton5 addTarget:self action:@selector(prevClick) forControlEvents:UIControlEventTouchUpInside];
    buttton4.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton5];
}

-(void)dealloc
{
    [self.musicPlayer endGeneratingPlaybackNotifications];
}

#pragma mark - 数据源

// 获取媒体队列
-(MPMediaQuery *)getLocalMediaQuery
{
    MPMediaQuery *mediaQueue = [MPMediaQuery songsQuery];
    for (MPMediaItem *item in mediaQueue.items)
    {
        NSLog(@"item 标题：%@，albumTitle 专辑标题：%@",item.title,item.albumTitle);
    }
    return mediaQueue;
}

-(MPMediaItemCollection *)getLocalMediaItemCollection
{
    MPMediaQuery *mediaQueue = [MPMediaQuery songsQuery];
    NSMutableArray *array = [NSMutableArray array];
    for (MPMediaItem *item in mediaQueue.items)
    {
        [array addObject:item];
        NSLog(@"item 标题：%@，albumTitle 专辑标题：%@",item.title,item.albumTitle);
    }
    MPMediaItemCollection *mediaItemCollection = [[MPMediaItemCollection alloc] initWithItems:[array copy]];
    return mediaItemCollection;
}

#pragma mark - MPMediaPickerControllerDelegate

// 选择完成
-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    MPMediaItem *mediaItem = [mediaItemCollection.items firstObject];// 播放第一个音乐
    
    //注意很多音乐信息如标题、专辑、表演者、封面、时长等信息都可以通过MPMediaItem的valueForKey:方法得到，也都有对应的属性可以直接访问
    //NSString *title = [mediaItem valueForKey:MPMediaItemPropertyAlbumTitle];
    //NSString *artist = [mediaItem valueForKey:MPMediaItemPropertyAlbumArtist];
    //MPMediaItemArtwork *artwork = [mediaItem valueForKey:MPMediaItemPropertyArtwork];
    //UIImage *image = [artwork imageWithSize:CGSizeMake(100, 100)];//专辑图片
    
    NSLog(@"标题：%@,表演者：%@,专辑：%@",mediaItem.title ,mediaItem.artist,mediaItem.albumTitle);
    [self.musicPlayer setQueueWithItemCollection:mediaItemCollection];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 取消选择
-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 通知

// 添加通知
-(void)addNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playbackStateChange:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:self.musicPlayer];
}

// 播放状态改变通知
-(void)playbackStateChange:(NSNotification *)notification
{
    switch (self.musicPlayer.playbackState)
    {
        case MPMusicPlaybackStatePlaying:
            NSLog(@"正在播放...");
            break;
        case MPMusicPlaybackStatePaused:
            NSLog(@"播放暂停.");
            break;
        case MPMusicPlaybackStateStopped:
            NSLog(@"播放停止.");
            break;
        default:
            break;
    }
}

#pragma mark - Events

// 呈现选择器
- (void)selectClick
{
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

// 播放
- (void)playClick
{
    [self.musicPlayer play];
}

// 暂停
- (void)puaseClick
{
    [self.musicPlayer pause];
}

// 停止
- (void)stopClick
{
    [self.musicPlayer stop];
}

// 下一首
- (void)nextClick
{
    [self.musicPlayer skipToNextItem];
}

// 上一首
- (void)prevClick
{
    [self.musicPlayer skipToPreviousItem];
}

#pragma mark - Getter/Setter

-(MPMusicPlayerController *)musicPlayer
{
    if (!_musicPlayer)
    {
        _musicPlayer = [MPMusicPlayerController systemMusicPlayer];
        // 开启通知，否则监控不到MPMusicPlayerController的通知
        [_musicPlayer beginGeneratingPlaybackNotifications];
        // 添加通知
        [self addNotification];
        
        // 如果不使用MPMediaPickerController可以使用如下方法获得音乐库媒体队列
        //[_musicPlayer setQueueWithItemCollection:[self getLocalMediaItemCollection]];
    }
    return _musicPlayer;
}

-(MPMediaPickerController *)mediaPicker
{
    if (!_mediaPicker)
    {
        // 初始化媒体选择器，这里设置媒体类型为音乐，其实这里也可以选择视频、广播等
        //_mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
        _mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAny];
        // 允许多选
        _mediaPicker.allowsPickingMultipleItems = YES;
        // 显示icloud选项
        _mediaPicker.showsCloudItems = YES;
        _mediaPicker.prompt = @"请选择要播放的音乐";
        //设置选择器代理
        _mediaPicker.delegate = self;
    }
    return _mediaPicker;
}

@end
