//
//  ImageFilterViewController.m
//  GPUImage
//
//  Created by 谢佳培 on 2021/1/9.
//

#import "ImageFilterViewController.h"
#import <GPUImage.h>

@interface ImageFilterViewController ()

@property (strong, nonatomic) UIImageView *imageView;

@property (nonatomic,strong) UIImage *luckinCoffeeImage;

// 饱和度滤镜
@property (nonatomic,strong) GPUImageSaturationFilter *disFilter;

@end

@implementation ImageFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 获取图片
    _luckinCoffeeImage = [UIImage imageNamed:@"luckinCoffee.jpg"];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.imageView.image = _luckinCoffeeImage;
    [self.view addSubview:self.imageView];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(250, 100, 150, 50)];
    slider.value = 1;
    [slider addTarget:self action:@selector(saturationChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview: slider];
}

- (void)saturationChange:(UISlider *)sender
{
    // 选择合适的滤镜，这里使用图像的饱和度滤镜
    if (_disFilter == nil)
    {
        _disFilter = [[GPUImageSaturationFilter alloc] init];
    }
    
    // 设置饱和度值，范围为 0.0 - 2.0，默认为1.0
    _disFilter.saturation = 1.0;
    
    // 设置要渲染的区域，这里设置为图片大小
    [_disFilter forceProcessingAtSize:_luckinCoffeeImage.size];
    
    // 使用单个滤镜
    [_disFilter useNextFrameForImageCapture];
    
    // 调整饱和度，用户通过拖动屏幕上的滑条进行控制
    _disFilter.saturation = sender.value;
    
    // 数据源头是一张静态图片
    GPUImagePicture *stillImageSoucer = [[GPUImagePicture alloc] initWithImage:_luckinCoffeeImage];
    
    // 为图片添加一个滤镜
    [stillImageSoucer addTarget:_disFilter];
    
    // 处理图片
    [stillImageSoucer processImage];
    
    // 处理完成后从帧缓存区中获取新图片
    UIImage *newImage = [_disFilter imageFromCurrentFramebuffer];
    
    // 及时更新屏幕上的图片
    _imageView.image = newImage;
}

@end
