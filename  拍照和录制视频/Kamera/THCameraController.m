
#import "THCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>//用于将文件写入到资源库中
#import "NSFileManager+THAdditions.h"

NSString *const THThumbnailCreatedNotification = @"THThumbnailCreated";

@interface THCameraController () <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) dispatch_queue_t videoQueue; //视频队列
@property (strong, nonatomic) AVCaptureSession *captureSession;// 捕捉会话
@property (weak, nonatomic) AVCaptureDeviceInput *activeVideoInput;//视图输入
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;//图片输出
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieOutput;//视频输出
@property (strong, nonatomic) NSURL *outputURL;//输出路径

@end

@implementation THCameraController

//配置Session
- (BOOL)setupSession:(NSError **)error {

    //创建捕捉会话。AVCaptureSession 是捕捉场景的中心枢纽
    self.captureSession = [[AVCaptureSession alloc]init];
    
    /*
     AVCaptureSessionPresetHigh
     AVCaptureSessionPresetMedium
     AVCaptureSessionPresetLow
     AVCaptureSessionPreset640x480
     AVCaptureSessionPreset1280x720
     AVCaptureSessionPresetPhoto
     */
    //设置图像的分辨率
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
// 添加视频的输入设备
    //拿到默认视频捕捉设备 iOS系统返回后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //将捕捉设备封装成AVCaptureDeviceInput
    //注意：为会话添加捕捉设备，必须将设备封装成AVCaptureDeviceInput对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    
    //判断videoInput是否有效
    if (videoInput)
    {
        //canAddInput：测试是否能被添加到会话中
        if ([self.captureSession canAddInput:videoInput])
        {
            //将videoInput 添加到 captureSession中
            [self.captureSession addInput:videoInput];
            //记录此时活跃的视图输入设备
            self.activeVideoInput = videoInput;
        }
    }
    else
    {
        return NO;
    }

// 添加音频的输入设备
    
    //选择默认音频捕捉设备 即返回一个内置麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //为这个设备创建一个捕捉设备输入
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
   
    //判断audioInput是否有效
    if (audioInput) {
        
        //canAddInput：测试是否能被添加到会话中
        if ([self.captureSession canAddInput:audioInput])
        {
            //将audioInput 添加到 captureSession中
            [self.captureSession addInput:audioInput];
        }
    }
    else
    {
        return NO;
    }

// 输出图片
    //AVCaptureStillImageOutput 实例 从摄像头捕捉静态图片
    self.imageOutput = [[AVCaptureStillImageOutput alloc]init];
    
    //配置字典：希望捕捉到JPEG格式的图片
    self.imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    
    //输出连接 判断是否可用，可用则添加到输出连接中去
    if ([self.captureSession canAddOutput:self.imageOutput])
    {
        [self.captureSession addOutput:self.imageOutput];
    }
    
// 输出视频
    //创建一个AVCaptureMovieFileOutput 实例，用于将Quick Time 电影录制到文件系统
    self.movieOutput = [[AVCaptureMovieFileOutput alloc]init];
    
    //输出连接 判断是否可用，可用则添加到输出连接中去
    if ([self.captureSession canAddOutput:self.movieOutput])
    {
        [self.captureSession addOutput:self.movieOutput];
    }
    
    //创建视频队列
    self.videoQueue = dispatch_queue_create("XieJiapei.VideoQueue", NULL);
    
    return YES;
}

