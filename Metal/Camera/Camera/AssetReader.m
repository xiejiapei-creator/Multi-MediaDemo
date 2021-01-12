//
//  AssetReader.m
//  Camera
//
//  Created by 谢佳培 on 2021/1/12.
//

#import "AssetReader.h"

@implementation AssetReader
{
    AVAssetReaderTrackOutput *readerVideoTrackOutput;// 视频输出轨道
    AVAssetReader *assetReader;// 可以从原始数据里获取解码后的音视频数据
    NSURL *videoUrl;// 视频地址
    NSLock *lock;// 锁
}

// 初始化
- (instancetype)initWithUrl:(NSURL *)url
{
    self = [super init];
    if(self != nil)
    {
        videoUrl = url;
        lock = [[NSLock alloc] init];
        [self setUpAsset];
    }
    return self;
}

// 设置Asset
- (void)setUpAsset
{
    // 1. 创建AVURLAsset
    // 默认为NO，设置为YES则可获取精确的时长
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:inputOptions];
    
    // 2.异步加载资源
    __weak typeof(self) weakSelf = self;// 解决循环引用
    NSString *tracks = @"tracks";// 键名称
    [inputAsset loadValuesAsynchronouslyForKeys:@[tracks] completionHandler: ^{
        __strong typeof(self) strongSelf = weakSelf;// 延长self生命周期
        
        // 3.开辟子线程并发队列异步函数来处理读取的inputAsset
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              NSError *error = nil;
      
              // 获取视频轨道状态码
              AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
              // 如果状态不等于成功加载则返回并打印错误信息
              if (tracksStatus != AVKeyValueStatusLoaded)
              {
                  NSLog(@"视频轨道状态为失败，错误信息为：%@", error);
                  return;
              }
              // 处理读取的inputAsset
              [strongSelf processWithAsset:inputAsset];
        });

    }];
    
}

// 处理获取到的asset
- (void)processWithAsset:(AVAsset *)asset
{
    [lock lock];// 锁定
    
    // 1.创建AVAssetReader
    NSError *error = nil;
    assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    // 2.设置像素格式为YUV 4:2:0
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // 3.读取资源中的视频信息
    readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    
    // 4.缓存区的数据输出之前是否会被复制。
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    
    // 5.为assetReader填充输出
    [assetReader addOutput:readerVideoTrackOutput];
    
    // 6.assetReader开始读取，倘若URL错误导致无法读取则进行提示
    if ([assetReader startReading] == NO)
    {
        NSLog(@"URL错误导致无法读取，错误资源为：%@", asset);
    }

    [lock unlock];// 取消锁
}

// 读取Buffer数据
- (CMSampleBufferRef)readBuffer
{
    [lock lock];// 锁定
    
    // 1.读取缓存区的内容
    CMSampleBufferRef sampleBufferRef = nil;
    if (readerVideoTrackOutput)// 判断视频输出轨道是否创建成功
    {
        // 复制下一个缓存区的内容到sampleBufferRef
        sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
    }
    
    // 2.内容读取完成后的操作
    // 判断资源读取器是否存在并且处于已经完成读取的状态
    if (assetReader && assetReader.status == AVAssetReaderStatusCompleted)
    {
        // 清空视频输出轨道
        readerVideoTrackOutput = nil;
        // 清空资源读取器
        assetReader = nil;
        // 重新初始化二者
        [self setUpAsset];
    }

    [lock unlock];// 取消锁
    return sampleBufferRef;// 返回读取到的sampleBufferRef数据
}

@end

