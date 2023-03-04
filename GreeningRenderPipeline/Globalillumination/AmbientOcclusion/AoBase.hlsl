#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

#if defined FULL_PRECISION_AO
#define half float
#define half2 float2
#define half3 float3
#define half4 float4
#define half4x4 float4x4
#define half3x3 float3x3
#endif

//declaredepth这个库，指定lod等级
TEXTURE2D_X_FLOAT(_CameraDepthTexture);
SamplerState Point_Clamp;
SamplerState Linear_Clamp;
half SampleSceneDepth(half2 uv)
{
    return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, Point_Clamp, UnityStereoTransformScreenSpaceTex(uv),0).r;
}
//*******************************



////函数

//正确的世界坐标
// half3 BuildViewPos(half2 uv){
//     half3 Vec;
//     Vec.xy=uv*2-1;
//     Vec.xy*=half2(_ScreenParams.x/_ScreenParams.y,1)*tan(fov*3.1415926/360);
//     Vec.z=-1;
//     return Vec*LinearEyeDepth(SampleSceneDepth(uv),_ZBufferParams);
// }







