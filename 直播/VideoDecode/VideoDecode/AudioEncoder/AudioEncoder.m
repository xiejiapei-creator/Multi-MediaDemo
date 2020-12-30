//
//  AudioEncoder.m
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/30.
//

#import "AudioEncoder.h"
#import <AudioToolbox/AudioToolbox.h>

@interface AudioEncoder()

// 编码队列
@property (nonatomic, strong) dispatch_queue_t encoderQueue;
// 回调队列
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

// 音频转换器对象
@property (nonatomic, unsafe_unretained) AudioConverterRef audioConverter;
// PCM缓存区
@property (nonatomic) char *pcmBuffer;
// PCM缓存区大小
@property (nonatomic) size_t pcmBufferSize;

@end

@implementation AudioEncoder

// 初始化时传入编码器配置
- (instancetype)initWithConfig:(AudioConfig *)config
{
    self = [super init];
    if (self)
    {
        // 音频编码队列
        _encoderQueue = dispatch_queue_create("aac hard encoder queue", DISPATCH_QUEUE_SERIAL);
        // 音频回调队列
        _callbackQueue = dispatch_queue_create("aac hard encoder callback queue", DISPATCH_QUEUE_SERIAL);
        // 音频转换器
        _audioConverter = NULL;
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        _config = config;
        if (config == nil)
        {
            _config = [[AudioConfig alloc] init];
        }
        
    }
    return self;
}

// 当AVFoundation捕获到音频内容之后进行音频编码
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer
{
    CFRetain(sampleBuffer);
    
    // 1.判断音频转换器是否创建成功。如果未创建成功，则配置音频编码参数且创建转码器
    if (!_audioConverter)
    {
        [self setupEncoderWithSampleBuffer:sampleBuffer];
    }
    
    // 2.来到音频编码异步队列
    dispatch_async(_encoderQueue, ^{
        
        // 3.获取CMBlockBuffer, 这里面保存了PCM数据
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        
        // 4.获取BlockBuffer中音频数据大小以及音频数据地址
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        
        // 5.判断status状态
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr)
        {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            NSLog(@"Error: ACC encode get data point error: %@",error);
            return;
        }
        
        // 开辟_pcmBuffsize大小的pcm内存空间
        uint8_t *pcmBuffer = malloc(_pcmBufferSize);
        // 将_pcmBufferSize数据set到pcmBuffer中.
        memset(pcmBuffer, 0, _pcmBufferSize);
        
        // 将pcmBuffer数据填充到outAudioBufferList对象中
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = (uint32_t)_config.channelCount;
        outAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)_pcmBufferSize;
        outAudioBufferList.mBuffers[0].mData = pcmBuffer;
        
        // 输出包大小为1
        UInt32 outputDataPacketSize = 1;
        
        // 配置填充函数，获取输出数据
        status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, (__bridge void * _Nullable)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
        
        if (status == noErr)
        {
            // 获取数据
            NSData *rawAAC = [NSData dataWithBytes: outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            
            // 释放pcmBuffer
            free(pcmBuffer);
            
            // 将裸流数据传递到回调队列中
            dispatch_async(_callbackQueue, ^{
                [_delegate audioEncodeCallback:rawAAC];
            });
        }
        else
        {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        CFRelease(blockBuffer);
        CFRelease(sampleBuffer);
        if (error)
        {
            NSLog(@"error: AAC编码失败 %@",error);
        }
    });
}

