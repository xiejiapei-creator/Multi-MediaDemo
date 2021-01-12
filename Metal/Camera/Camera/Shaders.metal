//
//  Shaders.metal
//  Camera
//
//  Created by 谢佳培 on 2021/1/12.
//
#import "ShaderTypes.h"
#include <metal_stdlib>
using namespace metal;

// 结构体(用于顶点函数输出/片元函数输入)
typedef struct
{
    float4 clipSpacePosition [[position]];// position修饰符表示这个是顶点
    float2 textureCoordinate;// 纹理坐标
} RasterizerData;


// 顶点函数
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant Vertex *vertexArray [[ buffer(VertexInputIndexVertices) ]])
{
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;// 顶点坐标
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;// 纹理坐标
    return out;
}

// 片源函数
fragment float4
samplingShader(RasterizerData input [[stage_in]],
               texture2d<float> textureY [[ texture(FragmentTextureIndexTextureY) ]],
               texture2d<float> textureUV [[ texture(FragmentTextureIndexTextureUV) ]],
               constant ConvertMatrix *convertMatrix [[ buffer(FragmentInputIndexMatrix) ]])
{
    // 获取纹理采样器
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    // 读取YUV颜色值
    float3 yuv = float3(textureY.sample(textureSampler, input.textureCoordinate).r,
                        textureUV.sample(textureSampler, input.textureCoordinate).rg);
    
    // 将YUV颜色值转化为RGB颜色值
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    
    // 返回RGBA颜色值
    return float4(rgb, 1.0);
}

