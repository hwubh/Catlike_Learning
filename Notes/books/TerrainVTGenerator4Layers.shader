Shader "CNC_Demo/World/TerrainVT/TerrainVTGenerator4Layers"
{
    Properties
    {
        // Specular vs Metallic workflow
        [HideInInspector] [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [HideInInspector][MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _TerrainSize("Mesh Size", Float) = 512

        [NoScaleOffset]_MaskMap01("MaskMap01", 2D) = "Black" {}
        [NoScaleOffset]_MaskMap02("MaskMap02", 2D) = "Black" {}

        [Header(Layer01)]
        [NoScaleOffset]_ColorMap01("ColorMap01", 2D) = "Black" {}
        [HDR]_Layer01TexColor("Color", Color) = (1,1,1,1)
        _Layer01TexScale("Layer01_Tex_Scale", Range(0, 200)) = 0.01
        [Space(10)]

        [Header(Layer02)]
        [NoScaleOffset]_ColorMap02("ColorMap02", 2D) = "Black" {}
        [HDR]_Layer02TexColor("Color", Color) = (1,1,1,1)
        _Layer02TexScale("Layer02_Tex_Scale", Range(0, 200)) = 0.01
        [Space(10)]

        [Header(Layer03)]
        [NoScaleOffset]_ColorMap03("ColorMap03", 2D) = "Black" {}
        [HDR]_Layer03TexColor("Color", Color) = (1,1,1,1)
        _Layer03TexScale("Layer03_Tex_Scale", Range(0, 200)) = 0.01
        [Space(10)]

        [Header(Layer04)]
        [NoScaleOffset]_ColorMap04("ColorMap04", 2D) = "Black" {}
        [HDR]_Layer04TexColor("Color", Color) = (1,1,1,1)
        _Layer04TexScale("Layer04_Tex_Scale", Range(0, 200)) = 0.01
        [Space(10)]
        
        /*
        [Header(CNC_NORMAL_TEXTURE_ARRAY)]
        [Toggle(CNC_NORMAL_TEXTURE_ARRAY)] _UseTerrainNormalTextureArray("Use Terrain Normal Texture Array", float) = 0
        [Toggle(CNC_USE_NORMAL_SMOOTHNESS)]_UseNormalSmoothness("Use normal alpha as smoothness", float) = 0
        [Space(10)]*/

        [Header(Local postion and scale)]
        _TerrainLocalScale("Local Scale", float) = 0
        _UvOffsetU("UV Offset(u)", float) = 0.5
        _UvOffsetV("UV Offset(v)", float) = 0.5
        [Space(10)]

        [Header(Enable Terrain LOW)]
        [Toggle(CNC_TERRAIN_LOW)] _UseTerrainLow("Use Terrain BlinnPhong", float) = 0
    }

        SubShader
        {
            // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
            // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
            // material work with both Universal Render Pipeline and Builtin Unity Pipeline
            Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
            LOD 100

            // ------------------------------------------------------------------
            //  Forward pass. Shades all light in a single pass. GI + emission + Fog
            Pass
            {
                // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
                // no LightMode tag are also rendered by Universal Render Pipeline
                Name "ForwardLit"
                Tags{"LightMode" = "UniversalForward"}

                //Blend One Zero
                //ZWrite On
                Cull Off

                HLSLPROGRAM
            // -------------------------------------
                // Material Keywords
                //#pragma shader_feature_local _NORMALMAP
                //#pragma shader_feature_local_fragment _ALPHATEST_ON
                //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
                //#pragma shader_feature_local_fragment _EMISSION
                //#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
                //#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                //#pragma shader_feature_local_fragment _OCCLUSIONMAP
                //#pragma shader_feature_local _PARALLAXMAP
                //#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
                //#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
                //#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
                //#pragma shader_feature_local_fragment _SPECULAR_SETUP
                #pragma shader_feature_local _ CNC_TERRAIN_LOW

                // -------------------------------------
                // Universal Pipeline keywords
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
                #pragma multi_compile_fragment _ _SHADOWS_SOFT
                #pragma multi_compile_fragment _ CNC_CLOUD_SHADOW_MAP
                #pragma multi_compile_fragment _ CNC_TERRAIN_BLEND_HEIGHT
                //#pragma multi_compile_fragment _ CNC_TERRAIN_SMOOTHNESS

                //--------------------------------------
                // GPU Instancing
                #pragma multi_compile_instancing
                // #pragma multi_compile _ DOTS_INSTANCING_ON

                #pragma vertex VTVertex
                #pragma fragment VTColorFragment

                #include "TerrainVTGeneratorPassesSimple.hlsl"
                ENDHLSL
            }

            Pass
            {
                Name "ShadowCaster"
                Tags{"LightMode" = "ShadowCaster"}

                ZWrite On
                ZTest LEqual
                ColorMask 0
                Cull Back

                HLSLPROGRAM
                #pragma exclude_renderers gles gles3 glcore
                #pragma target 4.5

                // -------------------------------------
                // Material Keywords
                #pragma shader_feature_local_fragment _ALPHATEST_ON
                #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

                //--------------------------------------
                // GPU Instancing
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON

                #pragma vertex ShadowPassVertex
                #pragma fragment ShadowPassFragment

                #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
                ENDHLSL
            }

            Pass
            {
                Name "DepthOnly"
                Tags{"LightMode" = "DepthOnly"}
                ZWrite On
                ZTest LEqual
                ColorMask 0
                Cull Back
                HLSLPROGRAM
                #pragma vertex DepthOnlyVertex
                #pragma fragment DepthOnlyFragment
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }
            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
        }


            FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
