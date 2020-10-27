//
//  LameTool.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "LameTool.h"
#import "lame.h"

@interface LameTool()

// 标记转换是否可以停止了
@property (nonatomic, assign) BOOL stopRecord;

@end

@implementation LameTool

// 工具类单例
SingleM(LameTool)

// 录音完成的调用
- (void)sendEndRecord
{
    self.stopRecord = YES;
}

// caf 转 mp3 ：录音完成后根据用户需要去调用转码
- (void)audioToMP3:(NSString *)sourcePath isDeleteSourchFile:(BOOL)isDelete withSuccessBack:(void (^)(NSString * _Nonnull))success withFailBack:(void (^)(NSString * _Nonnull))fail
{
    NSLog(@"转换开始!!");
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1. 输入路径
        NSString *inPath = sourcePath;
        
        // 判断输入路径是否存在
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:sourcePath])
        {
            if (fail)
            {
                fail(@"文件不存在");
            }
            return;
        }
        
        // 2. 输出路径
        NSString *outPath = [[sourcePath stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
        @try {
            int read, write;
            
            // source 被转换的音频文件位置
            // 打开只读二进制文件，该文件必须存在，否则报错
            FILE *pcm = fopen([inPath cStringUsingEncoding:1], "rb");
            // skip file header
            fseek(pcm, 4*1024, SEEK_CUR);
            // output 输出生成的Mp3文件位置
            // 只写方式打开或新建一个二进制文件，只允许写数据
            FILE *mp3 = fopen([outPath cStringUsingEncoding:1], "wb");
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();// 初始化
            
            // 设置1为单通道，默认为2双通道，设置单声道会更大程度减少压缩后文件的体积，但是会造成MP3声音尖锐变声
            // lame_set_num_channels(lame,1);
            // 设置MP3音频质量 0~9 其中0是最好但非常慢，9是最差
            // lame_set_quality(lame,2);
            // 设置输出MP3的采样率
            // lame_set_out_samplerate
            
            lame_set_in_samplerate(lame, 11025.0);// 设置wav或caf的采样率
            lame_set_VBR(lame, vbr_default);// 设置mp3的编码方式
            lame_init_params(lame);
            
            // 执行一个 do while 的循环来反复读取
            do {
                size_t size = (size_t)(2 * sizeof(short int));
                // 将文件读进内存
                read = (int)fread(pcm_buffer, size, PCM_SIZE, pcm);
                if (read == 0)
                {
                   // 当read为0，说明pcm文件已经全部读取完毕，调用lame_encode_flush即可
                   write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                }
                else // 当read不为0，调用lame_encode_buffer进行转码
                {
                    // 双声道千万要使用lame_encode_buffer_interleaved这个函数
                    // 32位、单声道需要调用其他函数
                    // lame_encode_buffer 单声道，16位
                    // lame_encode_buffer_interleaved 双声道，16位
                    // lame_encode_buffer_float 单声道，32位
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }
                // 保存mp3文件
                fwrite(mp3_buffer, write, 1, mp3);
            } while (read != 0);// 直到 read != 0 结束转码
            
            // 写入Mp3 VBR Tag，可解决获取时长不准的问题
            lame_mp3_tags_fid(lame, mp3);
            
            // 释放
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
            
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",[exception description]);
        } @finally {
            // 删除源文件
            if (isDelete)
            {
                NSError *error;
                [fileManager removeItemAtPath:sourcePath error:&error];
                if (error == nil)
                {
                    NSLog(@"删除源文件成功");
                }
            }
            
            // 转换成功的回调
            if (success)
            {
                success(outPath);
            }
            
            NSLog(@"转换结束!!");
        }
    });
}

