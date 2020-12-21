

#import <AVFoundation/AVFoundation.h>
#import "THBaseCameraController.h"
#import "THCodeDetectionDelegate.h"

// NOTE: THCodeDetectionDelegate shown in Listing 7.14 moved into it's own file.

@interface THCameraController : THBaseCameraController

@property (weak, nonatomic) id <THCodeDetectionDelegate> codeDetectionDelegate;

@end
