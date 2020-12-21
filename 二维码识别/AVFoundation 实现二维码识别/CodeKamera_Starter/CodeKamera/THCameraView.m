
#import "THCameraView.h"

@interface THCameraView ()

@property (weak, nonatomic) IBOutlet THPreviewView *previewView;
@property (weak, nonatomic) IBOutlet THOverlayView *controlsView;

@end

@implementation THCameraView

- (void)awakeFromNib {
    self.backgroundColor = [UIColor blackColor];
}

@end
