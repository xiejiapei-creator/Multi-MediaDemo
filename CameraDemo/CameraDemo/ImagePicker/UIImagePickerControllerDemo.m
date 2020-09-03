//
//  UIImagePickerControllerDemo.m
//  CameraDemo
//
//  Created by 谢佳培 on 2020/9/2.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "UIImagePickerControllerDemo.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface UIImagePickerControllerDemo ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (assign,nonatomic) BOOL isVideo; //是否录制视频，如果为1表示录制视频，0代表拍照
@property (strong,nonatomic) UIImagePickerController *imagePicker;
@property (strong,nonatomic) UIImageView *photo; //照片展示视图
@property (strong,nonatomic) AVPlayer *player; //播放器，用于录制完视频后播放视频

@end

@implementation UIImagePickerControllerDemo

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 通过这里设置当前程序是拍照还是录制视频
    self.isVideo = YES;
    
    // 拍照按钮
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 400, 300, 80)];
    button.backgroundColor = [UIColor blackColor];
    [button setTitle:@"拍照按钮" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(takeClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark - Events

// 点击拍照按钮
- (void)takeClick
{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

#pragma mark - UIImagePickerController代理方法

// 完成
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) //如果是拍照
    {
        NSLog(@"拍照");
        UIImage *image;
        // 如果允许编辑则获得编辑后的照片，否则获取原始照片
        if (self.imagePicker.allowsEditing)
        {
            // 获取编辑后的照片
            image = [info objectForKey:UIImagePickerControllerEditedImage];
        }
        else
        {
            // 获取原始照片
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        // 显示照片
        [self.photo setImage:image];
        // 保存到相簿
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    else if([mediaType isEqualToString:(NSString *)kUTTypeMovie]) //如果是录制视频
    {
        NSLog(@"录制视频");
        // 视频路径
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *urlStr = [url path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlStr))
        {
            // 保存视频到相簿，注意也可以使用ALAssetsLibrary来保存
            UISaveVideoAtPathToSavedPhotosAlbum(urlStr, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);//保存视频到相簿
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"取消");
}

#pragma mark - Getter/Setter

- (UIImagePickerController *)imagePicker
{
    if (!_imagePicker)
    {
        _imagePicker = [[UIImagePickerController alloc] init];
        // 设置image picker的来源，这里设置为摄像头
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        // 设置使用哪个摄像头，这里设置为后置摄像头
        _imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        if (self.isVideo)
        {
            _imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
            _imagePicker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
            // 设置摄像头模式（拍照，录制视频）
            _imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            
        }
        else
        {
            _imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        }
        // 允许编辑
        _imagePicker.allowsEditing = YES;
        // 设置代理，检测操作
        _imagePicker.delegate=self;
    }
    return _imagePicker;
}

@end
