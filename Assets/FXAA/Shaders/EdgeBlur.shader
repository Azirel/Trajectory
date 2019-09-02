Shader "Custom/ImageEffects/EdgeBlur"
{
	Properties
	{
		[HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
		[PowerSlider(2)]_Strength("Strength", Range (-2,5)) = 1
	}
		SubShader
		{
			Pass
			{
				HLSLPROGRAM
				#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/SurfaceInput.hlsl"

#ifdef UNITY_EDITOR
	TEXTURE2D(_MainTex);
#else 
	TEXTURE2D_ARRAY(_MainTex);
#endif
				SAMPLER(sampler_MainTex);

				SamplerState my_point_clamp_sampler;
				SamplerState my_linear_clamp_sampler;

				float4 _MainTex_TexelSize;
				float _Strength;
/*--------------------DefaultStuff--------------------*/
				struct Attributes
				{
					float4 positionOS       : POSITION;
					float2 uv               : TEXCOORD0;
				};

				struct Varyings
				{
					float2 uv        : TEXCOORD0;
					float4 vertex : SV_POSITION;
					UNITY_VERTEX_OUTPUT_STEREO
				};

				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

					VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
					output.vertex = vertexInput.positionCS;
					output.uv = input.uv;

					return output;
				}
/*----------------------------------------------------*/

				#define LumaTexOff(p, o, r) luma( SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, p + (o * r), unity_StereoEyeIndex))
				#define TexOff(p, o, r) SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, p + (o * r), unity_StereoEyeIndex)
				#define LumaTexTop(p) luma( SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, p, unity_StereoEyeIndex))

				half luma(half3 value)
				{
					return dot(value, half3(0.212f, 0.716f, 0.072f));
				}

				half4 EdgeBlurResult(Varyings i)
				{
					half2 filterSize = 1.0f * _MainTex_TexelSize.xy;

					half luminance_left = luma(SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv + filterSize*half2(-1.0f, 0.0f), unity_StereoEyeIndex));
					half luminance_right = luma(SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv + filterSize*half2(1.0f, 0.0f), unity_StereoEyeIndex));
					half luminance_top = luma(SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv + filterSize*half2(0.0f, -1.0f), unity_StereoEyeIndex));
					half luminance_bottom = luma(SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv + filterSize*half2(0.0f, 1.0f), unity_StereoEyeIndex));

					half2 tangent = half2( -(luminance_top - luminance_bottom), (luminance_right - luminance_left));
					half tangentLength = length(tangent);
					tangent /= tangentLength;
					tangent *= _MainTex_TexelSize.xy;

					half4 color_center = SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_point_clamp_sampler, i.uv, unity_StereoEyeIndex);
					half4 color_left = SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv - 0.5 * tangent, unity_StereoEyeIndex);// * 0.666f;
					half4 color_left2 = SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv - 0.5 * tangent, unity_StereoEyeIndex);// * 0.333f;

					half4 color_right = SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv + 0.5 * tangent, unity_StereoEyeIndex);// * 0.666f;
					half4 color_right2 = SAMPLE_TEXTURE2D_ARRAY(_MainTex, my_linear_clamp_sampler, i.uv + tangent, unity_StereoEyeIndex);// * 0.333f;

					half4 color_blurred = (color_center + color_left + color_left2 + color_right + color_right2) / 5.0f;

					half blurStrength = saturate(_Strength * tangentLength);
					return lerp(color_center, color_blurred, blurStrength);
				}

				half4 frag(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
					return EdgeBlurResult(input);
				}
					#pragma vertex vert
					#pragma fragment frag
					#pragma shader_feature UNITY_EDITOR
					#pragma fragmentoption ARB_precision_hint_fastest

					ENDHLSL
				}
		}
		FallBack "Diffuse"
}
