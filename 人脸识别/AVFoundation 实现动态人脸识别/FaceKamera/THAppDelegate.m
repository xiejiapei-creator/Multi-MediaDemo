
#import "THAppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@implementation THAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Configure audio session for playback and record
    AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
	[session setActive:YES error:nil];

    return YES;
}

@end
