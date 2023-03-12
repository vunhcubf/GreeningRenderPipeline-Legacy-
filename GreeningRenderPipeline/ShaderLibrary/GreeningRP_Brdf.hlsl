#ifndef GREENINGRP_BRDF
#define GREENINGRP_BRDF

#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"

struct BxDFContext
{
	half NoV;
	half NoL;
	half VoL;
	half NoH;
	half VoH;
};
//////////////////
//基于LearnOpengl的实现
//////////////////
float3 Fresnel_Schlick(float3 SpecularColor,float VoH){
	float VoH_5=Pow5(1.0f-VoH);
	return lerp(SpecularColor,1.0f.xxx,VoH_5.xxx);
}
float DistributionGGX(float NoH,float Roughness){
	float a2=Pow4(Roughness);
	float nominator=a2;
	float denominator=NoH*NoH*(a2-1.0f)+1.0f;
	denominator=PI*denominator*denominator;
	return nominator/denominator;
}
float GeometrySmith(float NoV,float NoL,float Roughness){//整合分子
	float k=Roughness+1.0f;
	k=k*k/8.0f;
	return 0.25f*rcp(lerp(NoV,1.0f,k))*rcp(lerp(NoL,1.0f,k));
}
float3 Brdf_Diffuse_Specular_LearnOpengl(float3 BaseColor,float Roughness,float Metallic,BxDFContext Context){
	float3 SpecularColor=lerp(0.04f.xxx,BaseColor.xyz,Metallic.xxx);
	float3 F=Fresnel_Schlick(SpecularColor,Context.VoH);
	float D=DistributionGGX(Context.NoH,Roughness);
	float G=GeometrySmith(Context.NoV,Context.NoL,Roughness);
	float3 DiffuseTerm=(1.0f.xxx-Metallic.xxx)*(1.0f.xxx-F)*BaseColor*REVERSE_PI;
	float3 SpecularTerm=D*F*G;
	return Context.NoL.xxx*(DiffuseTerm+SpecularTerm);
}
//////////////////
float3 FresnelSchlickRoughness(float VoH,float3 SpecularColor,float Roughness){
	float r1=1.0f-Roughness;
	return SpecularColor + (max(r1.xxx, SpecularColor) - SpecularColor) * Pow5(1 - VoH);
}
//////////////////
//基于UE5的实现
//////////////////
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
float3 Brdf_Diffuse_Specular_Ue5(float3 BaseColor,float Roughness,float Metallic,BxDFContext Context){
	float3 SpecularColor=lerp(0.04f.xxx,BaseColor.xyz,Metallic.xxx);
	float3 DiffuseColor=(1-Metallic)*BaseColor*REVERSE_PI;
	return Context.NoL*(DiffuseColor+SpecularGGX(Roughness,SpecularColor,Context));
}
//////////////////


#endif