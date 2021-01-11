//
//  Renderer.m
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/10.
//

#import "Renderer.h"

// 颜色结构体
typedef struct
{
    float red, green, blue, alpha;
} Color;

@implementation Renderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;// 命令队列
}

// 初始化方法
- (id)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
    }
    
    return self;
}

// 设置颜色
- (Color)makeFancyColor
{
    // 1.创建颜色变量
    // 用来判断是增加颜色还是减小颜色的变量
    static BOOL growing = YES;
    // 颜色通道值(0~3)，不需要每次修改红绿蓝3个通道，只需要修改1个
    static NSUInteger primaryChannel = 0;
    // 颜色通道数组 (颜色值)
    static float colorChannels[] = {1.0, 0.0, 0.0, 1.0};
    // 颜色调整步长
    const float DynamicColorRate = 0.015;
    
    if(growing)// 2.增加颜色
    {
        // 动态颜色通道的索引 (1,2,3,0) ，用来实现通道间切换
        NSUInteger dynamicChannelIndex = (primaryChannel+1)%3;
        
        // 修改对应通道的颜色值，每次只调整0.015
        colorChannels[dynamicChannelIndex] += DynamicColorRate;
        
        // 当颜色通道对应的颜色值 = 1.0
        if(colorChannels[dynamicChannelIndex] >= 1.0)
        {
            // 设置为NO
            growing = NO;
            
            // 将颜色通道修改为新的动态颜色通道的索引
            primaryChannel = dynamicChannelIndex;
        }
    }
    else// 3.减少颜色
    {
        // 获取动态颜色通道的索引
        NSUInteger dynamicChannelIndex = (primaryChannel+2)%3;
        
        // 将当前颜色的值减去0.015
        colorChannels[dynamicChannelIndex] -= DynamicColorRate;
        
        // 当颜色值小于等于0.0
        if(colorChannels[dynamicChannelIndex] <= 0.0)
        {
            // 又调整为颜色增加
            growing = YES;
        }
    }
    
    // 4.修改颜色的RGBA的值
    Color color;
    color.red   = colorChannels[0];
    color.green = colorChannels[1];
    color.blue  = colorChannels[2];
    color.alpha = colorChannels[3];
    
    // 返回颜色
    return color;
}

#pragma mark - MTKViewDelegate

// 当MTKView视图发生大小改变时调用
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    NSLog(@"当MTKView视图发生大小改变时调用");
}

// 每当视图需要渲染时调用
- (void)drawInMTKView:(nonnull MTKView *)view
{
    NSLog(@"每当视图需要渲染时调用");
    
    // 1.获取到颜色值来设置view的clearColor
    Color color = [self makeFancyColor];
    view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
    
    // 2.为每一帧创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"命令缓冲区";
    
    // 3.从视图绘制中获得渲染描述符
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    // 4.判断渲染描述符是否创建成功，未成功则跳过任何渲染
    if(renderPassDescriptor != nil)
    {
        // 5.通过渲染描述符创建渲染编码器对象
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"渲染编码器";
        
        // 6.结束渲染编码器的工作
        [renderEncoder endEncoding];
    
        // 7.添加一个展示命令来显示绘制的屏幕
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // 8.在这里完成渲染并将命令缓冲区提交给GPU
    [commandBuffer commit];
}



@end


