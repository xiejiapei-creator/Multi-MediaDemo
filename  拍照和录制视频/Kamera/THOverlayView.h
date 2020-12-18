
#import <UIKit/UIKit.h>
#import "THCameraModeView.h"
#import "THStatusView.h"

@interface THOverlayView : UIView

@property (weak, nonatomic) IBOutlet THCameraModeView *modeView;
@property (weak, nonatomic) IBOutlet THStatusView *statusView;

@property (nonatomic) BOOL flashControlHidden;

@end
