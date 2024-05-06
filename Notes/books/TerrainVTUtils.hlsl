#ifndef UNIVERSAL_TERRAIN_VT_INPUT_INCLUDED
#define UNIVERSAL_TERRAIN_VT_INPUT_INCLUDED

sampler2D g_TerrainColorVT;
sampler2D g_TerrainHeightVT;
sampler2D g_TerrainNormalVT;
//float4 g_TerrainVTInfo;	// xyz: _RT_ATLAS_NUM_X, _RT_ATLAS_NUM_Y, m_LodNum
//float4 g_TerrainVTSize; // xyzw: _CENTER_SIZE, Max Size, RTExtScale, HeightRTExtScale
float4 g_TerrainVTCenter;// xyz:CenterPos, w:HeightScale
float4 g_TerrainVTLod[4];// xy:Pos, z:Size, w:HalfSize
float4 g_TerrainVTLodUV[4];// xy:UVOffset, zw:1/RTSize
//float4 g_TerrainRootPos;
half4 g_TerrainVTViewDir;// xyz:ViewDir, w:Light Intensity

float hash(float2 pos)
{
	return frac(sin(dot(pos.xy, float2(12.9898, 78.233)))*43758.5453123);
}

float TerrainVT_IsOutRect(float2 worldPos, half lod)
{
	float4 pos = g_TerrainVTLod[lod];
	//float halfClipSize = pos.w * 0.5 * 0.98;// *0.98，为了避免接缝，边缘缩小范围采下一级
	//float v = (worldPos.x > (pos.x - halfClipSize)) * (worldPos.x < (pos.x + halfClipSize));
	//v *= (worldPos.z > (pos.y - halfClipSize)) * (worldPos.z < (pos.y + halfClipSize));
    //return 1 - v;
    half2 offset = abs(worldPos - pos.xy);
    half2 isOut = offset > pos.zw;
    return max(isOut.x, isOut.y);
}

float2 TerrainVT_GetUV(float2 worldPos)
{	
	// 如果当前lod不包含，则采样下一级lod
    half lod = TerrainVT_IsOutRect(worldPos, 0);
	lod += TerrainVT_IsOutRect(worldPos, 1);
    lod += TerrainVT_IsOutRect(worldPos, 2);
    lod += TerrainVT_IsOutRect(worldPos, 3);
    float2 offset = worldPos - g_TerrainVTLod[lod].xy; //half precision may cause problem

    // 计算UV偏移改为查找
	//float clipSize = g_TerrainVTLod[lod].z;// centerSize * pow(2, lod);
	//float2 uv = float2(floor(lod / g_TerrainVTInfo.y), floor(lod % g_TerrainVTInfo.y));
	//uv += (offset.xy / clipSize) + 0.5;
	//uv /= g_TerrainVTInfo.xy;
    float2 uv = g_TerrainVTLodUV[lod].xy;
    uv += (offset + g_TerrainVTLod[lod].zw / 0.98) * g_TerrainVTLodUV[lod].zw;

	return uv;
}

float2 TerrainVT_PackHeight(float height)
{
     uint a = (uint)(65535.0f * height);
     return float2((a >> 0) & 0xFF, (a >> 8) & 0xFF) / 255.0f;
}

float TerrainVT_UnpackHeight(float2 height)
{
     return (height.r + height.g * 256.0f) / 257.0f; // (255.0f * height.r + 255.0f * 256.0f * height.g) / 65535.0f
}

float TerrainVT_GetHeight(float2 uvVT)
{
	float4 color = tex2Dlod(g_TerrainHeightVT, float4(uvVT, 0, 0));
	float height = TerrainVT_UnpackHeight(color.rg);
	height *= g_TerrainVTCenter.w;// HeightScale
	return height;
}

half4 TerrainVT_GetColor(float2 uvVT)
{
    half4 color = tex2Dlod(g_TerrainColorVT, float4(uvVT, 0, 0));
//#if defined(_TERRAIN_VT_BAKED_LIGHT)
    color.rgb *= g_TerrainVTViewDir.w;
//#endif
    return color;
}

half4 TerrainVT_GetNormal(float2 uvVT)
{
    return tex2Dlod(g_TerrainNormalVT, float4(uvVT, 0, 0));
}

half2 TerrainVT_PackNormal(half3 n)
{
    half2 enc = normalize(n.xy) * (sqrt(-n.z*0.5+0.5));
	enc = enc*0.5+0.5;
	return enc;
}

half3 TerrainVT_UnpackNormal(half2 enc)
{
    half2 fenc = enc*2-1;
    half3 n;
	n.z = -(dot(fenc,fenc)*2-1);
	n.xy = normalize(fenc) * sqrt(1-n.z*n.z);
	return n;
}

half3 TerrainVT_UnpackNormalScale(half2 enc, half scale)
{
    half2 fenc = enc * 2 - 1;
    half3 n;
	n.z = -(dot(fenc, fenc) * 2 - 1);
	n.xy = normalize(fenc) * sqrt(1 - n.z*n.z);
	n.xy *= scale;
	return n;
}

half2 TerrainVT_PackNormalForBlend(half3 n)
{
    half2 enc = n.xy * 0.5 + 0.5;
	return enc;
}

half3 TerrainVT_UnpackNormalForBlend(half2 enc)
{
    half2 fenc = enc * 2 - 1;
    half3 n;
	n.xy = fenc;
	n.z = sqrt(1 - dot(fenc, fenc));
	return n;
}

float TerrainVT_GetHeightAndNormal(float2 uvVT, out half3 normal)
{
	float4 color = tex2Dlod(g_TerrainHeightVT, float4(uvVT,0,0));
	float height = TerrainVT_UnpackHeight(color.rg);
	height *= g_TerrainVTCenter.w;// HeightScale

	normal = TerrainVT_UnpackNormal(color.ba);
	return height;
}

//float TerrainVT_BlendTerrain(float3 positionWS, float blendTH)
//{
//	float2 uvVT = TerrainVT_GetUV(positionWS.xz);
//	float terrainHeight = TerrainVT_GetHeight(uvVT);
//	terrainHeight = positionWS.y - terrainHeight - g_TerrainRootPos.y;
//
//	float terrainH = saturate((blendTH - terrainHeight) / blendTH);
//	return terrainH;
//}

//float4 TerrainVT_BlendTerrain(float3 positionWS, half3 normalWS, float blendTH)
//{
//	float2 uvVT = TerrainVT_GetUV(positionWS.xz);
//	float terrainHeight = TerrainVT_GetHeight(uvVT);
//	terrainHeight = positionWS.y - terrainHeight - g_TerrainRootPos.y;
//
//	float4 terrainH = 0;
//	terrainH.w = saturate((blendTH - terrainHeight) / blendTH);
//	float off = 1 - saturate(dot(normalWS, float3(0, 1, 0)));
//	terrainH.xyz = normalWS * off * terrainHeight;
//
//	return terrainH;
//}

half3 TerrainVT_BlendTerrain(float3 positionWS, half3 color, half alpha)
{
    float2 uvVT = TerrainVT_GetUV(positionWS.xz);
    half4 TerrainColor = tex2Dlod(g_TerrainColorVT, float4(uvVT, 0, 0));
    return lerp(TerrainColor.xyz, color, alpha);
}

#endif
