#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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


