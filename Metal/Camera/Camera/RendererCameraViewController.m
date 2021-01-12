//
//  RendererCameraViewController.m
//  Camera
//
//  Created by 谢佳培 on 2021/1/12.
//

#import "RendererCameraViewController.h"
#import "ShaderTypes.h"
#import "AssetReader.h"
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

@interface RendererCameraViewController ()<MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
// 用来读取mov或者mp4文件中的视频数据
@property (nonatomic, strong) AssetReader *reader;
// 由CoreVideo框架提供的高速纹理读取缓存区，用来迅速读取纹理到GPU
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) vector_uint2 viewportSize;// 视口大小
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;// 渲染管道
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;// 命令队列
@property (nonatomic, strong) id<MTLTexture> texture;// 纹理
@property (nonatomic, strong) id<MTLBuffer> vertices;// 顶点缓存区
@property (nonatomic, strong) id<MTLBuffer> convertMatrix;// YUV->RGB 转换矩阵
@property (nonatomic, assign) NSUInteger numVertices;// 顶点个数

@end

@implementation RendererCameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 1.设置MTKView
    [self setupMTKView];
    // 2.设置AssetReader
    [self setupAsset];
    // 3.设置渲染管道
    [self setupPipeline];
    // 4.设置顶点数据
    [self setupVertex];
    // 5.设置转换矩阵
    [self setupMatrix];
}

- (void)setupMTKView
{
    // 初始化mtkView
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    // 获取默认的device
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    // 设置代理
    self.mtkView.delegate = self;
    // 获取视口大小
    self.viewportSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
    
    self.view = self.mtkView;
}

- (void)setupAsset
{
    // 视频文件路径
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"girl" withExtension:@"mp4"];
    
    // 初始化AssetReader
    self.reader = [[AssetReader alloc] initWithUrl:url];
    
    // 通过CoreVideo提供给CPU/GPU高速缓存通道读取纹理数据
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

- (void)setupPipeline
{
   // 1.获取metal文件
   id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
   // 顶点shader，vertexShader是函数名
   id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
   // 片元shader，samplingShader是函数名
   id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];
   
   // 2.渲染管道描述信息类
   MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
   // 设置vertexFunction
   pipelineStateDescriptor.vertexFunction = vertexFunction;
   // 设置fragmentFunction
   pipelineStateDescriptor.fragmentFunction = fragmentFunction;
   // 设置颜色格式
   pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
   
   // 3.根据渲染管道描述信息初始化渲染管道
   self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
   
   // 4.初始化渲染指令队列，保证渲染指令有序地提交到GPU
   self.commandQueue = [self.mtkView.device newCommandQueue];
}

- (void)setupVertex
{
    // 1.创建顶点坐标(x,y,z,w) 纹理坐标(x,y)
    static const Vertex quadVertices[] =
    {   // 顶点坐标分别是x、y、z、w  纹理坐标为x、y
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    // 2.创建顶点缓存区
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices
                                                     length:sizeof(quadVertices)
                                                    options:MTLResourceStorageModeShared];
    // 3.计算顶点个数
    self.numVertices = sizeof(quadVertices) / sizeof(Vertex);
}

- (void)setupMatrix
{
    // 1.转化矩阵
    // SDTV
    matrix_float3x3 kColorConversion601DefaultMatrix = (matrix_float3x3)
    {
        (simd_float3){1.164,  1.164, 1.164},
        (simd_float3){0.0, -0.392, 2.017},
        (simd_float3){1.596, -0.813,   0.0},
    };
    
    // full range
    matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3)
    {
        (simd_float3){1.0,    1.0,    1.0},
        (simd_float3){0.0,    -0.343, 1.765},
        (simd_float3){1.4,    -0.711, 0.0},
    };
   
    // HDTV
    matrix_float3x3 kColorConversion709DefaultMatrix[] =
    {
        (simd_float3){1.164,  1.164, 1.164},
        (simd_float3){0.0, -0.213, 2.112},
        (simd_float3){1.793, -0.533,   0.0},
    };
    
    // 2.设置偏移量
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5};
    
    // 3.创建转化矩阵结构体
    ConvertMatrix matrix;
    matrix.matrix = kColorConversion601FullRangeMatrix;// 设置转化矩阵
    matrix.offset = kColorConversion601FullRangeOffset;// 设置offset偏移量
    
    // 4.创建转换矩阵缓存区
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix
                                                        length:sizeof(ConvertMatrix)
                                                options:MTLResourceStorageModeShared];
}

