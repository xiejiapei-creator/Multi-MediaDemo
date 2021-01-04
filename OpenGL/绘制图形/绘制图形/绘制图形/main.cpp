//
//  main.cpp
//  绘制图形
//
//  Created by 谢佳培 on 2021/1/3.
//

#include "GLTools.h"
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLGeometryTransform.h"
#include "StopWatch.h"

#include <math.h>
#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

GLShaderManager        shaderManager;
GLMatrixStack        modelViewMatrix;
GLMatrixStack        projectionMatrix;

// 观察者位置
GLFrame                cameraFrame;
// 世界坐标位置
GLFrame             objectFrame;

// 视景体，用来构造投影矩阵
GLFrustum            viewFrustum;

// 三角形批次类
GLTriangleBatch     CC_Triangle;
// 球
GLTriangleBatch     sphereBatch;
// 环
GLTriangleBatch     torusBatch;
// 圆柱
GLTriangleBatch     cylinderBatch;
// 锥
GLTriangleBatch     coneBatch;
// 磁盘
GLTriangleBatch     diskBatch;

GLGeometryTransform    transformPipeline;
M3DMatrix44f        shadowMatrix;

GLfloat vGreen[] = { 0.0f, 1.0f, 0.0f, 1.0f };
GLfloat vBlack[] = { 0.0f, 0.0f, 0.0f, 1.0f };

int nStep = 0;

// 绘制图形和边框
void DrawWireFramedBatch(GLTriangleBatch* pBatch)
{
    //--------绘制图形---------
    // 1.平面着色器，绘制三角形
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vGreen);
    // 传过来的参数，对应不同的图形Batch
    pBatch->Draw();
    
    //-------画出黑色轮廓---------
    // 2.开启多边形偏移
    glEnable(GL_POLYGON_OFFSET_LINE);
    // 多边形模型(背面、线) 将多边形背面设为线框模式
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    // 开启多边形偏移(设置偏移数量)
    glPolygonOffset(-1.0f, -1.0f);
    // 线条宽度
    glLineWidth(2.5f);
    
    // 3.开启混合功能(颜色混合&抗锯齿功能)
    glEnable(GL_BLEND);
    // 开启处理线段抗锯齿功能
    glEnable(GL_LINE_SMOOTH);
    // 设置颜色混合因子
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
   
    // 4.平面着色器绘制线条
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vBlack);
    pBatch->Draw();
    
    // 5.恢复多边形模式和深度测试
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    glDisable(GL_POLYGON_OFFSET_LINE);
    glLineWidth(1.0f);
    glDisable(GL_BLEND);
    glDisable(GL_LINE_SMOOTH);
}

void SetupRC()
{
    // 1.初始化
    glClearColor(0.7f, 0.7f, 0.7f, 1.0f );
    shaderManager.InitializeStockShaders();
    
    // 2.开启深度测试
    glEnable(GL_DEPTH_TEST);

    // 3.将观察者坐标位置Z移动往屏幕里移动15个单位位置
    cameraFrame.MoveForward(-15.0f);
    // ***或者将物体向屏幕外移动15.0***
    //objectFrame.MoveForward(15.0f);

    // 4.利用三角形批次类构造图形对象
    // 球
    gltMakeSphere(sphereBatch, 3.0, 10, 20);
    
    // 环面
    gltMakeTorus(torusBatch, 3.0f, 0.75f, 15, 15);
    
    // 圆柱
    gltMakeCylinder(cylinderBatch, 2.0f, 2.0f, 3.0f, 15, 2);
    
    // 圆锥
    gltMakeCylinder(coneBatch, 2.0f, 0.0f, 3.0f, 13, 2);
    
    // 磁盘
    gltMakeDisk(diskBatch, 1.5f, 3.0f, 13, 3);
}

void RenderScene(void)
{
    // 1.用当前清除颜色清除窗口背景
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    // 2.模型视图矩阵栈堆，压栈
    modelViewMatrix.PushMatrix();
    // ***或者对objectFrame进行压栈，删掉3.和4. 直接进入switch(nStep)的判断步骤***
    //modelViewMatrix.PushMatrix(objectFrame);

    // 3.获取摄像头矩阵
    M3DMatrix44f mCamera;
    // 从camereaFrame中获取矩阵到mCamera
    cameraFrame.GetCameraMatrix(mCamera);
    // 模型视图堆栈的矩阵与mCamera矩阵相乘之后，存储到modelViewMatrix矩阵堆栈中
    modelViewMatrix.MultMatrix(mCamera);
    
    // 4.创建矩阵mObjectFrame
    M3DMatrix44f mObjectFrame;
    // 从ObjectFrame 获取矩阵到mOjectFrame中
    objectFrame.GetMatrix(mObjectFrame);
    // 将modelViewMatrix 的堆栈中的矩阵 与 mOjbectFrame 矩阵相乘，存储到modelViewMatrix矩阵堆栈中
    modelViewMatrix.MultMatrix(mObjectFrame);

    // 5.判断你目前是绘制第几个图形
    switch(nStep)
    {
        case 0:
            DrawWireFramedBatch(&sphereBatch);
            break;
        case 1:
            DrawWireFramedBatch(&torusBatch);
            break;
        case 2:
            DrawWireFramedBatch(&cylinderBatch);
            break;
        case 3:
            DrawWireFramedBatch(&coneBatch);
            break;
        case 4:
            DrawWireFramedBatch(&diskBatch);
            break;
    }
    
    // 6.出栈
    modelViewMatrix.PopMatrix();
    
    // 7.交换缓存
    glutSwapBuffers();
}

// 点击空格，切换渲染图形
void KeyPressFunc(unsigned char key, int x, int y)
{
    if(key == 32)
    {
        nStep++;
        if(nStep > 4) nStep = 0;
    }
    
    switch(nStep)
    {
        case 0:
            glutSetWindowTitle("Sphere");
            break;
        case 1:
            glutSetWindowTitle("Torus");
            break;
        case 2:
            glutSetWindowTitle("Cylinder");
            break;
        case 3:
            glutSetWindowTitle("Cone");
            break;
        case 4:
            glutSetWindowTitle("Disk");
            break;
    }
    
    glutPostRedisplay();
}

void SpecialKeys(int key, int x, int y)
{
    if(key == GLUT_KEY_UP) objectFrame.RotateWorld(m3dDegToRad(-5.0f), 1.0f, 0.0f, 0.0f);
    if(key == GLUT_KEY_DOWN) objectFrame.RotateWorld(m3dDegToRad(5.0f), 1.0f, 0.0f, 0.0f);
    if(key == GLUT_KEY_LEFT) objectFrame.RotateWorld(m3dDegToRad(-5.0f), 0.0f, 1.0f, 0.0f);
    if(key == GLUT_KEY_RIGHT) objectFrame.RotateWorld(m3dDegToRad(5.0f), 0.0f, 1.0f, 0.0f);
    
    glutPostRedisplay();
}

void ChangeSize(int w, int h)
{
    glViewport(0, 0, w, h);

    viewFrustum.SetPerspective(35.0f, float(w) / float(h), 1.0f, 500.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
     modelViewMatrix.LoadIdentity();
    
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("Sphere");
    glutReshapeFunc(ChangeSize);
    glutKeyboardFunc(KeyPressFunc);
    glutSpecialFunc(SpecialKeys);
    glutDisplayFunc(RenderScene);
    
    GLenum err = glewInit();
    if (GLEW_OK != err)
    {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    
    SetupRC();
    
    glutMainLoop();
    return 0;
}
