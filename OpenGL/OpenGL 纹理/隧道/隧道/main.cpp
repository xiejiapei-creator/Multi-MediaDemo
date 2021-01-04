//
//  main.cpp
//  隧道
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
GLFrustum            viewFrustum;
GLGeometryTransform    transformPipeline;

// 4个批次容器类
GLBatch             floorBatch;//地面
GLBatch             ceilingBatch;//天花板
GLBatch             leftWallBatch;//左墙面
GLBatch             rightWallBatch;//右墙面

#define TEXTURE_BRICK   0 //墙面
#define TEXTURE_FLOOR   1 //地板
#define TEXTURE_CEILING 2 //纹理天花板
#define TEXTURE_COUNT   3 //纹理个数

// 深度初始值为-65
GLfloat             viewZ = -65.0f;

// 纹理标记数组
GLuint  textures[TEXTURE_COUNT];

// 文件tag名字数组
const char *szTextureFiles[TEXTURE_COUNT] = { "brick.tga", "floor.tga", "ceiling.tga" };

//=====================================================

void SetupRC()
{
    glClearColor(0.0f, 0.0f, 0.0f,1.0f);// 黑色的背景
    shaderManager.InitializeStockShaders();
    
    GLbyte *pBytes;
    GLint iWidth, iHeight, iComponents;
    GLenum eFormat;
    GLint iLoop;
    
    // 1.分配纹理对象
    glGenTextures(TEXTURE_COUNT, textures);
    
    // 2.循环设置纹理数组的纹理参数
    for(iLoop = 0; iLoop < TEXTURE_COUNT; iLoop++)
    {
        // 绑定纹理对象
        glBindTexture(GL_TEXTURE_2D, textures[iLoop]);
        
        // 加载tga文件
        pBytes = gltReadTGABits(szTextureFiles[iLoop],&iWidth, &iHeight, &iComponents, &eFormat);
        
        // 加载纹理、设置过滤器和包装模式
        // 放大过滤器、最邻近过滤
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        // 缩小过滤器、最邻近过滤
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        // s轴环绕、环绕模式强制对范围之外的纹理坐标沿着合法的纹理单元的最后一行或一列进行采样
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        // t轴环绕、环绕模式强制对范围之外的纹理坐标沿着合法的纹理单元的最后一行或一列进行采样
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        // 载入纹理 glTexImage2D
        glTexImage2D(GL_TEXTURE_2D, 0, iComponents, iWidth, iHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBytes);
        
        // 为纹理对象生成一组完整的mipmap
        glGenerateMipmap(GL_TEXTURE_2D);
        
        // 释放原始纹理数据，不在需要纹理原始数据了
        free(pBytes);
    }
    
    // 3.设置图形上下左右各面的顶点/纹理坐标
    GLfloat z;// 隧道的深度
    floorBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);

    // 地板墙面
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        floorBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        floorBatch.Vertex3f(-10.0f, -10.0f, z);
        
        floorBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        floorBatch.Vertex3f(10.0f, -10.0f, z);
        
        floorBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        floorBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
        
        floorBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        floorBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
    }
    floorBatch.End();
    
    // 天花板墙面
    ceilingBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        ceilingBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        ceilingBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
        
        ceilingBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        ceilingBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
        
        ceilingBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        ceilingBatch.Vertex3f(-10.0f, 10.0f, z);
        
        ceilingBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        ceilingBatch.Vertex3f(10.0f, 10.0f, z);
    }
    ceilingBatch.End();
    
    // 左面墙面
    leftWallBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        leftWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        leftWallBatch.Vertex3f(-10.0f, -10.0f, z);
        
        leftWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        leftWallBatch.Vertex3f(-10.0f, 10.0f, z);
        
        leftWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        leftWallBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
        
        leftWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        leftWallBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
    }
    leftWallBatch.End();
    
    // 右面墙面
    rightWallBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        rightWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        rightWallBatch.Vertex3f(10.0f, -10.0f, z);
        
        rightWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        rightWallBatch.Vertex3f(10.0f, 10.0f, z);
        
        rightWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        rightWallBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
        
        rightWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        rightWallBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
    }
    rightWallBatch.End();
}

