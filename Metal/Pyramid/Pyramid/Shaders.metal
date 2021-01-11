//
//  Shaders.metal
//  Pyramid
//
//  Created by 谢佳培 on 2021/1/11.
//
#import "ShaderTypes.h"
#include <metal_stdlib>
using namespace metal;

typedef struct
{
    // 处理空间的顶点信息。position是默认属性修饰符，用来指定顶点
    float4 clipSpacePosition [[position]];
    // 颜色
    float3 pixelColor;
    // 纹理坐标
    float2 textureCoordinate;
} RasterizerData;

// 顶点函数
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant Vertex *vertexArray [[ buffer(VertexInputIndexVertices) ]],
             constant Matrix *matrix [[ buffer(VertexInputIndexMatrix) ]])
{
    // 定义输出
    RasterizerData out;
    // 计算裁剪空间坐标 = 投影矩阵 * 模型视图矩阵 * 顶点
    out.clipSpacePosition = matrix->projectionMatrix * matrix->modelViewMatrix * vertexArray[vertexID].position;
    // 纹理坐标
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    // 像素颜色值
    out.pixelColor = vertexArray[vertexID].color;
    
    return out;
}

// 片元函数
fragment float4
samplingShader(RasterizerData input [[stage_in]],
               texture2d<half> textureColor [[ texture(FragmentInputIndexTexture) ]])
{
    // 颜色值 从三维变量RGB -> 四维变量RGBA
    // half4 colorTex = half4(input.pixelColor.x, input.pixelColor.y, input.pixelColor.z, 1);
 
    constexpr sampler textureSampler (mag_filter::linear ,min_filter::linear);
    half4 colorTex = textureColor.sample(textureSampler, input.textureCoordinate);
    
    // 返回颜色
    return float4(colorTex);
}

 
