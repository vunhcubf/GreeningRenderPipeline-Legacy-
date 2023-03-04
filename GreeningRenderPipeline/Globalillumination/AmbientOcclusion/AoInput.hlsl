#ifndef AO_INPUT_INCLUDED
#define AO_INPUT_INCLUDED
int MAXDISTANCE;
half RADIUS;//RADIUS_PIXEL
int STEPCOUNT;
int DIRECTIONCOUNT;
half AngleBias;
half AoDistanceAttenuation;
half Intensity;
//纹素大小
SamplerState Point_Clamp;
SamplerState Linear_Clamp;

int Kernel_Radius;
half BlurSharpness;
half TemporalFilterIntensity;

Texture2D GBuffer0;
Texture2D GBuffer1;
Texture2D GBuffer2;
Texture2D RT_Spatial_In_X;
Texture2D RT_Spatial_In_Y;
Texture2D RT_MultiBounce_In;
Texture2D AmbientOcclusion;
Texture2D _AO_Previous_RT;
Texture2D RT_Temporal_In;
Texture2D SceneDepth;
Texture2D _MotionVectorTexture;



#endif