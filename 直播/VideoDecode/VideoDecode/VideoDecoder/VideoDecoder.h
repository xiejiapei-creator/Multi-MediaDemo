//
//  VideoDecoder.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AVConfig.h"

NS_ASSUME_NONNULL_BEGIN

/** H264解码回调代理 */
@protocol VideoDecoderDelegate <NSObject>

/** 解码后H264数据回调 */
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer;

@end

@interface VideoDecoder : NSObject

@property (nonatomic, strong) VideoConfig *config;
@property (nonatomic, weak) id<VideoDecoderDelegate> delegate;

/** 初始化解码器 **/
- (instancetype)initWithConfig:(VideoConfig*)config;

/** 解码h264数据 */
- (void)decodeNaluData:(NSData *)frame;

@end

NS_ASSUME_NONNULL_END
