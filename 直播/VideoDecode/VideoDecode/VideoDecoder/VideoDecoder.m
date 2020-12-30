//
//  VideoDecoder.m
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import "VideoDecoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface VideoDecoder ()

// 解码队列
@property (nonatomic, strong) dispatch_queue_t decodeQueue;
// 回调队列
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
// 解码会话
@property (nonatomic) VTDecompressionSessionRef decodeSesion;

@end

@implementation VideoDecoder
{
    // SPS
    uint8_t *_sps;
    NSUInteger _spsSize;
    
    // PPS
    uint8_t *_pps;
    NSUInteger _ppsSize;
    
    // 解密格式信息
    CMVideoFormatDescriptionRef _decodeDesc;
}

// 公有的解码Nalu数据方法
- (void)decodeNaluData:(NSData *)frame
{
    // 将解码放在异步队列
    dispatch_async(_decodeQueue, ^{
        // 获取frame，将NSData转化为二进制数据
        uint8_t *nalu = (uint8_t *)frame.bytes;
        // 调用私有的解码Nalu数据方法，参数1:数据 参数2:数据长度
        [self decodeNaluData:nalu size:(uint32_t)frame.length];
    });
}

// 私有的解码Nalu数据方法
- (void)decodeNaluData:(uint8_t *)frame size:(uint32_t)size
{
    // frame的前4个字节是NALU数据的开始码，也就是00 00 00 01
    int type = (frame[4] & 0x1F);
    
    // 将NALU的开始码转为4字节大端NALU的长度信息
    uint32_t naluSize = size - 4;
    uint8_t *pNaluSize = (uint8_t *)(&naluSize);
    CVPixelBufferRef pixelBuffer = NULL;
    frame[0] = *(pNaluSize + 3);
    frame[1] = *(pNaluSize + 2);
    frame[2] = *(pNaluSize + 1);
    frame[3] = *(pNaluSize);
    
    // 解析时第一次获取到关键帧的时候初始化解码器initDecoder
    switch (type)
    {
        case 0x05:// 关键帧
            if ([self initDecoder])
            {
                pixelBuffer= [self decode:frame withSize:size];
            }
            break;
        case 0x06:
            NSLog(@"SEI");// 增强信息
            break;
        case 0x07:// sps
            _spsSize = naluSize;
            _sps = malloc(_spsSize);
            memcpy(_sps, &frame[4], _spsSize);
            break;
        case 0x08:// pps
            _ppsSize = naluSize;
            _pps = malloc(_ppsSize);
            memcpy(_pps, &frame[4], _ppsSize);// 从第5位开始赋值数据
            break;
        default:// 其他帧（1-5）
            if ([self initDecoder])// 初始化解码器
            {
                // 进行解码
                pixelBuffer = [self decode:frame withSize:size];
            }
            break;
    }
}

