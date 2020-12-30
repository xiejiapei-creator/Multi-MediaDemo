//
//  AVConfig.m
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import "AVConfig.h"

@implementation AudioConfig

+ (instancetype)defaultAudioConfig
{
    return  [[AudioConfig alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.bitrate = 96000;
        self.channelCount = 1;
        self.sampleSize = 16;
        self.sampleRate = 44100;
    }
    return self;
}

@end

@implementation VideoConfig

+ (instancetype)defaultVideoConfig
{
    return [[VideoConfig alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.width = 480;
        self.height = 640;
        self.bitrate = 640*1000;
        self.fps = 25;
    }
    return self;
}

@end
