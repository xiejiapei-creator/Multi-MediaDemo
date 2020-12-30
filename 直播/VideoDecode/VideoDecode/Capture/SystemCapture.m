//
//  SystemCapture.m
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import "SystemCapture.h"

@interface SystemCapture ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

// 是否正在进行捕捉
@property (nonatomic, assign) BOOL isRunning;
// 捕捉会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
// 代理队列
@property (nonatomic, strong) dispatch_queue_t captureQueue;

//============音频==========/

// 音频输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
// 接收音频输出数据
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
// 音频连接器
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

//============视频==========/
// 当前使用的视频设备
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;

// 前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;

// 接收输出数据
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

// 预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, assign) CGSize prelayerSize;

@end

@implementation SystemCapture
{
    SystemCaptureType capture;//捕捉类型
}

#pragma mark - 初始化音视频捕捉器

- (instancetype)initWithType:(SystemCaptureType)type
{
    self = [super init];
    if (self)
    {
        capture = type;
    }
    return self;
}

// 准备工作(只捕获音频时调用)
- (void)prepare
{
    [self prepareWithPreviewSize:CGSizeZero];
}

// 捕获内容包括视频时调用（预览层大小，添加到view上用来显示）
- (void)prepareWithPreviewSize:(CGSize)size
{
    _prelayerSize = size;
    if (capture == SystemCaptureTypeAudio)
    {
        [self setupAudio];
    }
    else if (capture == SystemCaptureTypeVideo)
    {
        [self setupVideo];
    }
    else if (capture == SystemCaptureTypeAll)
    {
        [self setupAudio];
        [self setupVideo];
    }
}

#pragma mark - 控制捕捉

// 开始捕捉
- (void)start
{
    if (!self.isRunning)
    {
        self.isRunning = YES;
        [self.captureSession startRunning];
    }
}

// 结束捕捉
- (void)stop
{
    if (self.isRunning)
    {
        self.isRunning = NO;
        [self.captureSession stopRunning];
    }
    
}

// 切换摄像头
- (void)changeCamera
{
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.videoInputDevice];
    
    if ([self.videoInputDevice isEqual: self.frontCamera])
    {
        self.videoInputDevice = self.backCamera;
    }
    else
    {
        self.videoInputDevice = self.frontCamera;
    }
    
    [self.captureSession addInput:self.videoInputDevice];
    [self.captureSession commitConfiguration];
}

#pragma mark - 授权检测

// 麦克风授权状态：0（未授权） 1（已授权） -1（拒绝）
+ (int)checkMicrophoneAuthor
{
    int result = 0;
    // 麦克风录音授权
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    switch (permissionStatus)
    {
        case AVAudioSessionRecordPermissionUndetermined:// 请求授权
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
            result = 0;
            break;
        case AVAudioSessionRecordPermissionDenied:// 拒绝
            result = -1;
            break;
        case AVAudioSessionRecordPermissionGranted:// 允许
            result = 1;
            break;
        default:
            break;
    }
    return result;
}

// 摄像头授权状态：0（未授权） 1（已授权） -1（拒绝）
+ (int)checkCameraAuthor
{
    int result = 0;
    // 视频录制授权
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (videoStatus)
    {
        case AVAuthorizationStatusNotDetermined:// 第一次进入录制视频界面，请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {}];
            break;
        case AVAuthorizationStatusAuthorized:// 已授权
            result = 1;
            break;
        default:
            result = -1;
            break;
    }
    return result;
}

#pragma mark - 输出代理

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // 捕捉到音视频数据后的委托回调
    if (connection == self.audioConnection)
    {
        [_delegate captureSampleBuffer:sampleBuffer type:SystemCaptureTypeAudio];
    }
    else if (connection == self.videoConnection)
    {
        [_delegate captureSampleBuffer:sampleBuffer type:SystemCaptureTypeVideo];
    }
}

#pragma mark - 配置音视频参数

