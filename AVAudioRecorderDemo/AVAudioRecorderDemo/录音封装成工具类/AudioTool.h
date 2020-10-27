//
//  AudioTool.h
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Single.h"

NS_ASSUME_NONNULL_BEGIN

// 录音存放的文件夹 /Library/Caches/Recorder
#define cachesRecorderPath [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Caches/Recorder"]

//#define kSampleRate 44100 // 采样率
// #define kBitRate 96000 // 码率

typedef void(^AudioSuccess)(BOOL ret);

@interface AudioTool : NSObject

/** 工具类单例 */
SingleH(AudioTool)

/** 录音文件路径 */
@property (nonatomic, copy, readonly) NSString *recordPath;

/** 当前录音的时间 */
@property(nonatomic,assign) NSTimeInterval audioCurrentTime;

#pragma mark - 录音过程

/**开始录音
 * @param recordName 录音的名字
 * @param type 录音的类型
 * @param isConventToMp3 是否边录边转mp3
 */
- (void)beginRecordWithRecordName:(NSString *)recordName withRecordType:(NSString *)type withIsConventToMp3:(BOOL)isConventToMp3;

/** 结束录音 */
- (void)endRecord;

/** 暂停录音 */
- (void)pauseRecord;

/** 删除录音 */
- (void)deleteRecord;

/** 重新录音 */
- (void)restartRecord;

#pragma mark - 音频信息

/**更新音频测量值
 * 注意如果要更新音频测量值必须设置meteringEnabled为YES，通过音频测量值可以即时获得音频分贝等信息
 * @property(getter=isMeteringEnabled) BOOL meteringEnabled：是否启用音频测量，默认为NO，一旦启用音频测量可以通过updateMeters方法更新测量值
 */
- (void)updateMeters;

/**获得指定声道的分贝峰值
 * 注意如果要获得分贝峰值必须在此之前调用updateMeters方法
 * @return 指定频道的值
 */
- (float)peakPowerForChannel;

@end

NS_ASSUME_NONNULL_END
