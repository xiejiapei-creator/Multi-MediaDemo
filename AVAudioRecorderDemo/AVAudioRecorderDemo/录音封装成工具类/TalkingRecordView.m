//
//  TalkingRecordView.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/9/11.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "TalkingRecordView.h"
#import "lame.h"
#import "AudioConverter.h"// 将wav转化为Amr存储下来
#import <AVFoundation/AVFoundation.h>

#define kChannels   1
#define kSampleRate 8000.0

@interface TalkingRecordView ()<AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;// 音频录音机
@property (nonatomic, strong) NSString *audioTemporarySavePath;// 音频文件临时存储路径
@property (nonatomic, strong) NSTimer *timer;// 计时器
@property (nonatomic, assign) AudioType audioType;// 想要转化为的音频文件类型
@property (nonatomic, assign) NSTimeInterval duration;// 录音时长
@property (nonatomic, assign) BOOL recording;// 是否正在录制

@property (nonatomic, strong) UIImageView *powerView;// 音量大小视图
@property (nonatomic, strong) UIImageView *iconView;// 录音机器图标
@property (nonatomic, strong) UILabel *tipLabel;// 提示语

@end

@implementation TalkingRecordView

#pragma mark - 创建视图

// 初始化
- (id)initWithFrame:(CGRect)frame delegate:(id)delegate convertToAudioType:(AudioType)audioType
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.delegate = delegate;
        self.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5];
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 0;
        self.layer.cornerRadius = 8;
        self.hidden = YES;// 刚开始隐藏
        
        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 120, 100)];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.iconView];
        
        self.powerView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 20, 30, 100)];
        [self addSubview:self.powerView];

        self.tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 125, 120, 20)];
        self.tipLabel.backgroundColor = [UIColor clearColor];
        self.tipLabel.font = [UIFont boldSystemFontOfSize:15];
        self.tipLabel.textColor = [UIColor whiteColor];
        self.tipLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.tipLabel];
        
        self.audioTemporarySavePath = [NSString stringWithFormat:@"%@/tmp/temporary.wav", NSHomeDirectory()];
        self.recording = NO;
        self.audioType = audioType;
    }
    return self;
}

#pragma mark - 录音状态

