//
//  ShaderTypes.h
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/10.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// 缓存区索引值
typedef enum VertexInputIndex
{
    VertexInputIndexVertices = 0,// 顶点
    VertexInputIndexViewportSize = 1,// 视图大小
} VertexInputIndex;

// 顶点
typedef struct
{
    vector_float2 position;// 像素空间的位置，比如像素中心点(100,100)
    vector_float4 color;// RGBA颜色
} Vertex;


#endif /* ShaderTypes_h */
