//存储Shader中的一些常用的输入数据
#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED

//这三个变量也使用CBUFFER，使用UnityPerDraw命名该Buffer（UnityPerDraw为Unity内置好的名字）
CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
//在定义（UnityPerDraw）CBuffer时，因为Unity对一组相关数据都归到一个Feature中，即使我们没用到unity_LODFade，我们也需要放到这个CBuffer中来构造一个完整的Feature
//如果不加这个unity_LODFade，不能支持SRP Batcher
float4 unity_LODFade;
real4 unity_WorldTransformParams;
//采样 Shadowmask
float4 unity_ProbesOcclusion;
//采样 Lightmap
float4 unity_LightmapST;
float4 unity_DynamicLightmapST;
//采样Light Probe
float4 unity_SHAr;
float4 unity_SHAg;
float4 unity_SHAb;
float4 unity_SHBr;
float4 unity_SHBg;
float4 unity_SHBb;
float4 unity_SHC;
//采样LPPV
float4 unity_ProbeVolumeParams;
float4x4 unity_ProbeVolumeWorldToObject;
float4 unity_ProbeVolumeSizeInv;
float4 unity_ProbeVolumeMin;
CBUFFER_END

float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 unity_MatrixInvV;
float4x4 unity_prev_MatrixM;
float4x4 unity_prev_MatrixIM;
float4x4 glstate_matrix_projection;

float3 _WorldSpaceCameraPos;

#endif