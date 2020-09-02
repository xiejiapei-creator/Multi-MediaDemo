//
//  RootViewController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/26.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "BasicUseViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface BasicUseViewController ()<AVAudioRecorderDelegate>

@property(nonatomic, strong) AVAudioRecorder *audioRecorder;// 音频录音机
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;//音频播放器，用于播放录音文件
@property (nonatomic,strong) NSTimer *timer;// 录音声波监控（注意这里暂时不对播放进行监控）
@property (nonatomic,strong) UIProgressView *audioPower;// 音频波动
@property (nonatomic,strong) NSURL *savePathURL;// caf存储路径

@end

@implementation BasicUseViewController

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubviews];
}

- (void)createSubviews
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(150, 350, 100, 100);
    button.backgroundColor = [UIColor colorWithRed:0.6223 green:0.4564 blue:0.9735 alpha:1.0];
    [button setTitle:@"播放" forState:UIControlStateNormal];
    [button setTitle:@"暂停" forState:UIControlStateSelected];
    [button addTarget:self action:@selector(recorder:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *buttton1 = [[UIButton alloc]initWithFrame:CGRectMake(20, 100, 100, 40)];
    [buttton1 setTitle:@"开始录音" forState:UIControlStateNormal];
    [buttton1 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton1 setBackgroundColor:[UIColor yellowColor]];
    [buttton1 addTarget:self action:@selector(recordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton1.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton1];
    
    UIButton *buttton12 = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(buttton1.frame)+20, 100, 100, 40)];
    [buttton12 setTitle:@"暂停录音" forState:UIControlStateNormal];
    [buttton12 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton12 setBackgroundColor:[UIColor yellowColor]];
    [buttton12 addTarget:self action:@selector(pauseClick) forControlEvents:UIControlEventTouchUpInside];
    buttton12.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton12];
    
    UIButton *buttton2 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton1.frame)+30, 100, 40)];
    [buttton2 setTitle:@"恢复录音" forState:UIControlStateNormal];
    [buttton2 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton2 setBackgroundColor:[UIColor yellowColor]];
    [buttton2 addTarget:self action:@selector(resumeClick) forControlEvents:UIControlEventTouchUpInside];
    buttton2.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton2];
    
    UIButton *buttton3 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton2.frame)+30, 100, 40)];
    [buttton3 setTitle:@"停止录音" forState:UIControlStateNormal];
    [buttton3 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton3 setBackgroundColor:[UIColor yellowColor]];
    [buttton3 addTarget:self action:@selector(stopClick) forControlEvents:UIControlEventTouchUpInside];
    buttton3.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton3];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(50, 600, 300, 300)];
    progressView.progress = 0;
    self.audioPower = progressView;
    [self.view addSubview:self.audioPower];
}

-(void)recorder:(UIButton *)sender
{
    sender.selected = !sender.selected;
    sender.selected != YES ? [self.audioRecorder stop] : [self.audioRecorder record];
}

#pragma mark - Events

// 点击录音按钮
- (void)recordClick
{
    if (![self.audioRecorder isRecording])
    {
        // 首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        [self.audioRecorder record];
        self.timer.fireDate = [NSDate distantPast];
    }
}

// 点击暂停按钮
- (void)pauseClick
{
    if ([self.audioRecorder isRecording])
    {
        [self.audioRecorder pause];
        self.timer.fireDate = [NSDate distantFuture];
    }
}

// 点击恢复按钮，恢复录音只需要再次调用record，AVAudioSession会帮助你记录上次录音位置并追加录音
- (void)resumeClick
{
    [self recordClick];
}

// 点击停止按钮
- (void)stopClick
{
    [self.audioRecorder stop];
    self.timer.fireDate = [NSDate distantFuture];
    self.audioPower.progress = 0.0;
}

#pragma mark - 配置录音

// 判断设备录音权限
- (BOOL)checkPermission
{
    // AVAudioSessionRecordPermission枚举有三个参数 分别是未验证、未通过和通过
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    return permission == AVAudioSessionRecordPermissionGranted;
}

// 录音参数设置
- (NSDictionary *)recordSetting
{
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    // General Audio Format Settings
    recordSetting[AVFormatIDKey] = @(kAudioFormatLinearPCM);// 录音数据格式 可以参考CoreAudio 里面相关的值
    recordSetting[AVSampleRateKey] = @44100;// 采样率 单位是Hz 常见值 44100 48000 96000 192000
    recordSetting[AVNumberOfChannelsKey] = @2;// 声道数 1为单声道， 2为双声道（立体声）
    
    // Linear PCM Format Settings
    recordSetting[AVLinearPCMBitDepthKey] = @24;// 比特率 (位宽) 数据一般为： 8, 16, 24, 32
    recordSetting[AVLinearPCMIsBigEndianKey] = @YES;// 大小端编码：1为大端， 0为小端
    recordSetting[AVLinearPCMIsFloatKey] = @YES;
    
    // Encoder Settings
    recordSetting[AVEncoderAudioQualityKey] = @(AVAudioQualityMedium);// 声音质量，需要的参数是一个枚举，包括 Min Low Medium High Max
    recordSetting[AVEncoderBitRateKey] = @128000;// 音频的编码比特率 BPS传输速率 一般为128000bps
    return [recordSetting copy];
}

