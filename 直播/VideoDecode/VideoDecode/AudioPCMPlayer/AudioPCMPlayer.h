//
//  AudioPCMPlayer.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/30.
//

#import <Foundation/Foundation.h>
#import "AVConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioPCMPlayer : NSObject

- (instancetype)initWithConfig:(AudioConfig *)config;

/** 播放pcm */
- (void)playPCMData:(NSData *)data;

/** 设置音量增量 0.0 - 1.0 */
- (void)setupVoice:(Float32)gain;

/** 销毁播放器 */
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
