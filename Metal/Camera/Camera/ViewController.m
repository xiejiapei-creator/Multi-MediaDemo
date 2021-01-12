//
//  ViewController.m
//  Camera
//
//  Created by 谢佳培 on 2021/1/12.
//

#import "ViewController.h"
#import "ShaderTypes.h"
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
// 有一些滤镜处理的Metal实现
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface ViewController ()<MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) MTKView *mtkView;// 展示视图
@property (nonatomic, strong) AVCaptureSession *captureSession;// 负责输入和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;// 负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;// 输出设备
@property (nonatomic, strong) dispatch_queue_t processQueue;// 处理队列
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;// 纹理缓存区
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;// 命令队列
@property (nonatomic, strong) id<MTLTexture> texture;// 纹理

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 设置Metal
    [self setupMetal];
    // 设置AVFoundation
    [self setupCaptureSession];
}

- (void)setupMetal
{
    // 1.获取MTKView
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    [self.view insertSubview:self.mtkView atIndex:0];
    self.mtkView.delegate = self;
    
    // 2.设置MTKView的drawable纹理是可读写的(默认是只读)
    self.mtkView.framebufferOnly = NO;
    
    // 3.创建命令队列
    self.commandQueue = [self.mtkView.device newCommandQueue];
    
    // 4.创建Core Video的Metal纹理缓存区
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

// 设置AVFoundation进行视频采集
- (void)setupCaptureSession
{
    // 1.创建captureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    // 设置视频采集的分辨率
    self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
  
    // 2.创建串行队列（视频是有序的）
    self.processQueue = dispatch_queue_create("processQueue", DISPATCH_QUEUE_SERIAL);
   
    // 3.获取摄像头设备(前置/后置摄像头设备)
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *inputCamera = nil;
    // 循环设备数组，找到后置摄像头，设置为当前inputCamera
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            inputCamera = device;
        }
    }
    
    // 4.将AVCaptureDevice转换为AVCaptureDeviceInput
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    // 将设备添加到captureSession中
    if ([self.captureSession canAddInput:self.captureDeviceInput])
    {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    // 5.创建AVCaptureVideoDataOutput对象
    self.captureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    // 设置视频帧延迟时是否丢弃数据
    [self.captureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    // 这里设置格式为BGRA，而不用YUV的颜色空间，避免使用Shader转换
    // 这里必须和后面CVMetalTextureCacheCreateTextureFromImage保存图像像素存储格式保持一致，否则视频会出现异常现象
    [self.captureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    // 设置视频捕捉输出的代理方法
    [self.captureDeviceOutput setSampleBufferDelegate:self queue:self.processQueue];
    
    // 添加输出
    if ([self.captureSession canAddOutput:self.captureDeviceOutput])
    {
        [self.captureSession addOutput:self.captureDeviceOutput];
    }
    
    // 6.将输入与输出连接
    AVCaptureConnection *connection = [self.captureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    // 一定要设置视频方向，否则视频方向是异常的
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    // 7.开始捕捉
    [self.captureSession startRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// 实现视频采集回调方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // 1.从sampleBuffer获取视频像素缓存区对象
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
   
    // 2.获取捕捉视频的宽和高
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    // 3.根据视频像素缓存区创建Metal纹理缓存区
     
    // 4.从现有图像缓冲区创建核心视频Metal纹理缓冲区
    CVMetalTextureRef tmpTexture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    
    // 判断纹理缓冲区是否创建成功
    if(status == kCVReturnSuccess)
    {
        // 5.设置可绘制纹理的当前大小
        self.mtkView.drawableSize = CGSizeMake(width, height);
        // 6.返回纹理缓冲区的Metal纹理对象
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        // 7.使用完毕，则释放纹理缓冲区
        CFRelease(tmpTexture);
    }
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    NSLog(@"视图大小发生改变时会调用此方法");
}

// 视图渲染时会调用此方法
- (void)drawInMTKView:(MTKView *)view
{
    // 判断是否获取了AVFoundation采集的纹理数据
    if (self.texture)
    {
        // 1.创建指令缓冲
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
        // 2.将MTKView作为目标渲染纹理
        id<MTLTexture> drawingTexture = view.currentDrawable.texture;
        
        // 3.创建高斯滤镜，sigma值越高图像越模糊
        MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.mtkView.device sigma:1];
        
        // 4.高斯滤镜以Metal纹理作为输入和输出
        // 输入：摄像头采集的图像 self.texture
        // 输出：创建的纹理 drawingTexture(其实就是view.currentDrawable.texture)
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture];
        
        // 5.展示显示的内容并提交命令
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
        
        // 6.清空当前纹理，准备下一次的纹理数据读取
        self.texture = NULL;
    }
}


@end

