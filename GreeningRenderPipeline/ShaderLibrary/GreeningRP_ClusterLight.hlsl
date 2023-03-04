#ifndef GREENINGRP_CLUSTERLIGHT
#define GREENINGRP_CLUSTERLIGHT

#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Core.hlsl"
#include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_Input.hlsl"

struct ClusterBox{
    float3 p1;
    float3 p2;
    float3 p3;
    float3 p4;
    float3 p5;
    float3 p6;
    float3 p7;
    float3 p8;
};
struct AABB{
    float2 X_MinMax;
    float2 Y_MinMax;
    float2 Z_MinMax;
};
//获取球的截头锥包围盒
ClusterBox GetSphereFrustum(float3 PositionWS,float Range){
    float3 D=mul(World2View_Matrix,float4(PositionWS,1.0f)).xyz;
    float r=Range;
    D.z=abs(D.z);
    float Far=D.z+Range;
    float Near=D.z-Range;

    float3 p1,p2,p3,p4,p5,p6,p7,p8;
    
    float2 D_xoz=D.xz;
    float d_xoz=length(D_xoz);
    float a_xoz=r*d_xoz*rsqrt(d_xoz*d_xoz-r*r);
    float2 vec1_xoz,vec2_xoz;
    vec1_xoz=normalize(float2(D_xoz.y,-D_xoz.x));
    vec2_xoz=-vec1_xoz;
    vec1_xoz*=a_xoz;
    vec2_xoz*=a_xoz;
    vec1_xoz+=D_xoz;
    vec2_xoz+=D_xoz;

    p1.z=-Near;
    p2.z=-Near;
    p3.z=-Near;
    p4.z=-Near;
    p5.z=-Far;
    p6.z=-Far;
    p7.z=-Far;
    p8.z=-Far;

    p1.x=Near*vec1_xoz.x/vec1_xoz.y;
    p2.x=Near*vec2_xoz.x/vec2_xoz.y;
    p3.x=min(p1.x,p2.x);
    p4.x=max(p1.x,p2.x);
    p1.x=p3.x;
    p2.x=p4.x;

    p5.x=Far*vec1_xoz.x/vec1_xoz.y;
    p6.x=Far*vec2_xoz.x/vec2_xoz.y;
    p7.x=min(p5.x,p6.x);
    p8.x=max(p5.x,p6.x);
    p5.x=p7.x;
    p6.x=p8.x;

    float2 D_yoz=D.yz;
    float d_yoz=length(D_yoz);
    float a_yoz=r*d_yoz*rsqrt(d_yoz*d_yoz-r*r);
    float2 vec1_yoz,vec2_yoz;
    vec1_yoz=normalize(float2(D_yoz.y,-D_yoz.x));
    vec2_yoz=-vec1_yoz;
    vec1_yoz*=a_yoz;
    vec2_yoz*=a_yoz;
    vec1_yoz+=D_yoz;
    vec2_yoz+=D_yoz;

    p1.y=Near*vec1_yoz.x/vec1_yoz.y;
    p3.y=Near*vec2_yoz.x/vec2_yoz.y;
    p2.y=min(p1.y,p3.y);
    p4.y=max(p1.y,p3.y);
    p1.y=p2.y;
    p3.y=p4.y;

    p5.y=Far*vec1_yoz.x/vec1_yoz.y;
    p7.y=Far*vec2_yoz.x/vec2_yoz.y;
    p6.y=min(p5.y,p7.y);
    p8.y=max(p5.y,p7.y);
    p5.y=p6.y;
    p7.y=p8.y;

    ClusterBox Box;
    Box.p1=mul(View2World_Matrix,float4(p1,1.0f)).xyz;
    Box.p2=mul(View2World_Matrix,float4(p2,1.0f)).xyz;
    Box.p3=mul(View2World_Matrix,float4(p3,1.0f)).xyz;
    Box.p4=mul(View2World_Matrix,float4(p4,1.0f)).xyz;
    Box.p5=mul(View2World_Matrix,float4(p5,1.0f)).xyz;
    Box.p6=mul(View2World_Matrix,float4(p6,1.0f)).xyz;
    Box.p7=mul(View2World_Matrix,float4(p7,1.0f)).xyz;
    Box.p8=mul(View2World_Matrix,float4(p8,1.0f)).xyz;
    return Box;
}

