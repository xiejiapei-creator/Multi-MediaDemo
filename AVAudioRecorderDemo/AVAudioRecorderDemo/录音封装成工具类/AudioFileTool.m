//
//  AudioFileTool.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AudioFileTool.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioFileTool

#pragma mark - 音频的拼接/剪切

// 音频的拼接
+ (void)addAudio:(NSString *)fromPath toAudio:(NSString *)toPath outputPath:(NSString *)outputPath
{
    //1. 获取两个音频源
    AVURLAsset *frontAudioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fromPath]];
    AVURLAsset *backAudioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:toPath]];
    
    //2. 获取两个音频素材中的素材轨道
    AVAssetTrack *frontAudioAssetTrack = [[frontAudioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetTrack *backAudioAssetTrack = [[backAudioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    //3. 向音频合成器, 添加一个空的素材容器
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    
    //4. 向素材容器中, 插入音轨素材
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, backAudioAsset.duration) ofTrack:backAudioAssetTrack atTime:kCMTimeZero error:nil];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, frontAudioAsset.duration) ofTrack:frontAudioAssetTrack atTime:frontAudioAsset.duration error:nil];
    
    //5. 根据音频合成器, 创建一个导出对象, 并设置导出参数
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    // 导出AVFileTypeMPEGLayer3
    session.outputFileType = AVFileTypeMPEGLayer3;
    // 导出路径
    session.outputURL = [NSURL fileURLWithPath:outputPath];
    
    //6. 开始导出数据
    __weak typeof(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = session.status;
        NSString *statusString = [weakSelf outputStatus:status];
        NSLog(@"导出数据状态：%@",statusString);
    }];
}

// 音频的剪切
+ (void)cutAudio:(NSString *)audioPath fromTime:(NSTimeInterval)fromTime toTime:(NSTimeInterval)toTime outputPath:(NSString *)outputPath
{
    //1. 获取音频源
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
    
    //2. 创建一个音频会话，设置相应的配置
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:audioAsset presetName:AVAssetExportPresetAppleM4A];
    
    // 导出AVFileTypeAppleM4A
    session.outputFileType = AVFileTypeAppleM4A;
    // 导出路径
    session.outputURL = [NSURL fileURLWithPath:outputPath];
    
    // 剪切音频的时间范围
    CMTime startTime = CMTimeMake(fromTime, 1);
    CMTime endTime = CMTimeMake(toTime, 1);
    session.timeRange = CMTimeRangeFromTimeToTime(startTime, endTime);
    
    //3. 导出剪切好的音频
    __weak typeof(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = session.status;
        NSString *statusString = [weakSelf outputStatus:status];
        NSLog(@"导出数据状态：%@",statusString);
    }];
}

// 导出状态
+ (NSString *)outputStatus:(AVAssetExportSessionStatus)status
{
    NSString *statusString = @"";
    switch (status)
    {
        case AVAssetExportSessionStatusUnknown:
            statusString = @"未知状态";
            break;
        case AVAssetExportSessionStatusWaiting:
            statusString = @"等待导出";
            break;
        case AVAssetExportSessionStatusExporting:
            statusString = @"导出中";
            break;
        case AVAssetExportSessionStatusCompleted:
            statusString = @"导出成功";
            break;
        case AVAssetExportSessionStatusFailed:
            statusString = @"导出失败";
            break;
        case AVAssetExportSessionStatusCancelled:
            statusString = @"取消导出";
            break;
        default:
            break;
    }
    return statusString;
}

#pragma mark - 格式转化

// m4a格式转caf格式
+ (void)convetM4aToWav:(NSString *)originalUrlString destinationUrlString:(NSString *)destinationUrlString completed:(void (^)(NSError * _Nonnull))completed
{
    // 删除已经存在的旧文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationUrlString])
    {
        [[NSFileManager defaultManager] removeItemAtPath:destinationUrlString error:nil];
    }
    
    // 获取音频资源
    NSURL *originalUrl = [NSURL fileURLWithPath:originalUrlString];
    NSURL *destinationUrl = [NSURL fileURLWithPath:destinationUrlString];
    // AVURLAsset可以用来读取网络音视频流
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];

// 以下为视频的导入和导出
// 1. 创建一个读数据对象，用来读取原始文件信息
    
    // AVAssetReader可以将视频文件导出到CMSampleBuffer
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    
    if (error)
    {
        NSLog (@"创建一个读数据对象出错了: %@", error);
        completed(error);
        return;
    }
    
    //
    /**AVAssetReaderOutput
     * AVAssetReader将媒体数据读取后，会通过AVAssetReaderOutput输出为CMSampleBuffer
     * AVAssetReaderOutput有三个主要子类：AVAssetReaderAudioMixOutput、AVAssetReaderVideoCompositionOutput在读取可编辑视频源时使用。普通的AVAsset可以AVAssetReaderTrackOutput即可。
     * songAsset.tracks 音频输出
     * 此处配置音频输出设置，audioSettings可以为nil，表示不经过处理，输出原始格式
     */
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks audioSettings:nil];
    
    // 添加
    if (![assetReader canAddOutput:assetReaderOutput])
    {
        NSLog (@"can't add reader output... die!");
        completed(error);
        return;
    }
    [assetReader addOutput:assetReaderOutput];
    
