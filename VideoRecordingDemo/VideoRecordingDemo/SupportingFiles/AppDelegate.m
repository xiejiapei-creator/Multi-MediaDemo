//
//  AppDelegate.m
//  VideoRecordingDemo
//
//  Created by 谢佳培 on 2020/8/31.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AppDelegate.h"
#import "AVPlayerViewControllerDemo.h"
#import "AVAssetImageGeneratorDemo.h"
#import "AVPlayerDemo.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    AVPlayerDemo *rootVC = [[AVPlayerDemo alloc] init];
    UINavigationController *mainNC = [[UINavigationController alloc] initWithRootViewController:rootVC];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = mainNC;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
