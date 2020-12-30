//
//  SystemCapture.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// 捕获类型
typedef NS_ENUM(int,SystemCaptureType)
{
    SystemCaptureTypeVideo = 0,
    SystemCaptureTypeAudio,
    SystemCaptureTypeAll
};

// 捕捉到音视频数据后的委托回调
@protocol SystemCaptureDelegate <NSObject>

@optional
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type: (SystemCaptureType)type;

@end

/** 捕获音视频的工具类 */
@interface SystemCapture : NSObject

/** 捕捉到音视频数据后的委托回调 */
@property (nonatomic, weak) id<SystemCaptureDelegate> delegate;

/** 预览层 */
@property (nonatomic, strong) UIView *preview;
/** 捕获视频的宽 */
@property (nonatomic, assign, readonly) NSUInteger witdh;
/** 捕获视频的高 */
@property (nonatomic, assign, readonly) NSUInteger height;

/** 初始化音视频捕捉器 */
- (instancetype)initWithType:(SystemCaptureType)type;

/** 准备工作(只捕获音频时调用) */
- (void)prepare;
/** 捕获内容包括视频时调用（预览层大小，添加到view上用来显示） */
- (void)prepareWithPreviewSize:(CGSize)size;

/** 开始捕捉 */
- (void)start;
/** 结束捕捉 */
- (void)stop;
/** 切换摄像头 */
- (void)changeCamera;


/** 授权检测 */
+ (int)checkMicrophoneAuthor;
+ (int)checkCameraAuthor;

@end
 
