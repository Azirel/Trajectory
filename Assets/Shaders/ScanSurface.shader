Shader "Custom/ImageEffects/ScanSurface"
{
	Properties
	{
		[HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
		_DetailTex("Texture", 2D) = "white" {}
		_ScanDistance("Scan Distance", float) = 0
		_ScanWidth("Scan Width", float) = 10
		_LeadSharp("Leading Edge Sharpness", float) = 10
		_LeadColor("Leading Edge Color", Color) = (1, 1, 1, 0)
		_MidColor("Mid Color", Color) = (1, 1, 1, 0)
		_TrailColor("Trail Color", Color) = (1, 1, 1, 0)
		_HBarColor("Horizontal Bar Color", Color) = (0.5, 0.5, 0.5, 0)
	}
		SubShader
	{
		Pass
		{
			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"

#ifdef UNITY_EDITOR
	TEXTURE2D(_MainTex);
	TEXTURE2D(_CameraDepthTexture);
#else 
	TEXTURE2D_ARRAY(_MainTex);
	TEXTURE2D_ARRAY(_CameraDepthTexture);
#endif
				SAMPLER(sampler_MainTex);
				SAMPLER(sampler_CameraDepthTexture);

				struct Attributes
				{
					half4 positionOS       : POSITION;
					half2 uv               : TEXCOORD0;
					half4 ray				: TEXCOORD1;
				};

				struct Varyings
				{
					half2 uv        : TEXCOORD0;
					half4 vertex	 : SV_POSITION;
					half2 uv_depth : TEXCOORD1;
					half4 interpolatedRay : TEXCOORD2;
					UNITY_VERTEX_OUTPUT_STEREO
				};

				half4 _WorldSpaceScannerPos;
				half _ScanDistance;
				half _ScanWidth;
				half _LeadSharp;
				half4 _LeadColor;
				half4 _MidColor;
				half4 _TrailColor;
				half4 _HBarColor;

				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

					VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
					output.vertex = vertexInput.positionCS;
					output.uv = input.uv;
					output.uv_depth = input.uv.xy;
					output.interpolatedRay = input.ray;

					return output;
				}
				/*----------------------------------------------------*/

				inline half DecodeFloatRG(half enc)
				{
					half2 kDecodeDot = half2(1.0, 1 / 255.0);
					return dot(enc, kDecodeDot);
				}

				inline float Linear01Depth(float z)
				{
					return 1.0 / (_ZBufferParams.x * z + _ZBufferParams.y);
				}

				float4 horizBars(float2 p)
				{
					return 1 - saturate(round(abs(frac(p.y * 100) * 2)));
				}

				half4 frag(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
					half4 color = SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, input.uv, unity_StereoEyeIndex);
					half depth = SAMPLE_TEXTURE2D_ARRAY(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv, unity_StereoEyeIndex).x;
					half linearDepth = Linear01Depth(depth);
					half4 wsDir = linearDepth * input.interpolatedRay;
					half3 wsPos = _WorldSpaceCameraPos + wsDir;
					half4 scannerCol = 0;
					half dist = distance(wsPos, _WorldSpaceScannerPos);
					if (dist < _ScanDistance && dist > _ScanDistance - _ScanWidth && linearDepth < 1)
					{
						float diff = 1 - (_ScanDistance - dist) / (_ScanWidth);
						half4 edge = lerp(_MidColor, _LeadColor, pow(diff, _LeadSharp));
						scannerCol = lerp(_TrailColor, edge, diff)/* + horizBars(input.uv) * _HBarColor*/;
						scannerCol *= diff;
					}

					return color + scannerCol;
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