// //目前还有问题
// //其中线段p3p4平行线段p1p2,p3p4为远平面上的点,p1p2为近平面上的点
// bool IsPointInQuadrilateral(float2 Point,float2 p1,float2 p2,float2 p3,float2 p4){
//     float FarNear_Interpolation=(Point.y-p2.y)/(p4.y-p2.y);
//     bool IsInNear_Far=0.0f<FarNear_Interpolation && FarNear_Interpolation<1.0f;
//     float Left=lerp(p1.x,p3.x,FarNear_Interpolation);
//     float Right=lerp(p2.x,p4.x,FarNear_Interpolation);
//     bool IsInLeft_Right=Left<Point.x && Point.x<Right;
//     return IsInLeft_Right && IsInNear_Far;
// }

// //目前还有问题
// //其中线段p3p4平行线段p1p2,p3p4为远平面上的点,p1p2为近平面上的点
// bool IntersectCircleLadderShaped(float2 CircleCenter,float Range,float2 p1,float2 p2,float2 p3,float2 p4){
//     float2 p3p1=p3-p1;
//     float2 p1p3Normal=normalize(float2(-p3p1.y,p3p1.x));
//     float2 VectorLeft=float2(-1.0f,0.0f);
//     VectorLeft=Range*VectorLeft/abs(dot(VectorLeft,p1p3Normal));
//     float2 p3_prime=VectorLeft+p3+Range*p3p1/p3p1.y;
//     float2 p1_prime=VectorLeft+p1-Range*p3p1/p3p1.y;

//     float2 p4p2=p4-p2;
//     float2 p2p4Normal=normalize(float2(p4p2.y,-p4p2.x));
//     float2 VectorRight=float2(1.0f,0.0f);
//     VectorRight=Range*VectorRight/abs(dot(VectorRight,p2p4Normal));
//     float2 p2_prime=VectorRight+p2-Range*p4p2/p4p2.y;
//     float2 p4_prime=VectorRight+p4+Range*p4p2/p4p2.y;

//     return IsPointInQuadrilateral(CircleCenter,p1_prime,p2_prime,p3_prime,p4_prime);
// }

float PointToPlaneDistance(float3 Point,float3 PlanePoint1,float3 PlanePoint2,float3 PlanePoint3){
    float3 Vec=PlanePoint1-Point;
    float3 PlaneNormal=normalize(cross(PlanePoint3-PlanePoint1,PlanePoint2-PlanePoint1));
    return abs(dot(PlaneNormal,Vec));
}

bool PointInTriangle(float3 Point,float3 A,float3 B,float3 C){
    float Beta=(A.y-C.y)*Point.x+(C.x-A.x)*Point.y+A.x*C.x-C.x*A.y;
    Beta/=(A.y-C.y)*B.x+(C.x-A.x)*B.y+A.x*C.x-C.x*A.y;
    float Gamma=(A.y-B.y)*Point.x+(B.x-A.x)*Point.y+A.x*B.x-B.x*A.y;
    Gamma/=(A.y-B.y)*C.x+(B.x-A.x)*C.y+A.x*B.x-B.x*A.y;
    float Alpha=1.0f-Gamma-Beta;
    return 0.0f<=Alpha;
}

bool IsIntersectPlane(float3 Point,float3 PlanePoint1,float3 PlanePoint2,float3 PlanePoint3,float3 PlanePoint4,float Range){
    return PointToPlaneDistance(Point,PlanePoint1,PlanePoint2,PlanePoint3)<Range;
}

