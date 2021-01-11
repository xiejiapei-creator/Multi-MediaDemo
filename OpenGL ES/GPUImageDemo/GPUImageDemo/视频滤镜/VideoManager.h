//
//  VideoManager.h
//  GPUImageDemo
//
//  Created by 谢佳培 on 2021/1/9.
//

#import <Foundation/Foundation.h>
#import <GPUImage.h>

typedef NS_ENUM(NSUInteger, VideoManagerCameraType) {
    VideoManagerCameraTypeFront = 0,
    VideoManagerCameraTypeBack,
};

@protocol VideoManagerProtocol <NSObject>

/** 开始录制 */
- (void)didStartRecordVideo;

/** 视频压缩中 */
- (void)didCompressingVideo;

/** 结束录制 */
- (void)didEndRecordVideoWithTime:(CGFloat)totalTime outputFile:(NSString *)filePath;

@end

@interface VideoManager : NSObject

/** 代理 */
@property (nonatomic,weak) id <VideoManagerProtocol> delegate;

/** 录制视频区域 */
@property (nonatomic,assign) CGRect frame;

/** 录制视频最大时长 */
@property (nonatomic,assign) CGFloat maxTime;

/** 录制视频单例,若工程中不止一处用到录视频，尺寸有变，直接实例化即可 忽略此方法 */
+ (instancetype)manager;

/** 加载到显示的视图上 */
- (void)showWithFrame:(CGRect)frame superView:(UIView *)superView;

/** 开始录制 */
- (void)startRecording;

/** 结束录制 */
- (void)endRecording;

/** 暂停录制 */
- (void)pauseRecording;

/** 继续录制 */
- (void)resumeRecording;

/** 切换前后摄像头 */
- (void)changeCameraPosition:(VideoManagerCameraType)type;

/** 打开闪光灯 */
- (void)turnTorchOn:(BOOL)on;

@end


