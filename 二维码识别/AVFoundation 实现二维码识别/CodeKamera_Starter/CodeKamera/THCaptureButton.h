
typedef NS_ENUM(NSUInteger, THCaptureButtonMode) {
	THCaptureButtonModePhoto = 0, // default
	THCaptureButtonModeVideo = 1
};

@interface THCaptureButton : UIButton

+ (instancetype)captureButton;
+ (instancetype)captureButtonWithMode:(THCaptureButtonMode)captureButtonMode;

@property (nonatomic) THCaptureButtonMode captureButtonMode;


@end

