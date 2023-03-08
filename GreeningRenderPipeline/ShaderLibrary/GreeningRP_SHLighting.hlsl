#ifndef GREENINGRP_SHLIGHTING
#define GREENINGRP_SHLIGHTING

struct SH_Light
{
    float3 SH_1;
    float3 SH_2;
    float3 SH_3;
    float3 SH_4;
    float3 SH_5;
    float3 SH_6;
    float3 SH_7;
    float3 SH_8;
    float3 SH_9;
};
RWStructuredBuffer<SH_Light> MainSkyBox_SH;

float SHSample_1(float3 NormalWS){
    return 0.282094791774f;
}
float SHSample_2(float3 NormalWS){
    return 0.488602511903f*NormalWS.y;
}
float SHSample_3(float3 NormalWS){
    return 0.488602511903f*NormalWS.z;
}
float SHSample_4(float3 NormalWS){
    return 0.488602511903f*NormalWS.x;
}
float SHSample_5(float3 NormalWS){
    return 1.09254843059f*NormalWS.x*NormalWS.y;
}
float SHSample_6(float3 NormalWS){
    return 1.09254843059f*NormalWS.z*NormalWS.y;
}
float SHSample_7(float3 NormalWS){
    return 0.315391565253f*(3*NormalWS.z*NormalWS.z-1.0f);
}
float SHSample_8(float3 NormalWS){
    return 1.09254843059f*NormalWS.z*NormalWS.x;
}
float SHSample_9(float3 NormalWS){
    return 0.546274215296f*(NormalWS.x*NormalWS.x-NormalWS.y*NormalWS.y);
}
float3 GetViewDirWSFromCubeMapUv(float2 uv){
    uint2 FacingNum;
    float2 uv_1=uv*float2(3.0f,2.0f);
    uv_1=frac(uv_1);
    uv_1=uv_1*2.0f-1.0f;
    float3 ViewDirWS[6]={float3(uv_1.x,uv_1.y,1.0f),
                        float3(-uv_1.x,1.0f,uv_1.y),
                        float3(-uv_1.x,-1.0f,-uv_1.y),
                        float3(1.0f,uv_1.y,-uv_1.x),
                        float3(-uv_1.x,uv_1.y,-1.0f),
                        float3(-1.0f,uv_1.y,uv_1.x)
                        };
    uv*=float2(3.0f,2.0f);
    FacingNum=floor(uv);
    float3 ViewDirWS_1=normalize(ViewDirWS[FacingNum.x+FacingNum.y*3]);
    return -ViewDirWS_1;
}
static float AreaElement(float x, float y)
{
    return atan2(x * y, sqrt(x * x + y * y + 1));
}

static float GetDifferentialSolidAngle(int textureSize, float2 uv)
{
    uv*=float2(3.0f,2.0f);
    uv=frac(uv);
    float inv = 1.0f / textureSize;
    float u = 2.0f * (uv.x + 0.5f * inv) - 1;
    float v = 2.0f * (uv.y + 0.5f * inv) - 1;
    float x0 = u - inv;
    float y0 = v - inv;
    float x1 = u + inv;
    float y1 = v + inv;
    return AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
}

float3 GetSHLighting(float3 NormalWS){
    float3 Color1=SHSample_1(NormalWS)*MainSkyBox_SH[0].SH_1;
    float3 Color2=SHSample_2(NormalWS)*MainSkyBox_SH[0].SH_2;
    float3 Color3=SHSample_3(NormalWS)*MainSkyBox_SH[0].SH_3;
    float3 Color4=SHSample_4(NormalWS)*MainSkyBox_SH[0].SH_4;
    float3 Color5=SHSample_5(NormalWS)*MainSkyBox_SH[0].SH_5;
    float3 Color6=SHSample_6(NormalWS)*MainSkyBox_SH[0].SH_6;
    float3 Color7=SHSample_7(NormalWS)*MainSkyBox_SH[0].SH_7;
    float3 Color8=SHSample_8(NormalWS)*MainSkyBox_SH[0].SH_8;
    float3 Color9=SHSample_9(NormalWS)*MainSkyBox_SH[0].SH_9;
    return Color1+Color2+Color3+Color4+Color5+Color6+Color7+Color8+Color9;
}
#endif