//
//  ViewController.m
//  Pyramid
//
//  Created by 谢佳培 on 2021/1/11.
//

#import "ViewController.h"
#import "ShaderTypes.h"
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

@interface ViewController ()<MTKViewDelegate>

@property (nonatomic, strong) UISwitch *rotationX;
@property (nonatomic, strong) UISwitch *rotationY;
@property (nonatomic, strong) UISwitch *rotationZ;
@property (nonatomic, strong) UISlider *slider;

@property (nonatomic, strong) MTKView *mtkView;// 渲染视图
@property (nonatomic, assign) vector_uint2 viewportSize;// 视口
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;// 渲染管道
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;// 命令队列
@property (nonatomic, strong) id<MTLTexture> texture;// 纹理
@property (nonatomic, strong) id<MTLBuffer> vertices;// 顶点缓存区
@property (nonatomic, strong) id<MTLBuffer> indexs;// 索引缓存区
@property (nonatomic, assign) NSUInteger indexCount;// 索引个数

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubviews];
    
    // 1.设置MTKView
    [self setupMtkView];
    // 2.设置管道
    [self setupPipeline];
    // 3.设置顶点数据
    [self setupVertex];
    // 4.设置纹理
    [self setupTexture];
}

- (void)setupMtkView
{
    // 1. 获取MTKView
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    
    // 2.获取代表默认的GPU单个对象
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    
    // 3.将mtkView添加到self.view上
    [self.view insertSubview:self.mtkView atIndex:0];
    
    // 4.设置代理 表示由viewController实现代理方法
    self.mtkView.delegate = self;
    
    // 5.获取视口大小
    self.viewportSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
}

- (void)setupPipeline
{
    // 1.在项目中加载所有的着色器文件
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
    // 从库中加载顶点函数
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    // 从库中加载片元函数
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];
    
    // 2.创建渲染管道描述符
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    // 可编程函数，用于处理渲染过程中的各个顶点
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    // 可编程函数，用于处理渲染过程总的各个片段/片元
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    // 设置管道中存储颜色数据的组件格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    
    // 3.设置渲染管道
    self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
    
    // 4.创建命令队列
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

- (void)setupVertex
{
    // 1.金字塔的顶点坐标、顶点颜色、纹理坐标数据
    static const Vertex quadVertices[] =
    {  // 顶点坐标                          顶点颜色                    纹理坐标
        {{-0.5f, 0.5f, 0.0f, 1.0f},      {0.0f, 0.0f, 0.5f},       {0.0f, 1.0f}},//左上
        {{0.5f, 0.5f, 0.0f, 1.0f},       {0.0f, 0.5f, 0.0f},       {1.0f, 1.0f}},//右上
        {{-0.5f, -0.5f, 0.0f, 1.0f},     {0.5f, 0.0f, 1.0f},       {0.0f, 0.0f}},//左下
        {{0.5f, -0.5f, 0.0f, 1.0f},      {0.0f, 0.0f, 0.5f},       {1.0f, 0.0f}},//右下
        {{0.0f, 0.0f, 1.0f, 1.0f},       {1.0f, 1.0f, 1.0f},       {0.5f, 0.5f}},//顶点
    };
    
    // 2.创建顶点数组缓存区
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices
                                                     length:sizeof(quadVertices)
                                            options:MTLResourceStorageModeShared];
   
    // 3.索引数组
    static int indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    // 4.创建索引数组缓存区
    self.indexs = [self.mtkView.device newBufferWithBytes:indices
                                                   length:sizeof(indices)
                                            options:MTLResourceStorageModeShared];
    
    // 5.计算索引个数
    self.indexCount = sizeof(indices) / sizeof(int);
}

// 设置投影矩阵/模型视图矩阵
- (void)setupMatrixWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);// 纵横比
    static float x = 0.0, y = 0.0, z = M_PI;// x=0,y=0,z=180
    
    // 1.投影矩阵
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
    
    // 2.模型视图矩阵
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);

    // 3.判断X/Y/Z的开关状态，修改旋转的角度
    if (self.rotationX.on)
    {
        x += self.slider.value;
    }
    if (self.rotationY.on)
    {
        y += self.slider.value;
    }
    if (self.rotationZ.on)
    {
        z += self.slider.value;
    }
    
    // 4.将模型视图矩阵围绕(x,y,z)轴渲染相应的角度
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, x, 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, y, 0, 1, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, z, 0, 0, 1);
    
    // 5.将GLKit Matrix 转化为 MetalKit Matrix
    matrix_float4x4 pm = [self getMetalMatrixFromGLKMatrix:projectionMatrix];
    matrix_float4x4 mm = [self getMetalMatrixFromGLKMatrix:modelViewMatrix];
    
    // 6.将投影矩阵和模型视图矩阵加载到矩阵结构体
    Matrix matrix = {pm,mm};
    
    // 7.将矩阵结构体里的数据通过渲染编码器传递到顶点/片元函数中使用
    [renderEncoder setVertexBytes:&matrix
                           length:sizeof(matrix)
                          atIndex:VertexInputIndexMatrix];
}

