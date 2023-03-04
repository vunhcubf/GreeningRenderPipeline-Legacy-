#ifndef GREENINGRP_INPUT
#define GREENINGRP_INPUT
cbuffer UnityPerDraw{
        // Space block Feature
    float4x4 unity_ObjectToWorld;
    float4x4 unity_WorldToObject;
    float4 unity_LODFade; // x is the fade value ranging within [0,1]. y is x quantized into 16 levels
    float4 unity_WorldTransformParams; // w is usually 1.0, or -1.0 for odd-negative scale transforms
};

cbuffer UnityPerCamera{
    // Time (t = time since current level load) values from Unity
    float4 _Time; // (t/20, t, t*2, t*3)
    float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
    float4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
    float4 unity_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt
    float3 _WorldSpaceCameraPos;

    // x = 1 or -1 (-1 if projection is flipped)
    // y = near plane
    // z = far plane
    // w = 1/far plane
    float4 _ProjectionParams;

    // x = width
    // y = height
    // z = 1 + 1.0/width
    // w = 1 + 1.0/height
    float4 _ScreenParams;

    // Values used to linearize the Z buffer (http://www.humus.name/temp/Linearize%20depth.txt)
    // x = 1-far/near
    // y = far/near
    // z = x/far
    // w = y/far
    // or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1)
    // x = -1+far/near
    // y = 1
    // z = x/far
    // w = 1/far
    float4 _ZBufferParams;

    // x = orthographic camera's width
    // y = orthographic camera's height
    // z = unused
    // w = 1.0 if camera is ortho, 0.0 if perspective
    float4 unity_OrthoParams;
    //x-component is the half stereo separation value, which a positive for right eye and negative for left eye. The y,z,w components are unused.
    float4 unity_HalfStereoSeparation;
};

//这里是我自己加的，上面的是抄unityinput.hlsl的
float fov;
float FarClipPlane;
float NearClipPlane;
float Aspect;
float4 ScreenParams;
float4x4 InvProjection_Matrix;
float4x4 World2View_Matrix;
float4x4 View2World_Matrix;
float4x4 Projection_Matrix;
float4x4 CameraVP_Matrix;
float4x4 CameraInvVP_Matrix;

cbuffer UnityPerFrame{
    float4 glstate_lightmodel_ambient;
    float4 unity_AmbientSky;
    float4 unity_AmbientEquator;
    float4 unity_AmbientGround;
    float4 unity_IndirectSpecColor;
    float4x4 glstate_matrix_projection;
    float4x4 unity_MatrixV;
    float4x4 unity_MatrixInvV;
    float4x4 unity_MatrixVP;
    int unity_StereoEyeIndex;
    float4 unity_ShadowColor;
    //这些矩阵只有在绘制物体的时候有用
};

float4x4 OptimizeProjectionMatrix(float4x4 M)
{
    M._21_41 = 0;
    M._12_42 = 0;
    return M;
}
#define unity_MatrixP OptimizeProjectionMatrix(glstate_matrix_projection)
#endif