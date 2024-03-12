//定义与光照相关的物体表面属性
//HLSL编译保护机制
#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

//物体表面属性，该结构体在片元着色器中被构建
struct Surface
{
    float3 position;
    float3 normal;
    float3 viewDirection;
    float depth;
    float3 color;
    float alpha;
    float metallic;
    float smoothness;
    float dither;
};

#endif