// 将GLKit Matrix 转化为 MetalKit Matrix
- (matrix_float4x4)getMetalMatrixFromGLKMatrix:(GLKMatrix4)matrix
{
    matrix_float4x4 ret = (matrix_float4x4)
    {
        simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
        simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
        simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
        simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
    };
    return ret;
}

- (void)setupTexture
{
    // 1.获取图片
    UIImage *image = [UIImage imageNamed:@"luckcoffee.jpg"];
    
    // 2.创建纹理描述符
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    // 表示每个像素有蓝色、绿色、红色和alpha通道
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    // 设置纹理的像素尺寸
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;
    
    // 3.使用描述符从设备中创建纹理
    _texture = [self.mtkView.device newTextureWithDescriptor:textureDescriptor];
    
    // 4.创建MTLRegion结构体用来设置纹理填充的范围
    MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}};
    
    // 5.获取图片数据
    Byte *imageBytes = [self loadImage:image];
    
    // 6.UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
    if (imageBytes)
    {
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:imageBytes
                    bytesPerRow:4 * image.size.width];
        free(imageBytes);
        imageBytes = NULL;
    }
}

// 从UIImage中读取Byte数据返回
- (Byte *)loadImage:(UIImage *)image
{
    // 1.获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    
    // 2.读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    // 3.计算图片大小.rgba共4个byte
    Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte));
    
    // 4.创建画布
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 5.在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    // 6.图片翻转过来
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    // 7.释放spriteContext
    CGContextRelease(spriteContext);
    
    return spriteData;
}

- (void)createSubviews
{
    UILabel *rotationXLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.f, 750.f, 100, 50)];
    UILabel *rotationYLabel = [[UILabel alloc] initWithFrame:CGRectMake(170.f, 750.f, 100, 50)];
    UILabel *rotationZLabel = [[UILabel alloc] initWithFrame:CGRectMake(290.f, 750.f, 100, 50)];
    rotationXLabel.text = @"绕X轴旋转";
    rotationYLabel.text = @"绕Y轴旋转";
    rotationZLabel.text = @"绕Z轴旋转";
    [self.view addSubview:rotationXLabel];
    [self.view addSubview:rotationYLabel];
    [self.view addSubview:rotationZLabel];
    
    UISwitch *rotationX = [[UISwitch alloc] initWithFrame:CGRectMake(50.f, 820.f, 100, 50.f)];
    [self.view addSubview:rotationX];
    self.rotationX = rotationX;
    
    UISwitch *rotationY = [[UISwitch alloc] initWithFrame:CGRectMake(170.f, 820.f, 100, 50.f)];
    [self.view addSubview:rotationY];
    self.rotationY = rotationY;
    
    UISwitch *rotationZ = [[UISwitch alloc] initWithFrame:CGRectMake(290.f, 820.f, 100, 50.f)];
    [self.view addSubview:rotationZ];
    self.rotationZ = rotationZ;
    
    UILabel *sliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.f, 690.f, 100, 50)];
    sliderLabel.text = @"旋转速率";
    [self.view addSubview:sliderLabel];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(190.f, 690.f, 200, 50.f)];
    [self.view addSubview:slider];
    self.slider = slider;
}

#pragma mark - MTKViewDelegate

// 每当视图改变方向或调整大小时调用
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{    
    // 保存可绘制的大小。当我们绘制时将把这些值传递给顶点着色器
    self.viewportSize = (vector_uint2){size.width, size.height};
}

// 每当视图需要渲染帧时调用
- (void)drawInMTKView:(MTKView *)view
{
    // 1.为当前渲染的每个渲染传递创建一个新的命令缓存区
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // 2.获取视图的渲染描述符
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    // 判断是否获取成功
    if(renderPassDescriptor != nil)
    {
        // 3.通过渲染描述符修改背景颜色
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.6, 0.2, 0.5, 1.0f);

        // 4.设置颜色附着点加载方式为写入指定附件中的每个像素
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        // 5.根据渲染描述信息创建渲染编码器
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        // 6.设置视口
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0 }];
        
        // 7.设置渲染管道
        [renderEncoder setRenderPipelineState:self.pipelineState];
        
        // 8.设置投影矩阵/渲染矩阵
        [self setupMatrixWithEncoder:renderEncoder];
        
        // 9.将顶点数据传递到Metal文件的顶点函数
        [renderEncoder setVertexBuffer:self.vertices
                                offset:0
                               atIndex:VertexInputIndexVertices];
        // 10.设置正背面剔除
        // 设置逆时钟三角形为正面，其为默认值所以可省略此步骤
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        // 设置为背面剔除
        [renderEncoder setCullMode:MTLCullModeBack];
        
        // （补）给片元着色器传递纹理
        [renderEncoder setFragmentTexture:self.texture atIndex:FragmentInputIndexTexture];
        
        // 11.开始绘制(索引绘图)
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                  indexCount:self.indexCount
                                   indexType:MTLIndexTypeUInt32
                                 indexBuffer:self.indexs
                           indexBufferOffset:0];
        
        // 结束编码
        [renderEncoder endEncoding];
        
        // 展示视图
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // 完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
}

@end


