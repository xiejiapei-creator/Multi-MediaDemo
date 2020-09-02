//
//  ViewController.m
//  AVCaptureFaceDemo
//
//  Created by 谢佳培 on 2020/8/27.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic,strong) AVCaptureSession *session;
// 对捕捉的数据进行实时预览
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;

// 所有脸庞
@property (nonatomic,copy) NSMutableArray *facesViewArray;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _facesViewArray = [NSMutableArray arrayWithCapacity:0];
    
    //1.获取输入设备（摄像头）
    NSArray *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].devices;
    AVCaptureDevice *deviceFace = devices[0];
    
    //2.根据输入设备创建输入对象
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceFace error:nil];
    
    //3.创建原数据的输出对象
    AVCaptureMetadataOutput *metaout = [[AVCaptureMetadataOutput alloc] init];
    
    //4.设置代理监听输出对象输出的数据，在主线程中刷新
    [metaout setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //5.设置输出质量(高像素输出)
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480])
    {
        [self.session setSessionPreset:AVCaptureSessionPreset640x480];
    }
    
    //6.添加输入和输出到会话
    [self.session beginConfiguration];
    if ([self.session canAddInput:input])
    {
        [self.session addInput:input];
    }
    if ([self.session canAddOutput:metaout])
    {
        [self.session addOutput:metaout];
    }
    [self.session commitConfiguration];
    
    //7.告诉输出对象要输出什么样的数据，识别人脸，最多可识别10张人脸
    [metaout setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    
    //8.创建预览图层
    AVCaptureSession *session = (AVCaptureSession *)self.session;
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:_previewLayer above:0];
    
    //9.设置有效扫描区域(默认整个屏幕区域)（每个取值0~1, 以屏幕右上角为坐标原点）
    metaout.rectOfInterest = self.view.bounds;
    
    //10.前置摄像头一定要设置一下，要不然画面是镜像
    for (AVCaptureVideoDataOutput *output in session.outputs)
    {
        for (AVCaptureConnection *connection in output.connections)
        {
            //判断是否是前置摄像头状态
            if (connection.supportsVideoMirroring)
            {
                //镜像设置
                connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            }
        }
    }
    
    //11.开始扫描
    [self.session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

//当检测到了人脸会走这个回调
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //移除旧画框
    for (UIView *faceView in self.facesViewArray)
    {
        [faceView removeFromSuperview];
    }
    [self.facesViewArray removeAllObjects];
    
    //将脸庞数据转换为脸图像，并创建脸方框
    for (AVMetadataFaceObject *faceobject in metadataObjects)
    {
        //转换为脸图像
        AVMetadataObject *face = [self.previewLayer transformedMetadataObjectForMetadataObject:faceobject];
        
        //创建脸方框
        UIView *faceBox = [[UIView alloc] initWithFrame:face.bounds];
        faceBox.layer.borderWidth = 3;
        faceBox.layer.borderColor = [UIColor redColor].CGColor;
        faceBox.backgroundColor = [UIColor clearColor];
        [self.view addSubview:faceBox];
        [self.facesViewArray addObject:faceBox];
    }
}

@end
