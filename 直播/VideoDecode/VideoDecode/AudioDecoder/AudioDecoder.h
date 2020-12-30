//
//  AudioDecoder.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/30.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AVConfig.h"

/** AAC解码回调代理 */
@protocol AudioDecoderDelegate <NSObject>

- (void)audioDecodeCallback:(NSData *)pcmData;

@end

@interface AudioDecoder : NSObject

@property (nonatomic, weak) id<AudioDecoderDelegate> delegate;

/** 解码配置 */
@property (nonatomic, strong) AudioConfig *config;
/** 初始化时传入解码配置 */
- (instancetype)initWithConfig:(AudioConfig *)config;

/** 解码AAC */
- (void)decodeAudioAACData: (NSData *)aacData;

@end
