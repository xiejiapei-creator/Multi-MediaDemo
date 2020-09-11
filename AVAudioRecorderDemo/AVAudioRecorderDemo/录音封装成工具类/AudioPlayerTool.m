//
//  AudioPlayerTool.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AudioPlayerTool.h"
#import "AudioConverter.h"

@interface AudioPlayerTool()<AVAudioPlayerDelegate>

// 音乐播放器
@property (nonatomic ,strong) AVAudioPlayer *audioPlayer;
// 音乐播放器
@property (strong, nonatomic) AVAudioPlayer *currentPlayer;
// 本地路径
@property (copy, nonatomic) NSString * localPath;

@end

@implementation AudioPlayerTool

// 工具类单例
SingleM(AudioPlayerTool)

#pragma mark - 播放器

// 初始化
- (instancetype)initWithDelegate:(id)delegate
{
    if (self = [super init])
    {
        self.delegate = delegate;
    }
    return self;
}

// 根据URL播放音频
- (void)playAtURL:(NSString*)url isMP3Audio:(BOOL)isMP3Audio
{
    // 获取localPath
    NSString *localPath = [AudioPlayerTool defaultCachePathWithURL:url isMP3Audio:isMP3Audio];
    self.localPath = localPath;
    
    // 根据localPath播放音频
    [self playAtPath:localPath isMP3Audio:isMP3Audio];
}

// 根据localPath播放音频
- (void)playAtPath:(NSString *)path isMP3Audio:(BOOL)isMP3Audio
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    
    // 先停止之前的播放器
    if (self.currentPlayer)
    {
        self.currentPlayer.delegate = nil;
        [self.currentPlayer stop];
        self.currentPlayer = nil;
    }
    
    // 创建新的播放器
    NSData * data = [NSData dataWithContentsOfFile:path];
    if (!isMP3Audio)
    {
        // 如果是AVE则需要转化数据
        data = [AudioConverter getWAVEDataFrom:data];
    }
    NSError * error = nil;
    AVAudioPlayer * player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    
    // 创建出错
    if (error)
    {
        // 调用播放完成的委托回调
        if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:)])
        {
            [self.delegate audioPlayerDidFinishPlaying:self];
        }
        return;
    }
    
    // 开始播放
    player.delegate = self;
    [player prepareToPlay];
    [player play];
    self.currentPlayer = player;
}

// 默认缓存路径
+ (NSString*)defaultCachePathWithURL:(NSString*)url isMP3Audio:(BOOL)isMP3Audio
{
    // 获取缓存目录
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    // 创建缓存路径
    NSString *newPath  = [cachePath stringByAppendingPathComponent:@"AudioCaches"];
    
    NSString *localPath;
    if (isMP3Audio)
    {
        localPath = [newPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", url]];
    }
    else
    {
        localPath = [newPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.amr", url]];
    }
    
    return localPath;
}

// 停止播放
- (void)stopPlaying
{
    if (self.currentPlayer)
    {
        self.currentPlayer.delegate = nil;
        [self.currentPlayer stop];
        self.currentPlayer = nil;
    }
}

#pragma mark - 播放按钮

// 播放歌曲
- (AVAudioPlayer *)playAudioWith:(NSString *)audioPath
{
    // 获取歌曲文件的url
    NSURL *url = [NSURL URLWithString:audioPath];
    if (url == nil)
    {
        url = [[NSBundle mainBundle] URLForResource:audioPath.lastPathComponent withExtension:nil];
    }
    
    // 使用文件URL初始化播放器，注意这个URL不能是HTTP URL，AVAudioPlayer不支持加载网络媒体流，只能播放本地文件
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.delegate = self;
    
    // 加载音频文件到缓冲区，注意即使在播放之前音频文件没有加载到缓冲区程序也会隐式调用此方法
    [self.audioPlayer prepareToPlay];
    
    // 播放音频文件
    [self.audioPlayer play];
    
    return self.audioPlayer;
}

// 恢复当前歌曲播放
- (void)resumeCurrentAudio
{
    [self.audioPlayer play];
}

// 暂停歌曲
- (void)pauseCurrentAudio
{
    [self.audioPlayer pause];
}

// 停止歌曲
- (void)stopCurrentAudio
{
    [self.audioPlayer stop];
}

#pragma mark - AVAudioPlayerDelegate

// 音频播放完成
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"音频播放完成");
    
    // 停止播放并销毁播放器
    [player stop];
    self.currentPlayer = nil;
    
    // 调用播放完成的委托回调
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:)])
    {
        [self.delegate audioPlayerDidFinishPlaying:self];
    }
}

// 音频解码发生错误
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"音频解码发生错误");
    // 停止播放
    [player stop];
    // 调用播放完成的委托回调
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:)])
    {
        [self.delegate audioPlayerDidFinishPlaying:self];
    }
}

#pragma mark - Getter/Setter

// 音量大小
-(float)volumn
{
    return self.audioPlayer.volume;
}

- (void)setVolumn:(float)volumn
{
    self.audioPlayer.volume = volumn;
}

// 播放进度
- (float)progress
{
    return self.audioPlayer.currentTime / self.audioPlayer.duration;
}

// 是否允许改变播放速率
- (BOOL)enableRate
{
    return self.enableRate;
}

- (void)setEnableRate:(BOOL)enableRate
{
    [self.audioPlayer setEnableRate:enableRate];
}
 
// 播放速率
- (float)rate
{
    return self.rate;
}

- (void)setRate:(float)rate
{
    [self.audioPlayer setRate:rate];
}

// 立体声平衡
- (float)span
{
    return self.span;
}

-(void)setSpan:(float)span
{
    [self.audioPlayer setPan:span];
}

// 循环播放次数
- (NSInteger)numberOfLoops
{
    return self.numberOfLoops;
}

- (void)setNumberOfLoops:(NSInteger)numberOfLoops
{
    [self.audioPlayer setNumberOfLoops:numberOfLoops];
}

@end
