//
//  ShaderTypes.h
//  Pyramid
//
//  Created by 谢佳培 on 2021/1/11.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h
#include <simd/simd.h> // 连接OC与Metal之间的桥梁

// 顶点数据结构
typedef struct
{
    vector_float4 position;          //顶点 xyzw
    vector_float3 color;             //颜色 rgb
    vector_float2 textureCoordinate; //纹理坐标 xy
} Vertex;

// 矩阵结构体
typedef struct
{
    matrix_float4x4 projectionMatrix; //投影矩阵
    matrix_float4x4 modelViewMatrix;  //模型视图矩阵
} Matrix;


// 输入索引
typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0, //顶点坐标索引
    VertexInputIndexMatrix       = 1, //矩阵索引
} VertexInputIndex;


// 片元着色器索引
typedef enum FragmentInputIndex
{
    FragmentInputIndexTexture     = 0,//片元输入纹理索引
} FragmentInputIndex;


#endif /* ShaderTypes_h */
