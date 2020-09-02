//
//  AVAssetImageGeneratorDemo.m
//  VideoRecordingDemo
//
//  Created by 谢佳培 on 2020/9/2.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AVAssetImageGeneratorDemo.h"
#import <AVFoundation/AVFoundation.h>

@interface AVAssetImageGeneratorDemo ()

@end

@implementation AVAssetImageGeneratorDemo

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 获取第13.0s的缩略图
    [self thumbnailImageRequest:13.0];
}

// 截图
-(void)thumbnailImageRequest:(CGFloat )timeBySecond
{
    // 创建URL
    NSURL *url = [NSURL URLWithString:@"http://v.cctv.com/flash/mp4video6/TMS/2011/01/05/cf752b1c12ce452b3040cab2f90bc265_h264818000nero_aac32-1.mp4"];
    // 根据url创建AVURLAsset
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
    // 根据AVURLAsset创建AVAssetImageGenerator
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    
    NSError *error = nil;
    // CMTime是表示电影时间信息的结构体 第一个参数表示是视频第几秒，第二个参数表示每秒帧数
    // requestTime:缩略图创建时间 actualTime:缩略图实际生成的时间
    CMTime requestTime = CMTimeMakeWithSeconds(timeBySecond, 10);
    CMTime actualTime;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:requestTime actualTime:&actualTime error:&error];
    if(error)
    {
        NSLog(@"截取视频缩略图时发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    CMTimeShow(actualTime);
    
    //转化为UIImage
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    //保存到相册
    UIImageWriteToSavedPhotosAlbum(image,nil, nil, nil);
    CGImageRelease(cgImage);
}

@end
