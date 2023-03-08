#ifndef GREENINGRP_BRDF
#define GREENINGRP_BRDF

#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"

//////////////////从ue5抄来的
struct BxDFContext
{
	half NoV;
	half NoL;
	half VoL;
	half NoH;
	half VoH;
};
float D_GGX( float a2, float NoH )
{
	float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
	return a2 / ( PI*d*d );					// 4 mul, 1 rcp
}
float Vis_SmithJointApprox( float a2, float NoV, float NoL )
{
	float a = sqrt(a2);
	float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
	float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
	return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
}
float3 F_Schlick( float3 SpecularColor, float VoH )
{
	float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return Fc + (1 - Fc) * SpecularColor;
}
float3 SpecularGGX( float Roughness, float3 SpecularColor, BxDFContext Context)
{
	float a2 = Pow4( Roughness );
	
	// Generalized microfacet specular
	float D = D_GGX( a2, Context.NoH );
	float Vis = Vis_SmithJointApprox( a2, Context.NoV, Context.NoL );
	float3 F = F_Schlick( SpecularColor, Context.VoH );

	return (D * Vis) * F;
}
BxDFContext BxDFContext_Init(float3 N,float3 V,float3 L){
	BxDFContext Out;
	float3 H=normalize(V+L);
	Out.NoV=saturate(dot(N,V))+1e-6f;
	Out.NoL=saturate(dot(N,L))+1e-6f;
	Out.VoL=saturate(dot(V,L))+1e-6f;
	Out.NoH=saturate(dot(N,H))+1e-6f;
	Out.VoH=saturate(dot(V,H))+1e-6f;
	return Out;
}
/////////////////////
float3 Brdf_Diffuse_Specular(float3 BaseColor,float Roughness,float Metallic,BxDFContext Context){
	float3 SpecularColor=lerp(0.08f*0.5,BaseColor,Metallic.xxx);
	float3 DiffuseColor=(1-Metallic)*BaseColor/PI;
	return Context.NoL*(DiffuseColor+SpecularGGX(Roughness,SpecularColor,Context));
}
#endif