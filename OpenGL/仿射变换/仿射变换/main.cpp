//
//  main.cpp
//  仿射变换
//
//  Created by 谢佳培 on 2021/1/3.
//

#include "GLTools.h"
#include "GLShaderManager.h"
#include "math3d.h"

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

GLBatch    squareBatch;
GLShaderManager    shaderManager;

GLfloat blockSize = 0.1f;
GLfloat vVerts[] = {
    -blockSize, -blockSize, 0.0f,
    blockSize, -blockSize, 0.0f,
    blockSize,  blockSize, 0.0f,
    -blockSize,  blockSize, 0.0f};

// 在x、y轴上移动的距离
GLfloat xPos = 0.0f;
GLfloat yPos = 0.0f;

void SetupRC()
{
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f );
    shaderManager.InitializeStockShaders();
    
    squareBatch.Begin(GL_TRIANGLE_FAN, 4);
    squareBatch.CopyVertexData3f(vVerts);
    squareBatch.End();
}

void RenderScene(void)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    GLfloat vRed[] = { 1.0f, 0.0f, 0.0f, 1.0f };
    
    // 平移、旋转、最终矩阵
    M3DMatrix44f mFinalTransform, mTranslationMatrix, mRotationMatrix;
    
    // 根据xPos,yPos进行平移，每一个顶点都乘以平移矩阵
    m3dTranslationMatrix44(mTranslationMatrix, xPos, yPos, 0.0f);
    
    // 每次重绘时，旋转5度
    static float yRot = 0.0f;
    yRot += 5.0f;
    m3dRotationMatrix44(mRotationMatrix, m3dDegToRad(yRot), 0.0f, 0.0f, 1.0f);
    
    // 将旋转和移动的结果合并到mFinalTransform中（矩阵叉乘）
    m3dMatrixMultiply44(mFinalTransform, mTranslationMatrix, mRotationMatrix);
    
    // 将矩阵结果提交到固定着色器（平面着色器）中
    shaderManager.UseStockShader(GLT_SHADER_FLAT, mFinalTransform, vRed);
    squareBatch.Draw();
    
    // 执行缓冲区交换
    glutSwapBuffers();
}

// 移动
void SpecialKeys(int key, int x, int y)
{
    // 移动的步长
    GLfloat stepSize = 0.025f;
    
    // 上下左右移动
    if(key == GLUT_KEY_UP) yPos += stepSize;
    if(key == GLUT_KEY_DOWN) yPos -= stepSize;
    if(key == GLUT_KEY_LEFT) xPos -= stepSize;
    if(key == GLUT_KEY_RIGHT) xPos += stepSize;
        
    // 检测是否碰撞边界
    if(xPos < (-1.0f + blockSize)) xPos = -1.0f + blockSize;
    if(xPos > (1.0f - blockSize)) xPos = 1.0f - blockSize;
    if(yPos < (-1.0f + blockSize)) yPos = -1.0f + blockSize;
    if(yPos > (1.0f - blockSize)) yPos = 1.0f - blockSize;
    
    glutPostRedisplay();
}

void ChangeSize(int w, int h)
{
    glViewport(0, 0, w, h);
}

int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
    glutInitWindowSize(600, 600);
    glutCreateWindow("Move Block with Arrow Keys");
    
    GLenum err = glewInit();
    if (GLEW_OK != err)
    {
        
        fprintf(stderr, "Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    glutReshapeFunc(ChangeSize);
    glutDisplayFunc(RenderScene);
    glutSpecialFunc(SpecialKeys);
    
    SetupRC();
    
    glutMainLoop();
    return 0;
}
