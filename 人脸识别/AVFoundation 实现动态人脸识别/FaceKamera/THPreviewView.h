
#import <AVFoundation/AVFoundation.h>
#import "THFaceDetectionDelegate.h"

@interface THPreviewView : UIView <THFaceDetectionDelegate>

@property (strong, nonatomic) AVCaptureSession *session;

@end
