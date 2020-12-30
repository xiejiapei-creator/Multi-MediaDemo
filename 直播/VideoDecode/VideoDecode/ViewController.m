//
//  ViewController.m
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import "ViewController.h"
#import "SystemCapture.h"
#import "AVConfig.h"
#import "AAPLEAGLLayer.h"
#import "VideoEncoder.h"
#import "VideoDecoder.h"
#import "AudioEncoder.h"
#import "AudioDecoder.h"
#import "AudioPCMPlayer.h"

@interface ViewController ()<SystemCaptureDelegate,VideoEncoderDelegate, VideoDecoderDelegate, AudioDecoderDelegate, AudioEncoderDelegate>

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, strong) SystemCapture *capture;
@property (nonatomic, strong) AAPLEAGLLayer *displayLayer;
@property (nonatomic, strong) VideoEncoder *videoEncoder;
@property (nonatomic, strong) VideoDecoder *videoDecoder;
@property (nonatomic, strong) AudioEncoder *audioEncoder;
@property (nonatomic, strong) AudioDecoder *audioDecoder;
@property (nonatomic, strong) AudioPCMPlayer *pcmPlayer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubview];
    [self createSaveFile];
    [self createCaptureSession];
    [self createVideoEncoderAndDecoder];
}

// 开始捕捉
- (void)startCapture
{
     [self.capture start];
}

// 结束捕捉
- (void)stopCapture
{
    [self.capture stop];
}

// 关闭文件
- (void)closeFile
{
     [_handle closeFile];
}

- (void)createSubview
{
    UIButton *startCaptureButton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 620.f, 300, 50.f)];
    [startCaptureButton addTarget:self action:@selector(startCapture) forControlEvents:UIControlEventTouchUpInside];
    [startCaptureButton setTitle:@"开始捕捉" forState:UIControlStateNormal];
    [startCaptureButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    startCaptureButton.layer.cornerRadius = 5.f;
    startCaptureButton.clipsToBounds = YES;
    startCaptureButton.layer.borderWidth = 1.f;
    startCaptureButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:startCaptureButton];
    
    UIButton *stopCaptureButton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 720.f, 300, 50.f)];
    [stopCaptureButton addTarget:self action:@selector(stopCapture) forControlEvents:UIControlEventTouchUpInside];
    [stopCaptureButton setTitle:@"结束捕捉" forState:UIControlStateNormal];
    [stopCaptureButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    stopCaptureButton.layer.cornerRadius = 5.f;
    stopCaptureButton.clipsToBounds = YES;
    stopCaptureButton.layer.borderWidth = 1.f;
    stopCaptureButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:stopCaptureButton];
    
    UIButton *closeFileButton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 820.f, 300, 50.f)];
    [closeFileButton addTarget:self action:@selector(closeFile) forControlEvents:UIControlEventTouchUpInside];
    [closeFileButton setTitle:@"关闭文件" forState:UIControlStateNormal];
    [closeFileButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    closeFileButton.layer.cornerRadius = 5.f;
    closeFileButton.clipsToBounds = YES;
    closeFileButton.layer.borderWidth = 1.f;
    closeFileButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:closeFileButton];
}

#pragma mark - 创建

// 将H264转化为视频后写入到本地文件
- (void)createSaveFile
{
    _path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"xiejiapei.h264"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:_path])
    {
        if ([manager removeItemAtPath:_path error:nil])
        {
            NSLog(@"写入之前先删除之前存在的文件");
            if ([manager createFileAtPath:_path contents:nil attributes:nil])
            {
                NSLog(@"创建新文件成功");
            }
        }
    }
    else
    {
        if ([manager createFileAtPath:_path contents:nil attributes:nil])
        {
            NSLog(@"创建文件");
        }
    }
    
    NSLog(@"将H264转化为视频后写入到本地文件的路径为：%@", _path);
    _handle = [NSFileHandle fileHandleForWritingAtPath:_path];
}

