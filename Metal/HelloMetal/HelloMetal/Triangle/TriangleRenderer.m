//
//  TriangleRenderer.m
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/10.
//

#import "TriangleRenderer.h"
#import "ShaderTypes.h"

@implementation TriangleRenderer
{
    id<MTLDevice> _device;// 用来渲染的设备(又名GPU)
    
    // 渲染管道有顶点着色器和片元着色器，存储在shader.metal文件中
    id<MTLRenderPipelineState> _pipelineState;

    // 从命令缓存区获取命令队列
    id<MTLCommandQueue> _commandQueue;

    // 当前视图大小，在渲染通道时会使用这个视图
    vector_uint2 _viewportSize;
}

// 初始化MTKView
- (id)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        NSError *error = NULL;
        
        // 1.获取GPU设备
        _device = mtkView.device;

        // 2.从bundle中获取.metal文件，在项目中加载所有的(.metal)着色器文件
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        // 从库中加载顶点函数
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        // 从库中加载片元函数
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        // 3.配置用于创建管道状态的管道
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        // 管道名称
        pipelineStateDescriptor.label = @"Simple Pipeline";
        // 可编程函数，用于处理渲染过程中的各个顶点
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        // 可编程函数，用于处理渲染过程中各个片段/片元
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        // 一组存储颜色数据的组件
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        // 4.同步创建并返回渲染管线状态对象
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        // 判断是否返回了管线状态对象
        if (!_pipelineState)
        {
            // 如果我们没有正确设置管道描述符，则管道状态创建可能失败
            NSLog(@"管道状态创建失败，错误信息为：%@", error);
            return nil;
        }

        // 5.创建命令队列
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

#pragma mark - MTKViewDelegate

// 每当视图改变方向或调整大小时调用
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

// 每当视图需要渲染帧时调用
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // 1.顶点数据/颜色数据
    static const Vertex triangleVertices[] =
    {
        // 2D顶点，RGBA颜色值
        { {  250,  -250 }, { 1, 0, 0, 1 } },
        { { -250,  -250 }, { 0, 1, 0, 1 } },
        { {    0,   250 }, { 0, 0, 1, 1 } },
    };

    // 2.为当前渲染任务创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"CommandBuffer";// 指定缓存区名称
    
    // 3.一组渲染目标，用作渲染通道生成的像素的输出目标
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    // 判断渲染目标是否为空
    if(renderPassDescriptor != nil)
    {
        // 4.创建渲染命令编码器
        id<MTLRenderCommandEncoder> renderEncoder =[commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"RenderEncoder";// 渲染命令编码器名称

        // 5.设置可绘制区域
        MTLViewport viewPort =
        {
            0.0,0.0,_viewportSize.x,_viewportSize.y,-1.0,1.0
        };
        [renderEncoder setViewport:viewPort];
        
        // 6.设置当前渲染管道状态对象
        [renderEncoder setRenderPipelineState:_pipelineState];
    
        
        // 7.从应用程序OC代码中发送数据给Metal顶点着色器函数
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:VertexInputIndexVertices];

        // 8、视口大小的数据
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:VertexInputIndexViewportSize];
        
        // 9.画出三角形的3个顶点
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];

        // 10.编码器生成的命令都已完成
        [renderEncoder endEncoding];
        
        // 进行展示
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // 11.在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
}

@end




