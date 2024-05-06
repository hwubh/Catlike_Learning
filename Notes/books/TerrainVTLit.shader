Shader "Universal Render Pipeline/TerrainVT/TerrainVTLit"
{
    Properties
    {
        // Specular vs Metallic workflow
        [HideInInspector] [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [HideInInspector][MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _TerrainSize("Mesh Size", Float) = 512

        //_ShadowIntensity("Shadow Indenstiy", Float) = 1.0


        [Header(Enable Terrain Hole)]
        [Toggle(CNC_TERRAIN_HOLE)] _UseTerrainHole("Use Terrain Hole", float) = 0
        [HideIfDisabled(CNC_TERRAIN_HOLE)]_HoleMap("HoleMap", 2D) = "White" {}
        [HideIfDisabled(CNC_TERRAIN_HOLE)]_HoleNormalMap("HoleNormalMap", 2D) = "White" {}

        [Header(Enable Terrain LOW)]
        [Toggle(CNC_TERRAIN_LOW)] _UseTerrainLow("Use Terrain BlinnPhong", float) = 0
        
        //[Space(10)]
        //[Header(Is Light Baked)]
        //[Toggle(_TERRAIN_VT_BAKED_LIGHT)] _IS_BAKED_LIGHT_("Is Light Baked", float) = 1
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
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _ CNC_TERRAIN_LOCAL_POSITION
            #pragma shader_feature_local _ CNC_NORMAL_TEXTURE_ARRAY
            #pragma shader_feature_local _ CNC_TERRAIN_HOLE
            #pragma shader_feature_local _ CNC_SINGLE_BIOME

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            // #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            // #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            // #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ CNC_CLOUD_SHADOW_MAP
            #pragma multi_compile_fragment _ CNC_TERRAIN_LOW

            // -------------------------------------
            // User defined keywords
            //#pragma multi_compile _ _TERRAIN_VT_BAKED_LIGHT

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LLayer_LitPassVertex
            #pragma fragment LLayer_LitPassFragment

			#include "TerrainVTLitPasses.hlsl"
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
            #pragma multi_compile _ DOTS_INSTANCING_ON
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
