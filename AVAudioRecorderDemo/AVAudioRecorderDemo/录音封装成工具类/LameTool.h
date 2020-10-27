//
//  LameTool.h
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Single.h"

NS_ASSUME_NONNULL_BEGIN

@interface LameTool : NSObject

/** 工具类单例 */
SingleH(LameTool)

/**caf 转 mp3 ：录音完成后根据用户需要去调用转码
 * @param sourcePath 需要转mp3的caf路径
 * @param isDelete 是否删除原来的caf文件，YES：删除、NO：不删除
 * @param success 成功的回调
 * @param fail 失败的回调
 */
- (void)audioToMP3:(NSString *)sourcePath isDeleteSourchFile: (BOOL)isDelete withSuccessBack:(void(^)(NSString *resultPath))success withFailBack:(void(^)(NSString *error))fail;

/**caf 转 mp3 : 录音的同时转码
 * @param sourcePath 需要转mp3的caf路径
 * @param isDelete 是否删除原来的caf文件，YES：删除、NO：不删除
 * @param success 成功的回调
 * @param fail 失败的回调
 */
- (void)audioRecodingToMP3:(NSString *)sourcePath isDeleteSourchFile: (BOOL)isDelete withSuccessBack:(void(^)(NSString *resultPath))success withFailBack:(void(^)(NSString *error))fail;

// 录音完成的调用
- (void)sendEndRecord;

@end

NS_ASSUME_NONNULL_END
