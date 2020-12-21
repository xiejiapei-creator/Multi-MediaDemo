
#import "THViewController.h"
#import "THCameraController.h"
#import "THPreviewView.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface THViewController ()

@property (strong, nonatomic) THCameraController *cameraController;
@property (weak, nonatomic) IBOutlet THPreviewView *previewView;

@end

@implementation THViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.cameraController = [[THCameraController alloc] init];

    NSError *error;
    if ([self.cameraController setupSession:&error]) {

        [self.cameraController switchCameras];
        [self.previewView setSession:self.cameraController.captureSession];
        self.cameraController.faceDetectionDelegate = self.previewView;

        [self.cameraController startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }

}

- (IBAction)swapCameras:(id)sender {
    [self.cameraController switchCameras];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
