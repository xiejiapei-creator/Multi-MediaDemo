//
//  main.cpp
//  地球的公转
//
//  Created by 谢佳培 on 2021/1/3.
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

GLShaderManager        shaderManager;            // 着色器管理器
GLMatrixStack        modelViewMatrix;        // 模型视图矩阵
GLMatrixStack        projectionMatrix;        // 投影矩阵
GLFrustum            viewFrustum;            // 视景体
GLGeometryTransform    transformPipeline;        // 几何图形变换管道

GLTriangleBatch        torusBatch;             // 大球
GLTriangleBatch     sphereBatch;            // 小球（随机球，包括静止和自转两种类型）
GLBatch                floorBatch;          // 地板

// 角色帧 照相机角色帧
GLFrame             cameraFrame;

// 添加附加随机球
#define NUM_SPHERES 50
GLFrame spheres[NUM_SPHERES];

void SetupRC()
{
    // 1.清空颜色缓冲区中的残留颜色值，再进行初始化
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    shaderManager.InitializeStockShaders();
    
    // 2.开启深度测试（立体）
    glEnable(GL_DEPTH_TEST);
   
    // 3.设置地板顶点数据
    floorBatch.Begin(GL_LINES, 324);// 共324个
    for(GLfloat x = -20.0; x <= 20.0f; x+= 0.5)
    {
        // 地板是平面，只会在X、Y上发生变化
        floorBatch.Vertex3f(x, -0.55f, 20.0f);
        floorBatch.Vertex3f(x, -0.55f, -20.0f);
        
        floorBatch.Vertex3f(20.0f, -0.55f, x);
        floorBatch.Vertex3f(-20.0f, -0.55f, x);
    }
    floorBatch.End();
    
    // 4.设置大球模型
    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    
    // 5.设置小球球模型
    gltMakeSphere(sphereBatch, 0.1f, 26, 13);
    
    // 6. 随机位置放置小球
    for (int i = 0; i < NUM_SPHERES; i++)
    {
        // 小球在同一个平面，说明Y轴不变，X，Z使用随机值
        GLfloat x = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        GLfloat z = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        
        // 在y轴方向，将球体设置为0.0的位置，这使得它们看起来是飘浮在眼睛的高度
        // 对spheres数组中的每一个顶点，设置顶点数据
        spheres[i].SetOrigin(x, 0.0f, z);
    }
}

// 绘制场景
void RenderScene(void)
{
    // 1.颜色值(地板、大球、小球颜色)
    static GLfloat vFloorColor[] = { 0.0f, 1.0f, 0.0f, 1.0f};
    static GLfloat vTorusColor[] = { 1.0f, 0.0f, 0.0f, 1.0f };
    static GLfloat vSphereColor[] = { 0.0f, 0.0f, 1.0f, 1.0f};
    
    // 2.清除颜色缓存区和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 3.时间动画
    static CStopWatch    rotTimer;
    float yRot = rotTimer.GetElapsedSeconds() * 60.0f;
    
    // 4.为了让蓝色的小球的公转在任何角度都能看到需要加入观察者
    // 观察者放在地板之前，让地板也支持摄影机的移动
    M3DMatrix44f mCamera;
    cameraFrame.GetCameraMatrix(mCamera);
    modelViewMatrix.PushMatrix(mCamera);
    
    // 5.绘制地面
    shaderManager.UseStockShader(GLT_SHADER_FLAT,transformPipeline.GetModelViewProjectionMatrix(),vFloorColor);
    floorBatch.Draw();
    
    // 6.获取光源位置
    M3DVector4f vLightPos = {0.0f,10.0f,5.0f,1.0f};
   
    // 7.画中央的红色大球
    // 使得大球位置平移(3.0)向屏幕里面
    modelViewMatrix.Translate(0.0f, 0.0f, -3.0f);
    // 压栈(复制栈顶)，只有当图形发生了仿射变换的时候才需要使用到堆栈
    modelViewMatrix.PushMatrix();
    // 大球自转（围绕Y轴旋转）
    modelViewMatrix.Rotate(yRot, 0.0f, 1.0f, 0.0f);
    // 指定合适的着色器(点光源着色器)
    shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(),transformPipeline.GetProjectionMatrix(), vLightPos, vTorusColor);
    torusBatch.Draw();
    // 绘制完毕则Pop
    modelViewMatrix.PopMatrix();
    
    // 8.画静态的小球
    for (int i = 0; i < NUM_SPHERES; i++)
    {
        modelViewMatrix.PushMatrix();
        modelViewMatrix.MultMatrix(spheres[i]);
        shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(),transformPipeline.GetProjectionMatrix(), vLightPos, vSphereColor);
        sphereBatch.Draw();
        modelViewMatrix.PopMatrix();
    }
    
    // 9. 让一个小篮球围绕大球公众自转
    // 围绕Y轴绕负方向2倍速度旋转
    modelViewMatrix.Rotate(yRot * -2.0f, 0.0f, 1.0f, 0.0f);
    // 因为篮球和红球位置都在中央，为区分，将篮球沿着X轴正方向移动0.8
    modelViewMatrix.Translate(0.8f, 0.0f, 0.0f);
    shaderManager.UseStockShader(GLT_SHADER_FLAT,transformPipeline.GetModelViewProjectionMatrix(),vSphereColor);
    sphereBatch.Draw();
    modelViewMatrix.PopMatrix();
    
    // 10.执行缓存区交换
    glutSwapBuffers();
    
    // 11.为了让球旋转起来，需要进行不断渲染
    glutPostRedisplay();
}

// 屏幕更改大小或已初始化
void ChangeSize(int nWidth, int nHeight)
{
    // 1.设置视口
    glViewport(0, 0, nWidth, nHeight);
    
    // 2.创建投影矩阵
    viewFrustum.SetPerspective(35.0f, float(nWidth)/float(nHeight), 1.0f, 100.0f);
    // 获取viewFrustum投影矩阵，并将其加载到投影矩阵堆栈上
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    // 3.设置变换管道以使用两个矩阵堆栈（变换矩阵modelViewMatrix ，投影矩阵projectionMatrix）
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpeacialKeys(int key,int x,int y)
{
    // 移动步长
    float linear = 0.1f;
    // 旋转度数
    float angular = float(m3dDegToRad(5.0f));
    
    // 上下平移
    if (key == GLUT_KEY_UP)
    {
        cameraFrame.MoveForward(linear);
    }
    
    if (key == GLUT_KEY_DOWN)
    {
        cameraFrame.MoveForward(-linear);
    }
    
    // 左右旋转
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
    if (GLEW_OK != err)
    {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    SetupRC();
    glutMainLoop();
    return 0;
}
