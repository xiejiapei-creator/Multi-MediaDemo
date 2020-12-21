
typedef void(^THAssetsLibraryWriteCompletionHandler)(BOOL success, NSError *error);

@interface THAssetsLibrary : NSObject

- (void)writeImage:(UIImage *)image completionHandler:(THAssetsLibraryWriteCompletionHandler)completionHandler;
- (void)writeVideoAtURL:(NSURL *)videoURL completionHandler:(THAssetsLibraryWriteCompletionHandler)completionHandler;

@end