// 2. 创建一个写数据对象
    
    // AVAssetWriter可以将CMSampleBuffer编码成各种格式的音视频文件
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:destinationUrl fileType:AVFileTypeCoreAudioFormat error:&error];
    if (error)
    {
        NSLog (@"创建一个写数据对象出错了: %@", error);
        completed(error);
        return;
    }
    
    // 各个通道存储顺序
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    // 写入音频配置，音频以pcm流的形似写数据
    NSDictionary *writerSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,[NSNumber numberWithFloat:44100], AVSampleRateKey,[NSNumber numberWithInt:2], AVNumberOfChannelsKey,[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,[NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey, nil];
    
    // 输入CMsampleBuffer需要借助AVAssetWriterInput，用来说明怎么写数据
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
    outputSettings:writerSettings];
    
    // 添加
    if ([assetWriter canAddInput:assetWriterInput])
    {
        [assetWriter addInput:assetWriterInput];
    }
    else
    {
        NSLog (@"can't add asset writer input... die!");
        completed(error);
        return;
    }
    
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
// 3、准备工作准备好了，接下里开始读取和导出
    
    [assetWriter startWriting];//开始写
    [assetReader startReading];//开始读
    
    // 音频输出
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    // 这里开始时间是可以自己设置的
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:startTime];
    
    __block UInt64 convertedByteCount = 0;
    
    // 创建一个串行队列用于读取音频数据
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    // 这个方法里面的block会调用多次，并不是调用一次，然后执行循环就可以读完所有的内容，如果结束队列任务不正确，会提示必须调用startSessionAtSourceTime：的错误提示
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        while (assetWriterInput.readyForMoreMediaData)
        {
            // 下一个SampleBuffer
            CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
            if (nextBuffer)
            {
                // append buffer
                [assetWriterInput appendSampleBuffer: nextBuffer];
                NSLog (@"appended a buffer (%zu bytes)",
                          CMSampleBufferGetTotalSampleSize (nextBuffer));
                // 转化好的字节量
                convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                
            }
            else
            {
                // 标记写入任务完成
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                    NSLog(@"写入任务完成");
                }];
                
                // 取消继续读取
                [assetReader cancelReading];
                
                // 存储到目标路径里的导出文件的属性
                NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                                                      attributesOfItemAtPath:[destinationUrl path]
                                                      error:nil];
                NSLog (@"存储到目标路径里的导出文件的大小 %lld",[outputFileAttributes fileSize]);
                break;
            }
        }
        NSLog(@"转换结束");
        
        // 删除临时temprecordAudio.m4a文件
        NSError *removeError = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:originalUrlString])
        {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:originalUrlString error:&removeError];
            
            if (!success)// 删除失败
            {
                NSLog(@"删除临时 temprecordAudio.m4a 文件失败:%@",removeError);
                completed(removeError);
            }
            else// 删除成功
            {
                NSLog(@"删除临时 temprecordAudio.m4a 文件:%@成功",originalUrlString);
                completed(removeError);
            }
        }
    }];
}

// 把.caf转为.m4a格式
+ (void)convetCafToM4a:(NSString *)cafUrlString destUrl:(NSString *)m4aUrlString completed:(void (^)(NSError *))completed
{
// 1. 向音频合成器, 添加一个空的素材容器
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    // 音频插入的开始时间
    CMTime beginTime = kCMTimeZero;
    // 获取音频合并音轨
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
// 2. 插入原caf音频
    
    // 用于记录错误的对象
    NSError *error = nil;
    // 音频原文件资源
    AVURLAsset *cafAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:cafUrlString] options:nil];
    // 原音频需要合并的音频文件的区间
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, cafAsset.duration);
    
    BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[cafAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:beginTime error:&error];
    
    if (!success)
    {
        NSLog(@"插入原音频失败: %@",error);
    }
    else
    {
        NSLog(@"插入原音频成功");
    }

// 3.导出m4a文件
    // 创建一个导入M4A格式的音频的导出对象
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
    // 导入音视频的URL
    assetExport.outputURL = [NSURL fileURLWithPath:m4aUrlString];
    // 导出音视频的文件格式
    assetExport.outputFileType = @"com.apple.m4a-audio";
    // 开始导出数据
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        // 分发到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            if (assetExport.status == AVAssetExportSessionStatusCompleted)// 合成成功
            {
                completed(nil);
                NSError *removeError = nil;
                
                if([cafUrlString hasSuffix:@"caf"])
                {
                    // 删除旧的录音caf文件
                    if ([[NSFileManager defaultManager] fileExistsAtPath:cafUrlString])
                    {
                        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cafUrlString error:&removeError];
                        
                        if (!success)
                        {
                            NSLog(@"删除旧的录音caf文件失败:%@",removeError);
                        }
                        else
                        {
                            NSLog(@"删除旧的录音caf文件:%@成功",cafUrlString);
                        }
                    }
                }
                
            }
            else
            {
                completed(assetExport.error);
            }
            
        });
    }];
}

@end
