#ifndef GREENINGRP_ENVIRENMENTLIGHTING
#define GREENINGRP_ENVIRENMENTLIGHTING

#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Brdf.hlsl"

TextureCube SkyBoxMap;
int SkyBoxMap_MaxMipLevel;
Texture2D Brdf_Lut;

float PerceptualRoughnessToMipmapLevel(float Roughness, uint maxMipLevel)
{
    float perceptualRoughness=Roughness*Roughness;
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    return perceptualRoughness * maxMipLevel;
}
float GetArgumentfromVector2(float2 Vec2){
    float tan=atan(Vec2.y/Vec2.x);
    float mask;
    [flatten]
    if(Vec2.x<0){
        mask=PI;
    }
    else{
        mask=0.0f;
    }
    return (tan+PI*0.5f+mask)/(2*PI);
}
float3 SamplePanomanicMap(Texture2D Map,float3 ViewDirWS,float Rotation,uint MipLevel){
    float2 SphereUv;
    SphereUv.x=frac(GetArgumentfromVector2(ViewDirWS.xz)+Rotation);
    SphereUv.y=acos(ViewDirWS.y)/PI;
    return Map.SampleLevel(trilinear_clamp,SphereUv,MipLevel).xyz;
}
float3 SampleCubeMap(Texture2D Map,float3 ViewDirWS,float Rotation,uint MipLevel){
    #define UvScaler 0.99f
    Rotation*=2*PI;
    ViewDirWS.xz=float2(dot(ViewDirWS.xz,float2(cos(Rotation),-sin(Rotation))),dot(ViewDirWS.xz,float2(sin(Rotation),cos(Rotation))));
    ViewDirWS=ViewDirWS.xzy;
    ViewDirWS.z*=-1.0f;
    float MaxAxis=max(abs(ViewDirWS.z),max(abs(ViewDirWS.x),abs(ViewDirWS.y)));
    float2 uv;
    [branch]
    if(abs(ViewDirWS.z)==MaxAxis && ViewDirWS.z>=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xy;
        uv*=UvScaler;
        uv=uv*0.5+0.5;
        uv.y=1-uv.y;
        uv+=float2(1,0);
    }
    [branch]
    if(abs(ViewDirWS.z)==MaxAxis && ViewDirWS.z<=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xy;
        uv*=UvScaler;
        uv=uv*0.5+0.5;
        uv+=float2(2,0);
    }
    [branch]
    if(abs(ViewDirWS.x)==MaxAxis && ViewDirWS.x>=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.yz;
        uv*=UvScaler;
        uv=uv*0.5+0.5;
        uv.x=1-uv.x;
        uv+=float2(2,1);
    }
    [branch]
    if(abs(ViewDirWS.x)==MaxAxis && ViewDirWS.x<=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.yz;
        uv*=UvScaler;
        uv=uv*0.5+0.5;
        uv+=float2(0,1);
    }
    [branch]
    if(abs(ViewDirWS.y)==MaxAxis && ViewDirWS.y>=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xz;
        uv*=UvScaler;
        uv=uv*0.5+0.5;
        uv+=float2(1,1);
    }
    [branch]
    if(abs(ViewDirWS.y)==MaxAxis && ViewDirWS.y<=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xz;
        uv*=UvScaler;
        uv=uv*0.5+0.5;
        uv.x=1-uv.x;
        uv+=float2(0,0);
    }
    uv/=float2(3.0f,2.0f);
    return Map.SampleLevel(trilinear_clamp,uv,MipLevel).xyz;
}

float3 SampleEnvironmentReflection(float Roughness,float3 NormalWS,float3 ViewDirWS,uint maxMipLevel,float3 BaseColor,float Metallic){
    float3 ReflectDir=reflect(-ViewDirWS,NormalWS);
    float mip=PerceptualRoughnessToMipmapLevel(Roughness,maxMipLevel);
    float3 ReflectColor=SkyBoxMap.SampleLevel(trilinear_clamp,ReflectDir,mip).xyz;
    float NoV=saturate(dot(NormalWS,ViewDirWS));
    float2 Brdf=abs(lerp(0.01f.xx,0.99f.xx,Brdf_Lut.SampleLevel(bilinear_clamp,float2(NoV,Roughness),0).xy));
    Brdf=pow(Brdf,0.4545f);
    float3 SpecularColor=lerp(0.04.xxx,BaseColor.xyz,Metallic.xxx);
    float3 FresnelTerm=FresnelSchlickRoughness(NoV,SpecularColor,Roughness);

    float3 Specular_Brdf=ReflectColor*(FresnelTerm*Brdf.xxx+Brdf.yyy);
    return Specular_Brdf;
}
float3 SampleEnvironment_Diffuse_Specular(float Roughness,float3 NormalWS,float3 ViewDirWS,uint maxMipLevel,float3 BaseColor,float Metallic,float Occlusion){
    float3 ReflectDir=reflect(-ViewDirWS,NormalWS);
    float mip=PerceptualRoughnessToMipmapLevel(Roughness,maxMipLevel);
    float3 ReflectColor=SkyBoxMap.SampleLevel(trilinear_clamp,ReflectDir,mip).xyz;
    float NoV=saturate(dot(NormalWS,ViewDirWS));
    float2 Brdf=abs(lerp(0.01f.xx,0.99f.xx,Brdf_Lut.SampleLevel(bilinear_clamp,float2(NoV,Roughness),0).xy));
    Brdf=pow(Brdf,0.4545f);
    float3 SpecularColor=lerp(0.04.xxx,BaseColor.xyz,Metallic.xxx);
    float3 FresnelTerm=FresnelSchlickRoughness(NoV,SpecularColor,Roughness);

    float3 Specular_Brdf=ReflectColor*(FresnelTerm*Brdf.xxx+Brdf.yyy);
    float3 Diffuse_Brdf=(1.0f.xxx-FresnelTerm)*(1.0f.xxx-Metallic.xxx)*BaseColor*SkyBoxMap.SampleLevel(trilinear_clamp,ReflectDir,maxMipLevel).xyz*0.318309886184f;
    return Diffuse_Brdf*Occlusion+Specular_Brdf;
}


#endif