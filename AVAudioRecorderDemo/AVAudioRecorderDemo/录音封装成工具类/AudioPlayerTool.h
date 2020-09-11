//
//  AudioPlayerTool.h
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Single.h"

NS_ASSUME_NONNULL_BEGIN

@class AudioPlayerTool;

@protocol AudioPlayerDelegate <NSObject>

// 播放完成的回调
@optional
- (void)audioPlayerDidFinishPlaying:(AudioPlayerTool *)playerTool;

@end

@interface AudioPlayerTool : NSObject

/** 工具类单例 */
SingleH(AudioPlayerTool)

#pragma mark - 播放器

/** 播放完成回调的委托 */
@property (weak, nonatomic) id <AudioPlayerDelegate> delegate;

/** MP3 还是 AMR 音频 */
@property (nonatomic, assign) BOOL isMP3Audio;

/** 默认缓存路径 */
+ (NSString*)defaultCachePathWithURL:(NSString*)url isMP3Audio:(BOOL)isMP3Audio;

/** 初始化 */
- (instancetype)initWithDelegate:(id)delegate;

/** 根据URL播放音频 */
- (void)playAtURL:(NSString*)url isMP3Audio:(BOOL)isMP3Audio;

/** 根据Path播放音频 */
- (void)playAtPath:(NSString*)path isMP3Audio:(BOOL)isMP3Audio;

/** 停止播放 */
- (void)stopPlaying;

#pragma mark - 播放按钮

/** 播放歌曲 */
- (AVAudioPlayer *)playAudioWith:(NSString *)audioPath;

/** 恢复当前歌曲播放 */
- (void)resumeCurrentAudio;

/** 暂停歌曲 */
- (void)pauseCurrentAudio;

/** 停止歌曲播放 */
- (void)stopCurrentAudio;

#pragma mark - 播放选项

/** 音量大小，范围0-1.0 */
@property (nonatomic, assign) float volumn;

/** 播放进度大小 */
@property (nonatomic, assign, readonly) float progress;

/** 是否允许改变播放速率 */
@property (nonatomic, assign) BOOL enableRate;

/** 播放速率：范围0.5-2.0，如果为1.0则正常播放，如果要修改播放速率则必须设置enableRate为YES */
@property (nonatomic, assign) float rate;

/** 立体声平衡：如果为-1.0则完全左声道，如果0.0则左右声道平衡，如果为1.0则完全为右声道 */
@property (nonatomic, assign) float span;

/** 循环播放次数：如果为0则不循环，如果小于0则无限循环，大于0则表示循环次数 */
@property (nonatomic, assign) NSInteger numberOfLoops;

@end

NS_ASSUME_NONNULL_END
