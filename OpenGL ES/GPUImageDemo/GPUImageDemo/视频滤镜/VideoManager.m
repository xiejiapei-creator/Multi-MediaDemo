//
//  VideoManager.m
//  GPUImageDemo
//
//  Created by 谢佳培 on 2021/1/9.
//

#import "VideoManager.h"

#define COMPRESSEDVIDEOPATH [NSHomeDirectory() stringByAppendingFormat:@"/Documents/CompressionVideoField"]

@interface VideoManager ()<GPUImageVideoCameraDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong) GPUImageVideoCamera *videoCamera;// 摄像头
@property (nonatomic,strong) GPUImageSaturationFilter *saturationFilter;// 饱和度滤镜
@property (nonatomic,strong) GPUImageView *displayView;// 视频输出视图
@property (nonatomic,strong) GPUImageMovieWriter *movieWriter;// 视频写入
@property (nonatomic,strong) NSURL *movieURL;// 视频写入的地址URL
@property (nonatomic,copy) NSString *moviePath;// 视频写入路径
@property (nonatomic,copy) NSString *resultPath;// 压缩成功后的视频路径
@property (nonatomic,assign) int seconds;// 视频时长
@property (nonatomic,strong) NSTimer *timer;// 系统计时器
@property (nonatomic,assign) int recordSecond;// 计时器常量

@end

@implementation VideoManager

#pragma mark - 创建单例

static VideoManager *_manager;

+ (instancetype)manager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[VideoManager alloc] init];
    });
    return _manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_manager == nil)
        {
            _manager = [super allocWithZone:zone];
        }
    });
    return _manager;
}

#pragma mark - 控制录制过程

// 开始录制
- (void)startRecording
{
    // 1.获取录制路径
    NSString *defultPath = [self getVideoPathCache];
    self.moviePath = [defultPath stringByAppendingPathComponent:[self getVideoNameWithType:@"mp4"]];
    self.movieURL = [NSURL fileURLWithPath:self.moviePath];
    unlink([self.moviePath UTF8String]);// 这步的作用我也不知道
    
    // 2.视频写入
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 640.0)];
    self.movieWriter.encodingLiveVideo = YES;
    self.movieWriter.shouldPassthroughAudio = YES;
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    
    // 3.添加饱和度滤镜
    [self.saturationFilter addTarget:self.movieWriter];
    
    // 4.开始录制
    [self.movieWriter startRecording];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartRecordVideo)])
    {
        [self.delegate didStartRecordVideo];
    }
    
    // 5.开启计时器
    [self.timer setFireDate:[NSDate distantPast]];
    [self.timer fire];
}


// 结束录制
- (void)endRecording
{
    // 1.销毁计时器
    [self.timer invalidate];
    self.timer = nil;
    
    // 2.完成录制
    __weak typeof(self) weakSelf = self;
    [self.movieWriter finishRecording];

    // 3.移除饱和度滤镜和音频编码的对象
    [self.saturationFilter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    
    // 4.录制时间和录制视频最大时长进行比较
    if (self.recordSecond > self.maxTime)
    {
        NSLog(@"清除录制的视频");
    }
    else
    {
        // 5.进行压缩
        if ([self.delegate respondsToSelector:@selector(didCompressingVideo)])
        {
            [self.delegate didCompressingVideo];
        }
        
        [self compressVideoWithUrl:self.movieURL compressionType:AVAssetExportPresetMediumQuality filePath:^(NSString *resultPath, float memorySize, NSString *videoImagePath, int seconds) {
            
            // 6.压缩完后在回调方法中传入压缩文件的数据和耗时
            NSData *data = [NSData dataWithContentsOfFile:resultPath];
            CGFloat totalTime = (CGFloat)data.length / 1024 / 1024;

            if ([weakSelf.delegate respondsToSelector:@selector(didEndRecordVideoWithTime:outputFile:)])
            {
                [weakSelf.delegate didEndRecordVideoWithTime:totalTime outputFile:resultPath];
            }
        }];
    }
}


// 暂停录制
- (void)pauseRecording
{
    [self.timer invalidate];
    self.timer = nil;
    
    [_videoCamera pauseCameraCapture];
}

// 恢复录制
- (void)resumeRecording
{
    [_videoCamera resumeCameraCapture];
    [self.timer setFireDate:[NSDate distantPast]];
    [self.timer fire];
}

#pragma mark - 懒加载

// 摄像头
- (GPUImageVideoCamera *)videoCamera
{
    if (_videoCamera == nil)
    {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.delegate = self;
        [_videoCamera addAudioInputsAndOutputs];// 可防止允许声音通过的情况下，避免第一帧黑屏
    }
    return _videoCamera;
}

// 饱和度滤镜
- (GPUImageSaturationFilter *)saturationFilter
{
    if (_saturationFilter == nil)
    {
        _saturationFilter = [[GPUImageSaturationFilter alloc] init];
    }
    _saturationFilter.saturation = 0.1;
    return _saturationFilter;
}

// 展示视图
- (GPUImageView *)displayView
{
    if (_displayView == nil)
    {
        _displayView = [[GPUImageView alloc] initWithFrame:self.frame];
        _displayView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    }
    return _displayView;
}

// 计时器
- (NSTimer *)timer
{
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateWithTime) userInfo:nil repeats:YES];
    }
    return _timer;
}

