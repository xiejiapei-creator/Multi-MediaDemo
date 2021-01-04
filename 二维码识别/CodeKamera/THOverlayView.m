
#import "THOverlayView.h"

@interface THOverlayView ()

@end

@implementation THOverlayView

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
	self.statusView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
}

@end
