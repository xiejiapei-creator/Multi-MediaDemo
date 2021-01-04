//
//  main.cpp
//  自动旋转的球体
//
//  Created by 谢佳培 on 2021/1/3.
//

#include "GLTools.h"
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLFrustum.h"
#include "GLGeometryTransform.h"
#include "GLBatch.h"
#include "StopWatch.h"

#include <math.h>
#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

GLFrustum           viewFrustum;
GLShaderManager     shaderManager;
GLTriangleBatch     torusBatch;
GLGeometryTransform transformPipeline;

void ChangeSize(int w, int h)
{
    // 防止除以零
    if(h == 0) h = 1;
    
    // 将视口设置为窗口尺寸
    glViewport(0, 0, w, h);

    // 设置透视投影
    viewFrustum.SetPerspective(35.0f, float(w)/float(h), 1.0f, 1000.0f);
}

void SetupRC()
{
    glClearColor(0.8f, 0.8f, 0.8f, 1.0f );
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);
   
    gltMakeSphere(torusBatch, 0.4f, 10, 20);
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
}

void RenderScene(void)
{
    // 清除屏幕、深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 1.建立基于时间变化的动画
    static CStopWatch rotTimer;
    // 当前时间 * 60s
    float yRot = rotTimer.GetElapsedSeconds() * 60.0f;
    
    // 2.矩阵变量
    M3DMatrix44f mTranslate, mRotate, mModelview, mModelViewProjection;
    
    // 创建一个4*4矩阵变量，将花托沿着Z轴负方向移动2.5个单位长度
    m3dTranslationMatrix44(mTranslate, 0.0f, 0.0f, -2.5f);
    
    // 创建一个4*4矩阵变量，将花托在Y轴上渲染yRot度，yRot根据经过时间设置动画帧率
    m3dRotationMatrix44(mRotate, m3dDegToRad(yRot), 0.0f, 1.0f, 0.0f);
    
    // mModerView通过矩阵旋转矩阵、移动矩阵相乘，将结果添加到mModerView上
    m3dMatrixMultiply44(mModelview, mTranslate, mRotate);
    
    // 将投影矩阵乘以模型视图矩阵，将变化结果通过矩阵乘法应用到mModelViewProjection矩阵上
    // 注意顺序: 投影 * 模型 != 模型 * 投影
    m3dMatrixMultiply44(mModelViewProjection, viewFrustum.GetProjectionMatrix(),mModelview);
  
    // 绘图颜色
    GLfloat vBlack[] = { 0.0f, 0.0f, 0.0f, 1.0f };
    
    // 通过平面着色器提交矩阵和颜色
    shaderManager.UseStockShader(GLT_SHADER_FLAT, mModelViewProjection, vBlack);
    
    // 开始绘图
    torusBatch.Draw();
    
    // 交换缓冲区，并立即刷新
    glutSwapBuffers();
    glutPostRedisplay();
}


int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("ModelViewProjection Example");
    glutReshapeFunc(ChangeSize);
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