// 初始化配置信息
- (instancetype)initWithConfig:(VideoConfig *)config
{
    self = [super init];
    if (self)
    {
        // 初始化VideoConfig 信息
        _config = config;
        
        // 创建解码队列与回调队列
        _decodeQueue = dispatch_queue_create("h264 hard decode queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("h264 hard decode callback queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// 初始化解码器
- (BOOL)initDecoder
{
    // 解码器用来创建decodeSesion，通过判断它是否存在，可以保证只创建一次解码器，因为要防止每帧解码都会创建解码器
    if (_decodeSesion) return true;
    
    // 包含了sps/pps，用来保存参数集
    const uint8_t * const parameterSetPointers[2] = {_sps, _pps};
    // 用来用来保存参数集的尺寸
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    // Nalu Header的长度
    int naluHeaderLen = 4;
    
    // 根据sps pps设置解码参数
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, naluHeaderLen, &_decodeDesc);
    if (status != noErr)
    {
        NSLog(@"Video hard DecodeSession create H264ParameterSets(sps, pps) failed status= %d", (int)status);
        return false;
    }
    
    // 解码参数
    NSDictionary *destinationPixBufferAttrs =
    @{
      (id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
      (id)kCVPixelBufferWidthKey: [NSNumber numberWithInteger:_config.width],
      (id)kCVPixelBufferHeightKey: [NSNumber numberWithInteger:_config.height],
      (id)kCVPixelBufferOpenGLCompatibilityKey: [NSNumber numberWithBool:true]
      };
    
    // 解码回调设置
    VTDecompressionOutputCallbackRecord callbackRecord;
    callbackRecord.decompressionOutputCallback = videoDecompressionOutputCallback;
    callbackRecord.decompressionOutputRefCon = (__bridge void * _Nullable)(self);
    
    // 创建用于解压缩视频帧的会话
    status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decodeDesc, NULL, (__bridge CFDictionaryRef _Nullable)(destinationPixBufferAttrs), &callbackRecord, &_decodeSesion);
    
    // 判断一下status
    if (status != noErr)
    {
        NSLog(@"Video hard DecodeSession create failed status= %d", (int)status);
        return false;
    }
    
    // 设置解码会话属性(实时编码)
    status = VTSessionSetProperty(_decodeSesion, kVTDecompressionPropertyKey_RealTime,kCFBooleanTrue);
    NSLog(@"Vidoe hard decodeSession set property RealTime status = %d", (int)status);
    
    return true;
}

// 解码函数
- (CVPixelBufferRef)decode:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    CMBlockBufferFlags flag0 = 0;
    
    // 创建blockBuffer
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, frame, frameSize, kCFAllocatorNull, NULL, 0, frameSize, flag0, &blockBuffer);
    
    if (status != kCMBlockBufferNoErr)
    {
        NSLog(@"Video hard decode create blockBuffer error code=%d", (int)status);
        return outputPixelBuffer;
    }
    
    // 创建sampleBuffer
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {frameSize};
    
    status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decodeDesc, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
    
    if (status != noErr || !sampleBuffer)
    {
        NSLog(@"Video hard decode create sampleBuffer failed status=%d", (int)status);
        CFRelease(blockBuffer);
        return outputPixelBuffer;
    }
    
    // 解码数据
    // 向视频解码器提示使用低功耗模式是可以的
    VTDecodeFrameFlags flag1 = kVTDecodeFrame_1xRealTimePlayback;
    // 使用异步解码
    VTDecodeInfoFlags  infoFlag = kVTDecodeInfo_Asynchronous;
    
    status = VTDecompressionSessionDecodeFrame(_decodeSesion, sampleBuffer, flag1, &outputPixelBuffer, &infoFlag);
    
    if (status == kVTInvalidSessionErr)
    {
        NSLog(@"Video hard decode  InvalidSessionErr status =%d", (int)status);
    }
    else if (status == kVTVideoDecoderBadDataErr)
    {
        NSLog(@"Video hard decode  BadData status =%d", (int)status);
    }
    else if (status != noErr)
    {
        NSLog(@"Video hard decode failed status =%d", (int)status);
    }
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    
    return outputPixelBuffer;
}

// 解码完成后的回调函数
void videoDecompressionOutputCallback(void * CM_NULLABLE decompressionOutputRefCon,
                                      void * CM_NULLABLE sourceFrameRefCon,
                                      OSStatus status,
                                      VTDecodeInfoFlags infoFlags,
                                      CM_NULLABLE CVImageBufferRef imageBuffer,
                                      CMTime presentationTimeStamp,
                                      CMTime presentationDuration )
{
    // 解码失败后到回调函数
    if (status != noErr)
    {
        NSLog(@"Video hard decode callback error status=%d", (int)status);
        return;
    }
    
    // 将解码后的数据 sourceFrameRefCon -> CVPixelBufferRef
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
    
    // 获取self
    VideoDecoder *decoder = (__bridge VideoDecoder *)(decompressionOutputRefCon);
    
    // 调用回调队列
    dispatch_async(decoder.callbackQueue, ^{
        // 将解码后的数据交给decoder代理
        [decoder.delegate videoDecodeCallback:imageBuffer];
        
        // 释放数据
        CVPixelBufferRelease(imageBuffer);
    });
}

// 销毁
- (void)dealloc
{
    if (_decodeSesion)
    {
        VTDecompressionSessionInvalidate(_decodeSesion);
        CFRelease(_decodeSesion);
        _decodeSesion = NULL;
    }
}

@end


