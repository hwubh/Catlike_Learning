#ifndef UNIVERSAL_TERRAIN_VT_GENERATOR_PASSES_INCLUDED
#define UNIVERSAL_TERRAIN_VT_GENERATOR_PASSES_INCLUDED

//------------------------------------- 宏定义 -------------------------------------//
//#define _SPECULAR_SETUP
#define _NORMALMAP
#define _WORLDSPACETEXMAPPING

#if defined(_NORMALMAP)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

//------------------------------------- 文件引用 -------------------------------------//
#include "TerrainVTUtils.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#ifdef _GBUFFER_PASS
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
#endif
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

//------------------------------------- 材质属性 -------------------------------------//
CBUFFER_START(UnityPerMaterial)
float4 _PositionOffset;
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _SpecColor;
float _MeshTilling;
float _BiomeId;

half4 _Layer01TexColor;
half _Layer01TexScale;
half _Layer01NormalScale;

half4 _Layer02TexColor;
half _Layer02TexScale;
half _Layer02NormalScale;

half4 _Layer03TexColor;
half _Layer03TexScale;
half _Layer03NormalScale;

half4 _Layer04TexColor;
half _Layer04TexScale;
half _Layer04NormalScale;

half4 _Layer05TexColor;
half _Layer05TexScale;
half _Layer05NormalScale;

half4 _Layer06TexColor;
half _Layer06TexScale;
half _Layer06NormalScale;

half4 _Layer07TexColor;
half _Layer07TexScale;
half _Layer07NormalScale;

half4 _Layer08TexColor;
half _Layer08TexScale;
half _Layer08NormalScale;

half _Cutoff;
half _TerrainSize;
float _TerrainLocalScale;

//#if defined  CNC_TERRAIN_BLEND_HEIGHT
half _BlendThreshold;
half _CustomSmoothness;
//#endif

#if defined  CNC_TERRAIN_LOCAL_POSITION
half _UvOffsetU;
half _UvOffsetV;
#endif

CBUFFER_END

TEXTURE2D(_IndexMap);
SAMPLER(sampler_IndexMap);

TEXTURE2D_ARRAY(_MaskMap);
SAMPLER(sampler_MaskMap);

TEXTURE2D(_SmoothnessMap);
SAMPLER(sampler_SmoothnessMap);

TEXTURE2D_ARRAY(_BaseColorArray);
SAMPLER(sampler_BaseColorArray);

TEXTURE2D(_MaskMap01);
SAMPLER(sampler_MaskMap01);
TEXTURE2D(_MaskMap02);
SAMPLER(sampler_MaskMap02);

//------------------------------------- 顶点片源结构 -------------------------------------//
struct LandscapeLayer_Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct LandscapeLayer_Varyings
{
    float2 uv : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

    float3 positionWS : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float4 tangentWS : TEXCOORD4; // xyz: tangent, w: sign
    float3 viewDirWS : TEXCOORD5;

    half4 fogFactorAndVertexLight : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    float3 viewDirTS                : TEXCOORD8;
#endif

    float3 bitangentWS  : TEXCOORD9;

#if defined  CNC_TERRAIN_LOCAL_POSITION
    float3 positionOS : TEXCOORD10;
#endif

    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
};

//------------------------------------- 自定义函数 -------------------------------------//
void GetLayersBlendMask(int BlendLayerCount,
    half2 uv, float3 PositionWS,
    inout half mask_layers[8])
{
#if defined(CNC_TERRAIN_LOCAL_POSITION)
    half2 worldUv = _TerrainLocalScale * PositionWS.xz / _TerrainSize + half2(_UvOffsetU, _UvOffsetV);
#else
    half2 worldUv = PositionWS.xz / _TerrainSize;
#endif

    half4 maskA = SAMPLE_TEXTURE2D(_MaskMap01, sampler_MaskMap01, worldUv);
    half4 maskB = SAMPLE_TEXTURE2D(_MaskMap02, sampler_MaskMap02, worldUv);

    float summask = max(dot(maskA, half4(1, 1, 1, 1)) + dot(maskB, half4(1, 1, 1, 1)), 1e-6);
    maskA = maskA / summask;
    maskB = maskB / summask;

    half mask_layers_T[8] = { maskA.r, maskA.g, maskA.b, maskA.a, maskB.r, maskB.g, maskB.b, maskB.a };
    mask_layers = mask_layers_T;
}


