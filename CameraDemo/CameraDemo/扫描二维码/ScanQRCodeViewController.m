//
//  ScanQRCodeViewController.m
//  CameraDemo
//
//  Created by 谢佳培 on 2020/9/25.
//

#import "ScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ScanQRCodeViewController () <AVCaptureMetadataOutputObjectsDelegate>

// 捕获设备，默认后置摄像头
@property (strong, nonatomic) AVCaptureDevice *device;
// 输入设备
@property (strong, nonatomic) AVCaptureInput *input;
// 输出设备，需要指定他的输出类型及扫描范围
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
// AVFoundation框架捕获类的中心枢纽，协调输入输出设备以获得数据
@property (strong, nonatomic) AVCaptureSession *session;
// 展示捕获图像的图层，是CALayer的子类
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

// 缩放手势
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;
// 二维码正方形扫描区域的宽度，根据不同机型适配
@property (assign, nonatomic) CGFloat scanRegion_Width;
// 缩放尺寸
@property (assign, nonatomic) CGFloat initScale;

@end

@implementation ScanQRCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"扫一扫";
    
}

#pragma mark - 二维码扫描

// 设备的配置流程
- (void)configBasicDevice
{
// 先将需要的五大设备进行初始化
    // 默认使用后置摄像头进行扫描，使用AVMediaTypeVideo表示视频
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 设备输入初始化
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    
    // 设备输出初始化，并设置代理和回调
    self.output = [[AVCaptureMetadataOutput alloc] init];
    // 当设备扫描到数据时通过该代理输出队列，一般输出队列都设置为主队列，也是设置了回调方法执行所在的队列环境
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 会话 初始化，并设置采样质量为高
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    // 通过会话连接设备的输入输出
    if ([self.session canAddInput:_input])
    {
        [self.session addInput:_input];
    }
    if ([self.session canAddOutput:_output])
    {
        [self.session addOutput:_output];
    }
    
    // 指定设备的识别类型，这里只指定二维码识别这一种类型 AVMetadataObjectTypeQRCode
    // 指定识别类型这一步一定要在输出添加到会话之后，否则设备的可识别类型会为空，程序会出现崩溃
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    // 设置扫描信息的识别区域，本文设置正中央的一块正方形区域，该区域宽度是scanRegion_W
    // 这里考虑了导航栏的高度，所以计算有点麻烦，识别区域越小识别效率越高，所以不设置整个屏幕
    CGFloat navHeight = self.navigationController.navigationBar.bounds.size.height;
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat viewHeight = screenHeight - navHeight;
    CGFloat scanViewHeight = self.scanRegion_Width;
    
    CGFloat x = (screenWidth - scanViewHeight)/(2*screenWidth);
    CGFloat y = (viewHeight - scanViewHeight)/(2*viewHeight);
    CGFloat height = scanViewHeight/viewHeight;
    CGFloat width = scanViewHeight/screenWidth;
    [self.output setRectOfInterest:CGRectMake(x, y, width, height)];
    
    // 预览层初始化，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    // 预览层的区域设置为整个屏幕，这样可以方便我们进行移动二维码到扫描区域
    // 在上面我们已经对我们的扫描区域进行了相应的设置
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    // 扫描框下面的信息label布局
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, (viewHeight+scanViewHeight)/2+10.0f, screenWidth, 20.0f)];
    label.text = @"扫描二维码";
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
}

// 重写代理的回调方法，实现我们在成功识别二维码之后要实现的功能
// 后置摄像头扫描到二维码的信息
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 停止扫描
    [self.session stopRunning];
    
    if (metadataObjects.count >= 1)
    {
        // 数组中包含的都是AVMetadataMachineReadableCodeObject类型的对象，该对象中包含解码后的数据
        AVMetadataMachineReadableCodeObject *QRObject = [metadataObjects lastObject];
        // 拿到扫描内容在这里进行个性化处理
        NSString *result = QRObject.stringValue;
        // 解析数据进行处理并实现相应的逻辑...
        NSLog(@"扫描到的二维码的信息：%@",result);
    }
}

#pragma mark - 配置缩放手势

//添加一个缩放手势
- (void)configPinchGesture
{
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
    [self.view addGestureRecognizer:self.pinch];
}

//对我们的相机设备的焦距进行修改就达到了缩放的目的
- (void)pinchDetected:(UIPinchGestureRecognizer*)recogniser
{
    // 相机不存在
    if (!_device)
    {
        return;
    }
    
    // 对手势的状态进行判断
    if (recogniser.state == UIGestureRecognizerStateBegan)
    {
        _initScale = _device.videoZoomFactor;
    }
    
    // 锁定相机设备，相机设备在改变某些参数前必须先锁定，直到改变结束才能解锁
    NSError *error = nil;
    [_device lockForConfiguration:&error];
    if (!error)
    {
        CGFloat zoomFactor; //缩放因子
        CGFloat scale = recogniser.scale;
        
        if (scale < 1.0f)
        {
            zoomFactor = self.initScale - pow([self.device activeFormat].videoMaxZoomFactor, 1.0f - recogniser.scale);
        }
        else
        {
            zoomFactor = self.initScale + pow(self.device.activeFormat.videoMaxZoomFactor, (recogniser.scale - 1.0f) / 2.0f);
        }
        zoomFactor = MIN(15.0f, zoomFactor);
        zoomFactor = MAX(1.0f, zoomFactor);
        
        _device.videoZoomFactor = zoomFactor;
        [_device unlockForConfiguration];
    }
}


@end
