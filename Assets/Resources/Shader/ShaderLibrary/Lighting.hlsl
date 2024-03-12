//用来存放计算光照相关的方法
//HLSL编译保护机制
#ifndef CUSTOM_LIGHTING_INCLUDE
#define CUSTON_LIGHTING_INCLUDE

//计算物体表面接收到的光能量
float3 IncomingLight(Surface surface, Light light)
{
    return light.attenuation;//saturate(dot(surface.normal, light.direction) * light.attenuation) * light.color;
}

float3 GetLighting(Surface surface, BRDF brdf, Light light)
{
    return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

float3 GetLighting(Surface surfaceWS, BRDF brdf)
{
    ShadowData shadowData = GetShadowData(surfaceWS);
    float3 color = 0.0;
    for (int i = 0; i < GetDirectionalLightCount(); i++)
    {
        Light light = GetDirectionalLight(i, surfaceWS, shadowData);
        color += GetLighting(surfaceWS, brdf, light);
    }
    return color;
}

#endif