void BlendLayers_Weight_Simple(half2 uv, float3 PositionWS,
    inout half4 color,
    inout half3 normal,
    inout half4 surface)
{
    //Shader Feature
    int BlendLayerCount = 8;

    half L_layerTexScales[8] =
    {
        _Layer01TexScale,_Layer02TexScale,_Layer03TexScale,_Layer04TexScale,
        _Layer05TexScale,_Layer06TexScale,_Layer07TexScale,_Layer08TexScale
    };

    half L_layerNormalScales[8] =
    {
        _Layer01NormalScale, _Layer02NormalScale, _Layer03NormalScale, _Layer04NormalScale,
        _Layer05NormalScale, _Layer06NormalScale, _Layer07NormalScale,_Layer08NormalScale
    };

    half4 L_layerTexColors[8] =
    {
        _Layer01TexColor,_Layer02TexColor,_Layer03TexColor,_Layer04TexColor,
        _Layer05TexColor,_Layer06TexColor,_Layer07TexColor,_Layer08TexColor
    };

    half layerMasks[8];
    GetLayersBlendMask(BlendLayerCount, uv, PositionWS, layerMasks);

    color = half4(0, 0, 0, 0);
    normal = half3(0, 0, 1);
    surface = half4(0, 0, 0, 0);

    for (int i = 0; i < BlendLayerCount; i++)
    {
        half tilling = _TerrainSize / L_layerTexScales[i].x;

#if defined  CNC_TERRAIN_LOCAL_POSITION
        half2 uv_world = _TerrainLocalScale * PositionWS.xz / _TerrainSize * tilling.xx;
#else
        half2 uv_world = PositionWS.xz / _TerrainSize * tilling.xx;
#endif

        half4 color_01 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, i, -1);
        color += layerMasks[i] * color_01 * L_layerTexColors[i];

#if defined  CNC_NORMAL_TEXTURE_ARRAY
        half4 normal_mix = SAMPLE_TEXTURE2D_ARRAY_BIAS(_NormalArray, sampler_NormalArray, uv_world, i, -1);
        half3 normal_01 = UnpackNormalScale(normal_mix, L_layerNormalScales[i]);
        normal += layerMasks[i] * normal_01;
#endif

#if defined CNC_NORMAL_TEXTURE_ARRAY && CNC_USE_NORMAL_SMOOTHNESS
        surface += layerMasks[i] * half4(0, 1, 0, normal_mix.a);
#else
        surface += layerMasks[i] * half4(0, 1, 0, color_01.a);
#endif
    }
}

void GetLayersBlendMaskArray(int BlendLayerCount,
    half2 uv, float3 PositionWS,
    inout half4 mask,
    half index)
{
#if defined(CNC_TERRAIN_LOCAL_POSITION)
    half2 worldUv = _TerrainLocalScale * PositionWS.xz / _TerrainSize + half2(0.5, 0.5);
#else
    half2 worldUv = PositionWS.xz / _TerrainSize;
#endif

    half4 maskA = SAMPLE_TEXTURE2D_ARRAY(_MaskMap, sampler_MaskMap, worldUv, index);
    mask = maskA;
}

void BlendBiomeSnowland(half2 uv, float3 PositionWS,
    inout half4 color,
    inout half4 surface)
{
    //Shader Feature
    int BlendLayerCount = 4;
    half4 layerMasks = half4(0, 0, 0, 0);
    GetLayersBlendMaskArray(BlendLayerCount, uv, PositionWS, layerMasks, 0);

    half tilling = _TerrainSize / 56.884;
    half2 uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_01 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 0, -1);

    tilling = _TerrainSize / 30;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_02 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 1, -1);

    tilling = _TerrainSize / 56.884;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_03 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 2, -1);

    tilling = _TerrainSize / 50;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_04 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 3, -1);

    color += layerMasks.r * color_01 * half4(0.85, 0.85, 0.85, 1.00) + layerMasks.g * color_02 * half4(0.85, 0.85, 0.85, 1.00) + layerMasks.b * color_03 * half4(0.85, 0.85, 0.85, 1.00) + layerMasks.a * color_04 * half4(1, 1, 1, 1.00);
    
    #ifdef CNC_TERRAIN_SMOOTHNESS
        half2 worldUv = PositionWS.xz / _TerrainSize;
        half4 surface01 = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, worldUv);
        surface = half4(0, 1, 0, surface01.r);
    #else
        surface = half4(0, 1, 0, _CustomSmoothness);
    #endif
}

