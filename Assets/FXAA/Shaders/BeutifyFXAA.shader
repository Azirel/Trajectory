Shader "Custom/ImageEffects/BeutifyFXAA"
{
	Properties
	{
		[HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
		[HideInInspector]_rcpFrame("_rcpFrame", Vector) = (0,0,0,0)
		[HideInInspector]_rcpFrameOpt("_rcpFrameOpt", Vector) = (0,0,0,0)
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

	/*bool FXAA_GATHER4_ALPHA;
	bool FXAA_DISCARD;*/
	uniform float4 _rcpFrame;
	uniform float4 _rcpFrameOpt;

	struct Attributes
	{
		float4 positionOS       : POSITION;
		float2 uv               : TEXCOORD0;
	};

	struct Varyings
	{
		float2 uv        : TEXCOORD0;
		float4 vertex	 : SV_POSITION;
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

	float4 luma(float4 result)
	{
		result.a = dot( result.xyz, float3( 0.299f, 0.587f, 0.114f ) );
		return result;
	}

	#define int2 float2
	#define FxaaInt2 float2
	#define FxaaFloat2 float2
	#define FxaaFloat3 float3
	#define FxaaFloat4 float4
	#define FxaaDiscard clip(-1)
	#define FxaaDot3(a, b) dot(a, b)
	#define FxaaSat(x) saturate(x)
	#define FxaaLerp(x,y,s) lerp(x,y,s)
	#define FxaaTexTop(p) luma( SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, p, unity_StereoEyeIndex))
	#define FxaaTexOff(p, o, r) luma( SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, p + (o * r), unity_StereoEyeIndex))

	#ifndef FXAA_QUALITY__EDGE_THRESHOLD
	#define FXAA_QUALITY__EDGE_THRESHOLD (1.0/3.0)
	#endif
	#ifndef FXAA_QUALITY__EDGE_THRESHOLD_MIN
		#define FXAA_QUALITY__EDGE_THRESHOLD_MIN (1.0/12.0)
	#endif
	#ifndef FXAA_QUALITY__SUBPIX
		#define FXAA_QUALITY__SUBPIX (1)
	#endif

	half4 FxaaPixelShader_Quality(float2 pos,float2 rcpFrame,float4 rcpFrameOpt)
	{   
    float2 posM;
    posM.x = pos.x;
    posM.y = pos.y;
    #if (FXAA_GATHER4_ALPHA == 1)
        #if (FXAA_DISCARD == 0)
            float4 rgbyM = FxaaTexTop(tex, posM);
            #define lumaM rgbyM.w
        #endif            
        float4 luma4A = FxaaTexAlpha4(tex, posM, rcpFrame.xy);
        float4 luma4B = FxaaTexOffAlpha4(tex, posM, FxaaInt2(-1, -1), rcpFrame.xy);
        #if (FXAA_DISCARD == 1)
            #define lumaM luma4A.w
        #endif
        #define lumaE luma4A.z
        #define lumaS luma4A.x
        #define lumaSE luma4A.y
        #define lumaNW luma4B.w
        #define lumaN luma4B.z
        #define lumaW luma4B.x
    #else
        float4 rgbyM = FxaaTexTop(posM);
        #define lumaM rgbyM.w
        float lumaS = FxaaTexOff(posM, FxaaInt2( 0, 1), rcpFrame.xy);
        float lumaE = FxaaTexOff(posM, FxaaInt2( 1, 0), rcpFrame.xy);
        float lumaN = FxaaTexOff(posM, FxaaInt2( 0,-1), rcpFrame.xy);
        float lumaW = FxaaTexOff(posM, FxaaInt2(-1, 0), rcpFrame.xy);
    #endif
    float maxSM = max(lumaS, lumaM);
    float minSM = min(lumaS, lumaM);
    float maxESM = max(lumaE, maxSM); 
    float minESM = min(lumaE, minSM); 
    float maxWN = max(lumaN, lumaW);
    float minWN = min(lumaN, lumaW);
    float rangeMax = max(maxWN, maxESM);
    float rangeMin = min(minWN, minESM);
    float rangeMaxScaled = rangeMax * FXAA_QUALITY__EDGE_THRESHOLD;
    float range = rangeMax - rangeMin;
    float rangeMaxClamped = max(FXAA_QUALITY__EDGE_THRESHOLD_MIN, rangeMaxScaled);
    bool earlyExit = range < rangeMaxClamped;
    if(earlyExit) 
        #if (FXAA_DISCARD == 1)
            FxaaDiscard;
        #else
            return rgbyM;
        #endif
    #if (FXAA_GATHER4_ALPHA == 0) 
        float lumaNW = FxaaTexOff(posM, FxaaInt2(-1,-1), rcpFrame.xy);
        float lumaSE = FxaaTexOff(posM, FxaaInt2( 1, 1), rcpFrame.xy);
        float lumaNE = FxaaTexOff(posM, FxaaInt2( 1,-1), rcpFrame.xy);
        float lumaSW = FxaaTexOff(posM, FxaaInt2(-1, 1), rcpFrame.xy);
    #else
        float lumaNE = FxaaTexOff(posM, FxaaInt2(1, -1), rcpFrame.xy);
        float lumaSW = FxaaTexOff(posM, FxaaInt2(-1, 1), rcpFrame.xy);
    #endif
    float lumaNS = lumaN + lumaS;
    float lumaWE = lumaW + lumaE;
    float subpixRcpRange = 1.0/range;
    float subpixNSWE = lumaNS + lumaWE;
    float edgeHorz1 = (-2.0 * lumaM) + lumaNS;
    float edgeVert1 = (-2.0 * lumaM) + lumaWE;
    float lumaNESE = lumaNE + lumaSE;
    float lumaNWNE = lumaNW + lumaNE;
    float edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
    float edgeVert2 = (-2.0 * lumaN) + lumaNWNE;
    float lumaNWSW = lumaNW + lumaSW;
    float lumaSWSE = lumaSW + lumaSE;
    float edgeHorz4 = (abs(edgeHorz1) * 2.0) + abs(edgeHorz2);
    float edgeVert4 = (abs(edgeVert1) * 2.0) + abs(edgeVert2);
    float edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
    float edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
    float edgeHorz = abs(edgeHorz3) + edgeHorz4;
    float edgeVert = abs(edgeVert3) + edgeVert4;
    float subpixNWSWNESE = lumaNWSW + lumaNESE; 
    float lengthSign = rcpFrame.x;
    bool horzSpan = edgeHorz >= edgeVert;
    float subpixA = subpixNSWE * 2.0 + subpixNWSWNESE; 
    if(!horzSpan) lumaN = lumaW; 
    if(!horzSpan) lumaS = lumaE;
    if(horzSpan) lengthSign = rcpFrame.y;
    float subpixB = (subpixA * (1.0/12.0)) - lumaM;
    float gradientN = lumaN - lumaM;
    float gradientS = lumaS - lumaM;
    float lumaNN = lumaN + lumaM;
    float lumaSS = lumaS + lumaM;
    bool pairN = abs(gradientN) >= abs(gradientS);
    float gradient = max(abs(gradientN), abs(gradientS));
    if(pairN) lengthSign = -lengthSign;
    float subpixC = FxaaSat(abs(subpixB) * subpixRcpRange);
    float2 posB;
    posB.x = posM.x;
    posB.y = posM.y;
    float2 offNP;
    offNP.x = (!horzSpan) ? 0.0 : rcpFrame.x;
    offNP.y = ( horzSpan) ? 0.0 : rcpFrame.y;
    if(!horzSpan) posB.x += lengthSign * 0.5;
    if( horzSpan) posB.y += lengthSign * 0.5;
    float2 posN;
    posN.x = posB.x - offNP.x;
    posN.y = posB.y - offNP.y;
    float2 posP;
    posP.x = posB.x + offNP.x;
    posP.y = posB.y + offNP.y;
    float subpixD = ((-2.0)*subpixC) + 3.0;
    float lumaEndN = FxaaTexTop(posN);
    float subpixE = subpixC * subpixC;
    float lumaEndP = FxaaTexTop(posP);
    if(!pairN) lumaNN = lumaSS;
    float gradientScaled = gradient * 1.0/4.0;
    float lumaMM = lumaM - lumaNN * 0.5;
    float subpixF = subpixD * subpixE;
    bool lumaMLTZero = lumaMM < 0.0;
    lumaEndN -= lumaNN * 0.5;
    lumaEndP -= lumaNN * 0.5;
    bool doneN = abs(lumaEndN) >= gradientScaled;
    bool doneP = abs(lumaEndP) >= gradientScaled;
    if(!doneN) posN.x -= offNP.x * 1.5;
    if(!doneN) posN.y -= offNP.y * 1.5;
    bool doneNP = (!doneN) || (!doneP);
    if(!doneP) posP.x += offNP.x * 1.5;
    if(!doneP) posP.y += offNP.y * 1.5;
    if(doneNP) {
        if(!doneN) lumaEndN = FxaaTexTop(posN.xy);
        if(!doneP) lumaEndP = FxaaTexTop(posP.xy);
        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
        doneN = abs(lumaEndN) >= gradientScaled;
        doneP = abs(lumaEndP) >= gradientScaled;
        if(!doneN) posN.x -= offNP.x * 2.0;
        if(!doneN) posN.y -= offNP.y * 2.0;
        doneNP = (!doneN) || (!doneP);
        if(!doneP) posP.x += offNP.x * 2.0;
        if(!doneP) posP.y += offNP.y * 2.0;
        if(doneNP) {
            if(!doneN) lumaEndN = FxaaTexTop(posN.xy);
            if(!doneP) lumaEndP = FxaaTexTop(posP.xy);
            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
            doneN = abs(lumaEndN) >= gradientScaled;
            doneP = abs(lumaEndP) >= gradientScaled;
            if(!doneN) posN.x -= offNP.x * 2.0;
            if(!doneN) posN.y -= offNP.y * 2.0;
            doneNP = (!doneN) || (!doneP);
            if(!doneP) posP.x += offNP.x * 2.0;
            if(!doneP) posP.y += offNP.y * 2.0;
            if(doneNP) {
                if(!doneN) lumaEndN = FxaaTexTop(posN.xy);
                if(!doneP) lumaEndP = FxaaTexTop(posP.xy);
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = abs(lumaEndN) >= gradientScaled;
                doneP = abs(lumaEndP) >= gradientScaled;
                if(!doneN) posN.x -= offNP.x * 4.0;
                if(!doneN) posN.y -= offNP.y * 4.0;
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP.x += offNP.x * 4.0;
                if(!doneP) posP.y += offNP.y * 4.0;
                if(doneNP) {
                    if(!doneN) lumaEndN = FxaaTexTop(posN.xy);
                    if(!doneP) lumaEndP = FxaaTexTop(posP.xy);
                    if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                    if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                    doneN = abs(lumaEndN) >= gradientScaled;
                    doneP = abs(lumaEndP) >= gradientScaled;
                    if(!doneN) posN.x -= offNP.x * 2.0;
                    if(!doneN) posN.y -= offNP.y * 2.0;
                    if(!doneP) posP.x += offNP.x * 2.0; 
                    if(!doneP) posP.y += offNP.y * 2.0; } } } }
    float dstN = posM.x - posN.x;
    float dstP = posP.x - posM.x;
    if(!horzSpan) dstN = posM.y - posN.y;
    if(!horzSpan) dstP = posP.y - posM.y;
    bool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
    float spanLength = (dstP + dstN);
    bool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
    float spanLengthRcp = 1.0/spanLength;
    bool directionN = dstN < dstP;
    float dst = min(dstN, dstP);
    bool goodSpan = directionN ? goodSpanN : goodSpanP;
    float subpixG = subpixF * subpixF;
    float pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
    float subpixH = subpixG * FXAA_QUALITY__SUBPIX;
    float pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
    float pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
    if(!horzSpan) posM.x += pixelOffsetSubpix * lengthSign;
    if( horzSpan) posM.y += pixelOffsetSubpix * lengthSign;
    return FxaaTexTop(posM); }
	half4 frag(Varyings input) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
		return FxaaPixelShader_Quality(input.uv, _rcpFrame, _rcpFrameOpt);
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
