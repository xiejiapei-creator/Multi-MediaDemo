
@class THFlashControl;

@protocol THFlashControlDelegate <NSObject>

@optional
- (void)flashControlWillExpand;
- (void)flashControlDidExpand;
- (void)flashControlWillCollapse;
- (void)flashControlDidCollapse;

@end

@interface THFlashControl : UIControl

@property (nonatomic) NSInteger selectedMode;
@property (weak, nonatomic) id<THFlashControlDelegate> delegate;

@end
