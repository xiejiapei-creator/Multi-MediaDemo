//
//  ViewController.m
//  EditVideoOCDemo
//
//  Created by 谢佳培 on 2021/2/23.
//

#import "ViewController.h"
#import <Photos/Photos.h>

@interface ViewController ()

@property (strong, nonatomic) UIView *playerView;
@property (strong, nonatomic) UIButton *playButton;
@property (strong, nonatomic) UIButton *exportButton;

@property (strong,nonatomic) AVPlayer *player;
@property (strong,nonatomic) AVPlayerLayer *playerLayer;
@property (strong,nonatomic) AVMutableComposition *composition;
@property (strong,nonatomic) AVMutableAudioMix *audioMix;
@property (strong,nonatomic) AVMutableVideoComposition *videoComposition;
@property (strong,nonatomic) CALayer *waterMark;

@end


@implementation ViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    [self createSubviews];
    
    // 用户授权
    [self requestPhotoLibraryAuthorization];
    
    // 合成音视频
    [self setupComposition];
    
    // 视频播放器
    [self setupPlayer];
}

- (void)createSubviews
{
    UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 720.f, 300, 50.f)];
    [playButton addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];
    [playButton setTitle:@"播放视频" forState:UIControlStateNormal];
    [playButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    playButton.layer.cornerRadius = 5.f;
    playButton.clipsToBounds = YES;
    playButton.layer.borderWidth = 1.f;
    playButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:playButton];
    
    UIButton *exportButton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 820.f, 300, 50.f)];
    [exportButton addTarget:self action:@selector(exportVideoAction) forControlEvents:UIControlEventTouchUpInside];
    [exportButton setTitle:@"导出视频" forState:UIControlStateNormal];
    [exportButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    exportButton.layer.cornerRadius = 5.f;
    exportButton.clipsToBounds = YES;
    exportButton.layer.borderWidth = 1.f;
    exportButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:exportButton];
    
    self.playerView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, 450, 300)];
    self.playerView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.playerView];
    
    UILabel *videoFadeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 440, 100, 50)];
    videoFadeLabel.text = @"视频淡出";
    [self.view addSubview:videoFadeLabel];
    
    UILabel *audioFadeOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(150, 440, 100, 50)];
    audioFadeOutLabel.text = @"音频淡出";
    [self.view addSubview:audioFadeOutLabel];
    
    UILabel *videoTransformLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, 440, 100, 50)];
    videoTransformLabel.text = @"视频滑出";
    [self.view addSubview:videoTransformLabel];
    
    UISwitch *videoFadeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 500, 100, 50)];
    videoFadeSwitch.backgroundColor = [UIColor grayColor];
    [videoFadeSwitch addTarget:self action:@selector(videoFadeOut:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:videoFadeSwitch];
    
    UISwitch *audioFadeOutSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(150, 500, 100, 50)];
    audioFadeOutSwitch.backgroundColor = [UIColor grayColor];
    [audioFadeOutSwitch addTarget:self action:@selector(audioFadeOut:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:audioFadeOutSwitch];
    
    UISwitch *videoTransformSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(280, 500, 100, 50)];
    videoTransformSwitch.backgroundColor = [UIColor grayColor];
    [videoTransformSwitch addTarget:self action:@selector(videoTransform:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:videoTransformSwitch];
}

#pragma mark - 视频特效

// 播放视频
- (void)playAction
{
    [self.player play];
    self.playButton.enabled = NO;
}

// 导出视频
- (void)exportVideoAction
{
    [self.player pause];
    self.playButton.enabled = YES;
    
    [self exportVideo];
}

// 音频淡出
- (void)audioFadeOut:(UISwitch *)sender
{
    AVMutableAudioMixInputParameters *parameters = (AVMutableAudioMixInputParameters *)[self.audioMix.inputParameters firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero,self.composition.duration);
    
    if (sender.isOn)
    {
        // 淡出效果：逐渐变小
        [parameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:timeRange];
    }
    else
    {
        [parameters setVolumeRampFromStartVolume:1 toEndVolume:1 timeRange:timeRange];
    }
    
    [self setupPlayer];
}

