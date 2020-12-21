
#import "THPreviewView.h"
#import "THOverlayView.h"

@interface THCameraView : UIView

@property (weak, nonatomic, readonly) THPreviewView *previewView;
@property (weak, nonatomic, readonly) THOverlayView *controlsView;

@end
