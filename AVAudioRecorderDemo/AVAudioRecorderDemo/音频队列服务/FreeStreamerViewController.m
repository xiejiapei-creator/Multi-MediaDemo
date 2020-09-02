//
//  FreeStreamerViewController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/9/1.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "FreeStreamerViewController.h"
#import "FSAudioStream.h"

@interface FreeStreamerViewController ()

@property (nonatomic,strong) FSAudioStream *audioStream;

@end

@implementation FreeStreamerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.audioStream play];
}

// 取得本地文件路径
-(NSURL *)getFileUrl
{
    NSString *urlStr = [[NSBundle mainBundle]pathForResource:@"桜道.mp3" ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:urlStr];
    return url;
}

// 取得网络文件路径
-(NSURL *)getNetworkUrl
{
    NSString *urlStr = @"http://192.168.1.102/liu.mp3";
    NSURL *url = [NSURL URLWithString:urlStr];
    return url;
}

// 创建FSAudioStream对象
-(FSAudioStream *)audioStream
{
    if (!_audioStream)
    {
        NSURL *url = [self getNetworkUrl];
        
        // 创建FSAudioStream对象
        _audioStream=[[FSAudioStream alloc] initWithUrl:url];
        _audioStream.onFailure=^(FSAudioStreamError error,NSString *description){
            NSLog(@"播放过程中发生错误，错误信息：%@",description);
        };
        _audioStream.onCompletion=^(){
            NSLog(@"播放完成!");
        };
        [_audioStream setVolume:0.5];//设置声音
    }
    return _audioStream;
}

@end

