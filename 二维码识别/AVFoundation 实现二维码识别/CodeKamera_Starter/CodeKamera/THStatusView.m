
#import "THStatusView.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+THAdditions.h"

@implementation THStatusView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setupView];
	}
	return self;
}

- (void)awakeFromNib {
	[self setupView];
}

- (void)setupView {

}

@end
