#ifndef AO_LIB_INCLUDED
#define AO_LIB_INCLUDED
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"
#include "AoInput.hlsl"

#define NOISEINPUTSCALE 1000.0f
#define RADIUSSCALE_GTAO 500.0f
#define RADIUSSCALE_HBAO 100.0f
half Pow2(half x){
    return x*x;
}
half LinearEyeDepth(half z){
    return (FarClipPlane*NearClipPlane)/((FarClipPlane-NearClipPlane)*z+NearClipPlane);
}
half Linear01Depth(half z){
	return (LinearEyeDepth(z)-NearClipPlane)/(FarClipPlane-NearClipPlane);
}
half SampleSceneDepth(half2 uv)
{
    return SceneDepth.SampleLevel(Point_Clamp, uv,0).x;
}
half3 SampleSceneNormals(half2 uv){
    return UnpackNormal(GBuffer1.SampleLevel(Point_Clamp, uv,0).xyz);
}
bool GetSkyBoxMask(half2 uv){
    return step(SampleSceneDepth(uv),0);
}
half Noise2D(half2 p)
{
    p*=NOISEINPUTSCALE;
    #if defined USE_TEMPORALNOISE
    p*=1+_SinTime.y*0.5;
    #endif
    half3 p3  = frac(half3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}
half GetEyeDepth(half2 uv){
    return LinearEyeDepth(SampleSceneDepth(uv));
}
half3 GetPositionVs(half2 uv){
	float NdcDepth=SampleSceneDepth(uv);
    float EyeDepth=LinearEyeDepth(NdcDepth);
	float4 ClipPos=float4(uv.xy*2.0f-1.0f,NdcDepth,1.0f)*EyeDepth*float4(1,_ProjectionParams.x,1,1);
	return mul(InvProjection_Matrix,ClipPos).xyz;
}
half3 GetNormalVs(half2 uv){
    half3 Norm=SampleSceneNormals(uv);
    Norm=mul((half3x3)World2View_Matrix,Norm);
    return normalize(Norm);
}
half2 RotateDirection(half2 Vec,half x){
    return half2(Vec.x*cos(x)-Vec.y*sin(x),Vec.x*sin(x)+Vec.y*cos(x));
}
half FallOff(half Distance){
    return saturate(1-Distance*AoDistanceAttenuation*20.0);
}  
half2 FallOff(half2 Distance){
    return half2(FallOff(Distance.x),FallOff(Distance.y));
}        
half Noise2D(half2 value,half a ,half2 b)//1000,1000可以得到良好的噪声
{		
    #if defined USE_TEMPORALNOISE
    a*=1+_SinTime.y*0.1;
    #endif
    //avaoid artifacts
    half2 smallValue = sin(value);
    //get scalar value from 2d vector	
    half  random = dot(smallValue,b);
    random = frac(sin(random) * a);
    return random;
}
half GetUniformRadiusScale(half2 uv){
    return 1/length(GetPositionVs(uv));
}
half3 AOMultiBounce( half3 BaseColor, half AO )
{
	half3 a =  2.0404 * BaseColor - 0.3324;
	half3 b = -4.7951 * BaseColor + 0.6417;
	half3 c =  2.7552 * BaseColor + 0.6903;
	return max( AO, ( ( AO * a + b ) * AO + c ) * AO );
}

half Luminance(half3 rgb){
	return rgb.r*0.299 + rgb.g*0.587 + rgb.b*0.114;
}
half2 GetClosestUv(half2 uv){//要使用去除抖动的uv
	half2 Closest_Offset=half2(0,0);
	[unroll]
	for(int i=-1;i<=1;i++){
		[unroll]
		for(int j=-1;j<=1;j++){
			int flag=step(GetEyeDepth(uv),GetEyeDepth(uv+ScreenParams.xy*half2(i,j)));
			Closest_Offset=lerp(Closest_Offset,half2(i,j),flag);
		}
	}
	return ScreenParams.xy*Closest_Offset+uv;
}
void GetBoundingBox(out half cmin,out half cmax,half2 uv){
	half2 du=half2(1,0)*ScreenParams.xy;
	half2 dv=half2(0,1)*ScreenParams.xy;

	half ctl = RT_Temporal_In.SampleLevel(Point_Clamp, uv - dv - du,0).r;
	half ctc = RT_Temporal_In.SampleLevel(Point_Clamp, uv - dv,0).r;
	half ctr = RT_Temporal_In.SampleLevel(Point_Clamp, uv - dv + du,0).r;
	half cml = RT_Temporal_In.SampleLevel(Point_Clamp, uv - du,0).r;
	half cmc = RT_Temporal_In.SampleLevel(Point_Clamp, uv,0).r;
	half cmr = RT_Temporal_In.SampleLevel(Point_Clamp, uv + du,0).r;
	half cbl = RT_Temporal_In.SampleLevel(Point_Clamp, uv + dv - du,0).r;
	half cbc = RT_Temporal_In.SampleLevel(Point_Clamp, uv + dv,0).r;
	half cbr = RT_Temporal_In.SampleLevel(Point_Clamp, uv + dv + du,0).r;

	cmin = min(ctl, min(ctc, min(ctr, min(cml, min(cmc, min(cmr, min(cbl, min(cbc, cbr))))))));
	cmax = max(ctl, max(ctc, max(ctr, max(cml, max(cmc, max(cmr, max(cbl, max(cbc, cbr))))))));
}
void FetchAOAndDepth(half2 uv, inout half ao, inout half depth,bool Is_X){
	[branch] 
	if(Is_X){ao = RT_Spatial_In_X.SampleLevel(Point_Clamp, uv,0).r;}
	else{ao = RT_Spatial_In_Y.SampleLevel(Point_Clamp, uv,0).r;}
	depth = SampleSceneDepth(uv);
	depth = Linear01Depth(depth);
}
half CrossBilateralWeight(half r, half d, half d0){
	half blurSigma = Kernel_Radius * 0.5;
	half blurFalloff = 1.0 / (2.0 * blurSigma * blurSigma);

	half dz = (d0 - d) * _ProjectionParams.z * BlurSharpness;
	return exp2(-r * r * blurFalloff - dz * dz);
}

void ProcessSample(half ao, half d, half r, half d0, inout half totalAO, inout half totalW){
	half w = CrossBilateralWeight(r, d, d0);
	totalW += w;
	totalAO += w * ao;
}

void ProcessRadius(half2 uv0, half2 deltaUV, half d0, inout half totalAO, inout half totalW,bool Is_X){
	half ao;
	half d;
	half2 uv;
	[loop]
	for (int r = 1; r <= Kernel_Radius; r++)
	{
		uv = uv0 + r * deltaUV;
		FetchAOAndDepth(uv, ao, d,Is_X);
		ProcessSample(ao, d, r, d0, totalAO, totalW);
	}
}
#endif