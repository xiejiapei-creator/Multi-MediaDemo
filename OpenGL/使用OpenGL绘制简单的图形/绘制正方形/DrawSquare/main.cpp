//
//  main.cpp
//  DrawSquare
//
//  Created by 谢佳培 on 2020/12/31.
//

#include <stdio.h>
#include "GLShaderManager.h"
#include "GLTools.h"
#include <GLUT/GLUT.h>

GLShaderManager shaderManager;
GLBatch triangleBatch;

// blockSize 边长的一半（正方形顶点到Y的距离）
GLfloat blockSize = 0.1f;

// 正方形的4个点坐标
GLfloat vVerts[] =
{
    -blockSize,-blockSize,0.0f,
    blockSize,-blockSize,0.0f,
    blockSize,blockSize,0.0f,
    -blockSize,blockSize,0.0f
};

void ChangeSize(int w,int h)
{
    glViewport(0,0, w, h);
}

// 设置用于渲染的数据
void SetupRC()
{
    glClearColor(0.0f,0.0f,1.0f,1.0f);

    shaderManager.InitializeStockShaders();

    // 修改为GL_TRIANGLE_FAN ，4个顶点
    triangleBatch.Begin(GL_TRIANGLE_FAN,4);
    triangleBatch.CopyVertexData3f(vVerts);
    triangleBatch.End();
}

// 开始渲染
void RenderScene(void)
{
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

    GLfloat vRed[] = {1.0f,0.0f,0.0f,1.0f};
    
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY,vRed);

    triangleBatch.Draw();

    glutSwapBuffers();
}

// 特殊键位响应函数
void SpecialKeys(int key, int x, int y)
{
    // 移动步⻓
    GLfloat stepSize = 0.025f;
    // 相对移动顶点D
    GLfloat blockX = vVerts[0];
    GLfloat blockY = vVerts[10];
    
    printf("v[0] = %f\n",blockX);
    printf("v[10] = %f\n",blockY);
    
    // 根据键盘标记判断此时正方形移动⽅向(上下左右)
    // 然后根据方向调整相对移动坐标(blockX/blockY)值
    if (key == GLUT_KEY_UP)// 上
    {
        blockY += stepSize;
    }
    
    if (key == GLUT_KEY_DOWN)// 下
    {
        blockY -= stepSize;
    }
    
    if (key == GLUT_KEY_LEFT)// 左
    {
        blockX -= stepSize;
    }
    
    if (key == GLUT_KEY_RIGHT)// 右
    {
        blockX += stepSize;
    }

    // 触碰到边界（4个边界）的处理
    // 当正方形移动超过最左边的时候
    if (blockX < -1.0f)
    {
        blockX = -1.0f;
    }
    
    // 当正方形移动到最右边时
    // 1.0 - blockSize * 2 = 总边长 - 正方形的边长 = 最左边点的位置
    if (blockX > (1.0 - blockSize * 2))
    {
        blockX = 1.0f - blockSize * 2;
    }
    
    // 当正方形移动到最下面时
    // -1.0 - blockSize * 2 = Y（负轴边界） - 正方形边长 = 最下面点的位置
    if (blockY < -1.0f + blockSize * 2 )
    {
        blockY = -1.0f + blockSize * 2;
    }
    
    // 当正方形移动到最上面时
    if (blockY > 1.0f)
    {
        blockY = 1.0f;
    }

    printf("blockX = %f\n",blockX);
    printf("blockY = %f\n",blockY);
    
    // 根据相对顶点D计算出ABCD每个顶点坐标值
    vVerts[0] = blockX;
    vVerts[1] = blockY - blockSize*2;
    printf("(%f,%f)\n",vVerts[0],vVerts[1]);
    
    vVerts[3] = blockX + blockSize*2;
    vVerts[4] = blockY - blockSize*2;
    printf("(%f,%f)\n",vVerts[3],vVerts[4]);
    
    vVerts[6] = blockX + blockSize*2;
    vVerts[7] = blockY;
    printf("(%f,%f)\n",vVerts[6],vVerts[7]);
    
    vVerts[9] = blockX;
    vVerts[10] = blockY;
    printf("(%f,%f)\n",vVerts[9],vVerts[10]);
    
    // 更新顶点坐标数组
    triangleBatch.CopyVertexData3f(vVerts);
    
    // 手动触发重新渲染
    glutPostRedisplay();
}

// 程序入口函数
int main(int argc,char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    glutInitWindowSize(800,600);
    glutCreateWindow("Square");
    
    glutReshapeFunc(ChangeSize);
    glutDisplayFunc(RenderScene);

    // 注册特殊键位响应函数
    glutSpecialFunc(SpecialKeys);

    GLenum err = glewInit();
    if(GLEW_OK != err)
    {
        fprintf(stderr,"glew error:%s\n",glewGetErrorString(err));
        return 1;
    }

    SetupRC();

    glutMainLoop();
    
    return 0;
}