void BlendBiomeDesert(half2 uv, float3 PositionWS,
    inout half4 color,
    inout half4 surface)
{
    //Shader Feature
    int BlendLayerCount = 4;
    half4 layerMasks = half4(0, 0, 0, 0);
    GetLayersBlendMaskArray(BlendLayerCount, uv, PositionWS, layerMasks, 1);

    half tilling = _TerrainSize / 30;
    half2 uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_01 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 4, -1);

    tilling = _TerrainSize / 56.884;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_02 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 5, -1);

    tilling = _TerrainSize / 50;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_03 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 6, -1);

    tilling = _TerrainSize / 50;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_04 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 7, -1);

    color += layerMasks.r * color_01 * half4(0.48, 0.46, 0.32, 1.00) + layerMasks.g * color_02 * half4(0.43, 0.45, 0.29, 1.00) + layerMasks.b * color_03 * half4(0.46, 0.48, 0.30, 1.00) + layerMasks.a * color_04 * half4(0.43, 0.47, 0.33, 1.00);
    #ifdef CNC_TERRAIN_SMOOTHNESS
        half2 worldUv = PositionWS.xz / _TerrainSize;
        half4 surface01 = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, worldUv);
        surface = half4(0, 1, 0, surface01.g);
    #else
        surface = half4(0, 1, 0, _CustomSmoothness);
    #endif
}

void BlendBiomeGrassland(half2 uv, float3 PositionWS,
    inout half4 color,
    inout half4 surface)
{
    //Shader Feature
    int BlendLayerCount = 4;
    half4 layerMasks = half4(0, 0, 0, 0);
    GetLayersBlendMaskArray(BlendLayerCount, uv, PositionWS, layerMasks, 2);

    half tilling = _TerrainSize / 50;
    half2 uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_01 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 8, -1);

    tilling = _TerrainSize / 50;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_02 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 9, -1);

    tilling = _TerrainSize / 50;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_03 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 10, -1);

    tilling = _TerrainSize / 50;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_04 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 11, -1);

    color += layerMasks.r * color_01 * half4(0.62, 0.54, 0.42, 1.00) + layerMasks.g * color_02 * half4(0.78, 0.64, 0.56, 1.00) + layerMasks.b * color_03 * half4(1.00, 0.60, 0.53, 1.00) + layerMasks.a * color_04 * half4(0.64, 0.54, 0.51, 1.00);
    #ifdef CNC_TERRAIN_SMOOTHNESS
        half2 worldUv = PositionWS.xz / _TerrainSize;
        half4 surface01 = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, worldUv);
        surface = half4(0, 1, 0, surface01.b);
    #else
        surface = half4(0, 1, 0, _CustomSmoothness);
    #endif
}

void BlendBiomeBlackland(half2 uv, float3 PositionWS,
    inout half4 color,
    inout half4 surface)
{
    //Shader Feature
    int BlendLayerCount = 4;
    half4 layerMasks = half4(0, 0, 0, 0);
    GetLayersBlendMaskArray(BlendLayerCount, uv, PositionWS, layerMasks, 3);

    half tilling = _TerrainSize / 56.884;
    half2 uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_01 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 12, -1);

    tilling = _TerrainSize / 56.884;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_02 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 13, -1);

    tilling = _TerrainSize / 102.4;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_03 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 14, -1);

    tilling = _TerrainSize / 56.884;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling.xx;
    half4 color_04 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, 15, -1);

    color += layerMasks.r * color_01 * half4(0.62, 0.54, 0.42, 1.00) + layerMasks.g * color_02 * half4(0.78, 0.64, 0.56, 1.00) + layerMasks.b * color_03 * half4(0.645, 0.578, 0.516, 1.00) + layerMasks.a * color_04 * half4(0.645, 0.578, 0.516, 1.00);
    #ifdef CNC_TERRAIN_SMOOTHNESS
        half2 worldUv = PositionWS.xz / _TerrainSize;
        half4 surface01 = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, worldUv);
        surface = half4(0, 1, 0, surface01.a);
    #else
        surface = half4(0, 1, 0, _CustomSmoothness);
    #endif
}

