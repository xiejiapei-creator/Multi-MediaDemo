
#import <AVFoundation/AVFoundation.h>
#import "THBaseCameraController.h"
#import "THFaceDetectionDelegate.h"

@interface THCameraController : THBaseCameraController

@property (weak, nonatomic) id <THFaceDetectionDelegate> faceDetectionDelegate;

@end
