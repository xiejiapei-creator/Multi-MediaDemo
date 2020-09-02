//
//  SoundEffectViewController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/31.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "SoundEffectViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface SoundEffectViewController ()

@end

@implementation SoundEffectViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self playSoundEffect:@"Sound"];
}

/**
 *  播放音效文件
 *  @param name 音频文件名称
 */
-(void)playSoundEffect:(NSString *)name
{
    NSString *audioFile = [[NSBundle mainBundle] pathForResource:name ofType:@"caf"];
    NSURL *fileUrl = [NSURL fileURLWithPath:audioFile];
    
    //1.获得系统声音ID
    SystemSoundID soundID = 0;

    /**
     * inFileUrl:音频文件url
     * outSystemSoundID:声音id（此函数会将音效文件加入到系统音频服务中并返回一个长整形ID）
     */
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
  
    //如果需要在播放完之后执行某些操作，可以调用如下方法注册一个播放完成回调函数
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundCompleteCallback, NULL);
    
    //2.播放音频
    AudioServicesPlaySystemSound(soundID);//播放音效
    AudioServicesPlayAlertSound(soundID);//播放音效并震动
}

/**
 *  播放完成回调函数
 *  @param soundID    系统声音ID
 *  @param clientData 回调时传递的数据
 */
void soundCompleteCallback(SystemSoundID soundID,void * clientData)
{
    NSLog(@"播放完成...");
}

@end
