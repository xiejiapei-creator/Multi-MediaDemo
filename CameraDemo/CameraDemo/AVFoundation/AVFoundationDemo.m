//
//  AVFoundationDemo.m
//  CameraDemo
//
//  Created by 谢佳培 on 2020/9/2.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AVFoundationDemo.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface AVFoundationDemo ()<AVCapturePhotoCaptureDelegate,AVCaptureFileOutputRecordingDelegate>//拍照/视频文件输出代理

@property (strong,nonatomic) AVCaptureSession *captureSession; //负责输入和输出设备之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput; //负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCapturePhotoOutput *capturePhotoOutput; //照片输出流
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput; //视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer; //相机拍摄预览图层

@property (assign,nonatomic) BOOL enableRotation; //是否允许旋转（注意在视频录制过程中禁止屏幕旋转）
@property (assign,nonatomic) CGRect *lastBounds; //旋转的前大小
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier; //后台任务标识

@property (strong, nonatomic) UIView *viewContainer;
@property (strong, nonatomic) UIImageView *focusCursor; //聚焦光标
@property (strong, nonatomic) UIButton *flashAutoButton;//自动闪光灯按钮
@property (strong, nonatomic) UIButton *flashOnButton;//打开闪光灯按钮
@property (strong, nonatomic) UIButton *flashOffButton;//关闭闪光灯按钮

@end

@implementation AVFoundationDemo

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 视频按钮
    UIButton *takeVideoButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 300, 80)];
    takeVideoButton.backgroundColor = [UIColor blackColor];
    [takeVideoButton setTitle:@"视频按钮" forState:UIControlStateNormal];
    [takeVideoButton addTarget:self action:@selector(takeVideoClick::) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takeVideoButton];
    
    // 拍照按钮
    UIButton *takeButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 300, 80)];
    takeButton.backgroundColor = [UIColor blackColor];
    [takeButton setTitle:@"拍照按钮" forState:UIControlStateNormal];
    [takeButton addTarget:self action:@selector(takePictureClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takeButton];

    // 自动闪光灯按钮
    UIButton *flashAutoButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 300, 80)];
    flashAutoButton.backgroundColor = [UIColor blackColor];
    [flashAutoButton setTitle:@"自动闪光灯按钮" forState:UIControlStateNormal];
    [flashAutoButton addTarget:self action:@selector(flashAutoClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashAutoButton];
    self.flashAutoButton = flashAutoButton;
    
    // 打开闪光灯按钮
    UIButton *flashOnButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 300, 80)];
    flashOnButton.backgroundColor = [UIColor blackColor];
    [flashOnButton setTitle:@"拍照按钮" forState:UIControlStateNormal];
    [flashOnButton addTarget:self action:@selector(flashOnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashOnButton];
    self.flashOnButton = flashOnButton;
    
    // 关闭闪光灯按钮
    UIButton *flashOffButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 400, 300, 80)];
    flashOffButton.backgroundColor = [UIColor blackColor];
    [flashOffButton setTitle:@"拍照按钮" forState:UIControlStateNormal];
    [flashOffButton addTarget:self action:@selector(flashOffClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashOffButton];
    self.flashOffButton = flashOffButton;
    
    // 录像视图
    UIView *viewContainer = [[UIView alloc] initWithFrame:self.view.frame];
    viewContainer.backgroundColor = [UIColor blueColor];
    [self.view addSubview:viewContainer];
    self.viewContainer = viewContainer;
    
    // 聚焦光标
    UIImageView *focusCursor = [[UIImageView alloc] initWithFrame:CGRectMake(100, 200, 40, 40)];
    focusCursor.image = [UIImage imageNamed:@"focusCursor.png"];
    [self.view addSubview:focusCursor];
    self.focusCursor = focusCursor;
}

// 配置录制
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 1.初始化会话
    _captureSession = [[AVCaptureSession alloc] init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
    {
        // 设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    // 2.获得输入设备，取得后置摄像头
    AVCaptureDevice *captureDevice = [self cameraWithPostion:AVCaptureDevicePositionBack];
    if (!captureDevice)
    {
        NSLog(@"取得后置摄像头时出现问题.");
        return;
    }
    
    NSError *error = nil;
    // 3.根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error)
    {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //（视频）添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    if (error)
    {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    // 4.初始化设备输出对象，用于获得输出数据
    _capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];//（视频）
    
    // 5.将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput])
    {
        [_captureSession addInput:_captureDeviceInput];
        
        //（视频）
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported])
        {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    // 6.将设备输出添加到会话中
    if ([_captureSession canAddOutput:_capturePhotoOutput])
    {
        [_captureSession addOutput:_capturePhotoOutput];
        [_captureSession addOutput:_captureMovieFileOutput];//（视频）
    }
    
    // 7.创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    CALayer *layer = self.viewContainer.layer;
    layer.masksToBounds = YES;
    
    _captureVideoPreviewLayer.frame = layer.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    
    // 8.将视频预览层添加到界面中
    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];
    
    [self addNotificationToCaptureDevice:captureDevice];
    [self addGenstureRecognizer];
    [self setFlashModeButtonStatus];
}

// 开始录制
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

// 停止录制
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}

