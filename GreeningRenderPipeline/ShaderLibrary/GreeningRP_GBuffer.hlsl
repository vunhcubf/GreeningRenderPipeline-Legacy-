#ifndef GREENINGRP_GBUFFER
#define GREENINGRP_GBUFFER
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"

cbuffer UnityPerMaterial{
    sampler2D BaseColorMap;
    sampler2D MetallicMap;
    sampler2D RoughnessMap;
    sampler2D NormalMap;
    sampler2D OcclusionMap;

    float4 BaseColorMap_ST;

    int ShadingModel;
    float NormalMap_Intensity;
    float OcclusionMap_Intensity;
    float Roughness_Multiplier;
    float Metallic_Multiplier;
    float4 BaseColor_Tint;
    float ReversedNormalMap;
};
struct VertexInput_GBuffer{
    float4 PositionOS:POSITION;
    float2 uv:TEXCOORD0;
    float3 NormalOS:NORMAL;
    float3 TangentOS:TANGENT;
};
struct VertexOutput_GBuffer{
    float4 PositionCS:SV_POSITION;
    float2 uv:TEXCOORD0;
    float3 NormalWS:NORMAL;
    float3 TangentWS:TEXCOORD1;
    float3 BiNormalWS:TEXCOORD2;
    float3 PositionWS:TEXCOORD3;
};
float2 Transform_Tex(float2 uv,float4 Tex_ST){
    return uv.xy * Tex_ST.xy + Tex_ST.zw;
}
VertexOutput_GBuffer Vert_GBuffer(VertexInput_GBuffer v)
{
    VertexOutput_GBuffer o;
    o.PositionCS = mul(unity_ObjectToWorld,float4(v.PositionOS.xyz,1.0f));//M变换
    o.PositionWS=o.PositionCS.xyz;
    o.PositionCS = mul(unity_MatrixVP,float4(o.PositionCS.xyz,1.0f));//VP变换
    o.NormalWS=mul((float3x3)unity_ObjectToWorld,v.NormalOS);
    o.TangentWS=mul((float3x3)unity_ObjectToWorld,v.TangentOS);
    o.BiNormalWS=cross(o.NormalWS,o.TangentWS);
    o.uv = v.uv;
    return o;
}
struct GBufferOutput{
    float4 GBuffer0:SV_Target0;
    float4 GBuffer1:SV_Target1;
    float4 GBuffer2:SV_Target2;
    float CameraDepth:SV_Depth;
};
GBufferOutput Frag_GBuffer(VertexOutput_GBuffer i){
    GBufferOutput Result_GBuffer;
    float2 uv=i.uv;
    float4 PositionCS=mul(CameraVP_Matrix,float4(i.PositionWS,1.0f));

    //处理法线贴图
    float3 NormalWS=normalize(i.NormalWS);
    float3 TangentWS=normalize(i.TangentWS);
    float3 BiNormalWS=normalize(i.BiNormalWS);
    float3 NormalMap_Data=tex2D(NormalMap,Transform_Tex(uv,BaseColorMap_ST)).xyz;
    NormalWS=DecodeNormalMap(TangentWS,NormalWS,BiNormalWS,NormalMap_Data,NormalMap_Intensity,ReversedNormalMap);

    float3 BaseColor=BaseColor_Tint.xyz*tex2D(BaseColorMap,Transform_Tex(uv,BaseColorMap_ST)).xyz;
    float Occlusion=saturate(pow(saturate(tex2D(OcclusionMap,Transform_Tex(uv,BaseColorMap_ST)).x),OcclusionMap_Intensity));
    float Roughness=max(5.0f/255.0f,saturate(Roughness_Multiplier*tex2D(RoughnessMap,Transform_Tex(uv,BaseColorMap_ST)).x));
    float Metallic=saturate(Metallic_Multiplier*tex2D(MetallicMap,Transform_Tex(uv,BaseColorMap_ST)).x);

    Result_GBuffer.GBuffer0=float4(BaseColor,Occlusion);
    Result_GBuffer.GBuffer1=float4(PackOctNormal(NormalWS),ShadingModel/255.0f);
    Result_GBuffer.GBuffer2=float4(Roughness,Metallic,1.0f,1.0f);
    float NdcDepth=PositionCS.z/PositionCS.w;
    Result_GBuffer.CameraDepth=NdcDepth;//已经reversed-z了
    return Result_GBuffer;
}

#endif