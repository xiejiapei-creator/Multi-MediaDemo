//
//  ViewController.m
//  GLKit金字塔
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic,strong)EAGLContext *context;
@property(nonatomic,strong)GLKBaseEffect *effect;

@property(nonatomic,assign)int count;

// 旋转的度数
@property(nonatomic,assign)float XDegree;
@property(nonatomic,assign)float YDegree;
@property(nonatomic,assign)float ZDegree;

// 是否旋转X,Y,Z
@property(nonatomic,assign) BOOL XB;
@property(nonatomic,assign) BOOL YB;
@property(nonatomic,assign) BOOL ZB;

@end

@implementation ViewController
{
    dispatch_source_t timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubview];

    // 1.新建图层
    [self setupContext];
    
    // 2.渲染图形
    [self render];
}

// 新建图层
- (void)setupContext
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_DEPTH_TEST);
}

// 渲染图形
-(void)render
{
    // 1.顶点数据
    // 前3个元素，是顶点数据；中间3个元素，是顶点颜色值，最后2个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    
    // 2.绘图索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    // 计算顶点个数
    self.count = sizeof(indices) /sizeof(GLuint);

    // 3.将顶点数组放入数组缓冲区中 GL_ARRAY_BUFFER
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    // 4.将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 5.使用顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, NULL);
    
    // 使用颜色数据
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    // 使用纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    
    // 6.设置纹理参数
    // 获取纹理路径
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"读书" ofType:@"JPG"];
    // 解决纹理翻转问题
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"1",GLKTextureLoaderOriginBottomLeft, nil];
    // 加载纹理
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    // 7.添加着色器
    self.effect = [[GLKBaseEffect alloc]init];
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = textureInfo.name;
    
    // 8.设置投影矩阵
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    // 9.模型视图矩阵
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    
    // 10.定时器
    double seconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
       
        self.XDegree += 0.1f * self.XB;
        self.YDegree += 0.1f * self.YB;
        self.ZDegree += 0.1f * self.ZB ;
        
    });
    dispatch_resume(timer);
}

// 场景数据变化
- (void)update
{
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.XDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.YDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.ZDegree);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}

#pragma mark - 代理方法

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

#pragma mark - 控制按钮

- (void)createSubview
{
    UIButton *xbutton = [[UIButton alloc] initWithFrame:CGRectMake(50.f, 820.f, 100, 50.f)];
    [xbutton addTarget:self action:@selector(xbuttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [xbutton setTitle:@"绕X轴旋转" forState:UIControlStateNormal];
    [xbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    xbutton.layer.cornerRadius = 5.f;
    xbutton.clipsToBounds = YES;
    xbutton.layer.borderWidth = 1.f;
    xbutton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:xbutton];
    
    UIButton *ybutton = [[UIButton alloc] initWithFrame:CGRectMake(170.f, 820.f, 100, 50.f)];
    [ybutton addTarget:self action:@selector(ybuttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [ybutton setTitle:@"绕Y轴旋转" forState:UIControlStateNormal];
    [ybutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    ybutton.layer.cornerRadius = 5.f;
    ybutton.clipsToBounds = YES;
    ybutton.layer.borderWidth = 1.f;
    ybutton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:ybutton];
    
    UIButton *zbutton = [[UIButton alloc] initWithFrame:CGRectMake(290.f, 820.f, 100, 50.f)];
    [zbutton addTarget:self action:@selector(zbuttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [zbutton setTitle:@"绕Z轴旋转" forState:UIControlStateNormal];
    [zbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    zbutton.layer.cornerRadius = 5.f;
    zbutton.clipsToBounds = YES;
    zbutton.layer.borderWidth = 1.f;
    zbutton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:zbutton];
}

- (void)xbuttonClicked
{
    _XB = !_XB;
}

- (void)ybuttonClicked
{
    _YB = !_YB;
}

- (void)zbuttonClicked
{
    _ZB = !_ZB;
}

@end
