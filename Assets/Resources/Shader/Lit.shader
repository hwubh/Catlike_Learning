Shader "Custom RP/Lit"
{
	Properties
	{
		//"white"为默认纯白贴图，{}在很久之前用于纹理的设置
        _BaseMap("Texture", 2D) = "white"{}
		_BaseColor("Color",Color) = (0.5,0.5,0.5,1)
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
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
				#pragma shader_feature _CLIPPING
				#pragma multi_compile_instancing

				#pragma vertex LitPassVertex
				#pragma fragment LitPassFragment
				#include "LitPass.hlsl"
				ENDHLSL
			}
	}
}