// 检查授权状态
- (void)checkMicrophoneAuthorization:(void (^)(void))permissionGranted withNoPermission:(void (^)(BOOL error))noPermission
{
    // 获取音频媒体授权状态
    AVAuthorizationStatus audioAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (audioAuthorizationStatus)
    {
        case AVAuthorizationStatusNotDetermined:
        {
            // 第一次进入APP提示用户授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                
                granted ? permissionGranted() : noPermission(NO);
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        {
            // 通过授权
            permissionGranted();
            break;
        }
        case AVAuthorizationStatusRestricted:
        {
            // 拒绝授权
            noPermission(YES);
            break;
        }
        case AVAuthorizationStatusDenied:
        {
            // 提示跳转到相机设置(这里使用了blockits的弹窗方法）
            noPermission(NO);
            break;
        }
        default:
            break;
    }
}

// 开始录音
- (void)startRecord
{
    // 创建音频会话
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    
    __weak __typeof(self) weakSelf = self;
    // 检查授权状态
    [self checkMicrophoneAuthorization:^{
        // 修改录音状态为正在录音
        weakSelf.recording = YES;
        
       
        if (self.audioType == AudioTypeAMR)// 想要转化为的音频文件类型为AMR
        {
            // 音频存储路径
            weakSelf.audioFileSavePath = [NSString stringWithFormat:@"%@/tmp/%.0f.amr", NSHomeDirectory(), [NSDate timeIntervalSinceReferenceDate] * 1000];
        }
        else if (self.audioType == AudioTypeMP3)// 想要转化为的音频文件类型为MP3
        {
            // 音频存储路径
            weakSelf.audioFileSavePath = [NSString stringWithFormat:@"%@/tmp/%.0f.mp3", NSHomeDirectory(), [NSDate timeIntervalSinceReferenceDate] * 1000];
        }
        
        if (weakSelf.recorder == nil)// 需要创建音频录音机
        {
            // 音频参数设置
            NSMutableDictionary *recorderSetting = [[NSMutableDictionary alloc] init];
            [recorderSetting setValue : [NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
            [recorderSetting setValue :[NSNumber numberWithFloat:kSampleRate] forKey: AVSampleRateKey];
            [recorderSetting setValue :[NSNumber numberWithInt:kChannels] forKey: AVNumberOfChannelsKey];
            [recorderSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
            
            
            // 存储路径（区分模拟器和真机）
#if TARGET_IPHONE_SIMULATOR
            NSURL *savePathURL = [NSURL fileURLWithPath:weakSelf.audioTemporarySavePath];
#elif TARGET_OS_IPHONE
            NSURL *savePathURL = [NSURL URLWithString:weakSelf.audioTemporarySavePath];
#endif
            
            // 创建音频录音机
            AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:savePathURL settings:recorderSetting error:nil];
            weakSelf.recorder = recorder;
        }
        // 设置音频录音机的代理和监测
        weakSelf.recorder.delegate = self;
        weakSelf.recorder.meteringEnabled = YES;
        
        // 准备录音
        if ([weakSelf.recorder prepareToRecord])
        {
            // 展示音量大小视图
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.powerView.hidden = NO;
            });
            
            // 开始录音
            [weakSelf.recorder record];
            // 销毁之前的计时器
            [weakSelf.timer invalidate];
            // 创建新的计时器时刻更新音量大小
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:weakSelf selector:@selector(detectionVoice) userInfo:nil repeats:YES];
            weakSelf.timer = timer;
        }
            
    } withNoPermission:^(BOOL error) {
        if (error)
        {
            NSLog(@"无法录音");
        }
        else
        {
            NSLog(@"没有录音权限，请前往 “设置” - “隐私” - “麦克风” 为易维帮助台开启权限");
        }
    }];
}

// 时刻更新音量大小
- (void)detectionVoice
{
    // 刷新音量数据
    [self.recorder updateMeters];
    double lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));

    // 根据音量大小变化改变图片
    if (lowPassResults <= 0.10)
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p1.png"]];
    }
    else if (lowPassResults <= 0.20)
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p2.png"]];
    }
    else if (lowPassResults <= 0.30)
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p3.png"]];
    }
    else if (lowPassResults <= 0.40)
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p4.png"]];
    }
    else if (lowPassResults <= 0.50)
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p5.png"]];
    }
    else if (lowPassResults <= 0.60)
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p6.png"]];
    }
    else
    {
        [self.powerView setImage:[UIImage imageNamed:@"talk_sound_p7.png"]];
    }
    
    // 录制一个小时后自动结束录音
    if (self.recorder.currentTime >= 59.9)
    {
        [self endRecord];
    }
}

// 取消录音
- (void)cancelRecord
{
    // 隐藏音量大小视图
    self.powerView.hidden = YES;
    
    // 销毁计时器
    [self.timer invalidate];
    self.timer = nil;
    
    // 停止录音并销毁音频录音机
    self.recording = NO;
    self.recorder.delegate = nil;
    [self.recorder stop];
    self.recorder = nil;
    
    // 修改录音状态为未录制
    self.talkState = 0;
}

// 结束录音
- (void)endRecord
{
    // 记录录音完成时候的时长
    self.duration = self.recorder.currentTime;
    
    // 隐藏音量大小视图
    self.powerView.hidden = YES;
    
    // 销毁计时器
    [self.timer invalidate];
    self.timer = nil;
    
    // 停止录音
    self.recording = NO;
    [self.recorder stop];
    
    // 修改录音状态为未录制
    self.talkState = 0;
}

