//
//  VideoEncoder.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AVConfig.h"

/** h264编码回调代理 */
@protocol VideoEncoderDelegate <NSObject>

/** Video-H264数据编码完成回调 */
- (void)videoEncodeCallback:(NSData *)h264Data;
/** Video-SPS&PPS数据编码回调 */
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps;

@end

/** h264硬编码器 (编码和回调均在异步队列执行) */
@interface VideoEncoder : NSObject

@property (nonatomic, strong) VideoConfig *config;
/** h264编码回调代理 */
@property (nonatomic, weak) id<VideoEncoderDelegate> delegate;

/** 在初始化方法中配置编码参数 */
- (instancetype)initWithConfig:(VideoConfig *)config;

/** 进行编码 */
-(void)encodeVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
 
