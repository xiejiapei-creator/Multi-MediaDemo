//
//  main.cpp
//  球体世界
//
//  Created by 谢佳培 on 2021/1/4.
//

#include "GLTools.h"
#include "GLShaderManager.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"
#include "StopWatch.h"

#include <math.h>
#include <stdio.h>

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

// 添加附加随机球
#define NUM_SPHERES 50
GLFrame spheres[NUM_SPHERES];

GLShaderManager        shaderManager;            // 着色器管理器
GLMatrixStack        modelViewMatrix;        // 模型视图矩阵
GLMatrixStack        projectionMatrix;        // 投影矩阵
GLFrustum            viewFrustum;            // 视景体
GLGeometryTransform    transformPipeline;        // 几何图形变换管道

GLTriangleBatch        torusBatch;             // 花托批处理
GLBatch                floorBatch;             // 地板批处理
GLTriangleBatch     sphereBatch;            //公转球的批处理

GLFrame             cameraFrame;// 照相机角色帧

GLuint uiTextures[3];// 纹理标记数组

//====================

void drawSomething(GLfloat yRot)
{
    // 1.定义光源位置&漫反射颜色
    static GLfloat vWhite[] = { 1.0f, 1.0f, 1.0f, 1.0f };
    static GLfloat vLightPos[] = { 0.0f, 3.0f, 0.0f, 1.0f };
    
    // 2.绘制悬浮小球球
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    for(int i = 0; i < NUM_SPHERES; i++)
    {
        modelViewMatrix.PushMatrix();
        modelViewMatrix.MultMatrix(spheres[i]);
        shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,
                                     modelViewMatrix.GetMatrix(),
                                     transformPipeline.GetProjectionMatrix(),
                                     vLightPos,
                                     vWhite,
                                     0);
        sphereBatch.Draw();
        modelViewMatrix.PopMatrix();
    }
    
    // 3.绘制大球
    modelViewMatrix.Translate(0.0f, 0.2f, -2.5f);
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot, 0.0f, 1.0f, 0.0f);
    glBindTexture(GL_TEXTURE_2D, uiTextures[1]);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,
                                 modelViewMatrix.GetMatrix(),
                                 transformPipeline.GetProjectionMatrix(),
                                 vLightPos,
                                 vWhite,
                                 0);
    torusBatch.Draw();
    modelViewMatrix.PopMatrix();
    
    // 4.绘制公转自转小球
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot * -2.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix.Translate(0.8f, 0.0f, 0.0f);
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,
                                 modelViewMatrix.GetMatrix(),
                                 transformPipeline.GetProjectionMatrix(),
                                 vLightPos,
                                 vWhite,
                                 0);
    sphereBatch.Draw();
    modelViewMatrix.PopMatrix();
    
}

bool LoadTGATexture(const char *szFileName, GLenum minFilter, GLenum magFilter, GLenum wrapMode)
{

    GLbyte *pBits;
    int nWidth, nHeight, nComponents;
    GLenum eFormat;
    
    // 1.读取纹理数据
    pBits = gltReadTGABits(szFileName, &nWidth, &nHeight, &nComponents, &eFormat);
    if(pBits == NULL) return false;
    
    // 2、设置纹理参数
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
    
    // 3.载入纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB, nWidth, nHeight, 0,
                 eFormat, GL_UNSIGNED_BYTE, pBits);
    // 使用完毕释放pBits
    free(pBits);
    
    // 生成Mip贴图
    if(minFilter == GL_LINEAR_MIPMAP_LINEAR ||
       minFilter == GL_LINEAR_MIPMAP_NEAREST ||
       minFilter == GL_NEAREST_MIPMAP_LINEAR ||
       minFilter == GL_NEAREST_MIPMAP_NEAREST)
    {
        // 纹理生成所有的Mip层
        glGenerateMipmap(GL_TEXTURE_2D);
    }

    return true;
}

//===================

