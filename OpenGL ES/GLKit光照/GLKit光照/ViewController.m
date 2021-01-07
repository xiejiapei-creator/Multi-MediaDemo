//
//  ViewController.m
//  GLKit光照
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "sceneUtil.h"

@interface ViewController ()


@property(nonatomic,strong)EAGLContext *context;

// 基本Effect
@property(nonatomic,strong)GLKBaseEffect *baseEffect;
// 额外Effect，用来绘制法线，实际工程中只需要光照效果，不需要绘制法线
@property(nonatomic,strong)GLKBaseEffect *extraEffect;

// 顶点缓存区
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertexBuffer;
// 法线位置缓存区
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *extraBuffer;

// 是否绘制法线
@property(nonatomic,assign)BOOL shouldDrawNormals;
// 中心点的高
@property(nonatomic,assign) GLfloat centexVertexHeight;

@end

@implementation ViewController
{
    // 三角形-8面
    SceneTriangle triangles[NUM_FACES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSubviews];
  
    // 1.初始化上下文
    [self setupES];
    
    // 2.设置着色器
    [self setUpEffect];
    
    // 3.设置缓冲区
    [self setUpBuffer];
}
#pragma mark -- OpenGL ES

- (void)setupES
{
    // 1.新建OpenGL ES 上下文
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // 2.设置GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    // 3.设置当前上下文
    [EAGLContext setCurrentContext:self.context];
}

- (void)setUpEffect
{
    // 1.金字塔Effect
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.light0.enabled = GL_TRUE;
    
    // 光的漫射部分的颜色 GLKVector4Make(R,G,B,A)
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.7f, 0.7f, 0.7, 1.0f);
    // 世界坐标中的光的位置
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 1.0f, 0.5f, 0.0f);
    
    // 2.法线Effect
    self.extraEffect = [[GLKBaseEffect alloc]init];
    self.extraEffect.useConstantColor = GL_TRUE;
    
    // 3.为了更好的观察需要调整模型矩阵
    if (true)
    {
        // 围绕x轴旋转-60度
        // 返回一个4x4矩阵进行绕任意矢量旋转
        GLKMatrix4 modelViewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-60.0f), 1.0f, 0.0f, 0.0f);
        
        // 围绕z轴，旋转-30度
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix,GLKMathDegreesToRadians(-30.0f), 0.0f, 0.0f, 1.0f);
        
        // 围绕Z方向，移动0.25f
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 0.0f, 0.25f);
        
        // 设置baseEffect,extraEffect模型矩阵
        self.baseEffect.transform.modelviewMatrix = modelViewMatrix;
        self.extraEffect.transform.modelviewMatrix = modelViewMatrix;
    }
}

- (void)setUpBuffer
{
    // 调用工具类中创建三角形的函数确定图形的8个三角形面
    triangles[0] = SceneTriangleMake(vertexA, vertexB, vertexD);
    triangles[1] = SceneTriangleMake(vertexB, vertexC, vertexF);
    triangles[2] = SceneTriangleMake(vertexD, vertexB, vertexE);
    triangles[3] = SceneTriangleMake(vertexE, vertexB, vertexF);
    triangles[4] = SceneTriangleMake(vertexD, vertexE, vertexH);
    triangles[5] = SceneTriangleMake(vertexE, vertexF, vertexH);
    triangles[6] = SceneTriangleMake(vertexG, vertexD, vertexH);
    triangles[7] = SceneTriangleMake(vertexH, vertexF, vertexI);
    
    // 初始化顶点缓存区
    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles usage:GL_DYNAMIC_DRAW];
    
    // 不知道法线的数目和内容，先赋值为空
    self.extraBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:sizeof(SceneVertex) numberOfVertices:0 bytes:NULL usage:GL_DYNAMIC_DRAW];
    
    // 中心点的高为0，表示在原点
    self.centexVertexHeight = 0.0f;
}