void CalculateHeightBlend(float3 PositionWS, half biomeIndex, half2 splatUV, half4 layerIndex, half indexMap, half4 layerTilling, inout half4 blend, inout half blendAttribute, inout half4 color0, inout half4 color1, inout half4 color2, inout half4 color3,inout half4 mask) {
    mask = SAMPLE_TEXTURE2D_ARRAY(_MaskMap, sampler_MaskMap, splatUV, biomeIndex);

    half tilling = _TerrainSize / layerTilling.r;
    half2 uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling;
    color0 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, layerIndex.r, -1);

    tilling = _TerrainSize / layerTilling.g;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling;
    color1 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, layerIndex.g, -1);

    tilling = _TerrainSize / layerTilling.b;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling;
    color2 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, layerIndex.b, -1);

    tilling = _TerrainSize / layerTilling.a;
    uv_world = _MeshTilling * PositionWS.xz / _TerrainSize * tilling;
    color3 = SAMPLE_TEXTURE2D_ARRAY_BIAS(_BaseColorArray, sampler_BaseColorArray, uv_world, layerIndex.a, -1);

    blend = half4(color0.a, color1.a, color2.a, color3.a) * mask * indexMap;
    blendAttribute = max(blend.r, max(blend.g, max(blend.b, blend.a)));
}

