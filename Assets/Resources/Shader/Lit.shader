Shader "Custom RP/Lit"
{
	Properties
	{
		//"white"为默认纯白贴图，{}在很久之前用于纹理的设置
        _BaseMap("Texture", 2D) = "white"{}
		_BaseColor("Color",Color) = (0.5,0.5,0.5,1)
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha ("Premultiply Alpha", Float) = 0
		//混合模式使用的值，其值应该是枚举值，但是这里使用float
		//特性用于在Editor下更方便编辑
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend",Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend",Float) = 0
		//深度写入模式
        [Enum(Off,0,On,1)] _ZWrite("Z Write",Float) = 1
	}	

	SubShader
	{
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
				#pragma shader_feature _PREMULTIPLY_ALPHA

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
