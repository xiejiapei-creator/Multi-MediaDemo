//
//  View.m
//  GLSL纹理图片加载
//
//  Created by 谢佳培 on 2021/1/6.
//

#import "View.h"
#import <OpenGLES/ES2/gl.h>

@interface View()

// 绘制OpenGL ES内容的图层，继承自CALayer
@property(nonatomic,strong) CAEAGLLayer *eagLayer;
@property(nonatomic,strong) EAGLContext *context;

@property(nonatomic,assign) GLuint colorRenderBuffer;
@property(nonatomic,assign) GLuint colorFrameBuffer;

@property(nonatomic,assign) GLuint programe;

@end

@implementation View

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 1.设置图层
    [self setupLayer];
    
    // 2.设置图形上下文
    [self setupContext];
    
    // 3.清空缓存区
    [self deleteRenderAndFrameBuffer];

    // 4.设置RenderBuffer
    [self setupRenderBuffer];
    
    // 5.设置FrameBuffer
    [self setupFrameBuffer];
    
    // 6.开始绘制
    [self renderLayer];
}

// 设置图层
- (void)setupLayer
{
    // 1.创建特殊图层
    self.eagLayer = (CAEAGLLayer *)self.layer;
    
    // 2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];


    //3.设置描述属性
    self.eagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
}

// 设置上下文
- (void)setupContext
{
    // 1.指定OpenGL ES 渲染API版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
    
    // 2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    
    // 3.判断是否创建成功
    if (!context)
    {
        NSLog(@"创建图形上下文失败!");
        return;
    }
    
    // 4.设置当前图形上下文
    if (![EAGLContext setCurrentContext:context])
    {
        NSLog(@"设置当前图形上下文失败!");
        return;
    }
    
    // 5.将局部context变成全局的
    self.context = context;
}

// 使用之前清空渲染和帧缓存区
- (void)deleteRenderAndFrameBuffer
{
    glDeleteBuffers(1, &_colorRenderBuffer);// 根据ID清空缓存区
    self.colorRenderBuffer = 0;// ID重置
    
    // frame buffer 相当于render buffer的管理者
    glDeleteBuffers(1, &_colorFrameBuffer);
    self.colorFrameBuffer = 0;
}

// 设置渲染缓冲区
- (void)setupRenderBuffer
{
    // 1.定义一个缓存区ID
    GLuint buffer;
    
    // 2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    self.colorRenderBuffer = buffer;
    
    // 3.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderBuffer);
    
    // 4.将可绘制对象的CAEAGLLayer的存储绑定到renderBuffer对象
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
}

// 设置帧缓冲区
- (void)setupFrameBuffer
{
    // 1.定义一个缓存区ID
    GLuint buffer;
    
    // 2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    self.colorFrameBuffer = buffer;
    
    // 3.将标识符绑定到GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, self.colorFrameBuffer);

    // 4.将渲染缓存区colorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderBuffer);
}

// 开始绘制
- (void)renderLayer
{
    // 设置清屏颜色并清除屏幕
    glClearColor(0.3f, 0.45f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 设置视口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    // 1.读取顶点着色程序、片元着色程序
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    NSLog(@"vertFile:%@",vertFile);
    NSLog(@"fragFile:%@",fragFile);
    
    // 2.加载shader
    self.programe = [self loadShaders:vertFile Withfrag:fragFile];
    
    // 3.链接程序并获取链接状态
    glLinkProgram(self.programe);
    GLint linkStatus;
    // 判断是否链接成功
    glGetProgramiv(self.programe, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE)
    {
        // 打印链接失败的原因
        GLchar message[512];
        glGetProgramInfoLog(self.programe, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"程序链接错误原因: %@",messageString);
        return;
    }
    NSLog(@"程序链接成功!");
    // 使用链接后的程序
    glUseProgram(self.programe);
    
    // 4.设置顶点、纹理坐标
    // 前3个是顶点坐标，后2个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    // 5.处理顶点数据
    // 顶点缓存区
    GLuint attrBuffer;
    // 申请一个缓存区标识符
    glGenBuffers(1, &attrBuffer);
    // 将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    // 把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);

    // 6.将顶点数据通过programe中的传递到顶点着色程序的position
    // 用来获取vertex attribute的入口
    GLuint position = glGetAttribLocation(self.programe, "position");
    // 设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
    // 设置读取方式，将数据传递过去
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    // 7.处理纹理数据
    GLuint textCoor = glGetAttribLocation(self.programe, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL + 3);
    
    // 8.加载纹理 .JPG
    [self setupTexture:@"luckcoffee"];
    
    // 9.设置纹理采样器
    glUniform1i(glGetUniformLocation(self.programe, "colorMap"), 0);// 获取第1个纹理（写的0）
    
    // 10.数组绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 11.从渲染缓存区显示到屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - 辅助方法

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

// 加载shader
- (GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag
{
    // 定义2个临时着色器对象
    GLuint verShader, fragShader;
    
    // 1.创建program
    GLint program = glCreateProgram();
    
    // 2.编译顶点着色程序、片元着色器程序
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    // 3.将着色器与程序附着，创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    // 4.删除着色器，释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

// 编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    // 1.读取文件路径字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    // 2.根据type类型创建一个shader
    *shader = glCreateShader(type);
    
    // 3.将着色器源码附加到着色器对象上

    glShaderSource(*shader, 1, &source,NULL);
    
    //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

// 从图片中加载纹理
- (GLuint)setupTexture:(NSString *)fileName
{
    // 1、将 UIImage 转换为 CGImageRef 进行解压图片
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    // 判断图片是否获取成功
    if (!spriteImage)
    {
        NSLog(@"加载图片失败：%@", fileName);
        exit(1);
    }
    
    // 2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    // 获取图片字节数 宽*高*4（RGBA）
    GLubyte *spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    
    // 3.创建上下文
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 4、在CGContextRef上使用默认方式将图片绘制出来
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    CGContextRelease(spriteContext);// 画图完毕就释放上下文
    
    // 5、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);// 默认1个纹理（写0）
    
    // 6.设置纹理属性
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 7.载入纹理2D数据
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    // 8.释放spriteData
    free(spriteData);
    
    return 0;
}

@end