void BlendLyaerHeight(half2 uv, float3 PositionWS,
    inout half4 color,
    inout half4 surface)
{
    //Calculate biome index map
    half2 uv_whole_world = PositionWS.xz / 12288;
    half4 indexMap = SAMPLE_TEXTURE2D(_IndexMap, sampler_IndexMap, uv_whole_world);
    indexMap = indexMap / (indexMap.r + indexMap.g + indexMap.b+ indexMap.a);

    //Declare layer attribute
    half4 blend0 = half4(0, 0, 0, 0);
    half blendAttribute0 = 0;
    half4 mask0 = half4(0, 0, 0, 0);
    half4 blend1 = half4(0, 0, 0, 0);
    half blendAttribute1 = 0;
    half4 mask1 = half4(0, 0, 0, 0);
    half4 blend2 = half4(0, 0, 0, 0);
    half blendAttribute2 = 0;
    half4 mask2 = half4(0, 0, 0, 0);
    half4 blend3 = half4(0, 0, 0, 0);
    half blendAttribute3 = 0;
    half4 mask3 = half4(0, 0, 0, 0);

    //Calculate single biome color
    half2 splatUv = PositionWS.xz / _TerrainSize;
#ifdef CNC_BIOME_SNOWLAND
    half4 color0 = half4(0, 0, 0, 0);
    half4 color1 = half4(0, 0, 0, 0);
    half4 color2 = half4(0, 0, 0, 0);
    half4 color3 = half4(0, 0, 0, 0);
    half4 layerTilling0 = half4(56.884, 30, 56.884, 50);
    CalculateHeightBlend(PositionWS,0, splatUv, half4(0,1,2,3), indexMap.r, layerTilling0,blend0, blendAttribute0, color0, color1, color2, color3,mask0);
#endif
#ifdef CNC_BIOME_DESERT
    half4 color4 = half4(0, 0, 0, 0);
    half4 color5 = half4(0, 0, 0, 0);
    half4 color6 = half4(0, 0, 0, 0);
    half4 color7 = half4(0, 0, 0, 0);
    half4 layerTilling1 = half4(30, 56.884, 50, 50);
    CalculateHeightBlend(PositionWS,1, splatUv, half4(4,5,6,7), indexMap.g, layerTilling1,blend1, blendAttribute1, color4, color5, color6, color7, mask1);
#endif
#ifdef CNC_BIOME_GRASSLAND
    half4 color8 = half4(0, 0, 0, 0);
    half4 color9 = half4(0, 0, 0, 0);
    half4 color10 = half4(0, 0, 0, 0);
    half4 color11 = half4(0, 0, 0, 0);
    half4 layerTilling2 = half4(50, 50, 50, 50);
    CalculateHeightBlend(PositionWS,2, splatUv, half4(8,9,10,11), indexMap.b, layerTilling2,blend2, blendAttribute2, color8, color9, color10, color11, mask2);
#endif
#ifdef CNC_BIOME_BLACKLAND
    half4 color12 = half4(0, 0, 0, 0);
    half4 color13 = half4(0, 0, 0, 0);
    half4 color14 = half4(0, 0, 0, 0);
    half4 color15 = half4(0, 0, 0, 0);
    half4 layerTilling3 = half4(56.884, 56.884, 102.4, 56.884);
    CalculateHeightBlend(PositionWS,3, splatUv, half4(12,13,14,15), indexMap.a, layerTilling3,blend3, blendAttribute3, color12, color13, color14, color15, mask3);
#endif

    //Calculate height blend of each layer
    half ma = max(blendAttribute3.x, max(blendAttribute2.x, max(blendAttribute0.x, blendAttribute1.x)));
    blend0 = max(blend0 - ma + _BlendThreshold, 0) * mask0 * indexMap.r;
    blend1 = max(blend1 - ma + _BlendThreshold, 0) * mask1 * indexMap.g;
    blend2 = max(blend2 - ma + _BlendThreshold, 0) * mask2 * indexMap.b;
    blend3 = max(blend3 - ma + _BlendThreshold, 0) * mask3 * indexMap.a;

    half blendTotal = blend0.r + blend0.g + blend0.b + blend0.a + blend1.r + blend1.g + blend1.b + blend1.a + blend2.r + blend2.g + blend2.b + blend2.a + blend3.r + blend3.g + blend3.b + blend3.a;
    blend0 = blend0 / blendTotal;
    blend1 = blend1 / blendTotal;
    blend2 = blend2 / blendTotal;
    blend3 = blend3 / blendTotal;

    half4 color_total = half4(0, 0, 0, 0);
#ifdef CNC_BIOME_SNOWLAND
    color_total += color0 * half4(half3(0.85, 0.85, 0.85) * blend0.rrr, 1.0h) + color1 * half4(half3(0.85, 0.85, 0.85) * blend0.ggg, 1.0h) + color2 * half4(half3(0.85, 0.85, 0.85) * blend0.bbb, 1.0h) + color3 * half4(half3(1, 1, 1) * blend0.aaa, 1.0h);
#endif  
#ifdef CNC_BIOME_DESERT    
    color_total += color4 * half4(half3(0.48, 0.46, 0.32) * blend1.rrr, 1.0h) + color5 * half4(half3(0.43, 0.45, 0.29) * blend1.ggg, 1.0h) + color6 * half4(half3(0.46, 0.48, 0.30) * blend1.bbb, 1.0h) + color7 * half4(half3(0.43, 0.47, 0.33) * blend1.aaa, 1.0h);
#endif   
#ifdef CNC_BIOME_GRASSLAND   
    color_total += color8 * half4(half3(0.62, 0.54, 0.42) * blend2.rrr, 1.0h) + color9 * half4(half3(0.78, 0.64, 0.56) * blend2.ggg, 1.0h) + color10 * half4(half3(1.00, 0.60, 0.53) * blend2.bbb, 1.0h) + color11 * half4(half3(0.64, 0.54, 0.51) * blend2.aaa, 1.0h);
#endif
#ifdef CNC_BIOME_BLACKLAND    
    color_total += color12 * half4(half3(0.62, 0.54, 0.42) * blend3.rrr, 1.0h) + color13 * half4(half3(0.78, 0.64, 0.56) * blend3.ggg, 1.0h) + color14 * half4(half3(0.645, 0.578, 0.516) * blend3.bbb, 1.0h) + color15 * half4(half3(0.645, 0.578, 0.516) * blend3.aaa, 1.0h);
#endif
    color = color_total;

#ifdef CNC_TERRAIN_SMOOTHNESS
    half4 smoothness01 = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, splatUv*10);
    half smoothness = indexMap.r * smoothness01.r + indexMap.g * smoothness01.g + indexMap.b * smoothness01.b + indexMap.a * smoothness01.a;
    surface = half4(0, 1, 0, smoothness);