// 录音状态改变时调用
- (void)setTalkState:(int)talkState
{
    if (_talkState != talkState)
    {
        if (talkState == 1)// 录音中
        {
            // 展示音量大小视图
            self.powerView.hidden = NO;
            // 展示录音机器图标
            self.iconView.frame = CGRectMake(20, 20, 120, 100);
            self.iconView.image = [UIImage imageNamed:@"talk_icon_recoder"];
            // 展示录音提示语
            self.tipLabel.text = @"录制中...";
            // 录音开始
            if (!self.recording)
            {
                [self startRecord];
            }
        }
        else if (talkState == 2)// 取消录音
        {
            // 隐藏音量大小视图
            self.powerView.hidden = YES;
            // 展示取消录音图标
            self.iconView.frame = CGRectMake(20, 50, 120, 40);
            self.iconView.image = [UIImage imageNamed:@"talk_icon_recordCancel"];
            // 展示取消提示语
            self.tipLabel.text = @"放开手指取消";
        }
        else// 未录音或者录音完成
        {
            // 销毁取消录音或者录音机器图标
            self.iconView.image = nil;
        }
    }
}

#pragma mark - AVAudioRecorderDelegate

// 录音完成时调用
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)sender successfully:(BOOL)flag
{
    if (flag)
    {
        // 将音频转化为MP3
        [self audioConvert];
        
        // 调用录音完成时调用的委托方法
        if ([self.delegate respondsToSelector:@selector(recordView:didFinishSavePath:duration:convertToAudioType:)])
        {
            NSLog(@"录音时长为：%f",self.duration);
            [self.delegate recordView:self didFinishSavePath:self.audioFileSavePath duration:self.duration convertToAudioType:self.audioType];
        }
        
        // 销毁音频录音机
        self.recorder.delegate = nil;
        self.recorder = nil;
    }
}

#pragma mark - 音频转化

- (void)audioConvert
{
    // 音频文件路径
    NSString * audioFileSavePath = self.audioFileSavePath;
    if (self.audioType == AudioTypeAMR)// 想要转化为的音频文件类型为AMR
    {
        // 将wav转化为Amr存储下来
        [AudioConverter wavToAmr:self.audioTemporarySavePath amrSavePath:audioFileSavePath];

    }
    else// 想要转化为的音频文件类型为MP3
    {
        @try {
            int read, write;
            // source 被转换的音频文件位置
            FILE *pcm = fopen([self.audioTemporarySavePath cStringUsingEncoding:1], "rb");
            // skip file header 跳过 PCM header 能保证录音的开头没有噪音
            fseek(pcm, 4*1024, SEEK_CUR);
            // output 输出生成的Mp3文件位置
            FILE *mp3 = fopen([audioFileSavePath cStringUsingEncoding:1], "wb");
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*kChannels];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_in_samplerate(lame, kSampleRate);
            // 设置1为单通道，默认为2双通道
            lame_set_num_channels(lame,kChannels);
            lame_set_mode(lame, MONO);
            lame_set_brate(lame, 16);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            do {
                read = (int)fread(pcm_buffer, kChannels*sizeof(short int), PCM_SIZE, pcm);
                
                if (read == 0)
                {
                   write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                }
                else if (kChannels == 1)
                {
                    write = lame_encode_buffer(lame, pcm_buffer, nil, read, mp3_buffer, MP3_SIZE);
                }
                else if (kChannels == 2)
                {
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }
                
                fwrite(mp3_buffer, write, 1, mp3);
                
            } while (read != 0);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
        @catch (NSException *exception)
        {
            // 转化出错清空音频文件存储路径
            NSLog(@"转化为MP3出错了：%@", [exception description]);
            self.audioFileSavePath = nil;
        }
        @finally
        {
            // 打印路径
            NSLog(@"顺利生成了MP3文件，路径为: %@",self.audioFileSavePath);
        }
 
    }
}

@end
