//
//  LargeDataRenderer.m
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/10.
//

#import "LargeDataRenderer.h"
#import "ShaderTypes.h"

@implementation LargeDataRenderer
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
    
    // 顶点缓存区
    id<MTLBuffer> _vertexBuffer;
}

// 初始化
- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        // 初始GPU设备
        _device = mtkView.device;
        // 加载Metal文件
        [self loadMetal:mtkView];
    }
    return self;
}

// 加载Metal文件
- (void)loadMetal:(MTKView *)mtkView
{
    // 1.设置绘制纹理的像素格式
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    
    // 2.从项目中加载所有的.metal着色器文件
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
    // 可编程函数，用于处理渲染过程总的各个片段/片元
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    // 设置管道中存储颜色数据的组件格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    
    // 4.同步创建并返回渲染管线对象
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    // 判断是否创建成功
    if (!_pipelineState)
    {
        NSLog(@"创建渲染管线对象失败，错误信息为：%@", error);
    }
    
    // 5.获取顶点数据
    NSData *vertexData = [LargeDataRenderer generateVertexData];
    
    // 6.创建一个顶点缓冲区，可以由GPU来读取
    _vertexBuffer = [_device newBufferWithLength:vertexData.length
                                         options:MTLResourceStorageModeShared];
    
    // 7.复制顶点数据到顶点缓冲区，通过缓存区的内容属性访问指针
    // contents:目的地 bytes:源内容 length:长度
    memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
    
    // 8.计算顶点个数 = 顶点数据长度 / 单个顶点大小
    _numVertices = vertexData.length / sizeof(Vertex);
    
    // 9.创建命令队列
    _commandQueue = [_device newCommandQueue];
}

// 生成顶点数据
+ (NSData *)generateVertexData
{
    // 1.正方形 = 上三角形 + 下三角形
    const Vertex quadVertices[] =
    {
        // Pixel像素位置, RGBA颜色
        { { -20,   20 },    { 1, 0, 0, 1 } },
        { {  20,   20 },    { 1, 0, 0, 1 } },
        { { -20,  -20 },    { 1, 0, 0, 1 } },
        
        { {  20,  -20 },    { 0, 0, 1, 1 } },
        { { -20,  -20 },    { 0, 0, 1, 1 } },
        { {  20,   20 },    { 0, 0, 1, 1 } },
    };
    
    // 2.使用到的常量
    // 行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
    // 顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(Vertex);
    // 四边形间距
    const float QUAD_SPACING = 50.0;
    // 数据大小 = 单个四边形大小 * 行 * 列
    NSUInteger dataSize = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
    // 3.开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataSize];
    // 当前四边形
    Vertex * currentQuad = vertexData.mutableBytes;
    
    
    // 4.获取顶点坐标(循环计算)
    for(NSUInteger row = 0; row < NUM_ROWS; row++)// 行
    {
        for(NSUInteger column = 0; column < NUM_COLUMNS; column++)// 列
        {
            vector_float2 upperLeftPosition;// 左上角的位置
            
            // 5.计算X和Y位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;
            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            // 6.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
            
            // 7.遍历currentQuad中的数据，修改vertexInQuad中的position
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++)
            {
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            
            // 8.更新索引
            currentQuad += 6;
        }
    }
    return vertexData;
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
        [renderEncoder setVertexBuffer:_vertexBuffer
                                offset:0
                               atIndex:VertexInputIndexVertices];
        
        // 7.将_viewportSize设置到顶点缓存区绑定点设置数据
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:VertexInputIndexViewportSize];
        
        // 8.开始绘图
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];
        
        // 9.编码器生成的命令都已完成
        [renderEncoder endEncoding];
        
        // 10.进行展示
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // 11.在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
}

@end




