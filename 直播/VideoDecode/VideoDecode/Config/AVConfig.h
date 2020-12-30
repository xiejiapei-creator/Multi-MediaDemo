//
//  AVConfig.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 音频配置 */
@interface AudioConfig : NSObject

/** 码率 默认96000 */
@property (nonatomic, assign) NSInteger bitrate;
/** 声道 默认单声道 */
@property (nonatomic, assign) NSInteger channelCount;
/** 采样率 默认44100 */
@property (nonatomic, assign) NSInteger sampleRate;
/** 采样点量化 默认16 */
@property (nonatomic, assign) NSInteger sampleSize;

/** 使用默认音频配置 */
+ (instancetype)defaultAudioConfig;

@end

/** 视频配置 */
@interface VideoConfig : NSObject

/** 可选，分辨率的宽 */
@property (nonatomic, assign) NSInteger width;//系统支持的分辨率，采集
/** 可选，分辨率的高 */
@property (nonatomic, assign) NSInteger height;
/** 码率 */
@property (nonatomic, assign) NSInteger bitrate;
/** 帧数 */
@property (nonatomic, assign) NSInteger fps;

/** 使用默认视频配置 */
+ (instancetype)defaultVideoConfig;

@end

NS_ASSUME_NONNULL_END
