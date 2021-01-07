varying lowp vec4 varyColor;// 从顶点着色器传过来的颜色
void main()
{
    gl_FragColor = varyColor;// 将颜色值给着色器
}
