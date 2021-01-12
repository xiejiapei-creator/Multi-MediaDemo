//
//  ShaderTypes.h
//  Camera
//
//  Created by 谢佳培 on 2021/1/12.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h
#include <simd/simd.h>

// 顶点数据结构
typedef struct
{
    vector_float4 position;// 顶点坐标(x,y,z,w)
    vector_float2 textureCoordinate;// 纹理坐标(s,t)
} Vertex;

// 转换矩阵
typedef struct
{
    matrix_float3x3 matrix;// 三维矩阵
    vector_float3 offset;// 偏移量
} ConvertMatrix;

// 顶点函数输入索引
typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
} VertexInputIndex;

// 片元函数缓存区索引
typedef enum FragmentBufferIndex
{
    FragmentInputIndexMatrix     = 0,
} FragmentBufferIndex;

// 片元函数纹理索引
typedef enum FragmentTextureIndex
{
    FragmentTextureIndexTextureY     = 0,// Y纹理
    FragmentTextureIndexTextureUV     = 1,// UV纹理
} FragmentTextureIndex;

#endif /* ShaderTypes_h */