#pragma mark -- 绘制 GLKView

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 准备绘制
    [self.baseEffect prepareToDraw];
   
    // 准备绘制顶点数据
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:offsetof(SceneVertex,position)shouldEnable:YES];
   
    // 准备绘制光照法线数据
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:offsetof(SceneVertex, normal) shouldEnable:YES];
    
    // 使用着色器进行绘制
    [self.vertexBuffer drawArrayWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sizeof(triangles)/sizeof(SceneVertex)];
    
    // 是否要绘制光照法线
    if (self.shouldDrawNormals)
    {
        [self drawNormals];
    }
}

#pragma mark - 辅助方法

// 绘制法线
- (void)drawNormals
{
    GLKVector3 normalLineVertices[NUM_LINE_VERTS];
    
    // 1.以每个顶点的坐标为起点，顶点坐标加上法向量的偏移值作为终点，更新法线显示数组
    SceneTrianglesNormalLinesUpdate(triangles, GLKVector3MakeWithArray(self.baseEffect.light0.position.v), normalLineVertices);
    
    // 2.为extraBuffer重新开辟空间
    [self.extraBuffer reinitWithAttribStride:sizeof(GLKVector3) numberOfVertices:NUM_LINE_VERTS bytes:normalLineVertices];
    
    // 3.准备绘制数据
    [self.extraBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    
    // 4.指示是否使用常量颜色的布尔值
    self.extraEffect.useConstantColor = GL_TRUE;
    // 设置光源颜色为绿色，画顶点法线
    self.extraEffect.constantColor = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    
    // 5.绘制-绿色的法线
    [self.extraEffect prepareToDraw];
    [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:0 numberOfVertices:NUM_NORMAL_LINE_VERTS];
    
    // 6.设置光源颜色为黄色，并且画光源线
    self.extraEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 0.0f, 1.0f);
    // 准备绘制-黄色的光源方向线
    [self.extraEffect prepareToDraw];
    // 2点确定一条线
    [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:NUM_NORMAL_LINE_VERTS numberOfVertices:2];
}

// 更新每个点的平面法向量（非必需）
- (void)updateNormals
{
    SceneTrianglesUpdateFaceNormals(triangles);
    
    [self.vertexBuffer reinitWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles];
}

// 设置中心点的高度（非必需）
- (void)setCentexVertexHeight:(GLfloat)centexVertexHeight
{
    _centexVertexHeight = centexVertexHeight;
    
    // 更新金字塔的顶点E
    SceneVertex newVertexE = vertexE;
    newVertexE.position.z = _centexVertexHeight;
    
    // 更改顶点E影响下的底面顶点
    triangles[2] = SceneTriangleMake(vertexD, vertexB, newVertexE);
    triangles[3] = SceneTriangleMake(newVertexE, vertexB, vertexF);
    triangles[4] = SceneTriangleMake(vertexD, newVertexE, vertexH);
    triangles[5] = SceneTriangleMake(newVertexE, vertexF, vertexH);
    
    // 更新法线
    [self updateNormals];
}

#pragma mark - 视图

- (void)createSubviews
{
    UISwitch *normalSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(50.f, 820.f, 100, 50.f)];
    [normalSwitch addTarget:self action:@selector(takeShouldDrawNormals:) forControlEvents:UIControlEventTouchUpInside];
    normalSwitch.layer.cornerRadius = 5.f;
    normalSwitch.clipsToBounds = YES;
    normalSwitch.layer.borderWidth = 1.f;
    normalSwitch.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:normalSwitch];
    
    UISlider *heightSlider = [[UISlider alloc] initWithFrame:CGRectMake(200.f, 810.f, 150, 50.f)];
    [heightSlider addTarget:self action:@selector(changeCenterVertexHeight:) forControlEvents:UIControlEventTouchUpInside];
    heightSlider.layer.cornerRadius = 5.f;
    heightSlider.clipsToBounds = YES;
    heightSlider.layer.borderWidth = 1.f;
    heightSlider.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:heightSlider];
}

// 是否绘制法线
- (void)takeShouldDrawNormals:(UISwitch *)sender
{
     self.shouldDrawNormals = sender.isOn;
}

// 改变中心点的高度
- (void)changeCenterVertexHeight:(UISlider *)sender
{
    self.centexVertexHeight = sender.value;
}


@end
