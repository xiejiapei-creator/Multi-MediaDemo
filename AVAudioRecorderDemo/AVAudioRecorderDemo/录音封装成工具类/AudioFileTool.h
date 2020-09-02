//
//  AudioFileTool.h
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioFileTool : NSObject

#pragma mark - 音频的拼接/剪切

/**音频的拼接
 * @param fromPath 前段音频路径
 * @param toPath 后段音频路径
 * @param outputPath 拼接后的音频路径
 */
+(void)addAudio:(NSString *)fromPath toAudio:(NSString *)toPath outputPath:(NSString *)outputPath;

/**音频的剪切
 * @param audioPath 要剪切的音频路径
 * @param fromTime 开始剪切的时间
 * @param toTime 结束剪切的时间
 * @param outputPath 剪切成功后的音频路径
 */
+(void)cutAudio:(NSString *)audioPath fromTime:(NSTimeInterval)fromTime toTime:(NSTimeInterval)toTime outputPath:(NSString *)outputPath;

#pragma mark - 格式转化

/**把.m4a转为.caf格式
 * @param originalUrlString .m4a文件路径
 * @param destinationUrlString .caf文件路径
 * @param completed 转化完成的block
 */
+ (void)convetM4aToWav:(NSString *)originalUrlString
               destinationUrlString:(NSString *)destinationUrlString
             completed:(void (^)(NSError *error)) completed;

/**把.caf转为.m4a格式
 * @param cafUrlString .m4a文件路径
 * @param m4aUrlString .caf文件路径
 * @param completed 转化完成的block
 */
+ (void)convetCafToM4a:(NSString *)cafUrlString
               destUrl:(NSString *)m4aUrlString
             completed:(void (^)(NSError *error)) completed;

@end

 