void SetupRC()
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    shaderManager.InitializeStockShaders();
    
    // 1.开启深度测试/背面剔除
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);

    // 2.设置大球、小球(公转自转)
    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    gltMakeSphere(sphereBatch, 0.1f, 26, 13);
    
    // 3.设置地板顶点数据&地板纹理
    GLfloat texSize = 10.0f;
    floorBatch.Begin(GL_TRIANGLE_FAN, 4,1);
    
    floorBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    floorBatch.Vertex3f(-20.f, -0.41f, 20.0f);
    
    floorBatch.MultiTexCoord2f(0, texSize, 0.0f);
    floorBatch.Vertex3f(20.0f, -0.41f, 20.f);
    
    floorBatch.MultiTexCoord2f(0, texSize, texSize);
    floorBatch.Vertex3f(20.0f, -0.41f, -20.0f);
    
    floorBatch.MultiTexCoord2f(0, 0.0f, texSize);
    floorBatch.Vertex3f(-20.0f, -0.41f, -20.0f);
    
    floorBatch.End();
    
    // 4.随机小球顶点坐标数据
    for (int i = 0; i < NUM_SPHERES; i++)
    {
        // Y轴不变，X,Z产生随机值
        GLfloat x = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        GLfloat z = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        
        // 在y方向，将球体设置为0.0的位置，这使得它们看起来是飘浮在眼睛的高度
        // 对spheres数组中的每一个顶点，设置顶点数据
        spheres[i].SetOrigin(x, 0.0f, z);
    }
    
    // 5.命名纹理对象
    glGenTextures(3, uiTextures);
    
    // 6.将TGA文件加载为2D纹理
    glBindTexture(GL_TEXTURE_2D, uiTextures[0]);
    LoadTGATexture("marble.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_REPEAT);
    
    glBindTexture(GL_TEXTURE_2D, uiTextures[1]);
    LoadTGATexture("marslike.tga", GL_LINEAR_MIPMAP_LINEAR,
                   GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    LoadTGATexture("moonlike.tga", GL_LINEAR_MIPMAP_LINEAR,
                   GL_LINEAR, GL_CLAMP_TO_EDGE);
}

// 进行调用以绘制场景
void RenderScene(void)
{
    // 地板颜色值
    static GLfloat vFloorColor[] = { 1.0f, 1.0f, 0.0f, 0.75f};
    
    // 基于时间动画
    static CStopWatch    rotTimer;
    float yRot = rotTimer.GetElapsedSeconds() * 60.0f;
    
    // 清除颜色缓存区和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 压入栈(栈顶)
    modelViewMatrix.PushMatrix();
    
    // 设置观察者矩阵
    M3DMatrix44f mCamera;
    cameraFrame.GetCameraMatrix(mCamera);
    modelViewMatrix.MultMatrix(mCamera);
    
    // 1.添加反光效果
    // 压栈(镜面)
    modelViewMatrix.PushMatrix();

    // 翻转Y轴
    modelViewMatrix.Scale(1.0f, -1.0f, 1.0f);
    // 镜面世界围绕Y轴平移一定间距
    modelViewMatrix.Translate(0.0f, 0.8f, 0.0f);
    
    // 指定顺时针为正面
    glFrontFace(GL_CW);
    // 绘制地面以外其他部分(镜面)
    drawSomething(yRot);
    // 恢复为逆时针为正面
    glFrontFace(GL_CCW);
    
    // 绘制镜面，恢复矩阵
    modelViewMatrix.PopMatrix();
    
    // 2.开启混合功能(绘制地板)
    glEnable(GL_BLEND);
    // 指定glBlendFunc 颜色混合方程式
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    // 绑定地面纹理
    glBindTexture(GL_TEXTURE_2D, uiTextures[0]);
    // 纹理调整着色器(将一个基本色乘以一个取自纹理的单元nTextureUnit的纹理)
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_MODULATE,
                                 transformPipeline.GetModelViewProjectionMatrix(),
                                 vFloorColor,
                                 0);
    // 开始绘制
    floorBatch.Draw();
    // 取消混合
    glDisable(GL_BLEND);
    
    // 3.绘制地面以外其他部分
    drawSomething(yRot);
    
    // 绘制完，恢复矩阵
    modelViewMatrix.PopMatrix();
    
    // 交换缓存区
    glutSwapBuffers();
    
    // 提交重新渲染
    glutPostRedisplay();
}

// 屏幕更改大小或已初始化
void ChangeSize(int nWidth, int nHeight)
{
    glViewport(0, 0, nWidth, nHeight);
    viewFrustum.SetPerspective(35.0f, float(nWidth)/float(nHeight), 1.0f, 100.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    modelViewMatrix.LoadIdentity();
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

// 删除纹理
void ShutdownRC(void)
{
    glDeleteTextures(3, uiTextures);
}

// 移动照相机参考帧，来对方向键作出响应
void SpeacialKeys(int key,int x,int y)
{
    float linear = 0.1f;
    float angular = float(m3dDegToRad(5.0f));
    
    if (key == GLUT_KEY_UP)
    {
        cameraFrame.MoveForward(linear);
    }
    
    if (key == GLUT_KEY_DOWN)
    {
        cameraFrame.MoveForward(-linear);
    }
    
    if (key == GLUT_KEY_LEFT)
    {
        cameraFrame.RotateWorld(angular, 0.0f, 1.0f, 0.0f);
    }
    
    if (key == GLUT_KEY_RIGHT)
    {
        cameraFrame.RotateWorld(-angular, 0.0f, 1.0f, 0.0f);
    }
}

int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
    glutInitWindowSize(800,600);
    
    glutCreateWindow("OpenGL SphereWorld");
    
    glutReshapeFunc(ChangeSize);
    glutDisplayFunc(RenderScene);
    glutSpecialFunc(SpeacialKeys);
    
    GLenum err = glewInit();
    if (GLEW_OK != err) {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    
    SetupRC();
    glutMainLoop();
    ShutdownRC();
    return 0;
}
