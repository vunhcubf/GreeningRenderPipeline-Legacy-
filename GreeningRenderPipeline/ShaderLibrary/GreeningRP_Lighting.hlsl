#ifndef GREENINGRP_LIGHTING
#define GREENINGRP_LIGHTING
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"

struct PointLight{
    float3 Color;
    float3 PositionWS;
    float Range;
};
struct DirectionalLight{
    float3 Color;
    float3 Direction;
};
RWStructuredBuffer<PointLight> PointLightPropertiesList;
RWStructuredBuffer<DirectionalLight> DirectionalLightPropertiesList;
int PointLightCount;
int DirectionalLightCount;

bool IsAnyPointLight;
bool IsAnyDirectionalLight;

float3 GetDirectionalLight_Direction(int index){
    return normalize(DirectionalLightPropertiesList[index].Direction);
}
float3 GetDirectionalLight_Color(int index){
    return DirectionalLightPropertiesList[index].Color;
}

float3 GetPointLight_Direction(int index,float3 PositionWS){
    return normalize(PointLightPropertiesList[index].PositionWS-PositionWS);
}
float GetPointLight_DistanceAttenuation(int index,float3 PositionWS){
    float Distance=length(PointLightPropertiesList[index].PositionWS-PositionWS);
    float Range=PointLightPropertiesList[index].Range;
    float Attenuation=Pow2(1.0f-Pow4(saturate(Distance/Range)));
    return Attenuation;
}
float3 GetPointLight_Color(int index){
    return PointLightPropertiesList[index].Color;
}
#endif