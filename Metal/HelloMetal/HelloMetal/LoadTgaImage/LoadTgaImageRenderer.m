//
//  LoadTgaImageRenderer.m
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/11.
//

#import "LoadTgaImageRenderer.h"
#import "Image.h"
#import "ShaderTypes.h"

@implementation LoadTgaImageRenderer
{
    id<MTLDevice> _device;// 用来渲染的设备(又名GPU)
    
    // 渲染管道有顶点着色器和片元着色器，存储在shader.metal文件中
    id<MTLRenderPipelineState> _pipelineState;

    // 从命令缓存区获取命令队列
    id<MTLCommandQueue> _commandQueue;

    // 当前视图大小，在渲染通道时会使用这个视图
    vector_uint2 _viewportSize;
    
    // 顶点个数
    NSInteger _numVertices;
    
    // 存储在Metal buffer的顶点数据
    id<MTLBuffer> _vertices;
    
    // Metal 纹理对象
    id<MTLTexture> _texture;
    
    MTKView *_mtkView;
}

// 初始化方法
- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        // 1.获取GPU设备
        _device = mtkView.device;
        _mtkView = mtkView;
        
        // 2.设置顶点
        [self setupVertex];
        
        // 3.设置渲染管道
        [self setupPipeLine];
        
        // 4.加载纹理TGA文件
        [self setupTexture];
        
    }
    return self;
}

// 设置顶点
- (void)setupVertex
{
    // 1.根据顶点/纹理坐标建立一个MTLBuffer
    static const Vertex quadVertices[] =
    {
        // 像素坐标 纹理坐标
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,  -250 },  { 0.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        { {  250,   250 },  { 1.f, 1.f } },
    };
    
    // 2.创建顶点缓冲区，并用quadVertices数组初始化它
    _vertices = [_device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared];
    
    // 3.通过将字节长度除以每个顶点的大小来计算顶点的数目
    _numVertices = sizeof(quadVertices) / sizeof(Vertex);
}

// 设置渲染管道
- (void)setupPipeLine
{
    // 1.创建我们的渲染通道
    // 从项目中加载.metal文件，创建一个library
    id<MTLLibrary>defalutLibrary = [_device newDefaultLibrary];
    // 从库中加载顶点函数
    id<MTLFunction>vertexFunction = [defalutLibrary newFunctionWithName:@"vertexShader"];
    // 从库中加载片元函数
    id<MTLFunction> fragmentFunction = [defalutLibrary newFunctionWithName:@"fragmentShader"];
    
    // 2.配置用于创建管道状态的管道
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    // 管道名称
    pipelineStateDescriptor.label = @"Texturing Pipeline";
    // 可编程函数，用于处理渲染过程中的各个顶点
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    // 可编程函数，用于处理渲染过程总的各个片段/片元
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    // 设置管道中存储颜色数据的组件格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    
    // 3.同步创建并返回渲染管线对象
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    // 判断是否创建成功
    if (!_pipelineState)
    {
        NSLog(@"创建渲染管线对象失败，错误信息为：%@", error);
    }
    
    // 4.使用_device创建commandQueue
    _commandQueue = [_device newCommandQueue];
}

// 加载纹理TGA文件
- (void)setupTexture
{
    // 1.获取tag的路径
    NSURL *imageFileLocation = [[NSBundle mainBundle]  URLForResource:@"Image"withExtension:@"tga"];
    
    // 2.将tag文件转化为Image对象
    Image *image = [[Image alloc] initWithTGAFileAtLocation:imageFileLocation];
    if(!image)// 判断图片是否转换成功
    {
        NSLog(@"创建图片失败，tga文件路径为: %@",imageFileLocation.absoluteString);
    }
    
    // 3.创建纹理描述对象
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    // 表示每个像素有蓝色、绿色、红色和alpha通道。其中每个通道都是8位无符号归一化的值(即0映射成0，255映射成1)
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    // 设置纹理的像素尺寸
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;
    
    // 4.使用描述符从设备中创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];
    // 计算图像每行的字节数
    NSUInteger bytesPerRow = 4 * image.width;
    
    // 5.创建MTLRegion结构体
    MTLRegion region =
    {
        {0,0,0},// 开始位置 x,y,z
        {image.width,image.height,1}// 尺寸 width,height,depth
    };
    
    // 6.复制图片数据到纹理
    [_texture replaceRegion:region mipmapLevel:0 withBytes:image.data.bytes bytesPerRow:bytesPerRow];
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
    // 1.为当前渲染任务创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"CommandBuffer";// 指定缓存区名称
    
    // 2.一组渲染目标，用作渲染通道生成的像素的输出目标
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    // 判断渲染目标是否为空
    if(renderPassDescriptor != nil)
    {
        // 3.创建渲染命令编码器
        id<MTLRenderCommandEncoder> renderEncoder =[commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"RenderEncoder";// 渲染命令编码器名称

        // 4.设置可绘制区域
        MTLViewport viewPort =
        {
            0.0,0.0,_viewportSize.x,_viewportSize.y,-1.0,1.0
        };
        [renderEncoder setViewport:viewPort];
        
        // 5.设置当前渲染管道状态对象
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        // 6.将_vertexBuffer设置到顶点缓存区中
        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                               atIndex:VertexInputIndexVertices];
        
        // 7.将_viewportSize设置到顶点缓存区绑定点设置数据
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:VertexInputIndexViewportSize];
        
        // 8.设置纹理对象
        [renderEncoder setFragmentTexture:_texture atIndex:TextureIndexBaseColor];
        
        // 9.开始绘图
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];
        
        // 10.编码器生成的命令都已完成
        [renderEncoder endEncoding];
        
        // 11.进行展示
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // 12.在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
}

@end