bool IntersectAABB(AABB Cluster,AABB Light){
    bool IsInX=!(Cluster.X_MinMax.y<Light.X_MinMax.x || Light.X_MinMax.y<Cluster.X_MinMax.x);
    bool IsInY=!(Cluster.Y_MinMax.y<Light.Y_MinMax.x || Light.Y_MinMax.y<Cluster.Y_MinMax.x);
    bool IsInZ=!(Cluster.Z_MinMax.y<Light.Z_MinMax.x || Light.Z_MinMax.y<Cluster.Z_MinMax.x);
    return IsInX && IsInY && IsInZ;
}
float3 GetNdcPos(float3 WorldPos){
    //简易版，满足比较aabb的要求即可
    float3 ViewPos=mul(World2View_Matrix,float4(WorldPos,1.0f)).xyz;
    ViewPos.z=abs(ViewPos.z);
    ViewPos.xy/=ViewPos.z;
    return ViewPos;
}
int3 GetCurCluster(float2 uv,float NdcDepth,int NumClusterX,int NumClusterY,int NumClusterZ){
    int3 id;
    id.x=floor(uv.x*NumClusterX);
    id.y=floor(uv.y*NumClusterY);
    float EyeDepth=LinearEyeDepth(NdcDepth);
    EyeDepth=(EyeDepth-NearClipPlane)/(FarClipPlane-NearClipPlane);
    EyeDepth=1.0f-EyeDepth;
    id.z=floor(EyeDepth*NumClusterZ);
    return id;
}
AABB GetAABBfromCluster(ClusterBox Box){
    AABB aabb;
    aabb.X_MinMax.x=GetNdcPos(Box.p5).x;
    aabb.X_MinMax.y=GetNdcPos(Box.p6).x;
    aabb.X_MinMax=float2(min(aabb.X_MinMax.x,aabb.X_MinMax.y),max(aabb.X_MinMax.x,aabb.X_MinMax.y));

    aabb.Y_MinMax.x=GetNdcPos(Box.p5).y;
    aabb.Y_MinMax.y=GetNdcPos(Box.p7).y;
    aabb.Y_MinMax=float2(min(aabb.Y_MinMax.x,aabb.Y_MinMax.y),max(aabb.Y_MinMax.x,aabb.Y_MinMax.y));

    aabb.Z_MinMax.x=GetNdcPos(Box.p1).z;
    aabb.Z_MinMax.y=GetNdcPos(Box.p5).z;
    aabb.Z_MinMax=float2(min(aabb.Z_MinMax.x,aabb.Z_MinMax.y),max(aabb.Z_MinMax.x,aabb.Z_MinMax.y));
    return aabb;
}

ClusterBox GetClusterFrustum(uint3 id,int NumClusterX,int NumClusterY,int NumClusterZ){
    float3 p1=float3((id.x+0.0f)/NumClusterX,(id.y+0.0f)/NumClusterY,0.0f);
    float3 p2=float3((id.x+1.0f)/NumClusterX,(id.y+0.0f)/NumClusterY,0.0f);
    float3 p3=float3((id.x+0.0f)/NumClusterX,(id.y+1.0f)/NumClusterY,0.0f);
    float3 p4=float3((id.x+1.0f)/NumClusterX,(id.y+1.0f)/NumClusterY,0.0f);
    float3 p5=float3((id.x+0.0f)/NumClusterX,(id.y+0.0f)/NumClusterY,1.0f);
    float3 p6=float3((id.x+1.0f)/NumClusterX,(id.y+0.0f)/NumClusterY,1.0f);
    float3 p7=float3((id.x+0.0f)/NumClusterX,(id.y+1.0f)/NumClusterY,1.0f);
    float3 p8=float3((id.x+1.0f)/NumClusterX,(id.y+1.0f)/NumClusterY,1.0f);
    ClusterBox Box;
    p1=GetPositionWS(p1);
    p2=GetPositionWS(p2);
    p3=GetPositionWS(p3);
    p4=GetPositionWS(p4);
    p5=GetPositionWS(p5);
    p6=GetPositionWS(p6);
    p7=GetPositionWS(p7);
    p8=GetPositionWS(p8);
    Box.p1=lerp(p1,p5,(id.z+0.0f)/NumClusterZ);
    Box.p5=lerp(p1,p5,(id.z+1.0f)/NumClusterZ);
    Box.p2=lerp(p2,p6,(id.z+0.0f)/NumClusterZ);
    Box.p6=lerp(p2,p6,(id.z+1.0f)/NumClusterZ);
    Box.p3=lerp(p3,p7,(id.z+0.0f)/NumClusterZ);
    Box.p7=lerp(p3,p7,(id.z+1.0f)/NumClusterZ);
    Box.p4=lerp(p4,p8,(id.z+0.0f)/NumClusterZ);
    Box.p8=lerp(p4,p8,(id.z+1.0f)/NumClusterZ);
    return Box;
}

