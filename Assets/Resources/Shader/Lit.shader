Shader "Custom RP/Lit"
{
	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
		[KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0

		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha ("Premultiply Alpha", Float) = 0

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1

		[HideInInspector] _MainTex("Texture for Lightmap", 2D) = "white" {}
		[HideInInspector] _Color("Color for Lightmap", Color) = (0.5, 0.5, 0.5, 1.0)
	}	

	SubShader
	{

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
			#pragma multi_compile_instancing
			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "ShaderLibrary/ShadowCasterPass.hlsl"
			ENDHLSL
		}

		Pass {
				Tags {
					"LightMode" = "CustomLit"
					}

				//设置混合模式
				Blend [_SrcBlend] [_DstBlend]
				ZWrite [_ZWrite]

				HLSLPROGRAM

				//不生成OpenGL ES 2.0等图形API的着色器变体，其不支持可变次数的循环与线性颜色空间
				#pragma target 3.5

				#pragma shader_feature _CLIPPING
				#pragma shader_feature _RECEIVE_SHADOWS
				#pragma shader_feature _PREMULTIPLY_ALPHA
				#pragma multi_compile _ LIGHTMAP_ON
				#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
				#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
				#pragma multi_compile_instancing

				#pragma vertex LitPassVertex
				#pragma fragment LitPassFragment
				#include "ShaderLibrary/LitPass.hlsl"
				ENDHLSL
			}
	}

	//告诉Unity编辑器使用CustomShaderGUI类的一个实例来为使用Lit.shader的材质绘制Inspector窗口
    CustomEditor "CustomShaderGUI"

}
