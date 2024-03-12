Shader "Custom RP/Lit"
{
	Properties
	{
		//"white"ΪĬ�ϴ�����ͼ��{}�ںܾ�֮ǰ�������������
        _BaseMap("Texture", 2D) = "white"{}
		_BaseColor("Color",Color) = (0.5,0.5,0.5,1)
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha ("Premultiply Alpha", Float) = 0
		//���ģʽʹ�õ�ֵ����ֵӦ����ö��ֵ����������ʹ��float
		//����������Editor�¸�����༭
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend",Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend",Float) = 0
		//���д��ģʽ
        [Enum(Off,0,On,1)] _ZWrite("Z Write",Float) = 1
		[KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
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
			#pragma shader_feature _CLIPPING
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

				//���û��ģʽ
				Blend [_SrcBlend] [_DstBlend]
				ZWrite [_ZWrite]

				HLSLPROGRAM

				//������OpenGL ES 2.0��ͼ��API����ɫ�����壬�䲻֧�ֿɱ������ѭ����������ɫ�ռ�
				#pragma target 3.5

				#pragma shader_feature _RECEIVE_SHADOWS
				#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
				#pragma shader_feature _PREMULTIPLY_ALPHA
				#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
				#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
				#pragma multi_compile_instancing

				#pragma vertex LitPassVertex
				#pragma fragment LitPassFragment
				#include "ShaderLibrary/LitPass.hlsl"
				ENDHLSL
			}
	}

	//����Unity�༭��ʹ��CustomShaderGUI���һ��ʵ����Ϊʹ��Lit.shader�Ĳ��ʻ���Inspector����
    CustomEditor "CustomShaderGUI"

}