// 视频淡出
- (void)videoFadeOut:(UISwitch *)sender
{
    AVMutableVideoCompositionInstruction *compositionInstruction = (AVMutableVideoCompositionInstruction *)[self.videoComposition.instructions firstObject];
    AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction = (AVMutableVideoCompositionLayerInstruction *)[compositionInstruction.layerInstructions firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(self.composition.duration)/2, 600), self.composition.duration);
    
    if (sender.isOn)
    {
        [compositionLayerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:timeRange];
    }
    else
    {
        [compositionLayerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:1 timeRange:timeRange];
    }
    
    [self setupPlayer];
}

// 视频滑出
- (void)videoTransform:(UISwitch *)sender
{
    AVMutableVideoCompositionInstruction *compositionInstruction = (AVMutableVideoCompositionInstruction *)[self.videoComposition.instructions firstObject];
    AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction = (AVMutableVideoCompositionLayerInstruction *)[compositionInstruction.layerInstructions firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(self.composition.duration)/2, 600), self.composition.duration);
    
    AVMutableCompositionTrack *videoTrack = [[self.composition tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGAffineTransform currentTransform = videoTrack.preferredTransform;
    CGAffineTransform newTransform  = CGAffineTransformTranslate(currentTransform, 0, videoTrack.naturalSize.height);
    
    if (sender.isOn)
    {
        [compositionLayerInstruction setTransformRampFromStartTransform:currentTransform toEndTransform:newTransform timeRange:timeRange];
    }
    else
    {
        [compositionLayerInstruction setTransformRampFromStartTransform:currentTransform toEndTransform:currentTransform timeRange:timeRange];
    }
    
    [self setupPlayer];
}

#pragma mark - 用户授权

// 因为要将导出的视频保存到相册，所以需要用户授权
- (void)requestPhotoLibraryAuthorization
{
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized)
    {
        self.exportButton.enabled = NO;
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized)
                {
                    self.exportButton.enabled = YES;
                }
                else
                {
                    [self showAlertWithMessage:@"请允许app访问您的照片，否则无法使用视频导出功能"];
                }
            });
        }];
    }
}

// 弹出提示框
- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 音视频合成与播放

// 音视频合成
- (void)setupComposition
{
    // 获取音、视频资源（AVAssetTrack）
    NSURL *video1Url = [[NSBundle mainBundle] URLForResource:@"Girl" withExtension:@"mp4"];
    NSURL *video2Url = [[NSBundle mainBundle] URLForResource:@"Logic" withExtension:@"mp4"];
    NSURL *audioUrl = [[NSBundle mainBundle] URLForResource:@"audio" withExtension:@"mp3"];
    
    AVURLAsset *video1Asset = [AVURLAsset assetWithURL:video1Url];
    AVURLAsset *video2Asset = [AVURLAsset assetWithURL:video2Url];
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:audioUrl];
    
    AVAssetTrack *video1Track = [[video1Asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *video2Track = [[video2Asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *audioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    NSAssert(video1Track && video2Track && audioTrack, @"无法读取视频或音频材料");
    
    // 1、初始化AVMutableComposition，并创建两条空轨道AVMutableCompositionTrack，一条是video类型，另一条是audio类型
    self.composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // 2、往视频轨道插入视频资源
    Float64 videoCutTime = 3;
    CMTimeRange videoCutRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoCutTime, 600));
    [videoCompositionTrack insertTimeRange:videoCutRange ofTrack:video1Track atTime:kCMTimeZero error:nil];
    [videoCompositionTrack insertTimeRange:videoCutRange ofTrack:video2Track atTime:CMTimeMakeWithSeconds(videoCutTime, 600) error:nil];
    
    // 3、往音频轨道插入音频资源
    CMTimeRange audioCutRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoCutTime * 2, 600));
    [audioCompositionTrack insertTimeRange:audioCutRange ofTrack:audioTrack atTime:kCMTimeZero error:nil];
}

