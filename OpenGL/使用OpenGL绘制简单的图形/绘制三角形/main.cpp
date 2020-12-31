//
//  main.cpp
//  Demo
//
//  Created by 谢佳培 on 2020/12/31.
//

#include <stdio.h>
// 引入了GLTool着色器管理器类（shader Mananger）
// 没有着色器，我们就不能在OpenGL（核心框架）进行着色
#include "GLShaderManager.h"
// GLTool.h头文件包含了大部分GLTool中类似C语言的独立函数
#include "GLTools.h"
#include <GLUT/GLUT.h>

// 定义一个着色管理器
GLShaderManager shaderManager;

// 简单的批次容器，是GLTools的一个简单的容器类
GLBatch triangleBatch;

// 设置用于渲染的数据
void SetupRC()
{
    // 设置清屏颜色（背景颜色）
    glClearColor(0.0f,0.0f,1.0f,1.0f);
    
    // 没有着色器，在OpenGL 核心框架中是无法进行任何渲染的，所以需要初始化一个渲染管理器
    // 这里采用固管线渲染，后面会学着用OpenGL着色语言来写着色器
    shaderManager.InitializeStockShaders();
    
    // 设置三角形，其中数组vVert包含3个顶点的x,y,z
    GLfloat vVerts[] =
    {
        -0.5f,0.0f,0.0f,
        0.5f,0.0f,0.0f,
        0.0f,0.5f,0.0f,
    };
    
    // 批次处理将三角形数据传递到着色器
    triangleBatch.Begin(GL_TRIANGLES,3);
    triangleBatch.CopyVertexData3f(vVerts);
    triangleBatch.End();
}

// 开始渲染
void RenderScene(void)
{
    // 清除一个或一组特定的缓冲区
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
    
    // 设置一组浮点数来表示红色
    GLfloat vRed[] = {1.0f,0.0f,0.0f,1.0f};
    
    // 传递到存储着色器，即GLT_SHADER_IDENTITY代表着色器，这个着色器只是使用指定颜色以默认笛卡尔坐标第在屏幕上渲染几何图形
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY,vRed);
    
    // 提交着色器
    triangleBatch.Draw();
    
    // 将在后台缓冲区进行渲染，然后在结束时交换到前台
    glutSwapBuffers();
}

// 新建窗口或者窗口大小改变时触发，用来设置新的宽度和高度
// 其中0,0代表窗口中视口的左下角坐标
void ChangeSize(int w,int h)
{
    glViewport(0,0, w, h);
}

// 主入口函数
int main(int argc,char* argv[])
{
    // 设置当前工作目录，针对MAC OS X
    gltSetWorkingDirectory(argv[0]);
    
    // 传入命令参数初始化GLUT库
    glutInit(&argc, argv);
    
    // 初始化双缓冲窗口，其中标志GLUT_DOUBLE、GLUT_RGBA、GLUT_DEPTH、GLUT_STENCIL分别指双缓冲窗口、RGBA颜色模式、深度测试、模板缓冲区
    // 双缓存窗口 GLUT_DOUBLE：指绘图命令实际上是离屏缓存区执行的，然后迅速转换成窗口视图，这种方式经常用来生成动画效果
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    
    // GLUT窗口大小
    glutInitWindowSize(800,600);
    // GLUT窗口标题
    glutCreateWindow("Triangle");
    
    // GLUT 内部运行一个本地消息循环，拦截适当的消息，然后调用我们注册的回调函数
    // 注册窗口改变大小的重塑函数
    glutReshapeFunc(ChangeSize);
    // 注册显示函数
    glutDisplayFunc(RenderScene);
    
    // 初始化一个GLEW库，确保OpenGL API对程序完全可用
    GLenum err = glewInit();
    
    // 在试图做任何渲染之前，要检查驱动程序的初始化中没有出现任何问题
    if(GLEW_OK != err)
    {
        fprintf(stderr,"glew error:%s\n",glewGetErrorString(err));
        return 1;
    }
    
    // 设置用于渲染的数据
    SetupRC();
    
    // 类似于iOS runloop 运⾏循环
    glutMainLoop();
    
    return 0;
}









