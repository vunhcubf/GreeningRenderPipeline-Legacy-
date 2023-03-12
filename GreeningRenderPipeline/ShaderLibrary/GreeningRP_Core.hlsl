#ifndef GREENINGRP_CORE
#define GREENINGRP_CORE
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"

#define PI 3.14159265358979323846f
#define REVERSE_PI 0.318309886184f

SamplerState point_clamp;
SamplerState bilinear_clamp;
SamplerState trilinear_clamp;
SamplerState point_repeat;
SamplerState bilinear_repeat;
SamplerState trilinear_repeat;

float Pow2(float a){
    return a*a;
}
int Encodefloat32Toint32(float In){
    return (int)(In*16777216.0f);
}
float Decodeint32Tofloat32(int In){
    return (float)In/16777216.0f;
}
float Pow4(float a){
    a=a*a;
    return a*a;
}
float3 SafeNormalize(float3 n){
    float Length2=dot(n,n)+1e-6f;
    return n*rsqrt(Length2);
}
float Pow5(float a){
    return Pow4(a)*a;
}
float Max4(float a,float b,float c,float d){
    return max(a,max(b,max(c,d)));
}
float3x3 GetTangentToWorldMatrix(float3 NormalWS,float3 TangentWS,float3 BiTangentWS){
    return float3x3(TangentWS.x,TangentWS.y,TangentWS.z,
                    BiTangentWS.x,BiTangentWS.y,BiTangentWS.z,
                    NormalWS.x,NormalWS.y,NormalWS.z);
}
float3 DecodeNormalMap(float3 TangentWS,float3 NormalWS,float3 BiNormalWS,float3 NormalMap,float NormalMapIntensity,float ReversedNormalMap){
    NormalMap=pow(NormalMap,0.4545f);
    NormalMap=NormalMap*2.0f-1.0f;
    NormalMap=lerp(NormalMap.xyz,NormalMap.yxz,ReversedNormalMap);
    return normalize(lerp(NormalWS,normalize(TangentWS*NormalMap.x+BiNormalWS*NormalMap.y+NormalWS*NormalMap.z),NormalMapIntensity));
}
float2 PackNormalOctQuadEncode(float3 n)
{
    n *= rcp(max(dot(abs(n), 1.0), 1e-6));
    float t = saturate(-n.z);
    return n.xy + (n.xy >= 0.0 ? t : -t);
}

float3 UnpackNormalOctQuadEncode(float2 f)
{
    float3 n = float3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = max(-n.z, 0.0);
    n.xy += n.xy >= 0.0 ? -t.xx : t.xx;
    return normalize(n);
}
float3 PackFloat2To888(float2 f)
{
    uint2 i = (uint2)(f * 4095.5);
    uint2 hi = i >> 8;
    uint2 lo = i & 255;
    uint3 cb = uint3(lo, hi.x | (hi.y << 4));
    return cb / 255.0;
}
float2 Unpack888ToFloat2(float3 x)
{
    uint3 i = (uint3)(x * 255.5);
    uint hi = i.z >> 4;
    uint lo = i.z & 15;
    uint2 cb = i.xy | uint2(lo << 8, hi << 8);
    return cb / 4095.0;
}
float3 PackOctNormal(float3 n){
    float2 octNormalWS = PackNormalOctQuadEncode(n);                  // values between [-1, +1], must use fp32 on some platforms.
    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0, +1]
    return float3(PackFloat2To888(remappedOctNormalWS));               // values between [ 0, +1]
}
float3 UnpackNormal(float3 pn)
{
    float2 remappedOctNormalWS = float2(Unpack888ToFloat2(pn));          // values between [ 0, +1]
    float2 octNormalWS = remappedOctNormalWS.xy * float(2.0) - float(1.0);// values between [-1, +1]
    return SafeNormalize(float3(UnpackNormalOctQuadEncode(octNormalWS)));              // values between [-1, +1]
}
float LinearEyeDepth(float z){
    return (FarClipPlane*NearClipPlane)/((FarClipPlane-NearClipPlane)*z+NearClipPlane);
}
float Linear01Depth(float z){
    return (LinearEyeDepth(z)-NearClipPlane)/(FarClipPlane-NearClipPlane);
}
float EyeDepthToZbufferDepth(float z){
    return LinearEyeDepth(z);
}
float _01DepthToZbufferDepth(float z){
    z=lerp(NearClipPlane,FarClipPlane,z);
    return EyeDepthToZbufferDepth(z);
}
float3 GetPositionWS(float2 uv,float NdcDepth){
    float EyeDepth=LinearEyeDepth(NdcDepth);
    uv=uv.xy*2.0f-1.0f;
    uv*=float2(1.0f,-1.0f);
	float4 ClipPos=float4(uv,NdcDepth,1.0f)*EyeDepth;
	return mul(CameraInvVP_Matrix,ClipPos).xyz;
}
float3 GetPositionWS(float3 NdcPos){
    return GetPositionWS(NdcPos.xy,NdcPos.z);
}
#endif