// 设置纹理
- (void)setupTextureWithEncoder:(id<MTLRenderCommandEncoder>)encoder buffer:(CMSampleBufferRef)sampleBuffer
{    
    // 从CMSampleBuffer读取CVPixelBuffer
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 临时纹理，由于这个方法会多次调用，所以在每次创建新纹理之前需要清空之前的旧纹理
    id<MTLTexture> textureY = nil;
    id<MTLTexture> textureUV = nil;
   
    // 设置Y纹理
    {
        // 1.获取纹理的宽高
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
        
        // 2.设置像素格式为普通格式，即一个8位规范化的无符号整数组件
        MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;
        
        // 3.创建CoreVideo的Metal纹理
        CVMetalTextureRef texture = NULL;
        
        // 4.根据视频像素缓存区创建Metal纹理缓存区
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
        
        // 5.判断Metal纹理缓存区是否创建成功
        if(status == kCVReturnSuccess)
        {
            // 转成Metal用的纹理
            textureY = CVMetalTextureGetTexture(texture);
           
            // 使用完毕释放
            CFRelease(texture);
        }
    }
    
    // 6.同理设置纹理UV
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
        MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm;
        CVMetalTextureRef texture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
        if(status == kCVReturnSuccess)
        {
            textureUV = CVMetalTextureGetTexture(texture);
            CFRelease(texture);
        }
    }
    
    // 7.判断textureY和textureUV是否读取成功
    if(textureY != nil && textureUV != nil)
    {
        // 向片元函数设置textureY纹理
        [encoder setFragmentTexture:textureY atIndex:FragmentTextureIndexTextureY];
        // 向片元函数设置textureUV纹理
        [encoder setFragmentTexture:textureUV atIndex:FragmentTextureIndexTextureUV];
    }
    
    // 8.使用完毕则将sampleBuffer释放
    CFRelease(sampleBuffer);
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // 当MTKView size改变则修改self.viewportSize
    self.viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(MTKView *)view
{
    // 1.每次渲染都要单独创建一个命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // 2.获取渲染描述信息
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
   
    // 3.从AssetReader中读取图像数据
    CMSampleBufferRef sampleBuffer = [self.reader readBuffer];
    
    // 4.判断renderPassDescriptor和sampleBuffer是否已经获取到了
    if(renderPassDescriptor && sampleBuffer)
    {
        // 5.设置渲染描述信息中的颜色附着(默认背景色)
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f);
        
        // 6.根据渲染描述信息创建渲染命令编码器
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        // 7.设置视口大小(显示区域)
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0 }];
        
        // 8.为渲染编码器设置渲染管道
        [renderEncoder setRenderPipelineState:self.pipelineState];
        
        // 9.设置顶点缓存区
        [renderEncoder setVertexBuffer:self.vertices
                                offset:0
                               atIndex:VertexInputIndexVertices];
        
        // 10.设置纹理(将sampleBuffer数据设置到renderEncoder中)
        [self setupTextureWithEncoder:renderEncoder buffer:sampleBuffer];
        
        // 11.设置片元函数转化矩阵
        [renderEncoder setFragmentBuffer:self.convertMatrix
                                  offset:0
                                 atIndex:FragmentInputIndexMatrix];
        
        // 12.开始绘制
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:self.numVertices];

        //13.显示并结束编码
        [commandBuffer presentDrawable:view.currentDrawable];
        [renderEncoder endEncoding];
    }
    
    // 14.提交命令
    [commandBuffer commit];
    
}

@end






