//
//  AudioEncoder.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/30.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AVConfig.h"

/** AAC编码器代理 */
@protocol AudioEncoderDelegate <NSObject>

- (void)audioEncodeCallback:(NSData *)aacData;

@end

/** AAC硬编码器 (编码和回调均在异步队列执行) */
@interface AudioEncoder : NSObject

/** AAC编码器代理 */
@property (nonatomic, weak) id<AudioEncoderDelegate> delegate;

/** 编码器配置 */
@property (nonatomic, strong) AudioConfig *config;
 
/** 初始化时传入编码器配置 */
- (instancetype)initWithConfig:(AudioConfig *)config;

/** 进行编码 */
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer;

/** 可以直接播放PCM数据，只需要将sampleBuffer数据提取出的PCM数据返回给ViewController即可 */
- (NSData *)convertAudioSamepleBufferToPcmData: (CMSampleBufferRef)sampleBuffer;

@end

