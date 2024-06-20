Shader "Custom RP/Unlit"
{
	Properties
	{
		//"white"ΪĬ�ϴ�����ͼ��{}�ںܾ�֮ǰ��������������
        _BaseMap("Texture", 2D) = "white"{}
		[HDR] _BaseColor("Color",Color) = (1.0,1.0,1.0,1.0)
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		//���ģʽʹ�õ�ֵ����ֵӦ����ö��ֵ����������ʹ��float
		//����������Editor�¸�����༭
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend",Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend",Float) = 0
		//���д��ģʽ
        [Enum(Off,0,On,1)] _ZWrite("Z Write",Float) = 1
	}	

	SubShader
	{
		HLSLINCLUDE
		#include "Assets/ShaderLibrary/Common.hlsl"
		#include "UnlitInput.hlsl"
		ENDHLSL

		Pass {
				//���û��ģʽ
				Blend [_SrcBlend] [_DstBlend]
				ZWrite [_ZWrite]

				HLSLPROGRAM
				#pragma shader_feature _CLIPPING
				#pragma multi_compile_instancing

				#pragma vertex UnlitPassVertex
				#pragma fragment UnlitPassFragment
				#include "UnlitPass.hlsl"
				ENDHLSL
			}
	}

	CustomEditor "CustomShaderGUI"
}