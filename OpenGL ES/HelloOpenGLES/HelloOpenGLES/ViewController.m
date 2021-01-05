//
//  ViewController.m
//  HelloOpenGLES
//
//  Created by 谢佳培 on 2021/1/5.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@implementation ViewController
{
    EAGLContext *context;
    GLKBaseEffect *effect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 1.OpenGL ES相关初始化
    [self setUpConfig];
    
    // 2.加载顶点/纹理坐标数据
    [self setUpVertexData];
    
    // 3.加载纹理数据(使用GLBaseEffect)
    [self setUpTexture];
}

// OpenGL ES相关初始化
- (void)setUpConfig
{
    // 1.初始化上下文
    // EAGLContext是苹果iOS平台下实现OpenGLES渲染层
    context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    // 判断context是否创建成功
    if (!context)
    {
        NSLog(@"Create ES context Failed");
    }
    
    // 设置当前上下文
    [EAGLContext setCurrentContext:context];
    
    // 2.获取GLKView
    GLKView *view =(GLKView *) self.view;
    view.context = context;
    
    // 3.配置视图创建的渲染缓存区
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;// 颜色缓存区格式
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;// 深度缓存区格式
    
    // 4.设置背景颜色
    glClearColor(0, 0, 0, 1.0);
}

// 加载顶点/纹理坐标数据
- (void)setUpVertexData
{
    // 1.设置顶点数组(顶点坐标、纹理坐标)
    GLfloat vertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
 
    // 2.开辟顶点缓存区
    // 创建顶点缓存区标识符ID
    GLuint bufferID;
    glGenBuffers(1, &bufferID);
    // 绑定顶点缓存区(存储数组的缓冲区)
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    // 将顶点数组的数据copy到顶点缓存区中(GPU显存中)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    // 3.打开读取通道
    // 允许顶点着色器读取GPU（服务器端）数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);// 顶点
    // 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
    // 每次读取3个数据xyz，连续顶点之间的偏移量为5即每行5个元素，读取数据的首地址为0
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    // 纹理坐标数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);// 纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
 
}

// 加载纹理数据(使用GLBaseEffect)
- (void)setUpTexture
{
    // 1.获取纹理图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"luckcoffee" ofType:@"JPG"];
    
    // 2.设置纹理参数。纹理坐标原点是左下角，但是图片显示原点应该是左上角，所以需要图片翻转
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    // 3.使用苹果GLKit提供GLKBaseEffect完成着色器工作(顶点/片元)
    effect = [[GLKBaseEffect alloc]init];
    effect.texture2d0.enabled = GL_TRUE;// 使用纹理
    effect.texture2d0.name = textureInfo.name;// 纹理的名称
}

#pragma mark -- GLKViewDelegate

// 绘制视图的内容
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 准备绘制
    [effect prepareToDraw];
    
    // 开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);// 三角形，从0个顶点开始画，画6个
}

@end