// 配置音频编码参数
- (void)setupEncoderWithSampleBuffer: (CMSampleBufferRef)sampleBuffer
{
    // 获取输入参数
    AudioStreamBasicDescription inputAduioDes = *CMAudioFormatDescriptionGetStreamBasicDescription( CMSampleBufferGetFormatDescription(sampleBuffer));
    
    // 设置输出参数
    AudioStreamBasicDescription outputAudioDes = {0};
    outputAudioDes.mSampleRate = (Float64)_config.sampleRate;       // 采样率
    outputAudioDes.mFormatID = kAudioFormatMPEG4AAC;                // 输出格式
    outputAudioDes.mFormatFlags = kMPEG4Object_AAC_LC;              // 如果设为0 代表无损编码
    outputAudioDes.mBytesPerPacket = 0;                             // 自己确定每个packet大小
    outputAudioDes.mFramesPerPacket = 1024;                         // 每一个packet帧数 AAC-1024
    outputAudioDes.mBytesPerFrame = 0;                              // 每一帧大小
    outputAudioDes.mChannelsPerFrame = (uint32_t)_config.channelCount; // 输出声道数
    outputAudioDes.mBitsPerChannel = 0;                             // 数据帧中每个通道的采样位数
    outputAudioDes.mReserved =  0;                                  // 对齐方式 0(8字节对齐)
    
    // 填充输出相关信息
    UInt32 outDesSize = sizeof(outputAudioDes);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
    
    // 获取编码器的描述信息(只能传入software)
    AudioClassDescription *audioClassDesc = [self getAudioCalssDescriptionWithType:outputAudioDes.mFormatID fromManufacture:kAppleSoftwareAudioCodecManufacturer];
    
    /** 创建converter
     参数1：输入音频格式描述
     参数2：输出音频格式描述
     参数3：class desc的数量
     参数4：class desc
     参数5：创建的解码器
     */
    OSStatus status = AudioConverterNewSpecific(&inputAduioDes, &outputAudioDes, 1, audioClassDesc, &_audioConverter);
    if (status != noErr)
    {
        NSLog(@"Error！：硬编码AAC创建失败, status= %d", (int)status);
        return;
    }
    
    // 设置编解码质量
    UInt32 temp = kAudioConverterQuality_High;
    // 编解码器的呈现质量
    AudioConverterSetProperty(_audioConverter, kAudioConverterCodecQuality, sizeof(temp), &temp);
    
    // 设置比特率
    uint32_t audioBitrate = (uint32_t)self.config.bitrate;
    uint32_t audioBitrateSize = sizeof(audioBitrate);
    status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, audioBitrateSize, &audioBitrate);
    if (status != noErr)
    {
        NSLog(@"Error！：硬编码AAC 设置比特率失败");
    }
}

// 编码器回调函数
static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    
    // 获取self
    AudioEncoder *aacEncoder = (__bridge AudioEncoder *)(inUserData);
   
    // 判断pcmBuffsize大小，为空则表示不需要再填充数据了
    if (!aacEncoder.pcmBufferSize)
    {
        *ioNumberDataPackets = 0;
        return  - 1;
    }
    
    // 填充PCM数据
    ioData->mBuffers[0].mData = aacEncoder.pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (uint32_t)aacEncoder.pcmBufferSize;
    ioData->mBuffers[0].mNumberChannels = (uint32_t)aacEncoder.config.channelCount;
    
    // 填充完毕则清空数据
    aacEncoder.pcmBufferSize = 0;
    *ioNumberDataPackets = 1;
    return noErr;
}

#pragma mark - 辅助方法

- (void)dealloc
{
    if (_audioConverter)
    {
        AudioConverterDispose(_audioConverter);
        _audioConverter = NULL;
    }
}

// 可以直接播放PCM数据，只需要将sampleBuffer数据提取出的PCM数据返回给ViewController即可
- (NSData *)convertAudioSamepleBufferToPcmData: (CMSampleBufferRef)sampleBuffer
{
    // 获取pcm数据大小
    size_t size = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    
    // 分配空间
    int8_t *audio_data = (int8_t *)malloc(size);
    memset(audio_data, 0, size);// 所有数据初始化为0
    
    // 获取CMBlockBuffer, 这里面保存了PCM数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    // 将数据copy到我们分配的空间audio_data中
    CMBlockBufferCopyDataBytes(blockBuffer, 0, size, audio_data);
    // 将audio_data转化为NSData
    NSData *data = [NSData dataWithBytes:audio_data length:size];
    free(audio_data);
    
    return data;
}

// 为AAC添加ADTS头
- (NSData*)adtsDataForPacketLength:(NSUInteger)packetLength
{
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    int profile = 2;
    int freqIdx = 4;
    int chanCfg = 1;
    NSUInteger fullLength = adtsLength + packetLength;
    packet[0] = (char)0xFF;
    packet[1] = (char)0xF9;
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

// 获取编码器类型描述
- (AudioClassDescription *)getAudioCalssDescriptionWithType: (AudioFormatID)type fromManufacture: (uint32_t)manufacture
{
    static AudioClassDescription desc;
    UInt32 encoderSpecific = type;
    
    // 获取满足AAC编码器的总大小
    UInt32 size;

    OSStatus status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecific), &encoderSpecific, &size);
    if (status != noErr)
    {
        NSLog(@"Error！：硬编码AAC get info 失败, status= %d", (int)status);
        return nil;
    }
    
    // 计算aac编码器的个数
    unsigned int count = size / sizeof(AudioClassDescription);
    
    // 创建一个包含count个编码器的数组
    AudioClassDescription description[count];
    
    // 将满足aac编码的编码器的信息写入数组
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecific), &encoderSpecific, &size, &description);
    
    if (status != noErr)
    {
        NSLog(@"Error！：硬编码AAC get propery 失败, status= %d", (int)status);
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++)
    {
        if (type == description[i].mSubType && manufacture == description[i].mManufacturer)
        {
            desc = description[i];
            return &desc;
        }
    }
    return nil;
}

@end