#else
    surface = half4(0, 1, 0, _CustomSmoothness);
#endif
}

void BlendLayers_Weight(half2 uv, float3 PositionWS,
                inout half4 color,
                inout half3 normal,
                inout half4 surface)
{   
    // VT烘培坐标偏移
    PositionWS.xz = PositionWS.xz * _PositionOffset.w + _PositionOffset.xz;

#ifdef CNC_TERRAIN_BLEND_HEIGHT
    BlendLyaerHeight(uv, PositionWS, color, surface);
    normal = half3(0, 0, 1);
#else
    #ifdef CNC_SINGLE_BIOME
        color = half4(0, 0, 0, 0);
        #ifdef CNC_BIOME_SNOWLAND
            BlendBiomeSnowland(uv, PositionWS, color, surface);
        #elif CNC_BIOME_DESERT
            BlendBiomeDesert(uv, PositionWS, color, surface);
        #elif CNC_BIOME_GRASSLAND
            BlendBiomeGrassland(uv, PositionWS, color, surface);
        #else 
            BlendBiomeBlackland(uv, PositionWS, color, surface);
        #endif
    #else
        half4 color_01_total = half4(0, 0, 0, 0);
        half4 surface_01_total = half4(0, 0, 0, 0);

        half4 color_02_total = half4(0, 0, 0, 0);
        half4 surface_02_total = half4(0, 0, 0, 0);

        half4 color_03_total = half4(0, 0, 0, 0);
        half4 surface_03_total = half4(0, 0, 0, 0);

        half4 color_04_total = half4(0, 0, 0, 0);
        half4 surface_04_total = half4(0, 0, 0, 0);

        half2 uv_whole_world = PositionWS.xz / 12288;
        float4 indexMap = SAMPLE_TEXTURE2D(_IndexMap, sampler_IndexMap, uv_whole_world);

        #if defined CNC_BIOME_SNOWLAND
            BlendBiomeSnowland(uv, PositionWS, color_01_total, surface_01_total);
        #endif
        #if defined CNC_BIOME_DESERT
            BlendBiomeDesert(uv, PositionWS, color_02_total, surface_02_total);
        #endif
        #if defined CNC_BIOME_GRASSLAND
            BlendBiomeGrassland(uv, PositionWS, color_03_total, surface_03_total);
        #endif
        #if defined CNC_BIOME_BLACKLAND
            BlendBiomeBlackland(uv, PositionWS, color_04_total, surface_04_total);
        #endif
        float indexMaskTotal = indexMap.r + indexMap.g + indexMap.b + indexMap.a;
        color = color_01_total * indexMap.r / indexMaskTotal + color_02_total * indexMap.g / indexMaskTotal + color_03_total * indexMap.b / indexMaskTotal + color_04_total * indexMap.a / indexMaskTotal;
    #endif
    normal = half3(0, 0, 1);
    surface = half4(0, 1, 0, _CustomSmoothness);
#endif
}

//------------------------------------- 数据初始化 -------------------------------------//
//layer 混合主要就在这里
inline void InitializeLayerSurfaceData(LandscapeLayer_Varyings input, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData) 0;
    outSurfaceData.metallic = 0.0h;
    outSurfaceData.specular = _SpecColor.rgb;
    
    half4 color;
    half3 normal;
    half4 surface;

#if defined CNC_TERRAIN_LOCAL_POSITION
    BlendLayers_Weight_Simple(input.uv, input.positionOS, color, normal, surface);
#else 
    BlendLayers_Weight(input.uv, input.positionWS, color, normal, surface);
