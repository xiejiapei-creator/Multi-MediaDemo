#import "ShaderTypes.h"
#include <metal_stdlib>
using namespace metal;// 使用命名空间 Metal

/*
// 顶点着色器输出数据和片段着色器输入数据
typedef struct
{
    // 处理空间的顶点信息 position指的是顶点裁剪后的位置
    float4 clipSpacePosition [[position]];
    float4 color;// float4表示4维向量 颜色

} RasterizerData;

// 顶点着色函数
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]])
{
    // 定义out
    RasterizerData out;

    // 初始化输出剪辑空间位置
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);

    // 索引到我们的数组位置以获得当前顶点
    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    // 将vierportSizePointer从verctor_uint2转换为vector_float2类型
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);

    // 计算和写入 XY 值到我们的剪辑空间的位置
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);

    // 把我们输入的颜色直接赋值给输出颜色
    out.color = vertices[vertexID].color;

    // 完成! 将结构体传递到管道中下一个阶段
    return out;
}

// 片元函数
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // 返回输入的片元的颜色
    return in.color;
}
*/

// 一个项目里面只能有一个Tga文件
//=============加载Tga文件的修改版==========

// 顶点着色器输出数据和片段着色器输入数据
typedef struct
{
    // 处理空间的顶点信息 position指的是顶点裁剪后的位置
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;// 2维纹理坐标

} RasterizerData;

// 顶点着色函数
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]])
{
    // 定义out
    RasterizerData out;

    // 初始化输出剪辑空间位置
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);

    // 索引到我们的数组位置以获得当前顶点
    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    // 将vierportSizePointer从verctor_uint2转换为vector_float2类型
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);

    // 计算和写入 XYZW 值到我们的剪辑空间的位置
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.clipSpacePosition.z = 0.0f;
    out.clipSpacePosition.w = 1.0f;
    
    // 把输入的纹理坐标直接赋值给输出纹理坐标
    out.textureCoordinate = vertices[vertexID].textureCoordinate;

    // 完成! 将结构体传递到管道中下一个阶段
    return out;
}

// 片元函数
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[texture(TextureIndexBaseColor)]])
{
    // 设置纹理的属性。放大和缩小的过滤方式为线性（非邻近过滤）
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear);
    // 获取对应坐标下的纹理颜色值
    const half4 colorSampler = colorTexture.sample(textureSampler,in.textureCoordinate);
    
    // 输出颜色值
    return float4(colorSampler);
}

