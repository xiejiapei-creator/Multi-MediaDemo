//
//  ViewController.m
//  分屏滤镜
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "ViewController.h"
#import "FilterBar.h"
#import <GLKit/GLKit.h>

typedef struct
{
    GLKVector3 positionCoord; //顶点坐标(X, Y, Z)
    GLKVector2 textureCoord; //纹理坐标(U, V)
} SenceVertex;

@interface ViewController ()<FilterBarDelegate>

// 坐标
@property (nonatomic, assign) SenceVertex *vertices;
// 上下文
@property (nonatomic, strong) EAGLContext *context;
// 用于刷新屏幕
@property (nonatomic, strong) CADisplayLink *displayLink;
// 开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
// 着色器程序
@property (nonatomic, assign) GLuint program;
// 顶点缓存
@property (nonatomic, assign) GLuint vertexBuffer;
// 纹理 ID
@property (nonatomic, assign) GLuint textureID;

@end

@implementation ViewController

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // 1.创建滤镜工具栏
    [self setupFilterBar];
    
    // 2.滤镜处理初始化
    [self filterInit];
    
    // 3.开始一个滤镜动画
    [self startFilerAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 移除用于刷新屏幕的displayLink
    if (self.displayLink)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)dealloc
{
    // 1.上下文释放
    if ([EAGLContext currentContext] == self.context)
    {
        [EAGLContext setCurrentContext:nil];
    }
    
    // 2.顶点缓存区释放
    if (_vertexBuffer)
    {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    // 3.顶点数组释放
    if (_vertices)
    {
        free(_vertices);
        _vertices = nil;
    }
}

#pragma mark - 创建滤镜工具栏

- (void)setupFilterBar
{
    CGFloat filterBarWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat filterBarHeight = 100;
    CGFloat filterBarY = [UIScreen mainScreen].bounds.size.height - filterBarHeight;
    FilterBar *filerBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, filterBarY, filterBarWidth, filterBarHeight)];
    filerBar.delegate = self;
    [self.view addSubview:filerBar];
    
    NSArray *dataSource = @[@"原图",@"二分屏",@"三分屏",@"四分屏",@"六分屏",@"九分屏"];
    filerBar.itemList = dataSource;
}

// FilterBarDelegate
- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index
{
    // 使用默认的着色器程序
    if (index == 0)
    {
        [self setupNormalShaderProgram];
    }
    else if (index == 1)
    {
        [self setupSplitScreen_2ShaderProgram]; 
    }
    else if (index == 2)
    {
        [self setupSplitScreen_3ShaderProgram];
    }
    else if (index == 3)
    {
        [self setupSplitScreen_4ShaderProgram];
    }
    else if (index == 4)
    {
        [self setupSplitScreen_6ShaderProgram];
    }
    else if (index == 5)
    {
        [self setupSplitScreen_9ShaderProgram];
    }
   
    // 重新开始滤镜动画
    [self startFilerAnimation];
    
    // 按照原图进行渲染
    //[self render];
}

#pragma mark - 滤镜处理初始化

- (void)filterInit
{
    // 1. 初始化上下文并设置为当前上下文
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];
    
    // 2.开辟顶点数组内存空间
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    
    // 3.初始化(0,1,2,3)4个顶点的顶点坐标以及纹理坐标
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    // 4.创建CAEAGLLayer图层
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    // 设置图层frame
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    // 设置图层的scale
    layer.contentsScale = [[UIScreen mainScreen] scale];
    // 给View添加layer
    [self.view.layer addSublayer:layer];
    
    // 5.绑定渲染缓存区
    [self bindRenderLayer:layer];
    
    // 6.获取纹理图片
    // 获取处理的图片路径
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"luckcoffee.jpg"];
    // 读取图片
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    // 将JPG图片转换成纹理图片
    GLuint textureID = [self createTextureWithImage:image];
    // 将纹理ID保存，方便后面切换滤镜的时候重用
    self.textureID = textureID;
    
    // 7.设置视口
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    // 8.开辟顶点缓存区
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    // 9.设置默认着色器
    [self setupNormalShaderProgram];
    
    // 10.将顶点缓存保存，退出时才释放
    self.vertexBuffer = vertexBuffer;
}

// 绑定渲染缓存区和帧缓存区
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer
{
    // 1.渲染缓存区和帧缓存区对象
    GLuint renderBuffer;
    GLuint frameBuffer;
    
    // 2.获取帧渲染缓存区名称，绑定渲染缓存区以及将渲染缓存区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    // 3.获取帧缓存区名称，绑定帧缓存区以及将渲染缓存区附着到帧缓存区上
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              renderBuffer);
}