// 开启 Session 进行捕捉
- (void)startSession
{
    //检查是否处于运行状态
    if (![self.captureSession isRunning])
    {
        //使用同步调用会损耗一定的时间，则用异步的方式处理
        dispatch_async(self.videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

// 停止 Session 捕捉
- (void)stopSession
{
    //检查是否处于运行状态
    if ([self.captureSession isRunning])
    {
        //使用异步方式，停止运行
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}

//- (dispatch_queue_t)globalQueue {
//    
//    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//}

#pragma mark - Device Configuration   配置摄像头支持的方法

// 寻找指定摄像头设备
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    //获取可用视频设备
    NSArray *devicess = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //遍历可用的视频设备 并返回position 参数值
    for (AVCaptureDevice *device in devicess)
    {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

// 获取当前活跃的设备
- (AVCaptureDevice *)activeCamera
{
    //返回当前捕捉会话对应的摄像头的device 属性
    return self.activeVideoInput.device;
}

//返回当前未激活的摄像头
- (AVCaptureDevice *)inactiveCamera
{
    //通过查找当前激活摄像头的反向摄像头获得未激活的摄像头
    AVCaptureDevice *device = nil;
    if (self.cameraCount > 1)
    {
        // 当前是后置摄像头
        if ([self activeCamera].position == AVCaptureDevicePositionBack)
        {
            // 需要通过 cameraWithPosition 方法才能根据位置拿到设备
            device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        // 当前是前置摄像头
        else
        {
            device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
    }
    
    // 如果设备只有1个摄像头，则返回nil
    return device;
}

//判断是否有超过1个摄像头可用
- (BOOL)canSwitchCameras
{
    return self.cameraCount > 1;
}

//可用视频捕捉设备的数量
- (NSUInteger)cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

//切换摄像头
- (BOOL)switchCameras
{

    //判断是否有多个摄像头
    if (![self canSwitchCameras])
    {
        return NO;
    }
    
    //获取当前设备的反向设备
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamera];
    
    
    //将输入设备封装成AVCaptureDeviceInput
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    //判断videoInput 是否为nil
    if (videoInput)
    {
        //标注原配置变化开始
        [self.captureSession beginConfiguration];
        
        //将捕捉会话中，原本的捕捉输入设备移除
        [self.captureSession removeInput:self.activeVideoInput];
        
        //判断新的设备是否能加入
        if ([self.captureSession canAddInput:videoInput])
        {
            //能加入成功，则将videoInput 作为新的视频捕捉设备
            [self.captureSession addInput:videoInput];
            
            //将活跃设备修改为 videoInput
            self.activeVideoInput = videoInput;
        }
        else
        {
            //如果新设备无法加入，则将原本的视频捕捉设备重新加入到捕捉会话中
            [self.captureSession addInput:self.activeVideoInput];
        }
        
        //配置完成后， AVCaptureSession commitConfiguration 会分批的将所有变更整合在一起
        [self.captureSession commitConfiguration];
    }
    else
    {
        //创建AVCaptureDeviceInput 出现错误，则通知委托来处理该错误
        [self.delegate deviceConfigurationFailedWithError:error];
        return NO;
    }

    return YES;
}


#pragma mark - Focus Methods 点击聚焦方法的实现

//询问激活中的摄像头是否支持兴趣点对焦
- (BOOL)cameraSupportsTapToFocus
{
    return [[self activeCamera]isFocusPointOfInterestSupported];
}

//对兴趣点进行对焦
- (void)focusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [self activeCamera];
    
    //是否支持兴趣点对焦 & 是否支持自动对焦模式
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        
        NSError *error;
        //因为配置的时候，不能让多个对象对它进行更改，所以需要锁定设备进行配置
        if ([device lockForConfiguration:&error])
        {
            
            //聚焦位置
            device.focusPointOfInterest = point;
            
            //聚焦模式
            device.focusMode = AVCaptureFocusModeAutoFocus;
            
            //释放该锁定
            [device unlockForConfiguration];
        }
        else
        {
            //错误时，则返回给错误处理代理
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

#pragma mark - Exposure Methods   点击曝光的方法实现

//询问设备是否支持对一个兴趣点进行曝光
- (BOOL)cameraSupportsTapToExpose
{
    return [[self activeCamera] isExposurePointOfInterestSupported];
}

static const NSString *THCameraAdjustingExposureContext;

//对兴趣点进行曝光
- (void)exposeAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [self activeCamera];
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    
    //判断是否支持 AVCaptureExposureModeContinuousAutoExposure 模式
    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode])
    {
        [device isExposureModeSupported:exposureMode];
        
        NSError *error;
        //锁定设备准备配置
        if ([device lockForConfiguration:&error])
        {
            //配置期望值
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
            
            //判断设备是否支持锁定曝光的模式
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked])
            {
                //支持，则使用kvo确定设备的adjustingExposure属性的状态
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&THCameraAdjustingExposureContext];
            }
            
            //释放该锁定
            [device unlockForConfiguration];
        }
        else
        {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

// 重写observeValueForKeyPath方法，观察adjustingExposure属性的状态
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //判断 context（上下文）是否为 THCameraAdjustingExposureContext
    if (context == &THCameraAdjustingExposureContext)
    {
        //获取device
        AVCaptureDevice *device = (AVCaptureDevice *)object;
        
        //判断设备是否不再调整曝光等级，确认设备的exposureMode是否可以设置为AVCaptureExposureModeLocked
        if(!device.isAdjustingExposure && [device isExposureModeSupported:AVCaptureExposureModeLocked])
        {
            //移除作为adjustingExposure 的self，就不会得到后续变更的通知
            [object removeObserver:self forKeyPath:@"adjustingExposure" context:&THCameraAdjustingExposureContext];
            
            //异步方式调回主队列
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                if ([device lockForConfiguration:&error])
                {
                    
                    //修改exposureMode
                    device.exposureMode = AVCaptureExposureModeLocked;
                    
                    //释放该锁定
                    [device unlockForConfiguration];
                }
                else
                {
                    [self.delegate deviceConfigurationFailedWithError:error];
                }
            });
            
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

//重新设置对焦&曝光
- (void)resetFocusAndExposureModes
{
    AVCaptureDevice *device = [self activeCamera];
    
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    
    //获取对焦兴趣点和连续自动对焦模式是否被支持
    BOOL canResetFocus = [device isFocusPointOfInterestSupported]&& [device isFocusModeSupported:focusMode];
    
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    
    //确认曝光度是否可以被重设
    BOOL canResetExposure = [device isFocusPointOfInterestSupported] && [device isExposureModeSupported:exposureMode];
    
    //这一点作为默认聚焦的位置。捕捉设备空间左上角（0，0），右下角（1，1） 中心点则（0.5，0.5）
    CGPoint centPoint = CGPointMake(0.5f, 0.5f);
    
    NSError *error;
    
    //锁定设备，准备配置
    if ([device lockForConfiguration:&error])
    {
        //焦点可设，则修改
        if (canResetFocus)
        {
            device.focusMode = focusMode;
            device.focusPointOfInterest = centPoint;
        }
        
        //曝光度可设，则设置为期望的曝光模式
        if (canResetExposure)
        {
            device.exposureMode = exposureMode;
            device.exposurePointOfInterest = centPoint;
        }
        
        //释放锁定
        [device unlockForConfiguration];
        
    }
    else
    {
        [self.delegate deviceConfigurationFailedWithError:error];
    }
}


#pragma mark - Flash and Torch Modes    闪光灯 & 手电筒

//判断是否有闪光灯
- (BOOL)cameraHasFlash
{
    return [[self activeCamera] hasFlash];
}

//闪光灯模式
- (AVCaptureFlashMode)flashMode
{
    return [[self activeCamera] flashMode];
}

//设置闪光灯
- (void)setFlashMode:(AVCaptureFlashMode)flashMode
{
    //获取会话
    AVCaptureDevice *device = [self activeCamera];
    
    //判断是否支持闪光灯模式
    if ([device isFlashModeSupported:flashMode])
    {
    
        //如果支持，则锁定设备
        NSError *error;
        if ([device lockForConfiguration:&error])
        {

            //修改闪光灯模式
            device.flashMode = flashMode;
            //修改完成，解锁释放设备
            [device unlockForConfiguration];
            
        }
        else
        {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

//是否支持手电筒
- (BOOL)cameraHasTorch
{
    return [[self activeCamera] hasTorch];
}

//手电筒模式
- (AVCaptureTorchMode)torchMode
{
    return [[self activeCamera] torchMode];
}


//设置是否打开手电筒
- (void)setTorchMode:(AVCaptureTorchMode)torchMode
{
    AVCaptureDevice *device = [self activeCamera];
    
    if ([device isTorchModeSupported:torchMode])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        }
        else
        {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}


#pragma mark - Image Capture Methods 拍摄静态图片

// 捕捉图片
- (void)captureStillImage
{
    //获取连接
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //程序只支持纵向，但是如果用户横向拍照时，需要调整结果照片的方向
    //判断是否支持设置视频方向
    if (connection.isVideoOrientationSupported)
    {
        //获取方向值
        connection.videoOrientation = [self currentVideoOrientation];
    }
    
    //定义一个handler 块，会返回1个图片的NSData数据
    id handler = ^(CMSampleBufferRef sampleBuffer,NSError *error)
                {
                    if (sampleBuffer != NULL)
                    {
                        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
                        UIImage *image = [[UIImage alloc] initWithData:imageData];
                        
                        //重点：捕捉图片成功后，将图片传递出去
                        [self writeImageToAssetsLibrary:image];
                    }
                    else
                    {
                        NSLog(@"NULL sampleBuffer:%@",[error localizedDescription]);
                    }
                };
    
    //捕捉静态图片
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
}

//获取方向值
- (AVCaptureVideoOrientation)currentVideoOrientation
{
    AVCaptureVideoOrientation orientation;
    
    //获取UIDevice 的 orientation
    switch ([UIDevice currentDevice].orientation)
    {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }
    
    return orientation;
}

// 将图片写入到 Library
- (void)writeImageToAssetsLibrary:(UIImage *)image
{
    //创建ALAssetsLibrary  实例
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    //参数1:图片（参数为CGImageRef 所以image.CGImage）
    //参数2:方向参数 转为NSUInteger
    //参数3:写入成功、失败处理
    [library writeImageToSavedPhotosAlbum:image.CGImage
                             orientation:(NSUInteger)image.imageOrientation
                         completionBlock:^(NSURL *assetURL, NSError *error) {
                             //成功后，发送捕捉图片成功通知，用于绘制相机左下角的缩略图
                             if (!error)
                             {
                                 [self postThumbnailNotifification:image];
                             }
                             else
                             {
                                 //失败打印错误信息
                                 id message = [error localizedDescription];
                                 NSLog(@"%@",message);
                             }
                         }];
}

//发送缩略图通知
- (void)postThumbnailNotifification:(UIImage *)image
{
    //回到主队列
    dispatch_async(dispatch_get_main_queue(), ^{
        //发送请求
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:THThumbnailCreatedNotification object:image];
    });
}

#pragma mark - Video Capture Methods 捕捉视频

//判断是否录制状态
- (BOOL)isRecording
{
    return self.movieOutput.isRecording;
}

//开始录制
- (void)startRecording
{
    if (![self isRecording])
    {
        //获取当前视频捕捉连接信息，用于捕捉视频数据配置一些核心属性
        AVCaptureConnection * videoConnection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
        
        //判断是否支持设置videoOrientation属性
        if([videoConnection isVideoOrientationSupported])
        {
            //支持则修改当前视频的方向
            videoConnection.videoOrientation = [self currentVideoOrientation];
        }
        
        //判断是否支持视频稳定
        //视频稳定只会在录制视频文件涉及，可以显著提高视频的质量
        if([videoConnection isVideoStabilizationSupported])
        {
            videoConnection.enablesVideoStabilizationWhenAvailable = YES;
        }

        //拿到活跃的摄像头
        AVCaptureDevice *device = [self activeCamera];
        
        //判断当前活跃的摄像头是否可以进行平滑对焦模式操作
        //平滑对焦模式即减慢摄像头镜头对焦速度，这样当用户移动拍摄时摄像头会尝试快速自动对焦
        if (device.isSmoothAutoFocusEnabled)
        {
            NSError *error;
            if ([device lockForConfiguration:&error])
            {
                device.smoothAutoFocusEnabled = YES;
                [device unlockForConfiguration];
            }
            else
            {
                //设备错误
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }

        //查找写入捕捉视频的唯一文件系统URL
        self.outputURL = [self uniqueURL];
        
        //在捕捉输出上调用方法 参数1:录制保存路径  参数2:代理
        [self.movieOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
    }
}

//录制的时间
- (CMTime)recordedDuration
{
    return self.movieOutput.recordedDuration;
}


//提供写入视频唯一文件系统URL
- (NSURL *)uniqueURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //创建一个临时唯一命名的目录
    //临时文件在写入过程中不会产生后缀名，只有当全部写入完成后，才会产生后缀名
    NSString *dirPath = [fileManager temporaryDirectoryWithTemplateString:@"kamera.XXXXXX"];
    
    if (dirPath)
    {
        //mov是视频封装容器，和视频编码格式存在区别
        NSString *filePath = [dirPath stringByAppendingPathComponent:@"kamera_movie.mov"];
        return  [NSURL fileURLWithPath:filePath];
        
    }
    
    return nil;
}

//停止录制
- (void)stopRecording
{
    //是否正在录制
    if ([self isRecording])
    {
        [self.movieOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

//捕捉录制的输出文件
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    //错误
    if (error)
    {
        [self.delegate mediaCaptureFailedWithError:error];
    }
    else
    {
        //视频写入到相册
        [self writeVideoToAssetsLibrary:[self.outputURL copy]];
    }
    
    //录制完成后将路径清空
    self.outputURL = nil;
}

//写入捕捉到的视频到相册
- (void)writeVideoToAssetsLibrary:(NSURL *)videoURL
{
    //ALAssetsLibrary 实例 提供写入视频的接口
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    //写资源库写入前，检查视频是否可被写入 （写入前尽量养成判断的习惯）
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL])
    {
        //创建block块
        ALAssetsLibraryWriteVideoCompletionBlock completionBlock;
        completionBlock = ^(NSURL *assetURL,NSError *error)
        {
            if (error)
            {
                [self.delegate assetLibraryWriteFailedWithError:error];
            }
            else
            {
                //用于界面展示视频缩略图
                [self generateThumbnailForVideoAtURL:videoURL];
            }
        };
        
        //执行实际写入资源库的动作
        [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:completionBlock];
    }
}

//获取视频左下角缩略图
- (void)generateThumbnailForVideoAtURL:(NSURL *)videoURL
{
    //在videoQueue 上
    dispatch_async(self.videoQueue, ^{
        
        //建立新的AVAsset & AVAssetImageGenerator
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        
        //设置maximumSize 宽为100，高为0 根据视频的宽高比来计算图片的高度
        imageGenerator.maximumSize = CGSizeMake(100.0f, 0.0f);
        
        //捕捉视频缩略图会考虑视频的变化（如视频的方向变化），如果不设置，缩略图的方向可能出错
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        //获取CGImageRef图片 注意需要自己管理它的创建和释放
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:nil];
        
        //将图片转化为UIImage
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        //释放CGImageRef imageRef 防止内存泄漏
        CGImageRelease(imageRef);
        
        //回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //发送通知，传递最新的image
            [self postThumbnailNotifification:image];
        });
    });
}

@end


