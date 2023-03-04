#ifndef GREENINGRP_CORE
#define GREENINGRP_CORE
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"

float Pow2(float a){
    return a*a;
}
float Pow5(float a){
    return Pow4(a)*a;
}
float Max4(float a,float b,float c,float d){
    return max(a,max(b,max(c,d)));
}
float3x3 GetTangentToWorldMatrix(float3 NormalWS,float3 TangentWS){
    float3 BiTangentWS=normalize(cross(NormalWS,TangentWS));
    return float3x3(TangentWS.x,TangentWS.y,TangentWS.z,
                    BiTangentWS.x,BiTangentWS.y,BiTangentWS.z,
                    NormalWS.x,NormalWS.y,NormalWS.z);
}
float3 DecodeNormalMap(float3 TangentWS,float3 NormalWS,float3 NormalMap,float NormalMapIntensity,float ReversedNormalMap){
    NormalMap=NormalMap*2.0f-1.0f;
    //NormalMap=NormalMap.yzx;
    NormalMap.xy*=NormalMapIntensity*(ReversedNormalMap*2.0f-1.0f);
    NormalMap.z=max(sqrt(1.0f-dot(NormalMap.xy,NormalMap.xy)),1e-4f);
    return normalize(mul(NormalMap,GetTangentToWorldMatrix(NormalWS,TangentWS)));
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
    return normalize(float3(UnpackNormalOctQuadEncode(octNormalWS)));              // values between [-1, +1]
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