// 录音文件的名称使用时间戳+caf后缀
- (NSString *)newRecorderName
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddhhmmss";
    return [[formatter stringFromDate:[NSDate date]] stringByAppendingPathExtension:@"caf"];
}

// Document目录
- (NSString *)filePathWithName:(NSString *)fileName
{
    NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [urlStr stringByAppendingPathComponent:fileName];
}

// 取得录音文件保存路径
-(NSURL *)getSavePath
{
    NSURL *savePathURL = [NSURL fileURLWithPath:[self filePathWithName:[self newRecorderName]]];
    // 因为每次新录音文件都使用日期命名，所以需要使用存储之前的日期来进行获取而不能现在的日期
    self.savePathURL = savePathURL;
    return savePathURL;
}

// 获取录音时候的一些参数，监测声波变化
-(void)audioPowerChange
{
    // 启动一个计时器NSTimer，并在每次轮询的时候更新录音参数
    [self.audioRecorder updateMeters];
    
    // peakPowerForChannel:方法返回峰值
    float peak0 = ([_audioRecorder peakPowerForChannel:0] + 160.0) * (1.0 / 160.0);
    float peak1 = ([_audioRecorder peakPowerForChannel:1] + 160.0) * (1.0 / 160.0);
    
    // averagePowerForChannel:返回平均值，两个值的范围都是-160~0
    float ave0 = ([_audioRecorder averagePowerForChannel:0] + 160.0) * (1.0 / 160.0);
    float ave1 = ([_audioRecorder averagePowerForChannel:1] + 160.0) * (1.0 / 160.0);
    
    NSLog(@"峰值0:%f,峰值1:%f,平均值0:%f,平均值1:%f",peak0,peak1,ave0,ave1);
    
    // 取得第一个通道的音频，注意音频强度范围时-160到0
    float power = [self.audioRecorder averagePowerForChannel:0];
    CGFloat progress = (1.0 / 160.0) * (power + 160.0);
    [self.audioPower setProgress:progress];
}

#pragma mark - AVAudioRecorderDelegate

// 录音结束后获取到录音文件
// 录制完成或者调用stop时，回调用这个方法。但是如果是系统中断录音，则不会调用这个方法
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag)// 录音正常结束
    {
        NSLog(@"录音文件地址：%@",recorder.url.path) ;
        NSLog(@"录音文件大小：%@",[[NSFileManager defaultManager] attributesOfItemAtPath:recorder.url.path error:nil][NSFileSize]) ;
        
        
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
        NSFileManager *manager = [NSFileManager defaultManager];
        // 获得当前文件的所有子文件:subpathsAtPath:
        NSArray *pathList = [manager subpathsAtPath:path];

        NSMutableArray *audioPathList = [NSMutableArray array];
        // 遍历这个文件夹下面的子文件，只获得录音文件
        for (NSString *audioPath in pathList)
        {
            // 通过对比文件的延展名（扩展名、尾缀）来区分是不是录音文件
            if ([audioPath.pathExtension isEqualToString:@"caf"])
            {
                //把筛选出来的文件放到数组中 -> 得到所有的音频文件
                [audioPathList addObject:audioPath];
            }
        }
        
        NSLog(@"获得当前文件的所有子文件:%@",pathList);
        NSLog(@"所有的音频文件:%@",audioPathList);
        
        // 录音完成后播放录音
        if (![self.audioPlayer isPlaying])
        {
            NSLog(@"录音完成后播放录音");
            [self.audioPlayer play];
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

#pragma mark - Getter/Setter

- (AVAudioRecorder *)audioRecorder
{
     if (!_audioRecorder)
     {
         // 指定录音文件存储路径
         NSURL *fileUrl = [self getSavePath];
         NSError *error = nil;
         NSDictionary *setting = [self recordSetting];
         
         // 设置音频会话
         AVAudioSession *audioSession = [AVAudioSession sharedInstance];
         // 设置为播放和录音状态，以便可以在录制完之后播放录音
         [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
         [audioSession setActive:YES error:nil];
         
         // 创建AVAudioRecorder对象
         _audioRecorder = [[AVAudioRecorder alloc] initWithURL:fileUrl settings:setting error:&error];
         
         // 录音文件创建失败处理
         if (error)
         {
             NSLog(@"录音文件创建失败处理");
         }
         
         // 设置录音代理
         _audioRecorder.delegate = self;
         // 如果要获取录音时候的一些参数，监控声波，需要设置meteringEnabled参数为YES
         _audioRecorder.meteringEnabled = YES;
    }
    return _audioRecorder;
}

-(AVAudioPlayer *)audioPlayer
{
    if (!_audioPlayer)
    {
        NSURL *fileUrl = self.savePathURL;
        NSError *error = nil;
        
        // 初始化播放器，注意这里的Url参数只能是文件路径，不支持HTTP Url
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
        // 设置播放器属性
        _audioPlayer.numberOfLoops = 0; //设置为0不循环播放
        [_audioPlayer prepareToPlay]; //加载音频文件到缓存
        
        if (error)
        {
            NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}

-(NSTimer *)timer
{
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}



@end


