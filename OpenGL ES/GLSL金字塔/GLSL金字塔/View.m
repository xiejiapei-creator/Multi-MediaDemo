//
//  View.m
//  GLSL金字塔
//
//  Created by 谢佳培 on 2021/1/6.
//

#import "View.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface View()

@property(nonatomic,strong)CAEAGLLayer *eagLayer;
@property(nonatomic,strong)EAGLContext *context;

@property(nonatomic,assign)GLuint colorRenderBuffer;
@property(nonatomic,assign)GLuint colorFrameBuffer;

@property(nonatomic,assign)GLuint program;
@property (nonatomic , assign) GLuint  vertices;

@end

@implementation View
{
    float xDegree;
    float yDegree;
    float zDegree;
}

-(void)layoutSubviews
{
    // 1.设置图层
    [self setupLayer];
    
    // 2.设置上下文
    [self setupContext];
    
    // 3.清空缓存区
    [self deletBuffer];
    
    // 4.设置renderBuffer;
    [self setupRenderBuffer];
    
    // 5.设置frameBuffer
    [self setupFrameBuffer];
    
    // 6.绘制
    [self render];
}

// 1.设置图层
- (void)setupLayer
{
    self.eagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.eagLayer.opaque = YES;
    self.eagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

// 2.设置上下文
- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    
    if (!context)
    {
        NSLog(@"Create Context Failed");
        return;
    }
    
    if (![EAGLContext setCurrentContext:context])
    {
        NSLog(@"Set Current Context Failed");
        return;
    }
    
    self.context = context;
}

// 3.清空缓存区
- (void)deletBuffer
{
    glDeleteBuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_colorFrameBuffer);
    _colorFrameBuffer = 0;
}

// 4.设置renderBuffer
- (void)setupRenderBuffer
{
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.colorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
}

// 5.设置frameBuffer
- (void)setupFrameBuffer
{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.colorFrameBuffer = buffer;
    glBindFramebuffer(GL_FRAMEBUFFER, self.colorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderBuffer);
}

// 6.绘制
- (void)render
{
    // 清屏颜色
    glClearColor(0, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 设置视口
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    // 1.获取顶点着色程序、片元着色器程序文件位置
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    // 2.判断self.program是否存在，存在则清空其文件
    if (self.program)
    {
        glDeleteProgram(self.program);
        self.program = 0;
    }
    
    // 3.加载程序到program中来
    self.program = [self loadShader:vertFile frag:fragFile];
    
    // 4.链接程序
    glLinkProgram(self.program);
    
    // 5.获取链接状态
    GLint linkSuccess;
    glGetProgramiv(self.program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(self.program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        
        return ;
    }
    else
    {
        glUseProgram(self.program);
    }
    
    // 6.创建顶点数组 & 索引数组
    // 顶点数组：前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上0
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上1
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下2
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下3
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点4
    };
    
    // 索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    // 判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.vertices == 0)
    {
        glGenBuffers(1, &_vertices);
    }
    
    // 7.处理顶点数据
    // 将_vertices绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _vertices);
    // 把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    // 将顶点数据通过programe中的传递到顶点着色程序的position
    GLuint position = glGetAttribLocation(self.program, "position");
    // 打开position
    glEnableVertexAttribArray(position);
    // 设置读取方式
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    
    // 8.处理顶点颜色值
    // 用来获取vertex attribute的入口的
    GLuint positionColor = glGetAttribLocation(self.program, "positionColor");
    // 设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    // 设置读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);

    // 9.找到program中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象
    GLuint projectionMatrixSlot = glGetUniformLocation(self.program, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.program, "modelViewMatrix");

    // 10.创建4 * 4投影矩阵
    KSMatrix4 _projectionMatrix;
    // 获取单元矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    // 计算纵横比例 = 长/宽
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height; //长宽比
    // 获取透视矩阵
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
    // 将投影矩阵传递到顶点着色器
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);

    // 11.创建一个4 * 4 矩阵，模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    // 获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    // 平移，z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    
    // 12.创建一个4 * 4 矩阵，旋转矩阵
    KSMatrix4 _rotationMatrix;
    // 初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
    // 旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0); //绕Z轴
    
    // 13.把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
     ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    // 14.将模型视图矩阵传递到顶点着色器
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    // 15.开启剔除操作效果
    glEnable(GL_CULL_FACE);
    
    // 16.使用索引绘图
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    // 17.要求本地窗口系统显示OpenGL ES渲染目标
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - 辅助方法

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

// 加载shader
- (GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    GLuint verShader,fragShader;
    GLuint program = glCreateProgram();

    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    glDeleteProgram(verShader);
    glDeleteProgram(fragShader);
    
    return program;
}

// 链接shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

- (void)reDegree
{
    // 如果停止X轴旋转，X = 0则度数就停留在暂停前的度数
    // 更新度数
    xDegree += _bX * 5;
    yDegree += _bY * 5;
    zDegree += _bZ * 5;
    // 重新渲染
    [self render];
}

@end
