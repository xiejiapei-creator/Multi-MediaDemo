attribute vec4 position;// 每个点
attribute vec4 positionColor;// 每个点的颜色

uniform mat4 projectionMatrix;// 立体图形的投影矩阵
uniform mat4 modelViewMatrix;// 模型视图矩阵用来旋转

varying lowp vec4 varyColor;// 将颜色传递到片段着色器

void main()
{
    varyColor = positionColor;
    
    vec4 vPos;// 传递计算后的顶点
    vPos = projectionMatrix * modelViewMatrix * position;
    gl_Position = vPos;
}
