//
//  AppDelegate.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/26.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AppDelegate.h"
#import "BasicUseViewController.h"
#import "ToolKitViewController.h"
#import "SoundEffectViewController.h"
#import "MusicViewController.h"
#import "AudioSessionViewController.h"
#import "MusicPlayerController.h"
#import "FreeStreamerViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    FreeStreamerViewController *rootVC = [[FreeStreamerViewController alloc] init];
    UINavigationController *mainNC = [[UINavigationController alloc] initWithRootViewController:rootVC];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = mainNC;
    [self.window makeKeyAndVisible];
    
    return YES;
}



@end