//投影求交最准确，不会有漏解和错误解
bool PointDistanceInLineSegment(float2 p1,float2 p2,float2 Center,float Range){
    float2 p2p1=p2-p1;
    float2 p2Center=p2-Center;
    float2 LineNormal=normalize(float2(p2p1.y,-p2p1.x));
    float SignDistance=dot(LineNormal,p2Center);
    float2 Point=Center+SignDistance*LineNormal;
    float2 Vec1=Point-p1;
    float Ratio=Vec1.y/p2p1.y;
    return abs(SignDistance)<=Range && 0.0f<Ratio && Ratio<1.0f;
}

bool IntersectCircleLadderShaped(float2 Center,float Range,float2 p1,float2 p2,float2 p3,float2 p4){
    //先和包围球求交
    float2 BoundingSphereCenter=(p1+p2+p3+p4)*0.25f.xx;
    float BoundingSphereRadius=Max4(length(p1-BoundingSphereCenter),length(p2-BoundingSphereCenter),length(p3-BoundingSphereCenter),length(p4-BoundingSphereCenter));
    bool IsInBoundingSphere=length(BoundingSphereCenter-Center)<Range+BoundingSphereRadius;
    //判断光源是否在梯形内
    float FarNearInterpolationRatio=(Center.y-p2.y)/(p4.y-p2.y);
    bool IsInFarNear=0.0f<FarNearInterpolationRatio && FarNearInterpolationRatio<1.0f;
    float Left=lerp(p1.x,p3.x,FarNearInterpolationRatio);
    float Right=lerp(p2.x,p4.x,FarNearInterpolationRatio);
    bool IsInLeftRight=Left<Center.x && Center.x<Right;
    [branch]
    if(IsInLeftRight && IsInFarNear){
        return true;
    }
    [branch]
    if(!IsInBoundingSphere){
        return false;
    }
    //和四个角的球求交
    bool IsInSphere_p1=length(Center-p1)<Range;
    bool IsInSphere_p2=length(Center-p2)<Range;
    bool IsInSphere_p3=length(Center-p3)<Range;
    bool IsInSphere_p4=length(Center-p4)<Range;
    [branch]
    if(IsInSphere_p1 || IsInSphere_p2 || IsInSphere_p3 || IsInSphere_p4){
        return true;
    }
    //和左侧的线求交
    bool IsIntersectLeft=PointDistanceInLineSegment(p1,p3,Center,Range);
    //和右侧的线求交
    bool IsIntersectRight=PointDistanceInLineSegment(p2,p4,Center,Range);

    bool IsIntersectFar=abs(Center.y-p4.y)<Range && p3.x<Center.x && Center.x<p4.x;
    bool IsIntersectNear=abs(Center.y-p2.y)<Range && p1.x<Center.x && Center.x<p2.x;
    return IsIntersectLeft || IsIntersectRight || IsIntersectFar || IsIntersectNear;
}

uint Encode4ByteTouint32(uint a,uint b,uint c,uint d)
{
    a = 0x000000ff & a;
    b = 0x000000ff & b;
    c = 0x000000ff & c;
    d = 0x000000ff & d;
    b = b << 8;
    c = c << 16;
    d = d << 24;
    return a | b | c | d;
}
int4 Decodeuint32To4Byte(uint a)
{
    uint a_prime = a & 0x000000ff;
    uint b_prime = (a & 0x0000ff00)>> 8;
    uint c_prime = (a & 0x00ff0000)>> 16;
    uint d_prime = (a & 0xff000000)>> 24;
    int4 Out;
    Out.x = (int)a_prime;
    Out.y = (int)b_prime;
    Out.z = (int)c_prime;
    Out.w = (int)d_prime;
    return Out;
}
#endif