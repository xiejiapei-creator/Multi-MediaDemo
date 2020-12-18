
#import "THFlashControl.h"

@interface THStatusView : UIView <THFlashControlDelegate>

@property (weak, nonatomic) IBOutlet THFlashControl *flashControl;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@end