// 播放方法有问题，导致不能正常在展示时播放
// 各位前辈如果修复好了可以发给我一份哈 谢谢
- (void)setupPlayer
{
    // 一定要将animationTool设为NULL，否则会导致奔溃
    self.videoComposition.animationTool = NULL;
    
    // 将 composition 放入 AVPlayerItem 中，可用于视频播放
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.composition];
    item.audioMix = self.audioMix;
    item.videoComposition = self.videoComposition;
    
    if (self.player)
    {
        // 如果播放器已经存在则替换正在播放的资源
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:item];
        
    }
    else
    {
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.playerView.bounds;
        [self.playerView.layer addSublayer:self.playerLayer];
        [self.player play];
   
        // 播放完成后回到最初的位置
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            
            [self.player seekToTime:kCMTimeZero];
            self.playButton.enabled = YES;
        }];
    }
    
    self.playButton.enabled = YES;
}

#pragma mark - 导出视频

- (void)exportVideo
{
    // 创建导出音视频会话
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPresetHighestQuality];
    
    // 判断导出的文件是否已经存在，存在则移除旧文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *videoUrl = [[fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] URLByAppendingPathComponent:@"exportVideo.mp4"];
    if ([fileManager fileExistsAtPath:videoUrl.path])
    {
        [fileManager removeItemAtURL:videoUrl error:nil];
    }
    
    // 为导出视频添加水印记号
    if (self.waterMark)
    {
        CGSize videoSize = self.videoComposition.renderSize;
        CALayer *waterMark = [self getWaterMarkWithSource:self.waterMark videoSize:videoSize playerViewSize:self.playerView.frame.size];
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:waterMark];
        self.videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    
    // 导出视频的格式
    exportSession.outputURL = videoUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.audioMix = self.audioMix;
    exportSession.videoComposition = self.videoComposition;
    
    // 开启子线程异步导出
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *message = nil;
            if (exportSession.status == AVAssetExportSessionStatusCompleted)
            {
                message = @"导出成功";
                
                // 存储视频
                [self saveVideoWithUrl:videoUrl];
            }
            else
            {
                message = @"导出失败";
            }
            [self showAlertWithMessage:message];
        });
    }];
}

// 保存导出视频到相册
- (void)saveVideoWithUrl:(NSURL *)url
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:url];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        if (success)
        {
            NSLog(@"视频保存成功");
        }
        else
        {
            NSLog(@"视频保存失败");
        }
    }];
}

// 为导出视频添加水印
- (CALayer *)getWaterMarkWithSource:(CALayer *)sourceWaterMark videoSize:(CGSize)videoSize playerViewSize:(CGSize)videoViewSize
{
    CGFloat scale = videoSize.width / videoViewSize.width;
    CGRect sourceFrame = sourceWaterMark.frame;
    CGFloat width = sourceFrame.size.width * scale;
    CGFloat height = sourceFrame.size.height * scale;
    CGFloat x = sourceFrame.origin.x * scale;
    CGFloat y = (videoViewSize.height - sourceFrame.size.height - sourceFrame.origin.y) * scale;
    
    CALayer *waterMark = [CALayer layer];
    waterMark.backgroundColor = sourceWaterMark.backgroundColor;
    waterMark.frame = CGRectMake(x, y, width, height);
    return waterMark;
}

#pragma mark - 懒加载

- (AVMutableAudioMix *)audioMix
{
    if (!_audioMix)
    {
        AVMutableCompositionTrack *audioTrack = [[self.composition tracksWithMediaType:AVMediaTypeAudio] firstObject];
        AVMutableAudioMixInputParameters *parameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        _audioMix = [AVMutableAudioMix audioMix];
        _audioMix.inputParameters = @[parameters];
    }
    
    return _audioMix;
}

- (AVMutableVideoComposition *)videoComposition
{
    if (!_videoComposition)
    {
        AVMutableCompositionTrack *videoTrack = [[self.composition tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        // 时间范围信息
        AVMutableVideoCompositionInstruction *compositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        compositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
        compositionInstruction.layerInstructions = @[compositionLayerInstruction];
        
        _videoComposition = [AVMutableVideoComposition videoComposition];
        _videoComposition.instructions = @[compositionInstruction];
        _videoComposition.renderSize = videoTrack.naturalSize;
        _videoComposition.frameDuration = CMTimeMake(1, 30);
    }
    
    return _videoComposition;
}

@end