// 从图片中加载纹理
- (GLuint)createTextureWithImage:(UIImage *)image
{
    // 1.将UIImage转换为CGImageRef
    CGImageRef cgImageRef = [image CGImage];
    // 判断图片是否获取成功
    if (!cgImageRef)
    {
        NSLog(@"加载图片失败");
        exit(1);
    }
    
    // 2.获取图片的大小
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 3.创建上下文
    // 用来获取图片字节数 宽*高*4（RGBA）
    void *imageData = malloc(width * height * 4);
    
    // 用来获取图片的颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // 创建上下文
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // 4.将图片翻转过来(图片默认是倒置的)
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    
    // 5.对图片进行重新绘制，得到一张新的解压缩后的位图
    CGContextDrawImage(context, rect, cgImageRef);
    
    // 6.设置图片纹理属性
    GLuint textureID;
    glGenTextures(1, &textureID);// 获取纹理ID
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    // 7.载入纹理2D数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // 8.设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 9.绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 10.释放context和imageData
    CGContextRelease(context);
    free(imageData);
    
    // 11.返回纹理ID
    return textureID;
}

// 获取渲染缓存区的宽
- (GLint)drawableWidth
{
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}
// 获取渲染缓存区的高
- (GLint)drawableHeight
{
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}



#pragma mark - 滤镜动画

// 开始一个滤镜动画
- (void)startFilerAnimation
{
    // 1.创建之前需要先销毁旧的定时器
    if (self.displayLink)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    // 2.设置定时器调用的方法
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    
    // 3.将定时器添加到runloop运行循环
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

// 不使用动画直接渲染场景
- (void)render
{
    // 清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 使用program
    glUseProgram(self.program);
    // 绑定buffer
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    // 重绘
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    // 渲染到屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

// 实现滤镜动画重新绘制图形
- (void)timeAction
{
    // 1.获取定时器的当前时间戳
    if (self.startTimeInterval == 0)
    {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    
    // 2.使用着色器程序
    glUseProgram(self.program);
    
    // 3.绑定顶点缓冲区
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    // 4.传入时间
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
    // 5.清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 6.重绘后渲染到屏幕上
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - 着色器程序

// 默认着色器程序
- (void)setupNormalShaderProgram
{
    // 设置着色器程序
    [self setupShaderProgramWithName:@"Normal"];
}

// 二分屏着色器
- (void)setupSplitScreen_2ShaderProgram
{
    [self setupShaderProgramWithName:@"SplitScreen_2"];
}

// 三分屏着色器
- (void)setupSplitScreen_3ShaderProgram
{
    [self setupShaderProgramWithName:@"SplitScreen_3"];
}

// 四分屏着色器
- (void)setupSplitScreen_4ShaderProgram
{
    [self setupShaderProgramWithName:@"SplitScreen_4"];
}

// 六分屏着色器
- (void)setupSplitScreen_6ShaderProgram
{
    [self setupShaderProgramWithName:@"SplitScreen_6"];
}

// 九分屏着色器
- (void)setupSplitScreen_9ShaderProgram
{
    [self setupShaderProgramWithName:@"SplitScreen_9"];
}

// 初始化着色器程序
- (void)setupShaderProgramWithName:(NSString *)name
{
    // 1.获取着色器program
    GLuint program = [self programWithShaderName:name];
    
    // 2.使用着色器program
    glUseProgram(program);
    
    // 3.从CPU中获取顶点、纹理、纹理坐标的索引位置
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    // 4.激活纹理，绑定纹理ID
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    // 5.纹理sample
    glUniform1i(textureSlot, 0);
    
    // 6.打开positionSlot属性并且传递数据到positionSlot中(顶点坐标)
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    // 7.打开textureCoordsSlot属性并传递数据到textureCoordsSlot(纹理坐标)
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    // 8.保存program，界面销毁则释放
    self.program = program;
}

// 链接着色器
- (GLuint)programWithShaderName:(NSString *)shaderName
{
    // 1.编译顶点着色器/片元着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    // 2.将顶点/片元附着到program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    // 3.linkProgram
    glLinkProgram(program);
    
    // 4.检查是否link成功
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    
    // 5.返回program
    return program;
}

// 编译着色器
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType
{
    // 1.获取着色器路径
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    // 2.根据shaderType创建着色器
    GLuint shader = glCreateShader(shaderType);
    
    // 3.获取shader source
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4.编译着色器
    glCompileShader(shader);
    
    // 5.查看编译是否成功
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    
    // 6.返回着色器
    return shader;
}

@end