// 创建捕获会话。左边屏幕展示录制的视频
- (void)createCaptureSession
{
    // 检查摄像头授权状态
    [SystemCapture checkCameraAuthor];
    
    // 捕获视频
    _capture = [[SystemCapture alloc] initWithType:SystemCaptureTypeAudio];
    
    // 传入预览层大小来创建预览层
    CGSize size = CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [_capture prepareWithPreviewSize:size];
    _capture.preview.frame = CGRectMake(0, 100, size.width, size.height);
    [self.view addSubview:_capture.preview];
    
    // 捕捉到音视频数据后的委托回调
    self.capture.delegate = self;
}

// 创建编码和解码器。右边屏幕展示解码后的视频
- (void)createVideoEncoderAndDecoder
{
    VideoConfig *config = [VideoConfig defaultVideoConfig];
    config.width = _capture.witdh;
    config.height = _capture.height;
    config.bitrate = config.height * config.width * 5;
    
    // 编码器（H264编码）
    _videoEncoder = [[VideoEncoder alloc] initWithConfig:config];
    _videoEncoder.delegate = self;
    
    // 解码器（H264解码）
    _videoDecoder = [[VideoDecoder alloc] initWithConfig:config];
    _videoDecoder.delegate = self;
    
    // 编码器（AAC编码）
    _audioEncoder = [[AudioEncoder alloc] initWithConfig:[AudioConfig defaultAudioConfig]];
    _audioEncoder.delegate = self;
    
    // 解码器（AAC解码）
    _audioDecoder = [[AudioDecoder alloc]initWithConfig:[AudioConfig defaultAudioConfig]];
    _audioDecoder.delegate = self;
    
    // 创建音频播放器
    _pcmPlayer = [[AudioPCMPlayer alloc] initWithConfig:[AudioConfig defaultAudioConfig]];
    
    // 显示解码后的数据
    CGSize size = CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    _displayLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(size.width, 100, size.width, size.height)];
    [self.view.layer addSublayer:_displayLayer];
}

#pragma mark - 代理方法

// 捕获音视频回调
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type: (SystemCaptureType)type
{
    if (type == SystemCaptureTypeAudio)
    {
        // 使用方式一：直接播放PCM数据
        // NSData *pcmData = [_audioEncoder convertAudioSamepleBufferToPcmData:sampleBuffer];
        // [_pcmPalyer palyePCMData:pcmData];
        
        // 使用方式二：AAC编码
        [_audioEncoder encodeAudioSamepleBuffer:sampleBuffer];
    }
    else
    {
        // 将捕获到的数据进行H264硬编码
        [_videoEncoder encodeVideoSampleBuffer:sampleBuffer];
    }
}

// 实现H264硬编码的回调方法（sps/pps）
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps
{
    // 可以将获取到的sps/pps数据直接写入文件
    //[_handle seekToEndOfFile];
    //[_handle writeData:sps];
    //[_handle seekToEndOfFile];
    //[_handle writeData:pps];
    
    // 也可以选择对sps/pps进行解码
    [_videoDecoder decodeNaluData:sps];
    [_videoDecoder decodeNaluData:pps];
}

// 实现H264硬编码的回调方法（数据）
- (void)videoEncodeCallback:(NSData *)h264Data
{
    // 可以将获取到的NSAL数据直接写入文件
    //[_handle seekToEndOfFile];
    //[_handle writeData:h264Data];
    
    // 也可以选择对数据进行解码
    [_videoDecoder decodeNaluData:h264Data];
}

// 实现H264解码的回调方法
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer
{
    // 通过OpenGL ES渲染，将解码后的数据显示在屏幕上
    if (imageBuffer)
    {
        _displayLayer.pixelBuffer = imageBuffer;
    }
}

// 实现AAC编码的回调方法
- (void)audioEncodeCallback:(NSData *)aacData
{
    // 使用方式一：写入文件
    // [_handle seekToEndOfFile];
    // [_handle writeData:aacData];

    // 使用方式二：直接解码
    [_audioDecoder decodeAudioAACData:aacData];
}

// 实现AAC解码的回调方法
- (void)audioDecodeCallback:(NSData *)pcmData
{
    NSLog(@"获取到了pcmData");
}

@end
