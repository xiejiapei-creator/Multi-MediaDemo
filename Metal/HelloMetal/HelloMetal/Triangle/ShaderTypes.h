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
    //vector_float4 color;// RGBA颜色，在运行纹理Demo的时候需要注释掉，否则出错
    vector_float2 textureCoordinate;// 2D纹理
} Vertex;

// 纹理索引
typedef enum TextureIndex
{
    TextureIndexBaseColor = 0 //0表示只有一个纹理
} TextureIndex;


#endif /* ShaderTypes_h */