// caf 转 mp3 : 录音的同时转码，只是在可以录制后，重新开一个线程来进行文件的转码
- (void)audioRecodingToMP3:(NSString *)sourcePath isDeleteSourchFile:(BOOL)isDelete withSuccessBack:(void (^)(NSString * _Nonnull))success withFailBack:(void (^)(NSString * _Nonnull))fail
{
    NSLog(@"转换开始!!");
    
    // 1. 输入路径
    NSString *inPath = sourcePath;
    
    // 判断输入路径是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:sourcePath])
    {
        if (fail)
        {
            fail(@"文件不存在");
        }
        return;
    }
    
    // 2. 输出路径
    NSString *outPath = [[sourcePath stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
    
    // 边录边转码，只是在可以录制后，重新开一个线程来进行文件的转码
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 录音完成的调用，这里表示尚未完成
        // 需要在录制结束后发送一个信号， 让 do while 跳出循环
        weakself.stopRecord = NO;
        
        @try {
            int read, write;
            
            // source 被转换的音频文件位置
            // 打开只读二进制文件，该文件必须存在，否则报错
            FILE *pcm = fopen([inPath cStringUsingEncoding:NSASCIIStringEncoding], "rb");
            // output 输出生成的Mp3文件位置
            // 写方式打开或建立一个二进制文件，允许读和写
            FILE *mp3 = fopen([outPath cStringUsingEncoding:NSASCIIStringEncoding], "wb+");
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE * 2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            /*
             const int PCM_SIZE = 640 * 2; //双声道*2 单声道640即可
             const int MP3_SIZE = 8800; //计算公式pcm_size * 1.25 + 7200
             short int pcm_buffer[PCM_SIZE];
             unsigned char mp3_buffer[MP3_SIZE];
             */
            
            // 这里要注意，lame的配置要跟AVAudioRecorder的配置一致，否则会造成转换不成功
            // 初始化
            lame_t lame = lame_init();
            
            // 设置1为单通道，默认为2双通道，设置单声道会更大程度减少压缩后文件的体积，但是会造成MP3声音尖锐变声
            // lame_set_num_channels(lame,1);
            // 设置转码质量高
            // lame_set_quality(lame,2);
            
            lame_set_in_samplerate(lame, 11025.0);// 设置采样率
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            long curpos;
            BOOL isSkipPCMHeader = NO;
            
            do {
                curpos = ftell(pcm);
                long startPos = ftell(pcm);
                fseek(pcm, 0, SEEK_END);
                long endPos = ftell(pcm);
                long length = endPos - startPos;
                fseek(pcm, curpos, SEEK_SET);
                
                // 当录音进行中时, 会持续读取到指定大小文件，进行编码, 读取不到，则线程休眠
                // 在录音没有完成前，循环读取PCM文件，当读取到的字节大于我们规定的一个单位后，我们将这些字节交给lame，lame会把转码后的二进制数据输出到目标MP3文件里
                if (length > PCM_SIZE * 2 * sizeof(short int))
                {
                    
                    if (!isSkipPCMHeader)
                    {
                        // PCM数据头有四个字节的头信息，skip file header 跳过 PCM header 能保证录音的开头没有噪音
                        // 如果不跳过这一部分，转换成的mp3在播放的最初一秒内会听到一个明显的噪音
                        fseek(pcm, 4 * 1024, SEEK_CUR);
                        isSkipPCMHeader = YES;
                        NSLog(@"skip pcm file header !!!!!!!!!!，跳过 PCM header 能保证录音的开头没有噪音 ");
                    }
                    
                    // 从文件流每次读取一定数量buffer转码MP3写入，直到全部读取完文件流
                    // 将文件读进内存
                    read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                    fwrite(mp3_buffer, write, 1, mp3);
                    NSLog(@"read %d bytes", write);
                }
                else
                {
                    [NSThread sleepForTimeInterval:0.05];
                    // NSLog(@"sleep");
                }
                
            } while (!weakself.stopRecord);// 在while的条件中，当收到录音结束的判断，则会结束 do while 的循环
            
            // 从文件流每次读取一定数量buffer转码MP3写入，直到全部读取完文件流
            // 从文件流每次读取两个字节的数据，依次存入buffer，demo处理的是16位PCM数据，所以左右声道各占两个字节
            read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            
            NSLog(@"read %d bytes and flush to mp3 file", write);
            // 写入Mp3 VBR Tag，可解决获取时长不准的问题
            lame_mp3_tags_fid(lame, mp3);
            
            // 释放
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
            
        } @catch (NSException *exception) {
            if (fail)
            {
                fail([exception description]);
            }
        } @finally {
            if (isDelete)
            {
                NSError *error;
                [fileManager removeItemAtPath:sourcePath error:&error];
                if (error == nil)
                {
                    NSLog(@"删除源文件成功");
                }
            }
            
            if (success)
            {
                success(outPath);
            }
            
            NSLog(@"转换结束!!");
        }
    });
}

@end