#pragma mark - 视频旋转

//（视频）是否可旋转
-(BOOL)shouldAutorotate
{
    return self.enableRotation;
}

// 屏幕旋转时调整视频预览图层的方向
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    AVCaptureConnection *captureConnection=[self.captureVideoPreviewLayer connection];
    captureConnection.videoOrientation=(AVCaptureVideoOrientation)toInterfaceOrientation;
}

// 旋转后重新设置大小
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    _captureVideoPreviewLayer.frame = self.viewContainer.bounds;
}

#pragma mark - 视频录制

- (void)takeVideoClick:(UIButton *)sender
{
    // 根据设备输出获得连接
    AVCaptureConnection *captureConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    // 根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording])
    {
        self.enableRotation = NO;
        // 如果支持多任务则则开始多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported])
        {
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        
        // 预览图层和视频方向保持一致
        captureConnection.videoOrientation = [self.captureVideoPreviewLayer connection].videoOrientation;
        NSString *outputFielPath = [NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
        NSLog(@"保存路径为 :%@",outputFielPath);
        NSURL *fileUrl = [NSURL fileURLWithPath:outputFielPath];
        [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }
    else
    {
        // 停止录制
        [self.captureMovieFileOutput stopRecording];
    }
}

#pragma mark - 视频输出代理

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"开始录制...");
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"视频录制完成.");
    
    //视频录入完成之后在后台将视频存储到相簿
    self.enableRotation = YES;
    UIBackgroundTaskIdentifier lastBackgroundTaskIdentifier = self.backgroundTaskIdentifier;
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *tempURL = [documentsURL URLByAppendingPathComponent:[outputFileURL lastPathComponent]];

    [[NSFileManager defaultManager] moveItemAtURL:outputFileURL toURL:tempURL error:nil];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:tempURL];

        NSLog(@"%@", changeRequest.description);
    } completionHandler:^(BOOL success, NSError *error) {
        if (success)
        {
            NSLog(@"成功保存视频到相簿");
            if (lastBackgroundTaskIdentifier != UIBackgroundTaskInvalid)
            {
                [[UIApplication sharedApplication] endBackgroundTask:lastBackgroundTaskIdentifier];
            }
            [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
        }
        else
        {
            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
            [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
        }
    }];
}

#pragma mark - 闪光灯

// 自动闪光灯开启
- (void)flashAutoClick:(UIButton *)sender
{
    [self setFlashMode:AVCaptureFlashModeAuto];
    [self setFlashModeButtonStatus];
}

// 打开闪光灯
- (void)flashOnClick:(UIButton *)sender
{
    [self setFlashMode:AVCaptureFlashModeOn];
    [self setFlashModeButtonStatus];
}

// 关闭闪光灯
- (void)flashOffClick:(UIButton *)sender
{
    [self setFlashMode:AVCaptureFlashModeOff];
    [self setFlashModeButtonStatus];
}

// 改变设备属性的统一操作方法
// @param propertyChange 属性改变操作
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange
{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    // 注意改变设备属性前一定要首先调用lockForConfiguration:，调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error])
    {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }
    else
    {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

// 设置闪光灯模式
-(void)setFlashMode:(AVCaptureFlashMode )flashMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOff])
        {
            captureDevice.flashMode = AVCaptureFlashModeAuto;
        }
    }];
}

// 设置闪光灯按钮状态
-(void)setFlashModeButtonStatus
{
    AVCaptureDevice *captureDevice = [self.captureDeviceInput device];
//    if ([captureDevice hasFlash])
//    {
//        if ([self.capturePhotoOutput.supportedFlashModes containsObject:[NSNumber numberWithInt:AVCaptureFlashModeOn]])
//        {
//        }
//    }
    AVCaptureFlashMode flashMode = captureDevice.flashMode;
    if([captureDevice isFlashAvailable])
    {
        self.flashAutoButton.hidden = NO;
        self.flashOnButton.hidden = NO;
        self.flashOffButton.hidden = NO;
        self.flashAutoButton.enabled = YES;
        self.flashOnButton.enabled = YES;
        self.flashOffButton.enabled = YES;
        switch (flashMode)
        {
            case AVCaptureFlashModeAuto:
                self.flashAutoButton.enabled = NO;
                break;
            case AVCaptureFlashModeOn:
                self.flashOnButton.enabled = NO;
                break;
            case AVCaptureFlashModeOff:
                self.flashOffButton.enabled = NO;
                break;
            default:
                break;
        }
    }
    else
    {
        self.flashAutoButton.hidden = YES;
        self.flashOnButton.hidden = YES;
        self.flashOffButton.hidden = YES;
    }
}

