
#import "THAssetsLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

static NSString *const THThumbnailCreatedNotification = @"THThumbnailCreated";

@interface THAssetsLibrary ()
@property (strong, nonatomic) ALAssetsLibrary *library;
@end
@implementation THAssetsLibrary

- (instancetype)init {
	self = [super init];
	if (self) {
		_library = [[ALAssetsLibrary alloc] init];
	}
	return self;
}

- (void)writeImage:(UIImage *)image completionHandler:(THAssetsLibraryWriteCompletionHandler)completionHandler {

    [self.library writeImageToSavedPhotosAlbum:image.CGImage
                              orientation:(NSInteger)image.imageOrientation
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              if (!error) {
                                  [self postThumbnailNotifification:image];
								  completionHandler(YES, nil);
                              } else {
								  completionHandler(NO, error);
                              }
                          }];

}

- (void)writeVideoAtURL:(NSURL *)videoURL
	  completionHandler:(THAssetsLibraryWriteCompletionHandler)completionHandler {

    if ([self.library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL]) {

        ALAssetsLibraryWriteVideoCompletionBlock completionBlock;

        completionBlock = ^(NSURL *assetURL, NSError *error){
            if (error) {
				completionHandler(NO, error);
            } else {
                [self generateThumbnailForVideoAtURL:videoURL];
				completionHandler(YES, nil);
            }
        };

        [self.library writeVideoAtPathToSavedPhotosAlbum:videoURL
										 completionBlock:completionBlock];
    }
}

- (void)generateThumbnailForVideoAtURL:(NSURL *)videoURL {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        AVAsset *asset = [AVAsset assetWithURL:videoURL];

        AVAssetImageGenerator *imageGenerator =
			[AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        imageGenerator.maximumSize = CGSizeMake(100.0f, 0.0f);
        imageGenerator.appliesPreferredTrackTransform = YES;

        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero
                                                     actualTime:NULL
                                                          error:nil];
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);

		[self postThumbnailNotifification:image];
    });
}

- (void)postThumbnailNotifification:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:THThumbnailCreatedNotification object:image];
    });
}

@end