#pragma mark - 摄像头

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"摄像头输出代理方法");
}

// 手电筒开关
- (void)turnTorchOn:(BOOL)on
{
    if ([_videoCamera.inputCamera hasTorch] && [_videoCamera.inputCamera hasFlash])
    {
        [_videoCamera.inputCamera lockForConfiguration:nil];
        if (on)
        {
            [_videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
            [_videoCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
        }
        else
        {
            [_videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
            [_videoCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
        }
        [_videoCamera.inputCamera unlockForConfiguration];
    }
}

// 切换前后摄像头
- (void)changeCameraPosition:(VideoManagerCameraType)type
{
    switch (type)
    {
        case VideoManagerCameraTypeFront:
        {
            [_videoCamera rotateCamera];
        }
            break;
        case VideoManagerCameraTypeBack:
        {
            [_videoCamera rotateCamera];
        }
            break;
        default:
            break;
    }
}

#pragma mark - 辅助方法

// 超过最大录制时长结束录制
- (void)updateWithTime
{
    self.recordSecond++;
    if (self.recordSecond >= self.maxTime)
    {
        [self endRecording];
    }
}

// 获取视频地址
-(NSString *)getVideoPathCache
{
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingString:@"videos"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!existed)
    {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoCache;
}

// 获取视频名称
- (NSString *)getVideoNameWithType:(NSString *)fileType
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString *timeStr = [formatter stringFromDate:nowDate];
    NSString *fileName = [NSString stringWithFormat:@"video_%@.%@",timeStr,fileType];
    return fileName;
}

#pragma mark - 加载到显示的视图上

- (void)showWithFrame:(CGRect)frame superView:(UIView *)superView
{
    _frame = frame;
     
    // 将滤镜添加到展示视图上
    [self.saturationFilter addTarget:self.displayView];
    // 为摄像机添加滤镜
    [self.videoCamera addTarget:self.saturationFilter];
    // 将展示视图添加到屏幕视图上
    [superView addSubview:self.displayView];
    // 摄像机开始捕捉视频
    [self.videoCamera startCameraCapture];
}

#pragma mark - 压缩视频

- (void)compressVideoWithUrl:(NSURL *)url compressionType:(NSString *)type filePath:(void(^)(NSString *resultPath,float memorySize,NSString * videoImagePath,int seconds))resultBlock
{
    NSString *resultPath;

    // 1.获取视频压缩前大小
    NSData *data = [NSData dataWithContentsOfURL:url];
    CGFloat totalSize = (float)data.length / 1024 / 1024;
    NSLog(@"压缩前大小：%.2fM",totalSize);
    
    // 2.获取视频时长
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    CMTime time = [avAsset duration];
    int seconds = ceil(time.value / time.timescale);
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:type])
    {
        // 1.输出中等质量压缩视频
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        // 2.用时间给文件命名 防止存储被覆盖
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        
        // 3.若压缩路径不存在重新创建
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isExist = [manager fileExistsAtPath:COMPRESSEDVIDEOPATH];
        if (!isExist)
        {
            [manager createDirectoryAtPath:COMPRESSEDVIDEOPATH withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // 4.配置输出文件
        resultPath = [COMPRESSEDVIDEOPATH stringByAppendingPathComponent:[NSString stringWithFormat:@"user%outputVideo-%@.mp4",arc4random_uniform(10000),[formatter stringFromDate:[NSDate date]]]];
        session.outputURL = [NSURL fileURLWithPath:resultPath];
        session.outputFileType = AVFileTypeMPEG4;
        session.shouldOptimizeForNetworkUse = YES;
        
        // 5.压缩过程中的操作回调
        [session exportAsynchronouslyWithCompletionHandler:^{
            switch (session.status)
            {
                case AVAssetExportSessionStatusUnknown:
                    break;
                case AVAssetExportSessionStatusWaiting:
                    break;
                case AVAssetExportSessionStatusExporting:
                    break;
                case AVAssetExportSessionStatusCancelled:
                    break;
                case AVAssetExportSessionStatusFailed:
                    break;
                case AVAssetExportSessionStatusCompleted:
                {
                    // 6.打印压缩后的视频大小
                    NSData *data = [NSData dataWithContentsOfFile:resultPath];
                    float compressedSize = (float)data.length / 1024 / 1024;
                    resultBlock(resultPath,compressedSize,@"",seconds);
                    NSLog(@"压缩后大小：%.2f",compressedSize);
                }
                default:
                    break;
            }
        }];
    }
}



@end







