//
//  ViewController.m
//  CubeImage
//
//  Created by 谢佳培 on 2021/1/5.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord;   //顶点坐标
    GLKVector2 textureCoord;    //纹理坐标
    GLKVector3 normal;          //法线
} Vertex;

// 顶点数：正方体有6个面，每个面有两个三角形共6个顶点，包括重复顶点共36个
static NSInteger const kCoordCount = 36;

@interface ViewController () <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;// 效果
@property (nonatomic, assign) Vertex *vertices;// 顶点

@property (nonatomic, strong) CADisplayLink *displayLink;// 每隔多长时间渲染一次
@property (nonatomic, assign) NSInteger angle;// 旋转的角度
@property (nonatomic, assign) GLuint vertexBuffer;// 从内存拷贝到显存空间

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
   
    // 1.OpenGL ES 相关初始化
    [self commonInit];
    
    // 2.顶点/纹理坐标数据
    [self vertexDataSetup];
    
    // 3.添加CADisplayLink
    [self addCADisplayLink];
}

// OpenGL ES 相关初始化
- (void)commonInit
{
    // 1.创建context后设置为当前context
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:context];
    
    // 2.创建GLKView并设置代理
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc] initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    // 3.使用深度缓存
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    // 深度缓存区默认深度值计算后取值范围是(0, 1)，由于正方体围绕Z轴旋转，往屏幕外旋转的话需要将0和1反过来
    glDepthRangef(1, 0);
    
    // 4.将GLKView添加到self.view上
    [self.view addSubview:self.glkView];

    // 5.获取纹理图片
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"读书.JPG"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    // 6.设置纹理参数
    // 纹理坐标原点是左下角，但是图片显示原点应该是左上角，所以需要图片翻转
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
  
    // 7.使用baseEffect进行纹理的设置
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}

// 顶点/纹理坐标数据
- (void)vertexDataSetup
{
    // 1.开辟顶点数据空间(数据结构SenceVertex 大小 * 顶点个数kCoordCount)
    self.vertices = malloc(sizeof(Vertex) * kCoordCount);
    
    // 2.以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
    // 前面
    self.vertices[0] = (Vertex){{-0.5, 0.5, 0.5},  {0, 1}};
    self.vertices[1] = (Vertex){{-0.5, -0.5, 0.5}, {0, 0}};
    self.vertices[2] = (Vertex){{0.5, 0.5, 0.5},   {1, 1}};
    
    self.vertices[3] = (Vertex){{-0.5, -0.5, 0.5}, {0, 0}};
    self.vertices[4] = (Vertex){{0.5, 0.5, 0.5},   {1, 1}};
    self.vertices[5] = (Vertex){{0.5, -0.5, 0.5},  {1, 0}};
    
    // 上面
    self.vertices[6] = (Vertex){{0.5, 0.5, 0.5},    {1, 1}};
    self.vertices[7] = (Vertex){{-0.5, 0.5, 0.5},   {0, 1}};
    self.vertices[8] = (Vertex){{0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[9] = (Vertex){{-0.5, 0.5, 0.5},   {0, 1}};
    self.vertices[10] = (Vertex){{0.5, 0.5, -0.5},  {1, 0}};
    self.vertices[11] = (Vertex){{-0.5, 0.5, -0.5}, {0, 0}};
    
    // 下面
    self.vertices[12] = (Vertex){{0.5, -0.5, 0.5},    {1, 1}};
    self.vertices[13] = (Vertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[14] = (Vertex){{0.5, -0.5, -0.5},   {1, 0}};
    self.vertices[15] = (Vertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[16] = (Vertex){{0.5, -0.5, -0.5},   {1, 0}};
    self.vertices[17] = (Vertex){{-0.5, -0.5, -0.5},  {0, 0}};
    
    // 左面
    self.vertices[18] = (Vertex){{-0.5, 0.5, 0.5},    {1, 1}};
    self.vertices[19] = (Vertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[20] = (Vertex){{-0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[21] = (Vertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[22] = (Vertex){{-0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[23] = (Vertex){{-0.5, -0.5, -0.5},  {0, 0}};
    
    // 右面
    self.vertices[24] = (Vertex){{0.5, 0.5, 0.5},    {1, 1}};
    self.vertices[25] = (Vertex){{0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[26] = (Vertex){{0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[27] = (Vertex){{0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[28] = (Vertex){{0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[29] = (Vertex){{0.5, -0.5, -0.5},  {0, 0}};
    
    // 后面
    self.vertices[30] = (Vertex){{-0.5, 0.5, -0.5},   {0, 1}};
    self.vertices[31] = (Vertex){{-0.5, -0.5, -0.5},  {0, 0}};
    self.vertices[32] = (Vertex){{0.5, 0.5, -0.5},    {1, 1}};
    self.vertices[33] = (Vertex){{-0.5, -0.5, -0.5},  {0, 0}};
    self.vertices[34] = (Vertex){{0.5, 0.5, -0.5},    {1, 1}};
    self.vertices[35] = (Vertex){{0.5, -0.5, -0.5},   {1, 0}};
    
    // 3.开辟缓存区将顶点数据存储到显存
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(Vertex) * kCoordCount;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    // 4.允许顶点着色器读取GPU（服务器端）数据
    // 顶点数据。
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, positionCoord));
    
    // 纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, textureCoord));
}

#pragma mark - GLKViewDelegate

// 进行绘制
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // 1.开启深度测试
    glEnable(GL_DEPTH_TEST);
    // 2.清除颜色缓存区&深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // 3.准备绘制
    [self.baseEffect prepareToDraw];
    
    // 4.绘图
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);
}

#pragma mark - 旋转时需要不断重新绘制

// CADisplayLink类似定时器，提供一个周期性调用的方法，属于QuartzCore.framework中
- (void)addCADisplayLink
{
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

// 重新绘制
- (void)update
{
    // 1.计算旋转度数。每次加5度
    self.angle = (self.angle + 5) % 360;
    
    // 2.旋转、平移、缩放都属于模型视图矩阵的变化（不是投影矩阵）
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1, -0.7);
    
    // 3.重新渲染
    [self.glkView display];
}

#pragma mark - 清空

- (void)dealloc
{
    // 重置当前上下文
    if ([EAGLContext currentContext] == self.glkView.context)
    {
        [EAGLContext setCurrentContext:nil];
    }
    
    // 释放顶点数据
    if (_vertices)
    {
        free(_vertices);
        _vertices = nil;
    }
    
    // 释放_vertexBuffer这个ID对应的缓存区
    if (_vertexBuffer)
    {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    // displayLink 失效
    [self.displayLink invalidate];
}

@end