#pragma mark 切换前后摄像头

- (void)toggleButtonClick:(UIButton *)sender
{
    AVCaptureDevice *currentDevice = [self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    [self removeNotificationFromCaptureDevice:currentDevice];
    
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront)
    {
        toChangePosition = AVCaptureDevicePositionBack;
    }
    toChangeDevice = [self cameraWithPostion:toChangePosition];
    [self addNotificationToCaptureDevice:toChangeDevice];
    
    // 获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:nil];
    
    // 改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    // 移除原有输入对象
    [self.captureSession removeInput:self.captureDeviceInput];
    // 添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput])
    {
        [self.captureSession addInput:toChangeDeviceInput];
        self.captureDeviceInput = toChangeDeviceInput;
    }
    // 提交会话配置
    [self.captureSession commitConfiguration];
    
    [self setFlashModeButtonStatus];
}

- (AVCaptureDevice *)cameraWithPostion:(AVCaptureDevicePosition)position
{
    AVCaptureDeviceDiscoverySession *devicesIOS = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    
    NSArray *devices = devicesIOS.devices;
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    return nil;
}

#pragma mark - 聚焦点

// 设置聚焦点
// @param point 聚焦点
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice)
    {
        if ([captureDevice isFocusModeSupported:focusMode])
        {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported])
        {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode])
        {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported])
        {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

// 添加点按手势，点按时聚焦
-(void)addGenstureRecognizer
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    [self.viewContainer addGestureRecognizer:tapGesture];
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture
{
    CGPoint point = [tapGesture locationInView:self.viewContainer];
    
    // 将UI坐标转化为摄像头坐标
    CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

// 设置聚焦光标位置
// @param point 光标位置
-(void)setFocusCursorWithPoint:(CGPoint)point
{
    self.focusCursor.center = point;
    self.focusCursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha = 0;
    }];
}

// 设置聚焦模式
// @param focusMode 聚焦模式
-(void)setFocusMode:(AVCaptureFocusMode )focusMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice)
     {
        if ([captureDevice isFocusModeSupported:focusMode])
        {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

// 设置曝光模式
//  @param exposureMode 曝光模式
-(void)setExposureMode:(AVCaptureExposureMode)exposureMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice)
    {
        if ([captureDevice isExposureModeSupported:exposureMode])
        {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}

#pragma mark 拍照

- (void)takePictureClick:(UIButton *)sender
{
    AVCapturePhotoOutput * output = (AVCapturePhotoOutput *)self.capturePhotoOutput;
    AVCapturePhotoSettings * settings = [AVCapturePhotoSettings photoSettings];
    [output capturePhotoWithSettings:settings delegate:self];
}


- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (error)
    {
        NSLog(@"获取图片错误 --- %@",error.localizedDescription);
    }
    
    CGImageRef cgImage = [photo CGImageRepresentation];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    NSLog(@"获取图片成功: %@",image);
    
    // 前置摄像头拍照会旋转180解决办法
    if (self.captureDeviceInput.device.position == AVCaptureDevicePositionFront)
    {
        UIImageOrientation imgOrientation = UIImageOrientationLeftMirrored;
        image = [[UIImage alloc] initWithCGImage:cgImage scale:1.0f orientation:imgOrientation];
    }
    else
    {
        UIImageOrientation imgOrientation = UIImageOrientationRight;
        image = [[UIImage alloc] initWithCGImage:cgImage scale:1.0f orientation:imgOrientation];
    }
    
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}

#pragma mark - 通知

// 给输入设备添加通知
-(void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice
{
    // 注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // 捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

-(void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

// 移除所有通知
-(void)removeNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // 会话出错
    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

// 设备连接成功
-(void)deviceConnected:(NSNotification *)notification
{
    NSLog(@"设备已连接...");
}

// 设备连接断开
-(void)deviceDisconnected:(NSNotification *)notification
{
    NSLog(@"设备已断开.");
}

// 捕获区域改变
-(void)areaChange:(NSNotification *)notification
{
    NSLog(@"捕获区域改变...");
}

// 会话出错
-(void)sessionRuntimeError:(NSNotification *)notification
{
    NSLog(@"会话发生错误.");
}

@end



