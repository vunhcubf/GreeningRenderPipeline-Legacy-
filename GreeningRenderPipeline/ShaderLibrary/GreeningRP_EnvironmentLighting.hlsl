#ifndef GREENINGRP_ENVIRENMENTLIGHTING
#define GREENINGRP_ENVIRENMENTLIGHTING

SamplerState Trilinear_Repeat;
SamplerState Point_Clamp;

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
    return Map.SampleLevel(Trilinear_Repeat,SphereUv,MipLevel).xyz;
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
    return Map.SampleLevel(Trilinear_Repeat,uv,MipLevel).xyz;
}
float2 Test(float3 ViewDirWS){
    ViewDirWS=ViewDirWS.xzy;
    ViewDirWS.z*=-1.0f;
    float MaxAxis=max(abs(ViewDirWS.z),max(abs(ViewDirWS.x),abs(ViewDirWS.y)));
    float2 uv;
    [branch]
    if(abs(ViewDirWS.z)==MaxAxis && ViewDirWS.z>=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xy;
        uv=uv*0.5+0.5;
        uv.y=1-uv.y;
        uv+=float2(1,0);
    }
    [branch]
    if(abs(ViewDirWS.z)==MaxAxis && ViewDirWS.z<=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xy;
        uv=uv*0.5+0.5;
        uv+=float2(2,0);
    }
    [branch]
    if(abs(ViewDirWS.x)==MaxAxis && ViewDirWS.x>=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.yz;
        uv=uv*0.5+0.5;
        uv.x=1-uv.x;
        uv+=float2(2,1);
    }
    [branch]
    if(abs(ViewDirWS.x)==MaxAxis && ViewDirWS.x<=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.yz;
        uv=uv*0.5+0.5;
        uv+=float2(0,1);
    }
    [branch]
    if(abs(ViewDirWS.y)==MaxAxis && ViewDirWS.y>=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xz;
        uv=uv*0.5+0.5;
        uv+=float2(1,1);
    }
    [branch]
    if(abs(ViewDirWS.y)==MaxAxis && ViewDirWS.y<=0.0f){
        ViewDirWS=ViewDirWS.xyz/MaxAxis;
        uv=ViewDirWS.xz;
        uv=uv*0.5+0.5;
        uv.x=1-uv.x;
        uv+=float2(0,0);
    }
    uv/=float2(3.0f,2.0f);
    return uv;
}



#endif