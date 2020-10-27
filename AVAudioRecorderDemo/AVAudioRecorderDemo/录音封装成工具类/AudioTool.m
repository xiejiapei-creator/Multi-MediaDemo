//
//  AudioTool.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AudioTool.h"
#import "LameTool.h"
#import "AudioFilePathTool.h"

@interface AudioTool()<AVAudioRecorderDelegate>

// 录音对象
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

// 录音成功的block
@property (nonatomic, copy) AudioSuccess block;

// 录音文件的名字
@property (nonatomic, strong) NSString *audioFileName;

// 录音的类型
@property (nonatomic, strong) NSString *recordType;

// 是否边录边转mp3
@property (nonatomic, assign) BOOL isConventMp3;

// 计时器
@property (nonatomic, strong) NSTimer *timer;

@end


@implementation AudioTool

// 工具类单例
SingleM(AudioTool)

#pragma mark - 录音过程

// 开始录音
- (void)beginRecordWithRecordName:(NSString *)recordName withRecordType:(NSString *)type withIsConventToMp3:(BOOL)isConventToMp3
{
    //1. 正在录制就直接返回，防止多次点击录音
    if (_audioRecorder && [_audioRecorder isRecording])
    {
        NSLog(@"正在录制就直接返回");
        return;
    }
    
    _recordType = type;
    _isConventMp3 = isConventToMp3;
    
    //2. 录音的名字中已经包含录音的类型后缀则不再添加后缀
    if ([recordName containsString:[NSString stringWithFormat:@".%@",_recordType]])
    {
        _audioFileName = recordName;
    }
    else
    {
        _audioFileName = [NSString stringWithFormat:@"%@.%@",recordName,_recordType];
    }
    
    //3. 创建录音文件存放路径
    if (![AudioFilePathTool judgeFileOrFolderExists:cachesRecorderPath])
    {
        
        // 不存在则创建 /Library/Caches/Recorder 文件夹
        [AudioFilePathTool createFolder:cachesRecorderPath];
    }
    _recordPath = [cachesRecorderPath stringByAppendingPathComponent:_audioFileName];
    
    //4. 准备录音
    // prepareToRecord方法根据URL创建文件，并且执行底层Audio Queue初始化的必要过程，将录制启动时的延迟降到最低
    if ([self.audioRecorder prepareToRecord])
    {
        // 开始录音
        // 首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        [self.audioRecorder record];
        
        // 销毁之前的计时器
        [self.timer invalidate];
        
        // 创建新的计时器时刻监测录制时长
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:self selector:@selector(autoEndRecordingWithTime) userInfo:nil repeats:YES];
        self.timer = timer;
        
        // 判断是否需要边录边转 MP3
        if (isConventToMp3)
        {
            [[LameTool shareLameTool] audioRecodingToMP3:_recordPath isDeleteSourchFile:NO withSuccessBack:^(NSString * _Nonnull resultPath) {
                NSLog(@"转 MP3 成功");
                NSLog(@"转为MP3后的路径 = %@",resultPath);
            } withFailBack:^(NSString * _Nonnull error) {
                NSLog(@"转 MP3 失败");
            }];
        }
    }
}

// 录音文件每3分钟保存一个文件，保存成功则录制下一段，时长可配置
- (void)autoEndRecordingWithTime
{
    // 刷新音量数据
    [self.audioRecorder updateMeters];
    
    // 当前录音时长
    NSLog(@"当前录音时长：%f",self.audioRecorder.currentTime);
    
    // 录音文件每3分钟保存一个文件，保存成功则录制下一段，时长可配置
    if (self.audioRecorder.currentTime >= 180)
    {
        // 结束录音
        [self endRecord];
    }
}

// 结束录音
- (void)endRecord
{
    [self.audioRecorder stop];
}

// 暂停录音
- (void)pauseRecord
{
    [self.audioRecorder pause];
}

// 删除录音
- (void)deleteRecord
{
    // 删除录音之前必须先停止录音
    [self.audioRecorder stop];
    
    [self.audioRecorder deleteRecording];
}

// 重新录音
- (void)restartRecord
{
    // 清除之前旧的录音对象
    self.audioRecorder = nil;
    // 创建新的录音对象开始录音，参数用之前保存下来的旧的
    [self beginRecordWithRecordName:self.audioFileName withRecordType:self.recordType withIsConventToMp3:self.isConventMp3];
}

// 当前录音的时间
- (NSTimeInterval)audioCurrentTime
{
    return self.audioRecorder.currentTime;
}

#pragma mark - 音频信息

// 更新音频测量值
- (void)updateMeters
{
    [self.audioRecorder updateMeters];
}

// 获得指定声道的分贝峰值
- (float)peakPowerForChannel
{
    [self.audioRecorder updateMeters];
    return [self.audioRecorder peakPowerForChannel:0];
}

#pragma mark - AVAudioRecorderDelegate