void RenderScene(void)
{
    // 用当前清除色，清除窗口
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 模型视图压栈
    modelViewMatrix.PushMatrix();
    
    // 1.在Z轴上平移viewZ距离
    modelViewMatrix.Translate(0.0f, 0.0f, viewZ);
    
    // 2.纹理替换矩阵着色器
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_REPLACE, transformPipeline.GetModelViewProjectionMatrix(), 0);
    
    // 3.绑定纹理
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_FLOOR]);
    floorBatch.Draw();
    
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_CEILING]);
    ceilingBatch.Draw();
    
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_BRICK]);
    leftWallBatch.Draw();
    
    rightWallBatch.Draw();
    
    // 模型视图出栈
    modelViewMatrix.PopMatrix();
    
    // 缓存区交换
    glutSwapBuffers();
}

void ChangeSize(int w, int h)
{
    if(h == 0) h = 1;

    glViewport(0, 0, w, h);
    
    // 生成透视投影
    GLfloat fAspect = (GLfloat)w/(GLfloat)h;
    viewFrustum.SetPerspective(80.0f,fAspect,1.0,120.0);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

// 前后移动视口来对方向键作出响应
void SpecialKeys(int key, int x, int y)
{
    // 移动的是深度值，Z
    if(key == GLUT_KEY_UP) viewZ += 0.5f;
    if(key == GLUT_KEY_DOWN) viewZ -= 0.5f;
    
    // 更新窗口，即可回调到RenderScene函数里
    glutPostRedisplay();
}

// 关闭渲染环境
void ShutdownRC(void)
{
    // 删除纹理
    glDeleteTextures(TEXTURE_COUNT, textures);
}

// 菜单栏选择
void ProcessMenu(int value)
{
    GLint iLoop;
    
    for(iLoop = 0; iLoop < TEXTURE_COUNT; iLoop++)
    {
        // 绑定纹理
        glBindTexture(GL_TEXTURE_2D, textures[iLoop]);
        
        // 配置纹理参数
        switch(value)
        {
            case 0:
                // 缩小过滤器、最邻近过滤
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                break;
                
            case 1:
                // 缩小过滤器、线性过滤
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                break;
                
            case 2:
                // 缩小过滤器、选择最邻近的Mip层，并执行最邻近过滤
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
                break;
                
            case 3:
                // 缩小过滤器、在Mip层之间执行线性插补，并执行最邻近过滤
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
                break;
                
            case 4:
                // 缩小过滤器、选择最邻近Mip层，并执行线性过滤
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
                break;
                
            case 5:
                // 缩小过滤器、在Mip层之间执行线性插补，并执行线性过滤，又称为三线性过滤
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                break;
                
            case 6:
            
                // 设置各向异性过滤
                GLfloat fLargest;
                // 获取各向异性过滤的最大数量
                glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &fLargest);
                // 设置纹理参数(各向异性采样)
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, fLargest);
                break;
        
            case 7:
                // 设置各向同性过滤，数量为1.0表示(各向同性采样)
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1.0f);
                break;
        }
    }
    
    // 触发重画
    glutPostRedisplay();
}

int main(int argc, char *argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
    glutInitWindowSize(800, 600);
    glutCreateWindow("Tunnel");
    glutReshapeFunc(ChangeSize);
    glutSpecialFunc(SpecialKeys);
    glutDisplayFunc(RenderScene);
    
    // 添加菜单入口，改变过滤器
    glutCreateMenu(ProcessMenu);
    glutAddMenuEntry("GL_NEAREST",0);
    glutAddMenuEntry("GL_LINEAR",1);
    glutAddMenuEntry("GL_NEAREST_MIPMAP_NEAREST",2);
    glutAddMenuEntry("GL_NEAREST_MIPMAP_LINEAR", 3);
    glutAddMenuEntry("GL_LINEAR_MIPMAP_NEAREST", 4);
    glutAddMenuEntry("GL_LINEAR_MIPMAP_LINEAR", 5);
    glutAddMenuEntry("Anisotropic Filter", 6);
    glutAddMenuEntry("Anisotropic Off", 7);
    glutAttachMenu(GLUT_RIGHT_BUTTON);
    
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
