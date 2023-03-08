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
struct SpotLight{
    float3 Color;
    float3 PositionWS;
    float3 Direction;
    float2 SpotAngleAttenuation;
    float Range;
};
RWStructuredBuffer<PointLight> PointLightPropertiesList;
RWStructuredBuffer<DirectionalLight> DirectionalLightPropertiesList;
RWStructuredBuffer<SpotLight> SpotLightPropertiesList;

int PointLightCount;
int DirectionalLightCount;
int SpotLightCount;

bool IsAnyPointLight;
bool IsAnyDirectionalLight;
bool IsAnySpotLight;

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

float3 GetSpotLight_Direction(int LightIndex){
    return SafeNormalize(SpotLightPropertiesList[LightIndex].Direction);
}
float3 GetSpotLight_LightDir(int LightIndex,float3 PositionWS){
    float3 LightPosition=SpotLightPropertiesList[LightIndex].PositionWS;
    return SafeNormalize(LightPosition-PositionWS);
}
float2 GetSpotLight_AttenuationParams(int LightIndex){
    return SpotLightPropertiesList[LightIndex].SpotAngleAttenuation;
}
float3 GetSpotLight_Color(int LightIndex){
    return SpotLightPropertiesList[LightIndex].Color;
}
float GetSpotLight_DistanceAttenuation(int index,float3 PositionWS){
    float Distance=length(SpotLightPropertiesList[index].PositionWS-PositionWS);
    float Range=SpotLightPropertiesList[index].Range;
    float Attenuation=Pow2(1.0f-Pow4(saturate(Distance/Range)));
    return Attenuation;
}
#endif