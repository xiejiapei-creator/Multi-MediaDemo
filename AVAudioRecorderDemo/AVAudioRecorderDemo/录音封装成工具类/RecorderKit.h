//
//  RecorderKit.h
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#ifndef RecorderKit_h
#define RecorderKit_h

// 系统的音频框架
#import <AVFoundation/AVFoundation.h>
// 单例类
#import "Single.h"
// 音频录制类
#import "AudioTool.h"
// 操作音频文件拼接、剪切、转化的类
#import "AudioFileTool.h"
// 音频播放的类
#import "AudioPlayerTool.h"
// lame 静态库的 .h 文件
#import "lame.h"
// 音频转码成MP3类
#import "LameTool.h"
// 音频路径操作的类
#import "AudioFilePathTool.h"

#endif /* RecorderKit_h */
