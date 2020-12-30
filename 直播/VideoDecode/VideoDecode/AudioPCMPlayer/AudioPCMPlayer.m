//
//  AudioPCMPlayer.m
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/30.
//

#import "AudioPCMPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define MIN_SIZE_PER_FRAME 2048 // 每帧最小数据长度
static const int kNumberBuffers_play = 3;

typedef struct AudioPlayerState
{
    AudioStreamBasicDescription   mDataFormat;
    AudioQueueRef                 mQueue;
    AudioQueueBufferRef           mBuffers[kNumberBuffers_play];
    AudioStreamPacketDescription  *mPacketDescs;
}AudioPlayerState;

@interface AudioPCMPlayer ()

@property (nonatomic, assign) AudioPlayerState audioPlayerState;
@property (nonatomic, strong) AudioConfig *config;
@property (nonatomic, assign) BOOL isPlaying;

@end

@implementation AudioPCMPlayer

// 初始化配置
- (instancetype)initWithConfig:(AudioConfig *)config
{
    self = [super init];
    if (self)
    {
        _config = config;

        AudioStreamBasicDescription dataFormat = {0};
        dataFormat.mSampleRate = (Float64)_config.sampleRate;       //采样率
        dataFormat.mChannelsPerFrame = (UInt32)_config.channelCount; //输出声道数
        dataFormat.mFormatID = kAudioFormatLinearPCM;                //输出格式
        dataFormat.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked); //编码 12
        dataFormat.mFramesPerPacket = 1;                            //每一个packet帧数 ；
        dataFormat.mBitsPerChannel = 16;                             //数据帧中每个通道的采样位数。
        dataFormat.mBytesPerFrame = dataFormat.mBitsPerChannel / 8 *dataFormat.mChannelsPerFrame;                              //每一帧大小（采样位数 / 8 *声道数）
        dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame * dataFormat.mFramesPerPacket;                             //每个packet大小（帧大小 * 帧数）
        dataFormat.mReserved =  0;
        
        AudioPlayerState state = {0};
        state.mDataFormat = dataFormat;
        _audioPlayerState = state;
        
        // 设置会话
        [self setupSession];
        
        // 创建播放队列
        OSStatus status = AudioQueueNewOutput(&_audioPlayerState.mDataFormat, TMAudioQueueOutputCallback, NULL, NULL, NULL, 0, &_audioPlayerState.mQueue);
        if (status != noErr)
        {
            NSError *error = [[NSError alloc] initWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            NSLog(@"Error: AudioQueue create error = %@", [error description]);
            return self;
        }
        
        // 设置音量
        [self setupVoice:1];
        
        _isPlaying = false;
    }
    return self;
}

// 设置会话
- (void)setupSession
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error)
    {
        NSLog(@"Error: audioQueue palyer AVAudioSession error, error: %@", error);
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error)
    {
        NSLog(@"Error: audioQueue palyer AVAudioSession error, error: %@", error);
    }
}

// 设置音量增量
- (void)setupVoice:(Float32)gain
{
    Float32 localGain = gain;
    if (gain < 0)
    {
        localGain = 0;
    }
    else if (gain > 1)
    {
        localGain = 1;
    }
    
    // 设置播放音频队列参数值
    AudioQueueSetParameter(_audioPlayerState.mQueue, kAudioQueueParam_Volume, localGain);
}

// 播放pcm
- (void)playPCMData:(NSData *)data
{
    // 指向音频队列缓冲区
    AudioQueueBufferRef inBuffer;
    // 要求音频队列对象分配音频队列缓冲区
    AudioQueueAllocateBuffer(_audioPlayerState.mQueue, MIN_SIZE_PER_FRAME, &inBuffer);
    // 将data里的数据拷贝到inBuffer.mAudioData中
    memcpy(inBuffer->mAudioData, data.bytes, data.length);
    // 设置inBuffer.mAudioDataByteSize
    inBuffer->mAudioDataByteSize = (UInt32)data.length;
    
    // 将缓冲区添加到录制或播放音频队列的缓冲区队列
    OSStatus status = AudioQueueEnqueueBuffer(_audioPlayerState.mQueue, inBuffer, 0, NULL);
    if (status != noErr)
    {
        NSLog(@"Error: audio queue palyer  enqueue error: %d",(int)status);
    }
    
    // 开始播放或录制音频
    AudioQueueStart(_audioPlayerState.mQueue, NULL);
}

// 回调函数
static void TMAudioQueueOutputCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{   
    AudioQueueFreeBuffer(inAQ, inBuffer);
}

// 销毁播放器
- (void)dispose
{
    AudioQueueStop(_audioPlayerState.mQueue, true);
    AudioQueueDispose(_audioPlayerState.mQueue, true);
}

@end
