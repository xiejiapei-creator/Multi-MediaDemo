
#import "THViewController.h"
#import "THCameraController.h"
#import "THPreviewView.h"
#import <AVFoundation/AVFoundation.h>
#import "THOverlayView.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface THViewController ()

@property (strong, nonatomic) THCameraController *cameraController;
@property (weak, nonatomic) IBOutlet THPreviewView *previewView;
@property (weak, nonatomic) IBOutlet THOverlayView *overlayView;
@property (weak, nonatomic) IBOutlet UIButton *thumbnailButton;

@end

@implementation THViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateThumbnail:)
                                                 name:THThumbnailCreatedNotification
                                               object:nil];
    
    self.cameraController = [[THCameraController alloc] init];

    NSError *error;
    if ([self.cameraController setupSession:&error]) {

        [self.previewView setSession:self.cameraController.captureSession];
        self.cameraController.codeDetectionDelegate = self.previewView;

        [self.cameraController startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }

}

- (void)updateThumbnail:(NSNotification *)notification {
    UIImage *image = notification.object;
    [self.thumbnailButton setBackgroundImage:image forState:UIControlStateNormal];
    self.thumbnailButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.thumbnailButton.layer.borderWidth = 1.0f;
}

- (IBAction)showCameraRoll:(id)sender {
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)toggleRecording:(UIButton *)sender {
    if (!self.cameraController.isRecording) {
        dispatch_async(dispatch_queue_create("com.tapharmonic.kamera", NULL), ^{
            [self.cameraController startRecording];
        });
    } else {
        [self.cameraController stopRecording];
    }
    sender.selected = !sender.selected;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
