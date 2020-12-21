

#import "THCameraView.h"

@interface THCameraView ()
@property (weak, nonatomic) IBOutlet THPreviewView *previewView;
@end

@implementation THCameraView

- (void)awakeFromNib {
    self.backgroundColor = [UIColor blackColor];
}

@end
