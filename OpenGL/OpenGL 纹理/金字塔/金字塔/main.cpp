//
//  main.cpp
//  金字塔
//
//  Created by 谢佳培 on 2021/1/4.
//

#include "GLTools.h"
#include "GLShaderManager.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLFrame.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

GLShaderManager        shaderManager;
GLMatrixStack        modelViewMatrix;
GLMatrixStack        projectionMatrix;
GLFrame                cameraFrame;
GLFrame             objectFrame;
GLFrustum            viewFrustum;

GLBatch             pyramidBatch;
GLGeometryTransform    transformPipeline;
M3DMatrix44f        shadowMatrix;

// 纹理变量，一般使用无符号整型
GLuint              textureID;

// 将TGA文件加载为2D纹理
bool LoadTGATexture(const char *szFileName, GLenum minFilter, GLenum magFilter, GLenum wrapMode)
{
    // 指向图像数据的指针
    GLbyte *pBits;
    // 图片的宽、高、颜色
    int nWidth, nHeight, nComponents;
    // 颜色存储方式
    GLenum eFormat;
    
    // 1、读取纹理位置，读取像素
    pBits = gltReadTGABits(szFileName, &nWidth, &nHeight, &nComponents, &eFormat);
    if(pBits == NULL) return false;// 未能成功读取到数据

    // 2、设置纹理参数
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
    
    // 3、载入纹理
    glTexImage2D(GL_TEXTURE_2D, 0, nComponents, nWidth, nHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBits);
    // 使用完毕释放pBits
    free(pBits);

    // 4、加载Mip，纹理生成所有的Mip层
    glGenerateMipmap(GL_TEXTURE_2D);
 
    return true;
}

// 绘制金字塔
void MakePyramid(GLBatch& pyramidBatch)
{
    // 1、通过pyramidBatch组建三角形批次
    pyramidBatch.Begin(GL_TRIANGLES, 18, 1);
    
    // 2、创建顶点数据
    M3DVector3f vApex = { 0.0f, 1.0f, 0.0f };// 塔顶
    M3DVector3f vFrontLeft = { -1.0f, -1.0f, 1.0f };// 前左
    M3DVector3f vFrontRight = { 1.0f, -1.0f, 1.0f };// 前右
    M3DVector3f vBackLeft = { -1.0f,  -1.0f, -1.0f };// 后左
    M3DVector3f vBackRight = { 1.0f,  -1.0f, -1.0f };// 后右
    M3DVector3f n;// 法线变量
    
    // 3、绘制金字塔底部的四边形
    // 四边形 = 三角形X(vBackLeft,vBackRight,vFrontRight) + 三角形Y(vFrontLeft,vBackLeft,vFrontRight)
    
    // 找到三角形X的法线
    m3dFindNormal(n, vBackLeft, vBackRight, vFrontRight);
   
    // vBackLeft
    pyramidBatch.Normal3fv(n);// 设置法线
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);// 设置纹理坐标
    pyramidBatch.Vertex3fv(vBackLeft);// 向三角形批次类添加顶点数据
    
    // vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    
    // 找到三角形Y的法线
    m3dFindNormal(n, vFrontLeft, vBackLeft, vFrontRight);
    
    // vFrontLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    
    // vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    // vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);

    
    // 4、绘制金字塔前面的三角形（Apex，vFrontLeft，vFrontRight）
    m3dFindNormal(n, vApex, vFrontLeft, vFrontRight);
   
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);

    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    // 4、绘制金字塔左边的三角形（vApex, vBackLeft, vFrontLeft）
    m3dFindNormal(n, vApex, vBackLeft, vFrontLeft);
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    
    // 5、绘制金字塔右边的三角形（vApex, vFrontRight, vBackRight）
    m3dFindNormal(n, vApex, vFrontRight, vBackRight);
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    // 6、绘制金字塔后边的三角形（vApex, vBackRight, vBackLeft）
    m3dFindNormal(n, vApex, vBackRight, vBackLeft);
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    // 7、结束批次设置
    pyramidBatch.End();
}

void SetupRC()
{
    glClearColor(0.7f, 0.7f, 0.7f, 1.0f );
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);
    
    // 1.分配纹理对象
    glGenTextures(1, &textureID);
    
    // 2.绑定纹理状态 参数1： 参数2：
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    // 3.将TGA文件加载为2D纹理
    LoadTGATexture("stone.tga", GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    // 4.创造金字塔pyramidBatch
    MakePyramid(pyramidBatch);
    
    // 5.修改观察者，将相机平移
    cameraFrame.MoveForward(-10);
}

void RenderScene(void)
{
    // 1.颜色值&光源位置
    static GLfloat vLightPos [] = { 1.0f, 1.0f, 0.0f };
    static GLfloat vWhite [] = { 1.0f, 1.0f, 1.0f, 1.0f };
    
    // 2.清理缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    // 3.当前模型视频压栈
    modelViewMatrix.PushMatrix();
    
    // 添加照相机矩阵
    M3DMatrix44f mCamera;
    // 从camraFrame中获取一个4*4的矩阵
    cameraFrame.GetCameraMatrix(mCamera);
    // 矩阵乘以矩阵堆栈顶部矩阵，相乘结果存储到堆栈的顶部将照相机矩阵与当前模型矩阵相乘压入栈顶
    modelViewMatrix.MultMatrix(mCamera);
    
    // 创建mObjectFrame矩阵
    M3DMatrix44f mObjectFrame;
    // 从objectFrame中获取矩阵，objectFrame保存的是特殊键位的变换矩阵
    objectFrame.GetMatrix(mObjectFrame);
    // 矩阵乘以矩阵堆栈顶部矩阵，相乘结果存储到堆栈的顶部将照相机矩阵与当前模型矩阵相乘压入栈顶
    modelViewMatrix.MultMatrix(mObjectFrame);
    
    // 4.绑定纹理。因为我们的项目中只有一个纹理，可以省略这步，但如果有多个纹理，绑定纹理很重要
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    // 5.点光源着色器
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,
                                 transformPipeline.GetModelViewMatrix(),
                                 transformPipeline.GetProjectionMatrix(),
                                 vLightPos, vWhite, 0);
    
    // 6.绘制金字塔
    pyramidBatch.Draw();
    
    // 7.模型视图出栈，恢复矩阵（push一次就要pop一次）
    modelViewMatrix.PopMatrix();
    
    // 8.交换缓存区
    glutSwapBuffers();
}

void ChangeSize(int w, int h)
{
    glViewport(0, 0, w, h);
    viewFrustum.SetPerspective(35.0f, float(w) / float(h), 1.0f, 500.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpecialKeys(int key, int x, int y)
{
    if(key == GLUT_KEY_UP) objectFrame.RotateWorld(m3dDegToRad(-5.0f), 1.0f, 0.0f, 0.0f);
    if(key == GLUT_KEY_DOWN) objectFrame.RotateWorld(m3dDegToRad(5.0f), 1.0f, 0.0f, 0.0f);
    if(key == GLUT_KEY_LEFT) objectFrame.RotateWorld(m3dDegToRad(-5.0f), 0.0f, 1.0f, 0.0f);
    if(key == GLUT_KEY_RIGHT) objectFrame.RotateWorld(m3dDegToRad(5.0f), 0.0f, 1.0f, 0.0f);
    
    glutPostRedisplay();
}

// 进行清理，例如删除纹理对象
void ShutdownRC(void)
{
    glDeleteTextures(1, &textureID);
}

int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("Pyramid");
    glutReshapeFunc(ChangeSize);
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
    
    ShutdownRC();
    
    return 0;
}
