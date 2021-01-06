attribute vec4 position;
attribute vec2 textCoordinate;// 纹理坐标
varying lowp vec2 varyTextCoord;// 用来作顶点和片源着色器中间传递的过渡值

void main()
{
    //varyTextCoord = textCoordinate;
    varyTextCoord = vec2(textCoordinate.x,1.0-textCoordinate.y);
    gl_Position = position;
}