// 录制完成或者调用stop时，回调用这个方法。但是如果是系统中断录音，则不会调用这个方法
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag)// 录音正常结束
    {
        NSLog(@"录音文件地址：%@",recorder.url.path) ;
        NSLog(@"录音文件大小：%@",[[NSFileManager defaultManager] attributesOfItemAtPath:recorder.url.path error:nil][NSFileSize]) ;
          
        if (self.isConventMp3)
        {
            [[LameTool shareLameTool] sendEndRecord];
        }
    }
    else// 未正常结束
    {
        
        if ([recorder deleteRecording])// 录音文件删除成功
        {
            NSLog(@"录音文件删除成功");
        }
        else// 录音文件删除失败
        {
            NSLog(@"录音文件删除失败");
        }
    }
    
    NSLog(@"录音结束");
}

// AVAudioSession通知：接收录制中断事件通知，并处理相关事件
// 监听诸如系统来电，闹钟响铃，Facetime……导致的音频录制终端事件
- (void)handleNotification:(NSNotification *)notification
{
    NSArray *allKeys = notification.userInfo.allKeys;
    // 判断事件类型
    if([allKeys containsObject:AVAudioSessionInterruptionTypeKey])
    {
        AVAudioSessionInterruptionType audioInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        switch (audioInterruptionType)
        {
            case AVAudioSessionInterruptionTypeBegan:
                NSLog(@"录音被打断……开始");
                break;
            case AVAudioSessionInterruptionTypeEnded:
                NSLog(@"录音被打断……结束");
                break;
        }
    }
    
    // 判断中断的音频录制是否可恢复录制
    if([allKeys containsObject:AVAudioSessionInterruptionOptionKey])
    {
        AVAudioSessionInterruptionOptions shouldResume = [[notification.userInfo valueForKey:AVAudioSessionInterruptionOptionKey] integerValue];
        if(shouldResume)
        {
            NSLog(@"录音被打断…… 结束 可以恢复录音了");
        }
    }
}

// 耳机：开启接近监视(靠近耳朵的时候听筒播放，离开的时候扬声器播放)
/*
- (void)proximityStateChange:(NSNotificationCenter *)notification
{
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        //靠近耳朵
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    else
    {
        //离开耳朵
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}
*/

#pragma mark - Getter/Setter

- (AVAudioRecorder *)audioRecorder
{
    __weak typeof(self) weakSelf = self;
    
    if (!_audioRecorder)
    {
//0. 设置录音会话
        // 音频会话是应用程序和操作系统之间的中间人。应用程序不需要具体知道怎样和音频硬件交互的细节，只需要把所需的音频行为委托给音频会话管理即可。
        /* Category
         * AVAudioSessionCategoryPlayAndRecord :录制和播放。打断不支持混音播放的APP，不会响应手机静音键开关
         * AVAudioSessionCategoryAmbient       :用于非以语音为主的应用，随着静音键和屏幕关闭而静音
         * AVAudioSessionCategorySoloAmbient   :类似AVAudioSessionCategoryAmbient不同之处在于它会中止其它应用播放声音
         * AVAudioSessionCategoryPlayback      :用于以语音为主的应用，不会随着静音键和屏幕关闭而静音，可在后台播放声音
         * AVAudioSessionCategoryRecord        :用于需要录音的应用，除了来电铃声，闹钟或日历提醒之外的其它系统声音都不会被播放，只提供单纯录音功能
         */
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        // 启动会话
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        // 注册音频录制中断通知
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handleNotification:) name:AVAudioSessionInterruptionNotification object:nil];
        
        // 耳机：开启接近监视(靠近耳朵的时候听筒播放，离开的时候扬声器播放)
        // [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
        
//1. 确定录音存放的位置
        NSURL *url = [NSURL URLWithString:weakSelf.recordPath];
        
//2. 设置录音参数
        NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
        
        /**设置编码格式AVFormatIDKey
         * kAudioFormatLinearPCM: 无损压缩，内容非常大
         * kAudioFormatMPEG4AAC
         */
        [recordSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        
        // 设置采样率AVSampleRateKey：必须保证和转码设置的相同
        // 采样率越高，文件越大，质量越好，反之，文件小，质量相对差一些，但是低于普通的音频，人耳并不能明显的分辨出好坏
        // 建议使用标准的采样率，8000、16000、22050、44100(11025.0)
        [recordSettings setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
        
        // 设置通道数AVNumberOfChannelsKey，用于指定记录音频的通道数。
        // 1为单声道，2为立体声。这里必须设置为双声道，不然转码生成的 MP3 会声音尖锐变声
        [recordSettings setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        
        // 设置音频质量AVEncoderAudioQualityKey，音频质量越高，文件的大小也就越大
        [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
        
//3. 创建录音对象
        NSError *error;
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&error];
        
        // 开启音量监测
        _audioRecorder.meteringEnabled = YES;
        // 设置录音完成委托回调
        _audioRecorder.delegate = self;
        
        if(error)
        {
            NSLog(@"创建录音对象时发生错误，错误信息：%@",error.localizedDescription);
        }
    }
    return _audioRecorder;
}

@end