// 配置音频
- (void)setupAudio
{
    // 麦克风设备
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    // 将 audioDevice -> AVCaptureDeviceInput 对象
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    // 音频输出
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
    
    // 添加音频输入输出设备的配置
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.audioInputDevice])
    {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.audioDataOutput])
    {
        [self.captureSession addOutput:self.audioDataOutput];
    }
    [self.captureSession commitConfiguration];
    
    // 进行连接
    self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}

// 配置视频
- (void)setupVideo
{
    // 所有video设备（包括前置和后置摄像头）
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    // 前后置摄像头
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    
    // 设置当前输入设备为前置摄像头
    self.videoInputDevice = self.backCamera;
    
    // 视频输出设备
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    //kCVPixelBufferPixelFormatTypeKey用来指定像素的输出格式，这里使用全画幅YUV420格式
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                             }];
    // 进行配置，添加视频输入和输出设备，并设置分辨率
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.videoInputDevice])
    {
        [self.captureSession addInput:self.videoInputDevice];
    }
    if([self.captureSession canAddOutput:self.videoDataOutput])
    {
        [self.captureSession addOutput:self.videoDataOutput];
    }
    // 设置分辨率
    [self setVideoPreset];
    [self.captureSession commitConfiguration];
    
    // 进行连接。commit后下面的代码才会有效
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 设置视频输出方向
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    // FPS指画面每秒传输帧数，每秒钟帧数愈多，所显示的动作就会越流畅，要避免动作不流畅的最低是30
    [self updateFps:25];
    
    // 设置预览图层
    [self setupPreviewLayer];
}

// 设置分辨率
- (void)setVideoPreset
{
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080])
    {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        _witdh = 1080; _height = 1920;
    }
    else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
    {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        _witdh = 720; _height = 1280;
    }
    else
    {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        _witdh = 480; _height = 640;
    }
}

// 设置FPS
- (void)updateFps:(NSInteger)fps
{
    // 获取当前capture设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    // 遍历所有设备（前后摄像头）
    for (AVCaptureDevice *videoDevice in videoDevices)
    {
        // 获取当前支持的最大fps
        float maxRate = [(AVFrameRateRange *)[videoDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        
        // 如果想要设置的fps小于或等于最大fps，就进行修改
        if (maxRate >= fps)
        {
            if ([videoDevice lockForConfiguration:NULL])
            {
                videoDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                videoDevice.activeVideoMaxFrameDuration = videoDevice.activeVideoMinFrameDuration;
                [videoDevice unlockForConfiguration];
            }
        }
    }
}

// 设置预览层
- (void)setupPreviewLayer
{
    self.preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.preLayer.frame =  CGRectMake(0, 0, self.prelayerSize.width, self.prelayerSize.height);
    self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;// 设置满屏
    [self.preview.layer addSublayer:self.preLayer];
}

#pragma mark - 销毁捕捉会话

- (void)dealloc
{
    NSLog(@"销毁捕捉会话");
    [self destroyCaptureSession];
}

- (void)destroyCaptureSession
{
    if (self.captureSession)
    {
        if (capture == SystemCaptureTypeAudio)
        {
            [self.captureSession removeInput:self.audioInputDevice];
            [self.captureSession removeOutput:self.audioDataOutput];
        }
        else if (capture == SystemCaptureTypeVideo)
        {
            [self.captureSession removeInput:self.videoInputDevice];
            [self.captureSession removeOutput:self.videoDataOutput];
        }
        else if (capture == SystemCaptureTypeAll)
        {
            [self.captureSession removeInput:self.audioInputDevice];
            [self.captureSession removeOutput:self.audioDataOutput];
            [self.captureSession removeInput:self.videoInputDevice];
            [self.captureSession removeOutput:self.videoDataOutput];
        }
    }
    self.captureSession = nil;
}

#pragma mark - 懒加载

- (AVCaptureSession *)captureSession
{
    if (!_captureSession)
    {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

- (dispatch_queue_t)captureQueue
{
    if (!_captureQueue)
    {
        _captureQueue = dispatch_queue_create("CaptureQueue", NULL);
    }
    return _captureQueue;
}

- (UIView *)preview
{
    if (!_preview)
    {
        _preview = [[UIView alloc] init];
    }
    return _preview;
}

@end
