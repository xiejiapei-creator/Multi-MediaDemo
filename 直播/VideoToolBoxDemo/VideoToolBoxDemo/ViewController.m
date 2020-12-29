//
//  ViewController.m
//  VideoToolBoxDemo
//
//  Created by 谢佳培 on 2020/12/23.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic,strong)UILabel *tipLabel;
@property(nonatomic,strong)AVCaptureSession *capturesession;//捕捉会话，用于输入输出设备之间的数据传递
@property(nonatomic,strong)AVCaptureDeviceInput *captureDeviceInput;//捕捉输入
@property(nonatomic,strong)AVCaptureVideoDataOutput *captureDataOutput;//捕捉输出
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;//预览图层

@end

@implementation ViewController
{
    int  frameID; //帧ID
    dispatch_queue_t captureQueue; //捕获队列
    dispatch_queue_t encodeQueue;  //编码队列
    VTCompressionSessionRef encodeingSession;//编码session
    CMFormatDescriptionRef format; //编码格式
    NSFileHandle *fileHandele;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubview];
}

- (void)createSubview
{
    _tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(150, 200, 200, 50)];
    _tipLabel.text = @"H.264硬编码";
    _tipLabel.textColor = [UIColor redColor];
    [self.view addSubview:_tipLabel];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(150, 300, 100, 100)];
    [button setTitle:@"开始捕捉" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor orangeColor]];
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonClick:(UIButton *)button
{
    //判断_capturesession 和 _capturesession是否正在捕捉
    if (!_capturesession || !_capturesession.isRunning )
    {
        //修改按钮状态
        [button setTitle:@"停止捕捉" forState:UIControlStateNormal];
        
        //开始捕捉
        [self startCapture];
    }
    else
    {
        [button setTitle:@"开始捕捉" forState:UIControlStateNormal];
        
        //停止捕捉
        [self stopCapture];
    }
}

// 开始捕捉
- (void)startCapture
{
    // 配置捕捉视频
    [self captureVideo];
    
    // 存储捕捉到的文件
    [self saveFile];
    
    // 使用 VideoToolBox 进行编码
    [self initVideoToolBox];
    
    // 开始捕捉视频
    [self.capturesession startRunning];
}

// 配置捕捉视频
- (void)captureVideo
{
    //初始化CaptureSession
    self.capturesession = [[AVCaptureSession alloc]init];
    
    //设置捕捉分辨率
    self.capturesession.sessionPreset = AVCaptureSessionPreset640x480;
    
    //使用函数dispath_get_global_queue去初始化队列
    captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    encodeQueue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //输入输出
    AVCaptureDevice *inputCamera = nil;
    //获取用于视频捕捉的所有设备，例如前置摄像头、后置摄像头等
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        //拿到后置摄像头
        if ([device position] == AVCaptureDevicePositionBack)
        {
            inputCamera = device;
        }
    }
    //将捕捉设备 封装成 AVCaptureDeviceInput 对象
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:inputCamera error:nil];
    
    //判断是否能加入后置摄像头作为输入设备
    if ([self.capturesession canAddInput:self.captureDeviceInput])
    {
        //将设备添加到会话中
        [self.capturesession addInput:self.captureDeviceInput];
    }
    
    
    //配置输出
    self.captureDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    //设置丢弃最后的video frame为NO
    [self.captureDataOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    //设置video的视频捕捉的像素点压缩方式为420
    [self.captureDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    //设置捕捉代理和捕捉队列
    [self.captureDataOutput setSampleBufferDelegate:self queue:captureQueue];
    
    //判断是否能添加输出
    if ([self.capturesession canAddOutput:self.captureDataOutput])
    {
        //添加输出
        [self.capturesession addOutput:self.captureDataOutput];
    }
    
    //创建连接
    AVCaptureConnection *connection = [self.captureDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //设置连接的方向
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    //初始化图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.capturesession];
    
    //设置视频重力
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    //设置图层的frame
    [self.previewLayer setFrame:self.view.bounds];
    
    //添加图层
    [self.view.layer addSublayer:self.previewLayer];
}

// 存储捕捉到的文件
- (void)saveFile
{
    //获取沙盒路径
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject] stringByAppendingPathComponent:@"video.h264"];
    
    //先移除已存在的文件
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
    //新建文件
    BOOL createFile = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    if (!createFile)
    {
        NSLog(@"新建文件失败");
    }
    else
    {
        NSLog(@"成功新建文件");
    }
    NSLog(@"文件存储路径为：%@",filePath);
    
    //写入文件到存储路径
    fileHandele = [NSFileHandle fileHandleForWritingAtPath:filePath];
}

// 使用 VideoToolBox 进行编码
- (void)initVideoToolBox
{
    // 编码队列
    dispatch_sync(encodeQueue, ^{
        // 第一帧
        frameID = 0;
        
        // width和height表示分辨率，需要和AVFoundation的分辨率保持一致
        int width = 480, height = 640;
        
        // 1.调用VTCompressionSessionCreate创建编码session
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self), &encodeingSession);
        NSLog(@"调用VTCompressionSessionCreate创建编码session：%d",(int)status);
        if (status != 0)
        {
            NSLog(@"创建H264编码session失败");
            return ;
        }
        
        // 2.配置编码session的参数
        //设置实时编码输出（避免延迟）
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        
        //是否产生B帧(因为B帧在解码时并不是必要的，是可以抛弃B帧的)
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_ProfileLevel,kVTProfileLevel_H264_Baseline_AutoLevel);
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        
        //设置关键帧（GOPsize）间隔，GOP太小的话图像会模糊
        int frameInterval = 10;
        CFNumberRef frameIntervalRaf = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRaf);
        
        //设置期望帧率，不是实际帧率
        int fps = 10;
        CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
        
        //设置码率均值和上限
        int bitRate = width * height * 3 * 4 * 8;// 码率计算公式
        CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
        
        int bigRateLimit = width * height * 3 * 4;
        CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bigRateLimit);
        VTSessionSetProperty(encodeingSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
        
        // 3.开始编码
        VTCompressionSessionPrepareToEncodeFrames(encodeingSession);
    });
}