#endif

    half4 albedoAlpha = color;
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor.a, _Cutoff);

    outSurfaceData.normalTS  = normalize(normal);

    outSurfaceData.smoothness = surface.a; // PerceptualRoughnessToPerceptualSmoothness(surface.r); //_Smoothness; //mask.r *
    outSurfaceData.metallic = surface.r;
    outSurfaceData.occlusion = surface.g; //1 - _OcclusionStrength; //LerpWhiteTo(mask.g, _OcclusionStrength);
}

//初始化参数
void InitializeInputData(LandscapeLayer_Varyings input, half3 normalTS, out InputData inputData)
{
	inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
	inputData.positionWS = input.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    //    inputData.shadowCoord = input.shadowCoord;
    //#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    //    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    //#else
    //    inputData.shadowCoord = float4(0, 0, 0, 0);
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

	half3 viewDirWS = SafeNormalize(input.viewDirWS);
#if defined(_NORMALMAP) || defined(_DETAIL)
	half3 bitangentWS = cross(input.normalWS.xyz, input.tangentWS.xyz);

	float4 tSpace0 = float4(input.tangentWS.x, bitangentWS.x, input.normalWS.x, input.positionWS.x);
	float4 tSpace1 = float4(input.tangentWS.y, bitangentWS.y, input.normalWS.y, input.positionWS.y);
	float4 tSpace2 = float4(input.tangentWS.z, bitangentWS.z, input.normalWS.z, input.positionWS.z);

	half3 worldN;
	worldN.x = dot(tSpace0.xyz, normalTS);
	worldN.y = dot(tSpace1.xyz, normalTS);
	worldN.z = dot(tSpace2.xyz, normalTS);
	worldN = SafeNormalize(worldN);

	inputData.normalWS = worldN;

#else
	inputData.normalWS = input.bitangentWS;
#endif

	//inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	inputData.viewDirectionWS = viewDirWS;

	inputData.fogCoord = input.fogFactorAndVertexLight.x;
	inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
	inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
	inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
	inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

//------------------------------------- 顶点着色器 -------------------------------------//
// Used in Standard (Physically Based) shader
LandscapeLayer_Varyings VTVertex(LandscapeLayer_Attributes input)
{
	LandscapeLayer_Varyings output = (LandscapeLayer_Varyings)0;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
	float4 vertexTangent = float4(cross(float3(0, 0, 1), input.normalOS), 1.0);
	VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, vertexTangent);

    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);

	output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
	// already normalized from normal transform to WS.
	output.normalWS = normalInput.normalWS;
	output.bitangentWS = normalInput.bitangentWS;

    output.viewDirWS = viewDirWS;

#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);
    //half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

	output.positionWS = vertexInput.positionWS;
	output.positionCS = vertexInput.positionCS;

#if defined(CNC_TERRAIN_LOCAL_POSITION)
	output.positionOS = input.positionOS;
#endif

	return output;
}

half4 VTColorFragment(LandscapeLayer_Varyings input) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	SurfaceData surfaceData;
	InitializeLayerSurfaceData(input, surfaceData);

//#if defined(_TERRAIN_VT_BAKED_LIGHT)
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    // 烘培时是正交相机，所以高光效果不一致，这里修改掉viewDir
    inputData.viewDirectionWS = g_TerrainVTViewDir.xyz;
    inputData.normalWS = half3(0, 1, 0);

    #if defined(CNC_TERRAIN_LOW)
    half4 color = UniversalFragmentBlinnPhong(inputData, surfaceData.albedo, half4(surfaceData.specular, 1), surfaceData.smoothness, surfaceData.emission, surfaceData.alpha, surfaceData.normalTS);
    #else
    half4 color = UniversalFragmentPBR(inputData, surfaceData);
    #endif
    color.rgb /= g_TerrainVTViewDir.w;
//#else
//	half4 color = half4(surfaceData.albedo, surfaceData.occlusion);
//#endif
	return color;
}

half4 VTNormalFragment(LandscapeLayer_Varyings input) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	SurfaceData surfaceData;
	InitializeLayerSurfaceData(input, surfaceData);

	half4 color = half4(TerrainVT_PackNormalForBlend(surfaceData.normalTS.xyz), surfaceData.metallic, surfaceData.smoothness);
	return color;
}

#endif
