
#import <AVFoundation/AVFoundation.h>

extern NSString *const THThumbnailCreatedNotification;

@protocol THCameraControllerDelegate <NSObject>

// 1发生错误事件是，需要在对象委托上调用一些方法来处理
// 设备错误
- (void)deviceConfigurationFailedWithError:(NSError *)error;
// 媒体捕捉错误
- (void)mediaCaptureFailedWithError:(NSError *)error;
// 写入时错误
- (void)assetLibraryWriteFailedWithError:(NSError *)error;

@end

@interface THCameraController : NSObject

@property (weak, nonatomic) id<THCameraControllerDelegate> delegate;
@property (nonatomic, strong, readonly) AVCaptureSession *captureSession;


// 2 用于设置、配置视频捕捉会话
- (BOOL)setupSession:(NSError **)error;
- (void)startSession;
- (void)stopSession;

// 3 切换不同的摄像头
- (BOOL)switchCameras;//切换不同的摄像头
- (BOOL)canSwitchCameras;//是否能切换
@property (nonatomic, readonly) NSUInteger cameraCount;//摄像头个数
@property (nonatomic, readonly) BOOL cameraHasTorch; //手电筒
@property (nonatomic, readonly) BOOL cameraHasFlash; //闪光灯
@property (nonatomic, readonly) BOOL cameraSupportsTapToFocus; //聚焦
@property (nonatomic, readonly) BOOL cameraSupportsTapToExpose;//曝光
@property (nonatomic) AVCaptureTorchMode torchMode; //手电筒模式
@property (nonatomic) AVCaptureFlashMode flashMode; //闪光灯模式

// 4 聚焦、曝光、重设聚焦、曝光的方法
- (void)focusAtPoint:(CGPoint)point;//聚焦
- (void)exposeAtPoint:(CGPoint)point;//曝光
- (void)resetFocusAndExposureModes;//重设聚焦、曝光

// 5 实现捕捉静态图片 & 视频的功能

//捕捉静态图片
- (void)captureStillImage;

//开始录制
- (void)startRecording;

//停止录制
- (void)stopRecording;

//获取录制状态
- (BOOL)isRecording;

//录制时间
- (CMTime)recordedDuration;

@end
