
typedef NS_ENUM(NSUInteger, THCameraMode) {
	THCameraModePhoto = 0, // default
	THCameraModeVideo = 1
};

@interface THCameraModeView : UIControl

@property (nonatomic) THCameraMode cameraMode;

@end
