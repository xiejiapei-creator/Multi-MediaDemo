//
//  ViewController.m
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/10.
//

#import "ViewController.h"
#import "Renderer.h"
#import "TriangleRenderer.h"
#import "LargeDataRenderer.h"
#import "LoadTgaImageRenderer.h"
#import "LoadPngImageRenderer.h"
#import <MetalKit/MetalKit.h>

@interface ViewController ()

@property (nonatomic, strong) MTKView *mtkView;// 视图
//@property (nonatomic, strong) Renderer *renderer;// 渲染器
//@property (nonatomic, strong) TriangleRenderer *renderer;// 三角形渲染器
//@property (nonatomic, strong) LargeDataRenderer *renderer;// 顶点数据达到上限渲染器
@property (nonatomic, strong) LoadTgaImageRenderer *renderer;// 加载TGA文件渲染器
//@property (nonatomic, strong) LoadPngImageRenderer *renderer;// 加载PNG文件渲染器

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1.获取mtkView
    self.mtkView = (MTKView *)self.view;
    
    // 2.为mtkView设置MTLDevice
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    
    // 3.判断是否设置成功
    if (!self.mtkView.device)
    {
        NSLog(@"Metal不支持这个设备");
        return;
    }
    
    // 4. 创建渲染器
    self.renderer = [[LoadTgaImageRenderer alloc] initWithMetalKitView:self.mtkView];
    
    // 5.判断renderer是否创建成功
    if (!self.renderer)
    {
        NSLog(@"Renderer初始化失败");
        return;
    }
    
    // 6.设置MTKView的代理(由renderer来实现MTKView的代理方法)
    self.mtkView.delegate = self.renderer;
    
    // 7.为视图设置帧速率，默认每秒60帧
    self.mtkView.preferredFramesPerSecond = 60;
    
    // 8.告知 mtkView 的大小（可省略这步）
    [self.renderer mtkView:self.mtkView drawableSizeWillChange:self.mtkView.drawableSize];
}


@end