// 停止捕捉视频
- (void)stopCapture
{
    //停止捕捉
    [self.capturesession stopRunning];
    
    //移除预览图层
    [self.previewLayer removeFromSuperlayer];
    
    //结束videoToolbBox编码
    [self endVideoToolBox];
    
    //关闭文件存储
    [fileHandele closeFile];
    fileHandele = NULL;
}

// 结束videoToolbBox编码
- (void)endVideoToolBox
{
    VTCompressionSessionCompleteFrames(encodeingSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(encodeingSession);
    CFRelease(encodeingSession);
    encodeingSession = NULL;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// AV Foundation 获取到视频流
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // 开始视频录制，获取到摄像头的视频帧，传入encode方法中进行编码
    dispatch_sync(encodeQueue, ^{
        [self encode:sampleBuffer];
    });
}

- (void)encode:(CMSampleBufferRef)sampleBuffer
{
    // 拿到每一帧未编码数据
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 设置帧时间，如果不设置会导致时间轴过长
    CMTime presentationTimeStamp = CMTimeMake(frameID++, 1000);
    
    // 编码函数
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(encodeingSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    
    if (statusCode != noErr)
    {
        NSLog(@"H.264在VTCompressionSessionEncodeFrame时出错：%d",(int)statusCode);
        
        // 结束编码
        VTCompressionSessionInvalidate(encodeingSession);
        // 安全释放
        CFRelease(encodeingSession);
        encodeingSession = NULL;
        return;
    }
    
    NSLog(@"H.264在VTCompressionSessionEncodeFrame时成功");
}

// 编码完成后的回调函数
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    NSLog(@"didCompressH264 编码完成后的回调函数被调用 status状态为：%d，infoFlags为：%d",(int)status,(int)infoFlags);

    // 状态错误
    if (status != 0)
    {
        return;
    }
    
    // 没准备好
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264函数中的sampleBuffer数据没有准备好");
        return;
    }
    
    // C语言中的函数调用OC中的方法
    ViewController *encoder = (__bridge ViewController *)outputCallbackRefCon;
    
    // 判断当前帧是否为关键帧
    bool keyFrame = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    // 获取sps & pps 数据
    if (keyFrame)
    {
        // 获取图像存储方式，编码器等格式描述
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);

        // 获取sps count / size / content
        size_t sparameterSetSize,sparameterSetCount;
        const uint8_t *sparameterSet;
        
        // 通过下面这个函数获取到sps的count / size / content
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        
        if (statusCode == noErr)
        {
            // 获取pps
            size_t pparameterSetSize,pparameterSetCount;
            const uint8_t *pparameterSet;
            
            // 从第一个关键帧获取pps
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            
            // 获取H264参数集合中的SPS和PPS
            if (statusCode == noErr)
            {
                // 将sps/pps转化为NSData
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                
                // 将sps/pps写入文件
                if (encoder)
                {
                    [encoder gotSpsPps:sps pps:pps];
                }
            }
        }
        
        // 经过sps & pps即编码后的H264的NALU数据
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        
        // 用来记录单个数据块的长度和整个数据块的总长度
        size_t length,totalLength;
        // 记录首地址
        char *dataPointer;
        // 用来获取blockBuffer信息的函数，可以获取到单个数据块的长度和整个数据块的总长度、数据块的首地址
        OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
        
        // 创建成功后读取数据
        if (statusCodeRet == noErr)
        {
            size_t bufferOffset = 0;
            //返回的nalu数据前4个字节不是001的startcode,而是大端模式的帧长度length
            static const int AVCCHeaderLength = 4;
            
            //循环获取nalu数据
            while (bufferOffset < totalLength - AVCCHeaderLength)
            {
                uint32_t NALUnitLength = 0;
                
                //读取 一单元长度的 nalu
                memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
                
                //从大端模式转换为系统端模式
                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
                
                //获取nalu数据
                NSData *data = [[NSData alloc]initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
                
                //将nalu数据写入到文件
                [encoder gotEncodedData:data isKeyFrame:keyFrame];
                
                //读取下一个nalu 一次回调可能包含多个nalu数据
                bufferOffset += AVCCHeaderLength + NALUnitLength;
            }
        }
    }
}

// 第一帧写入 sps & pps
- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    NSLog(@"gotSpsPp %d %d",(int)[sps length],(int)[pps length]);
    
    // 写入之前的起始位
    const char bytes[] = "\x00\x00\x00\x01";
    // 删去'/0'
    size_t length = (sizeof bytes) - 1;
    
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    // 写入sps
    [fileHandele writeData:ByteHeader];
    [fileHandele writeData:sps];
    [fileHandele writeData:ByteHeader];
    [fileHandele writeData:pps];
}

// 将nalu数据写入到文件
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"将nalu数据写入到文件，数据长度为：%d",(int)[data length]);
    
    if (fileHandele != NULL)
    {
        // 创建起始位
        const char bytes[] ="\x00\x00\x00\x01";
        
        // 计算长度
        size_t length = (sizeof bytes) - 1;
        
        // 将头字节bytes转化为NSData
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        
        // 写入头字节。注意在写入NSLU数据之前，先写入起始位
        [fileHandele writeData:ByteHeader];
        
        // 写入H264数据到沙盒文件中
        [fileHandele writeData:data];
    }
}

@end



