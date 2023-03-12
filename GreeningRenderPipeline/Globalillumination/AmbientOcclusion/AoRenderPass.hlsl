#include "AoLib.hlsl"
#include "AoInput.hlsl"
#define NOISEINPUTSCALE 1000.0f
#define RADIUSSCALE_GTAO 500.0f
#define RADIUSSCALE_HBAO 600.0f

struct VertexInput{
    half4 positionOS:POSITION;
    half2 uv:TEXCOORD0;
};

struct VertexOutput{
    half4 position:SV_POSITION;
    half2 uv:TEXCOORD0;
};
VertexOutput Vert_PostProcessDefault(VertexInput v)
{
    VertexOutput o;
    o.position = mul(unity_ObjectToWorld,float4(v.positionOS.xyz,1.0f));//M变换
    o.position = mul(unity_MatrixV,float4(o.position.xyz,1.0f));//V变换
    o.position = mul(unity_MatrixP,float4(o.position.xyz,1.0f));//P变换
    o.uv = v.uv;
    return o;
}
////////////////////////////////////////////////////////////////
//主要用到的函数
half ComputeHBAO(half3 P,half3 N,half3 S){
    half3 V=S-P;
    half VdotV=dot(V,V);
    half NdotV=dot(N,V)*rsqrt(VdotV);
    return saturate(NdotV-AngleBias)*FallOff(VdotV);//使用距离衰减
}
half ComputeGTAO(half h1,half h2,half n){
    return 0.25*(-cos(2*h2-n)+cos(n)+2*h2*sin(n))+0.25*(-cos(2*h1-n)+cos(n)+2*h1*sin(n));
}
half GetGTAO(half2 uv,half3 PositionVs,half3 NormalVs){
    half3 ViewDir=normalize(0-PositionVs);
    half AngleOffset=2*PI*Noise2D(uv);
    half AO,Angle,BentAngle,SliceLength,n,cos_n;
    half2 h,H,falloff,h1h2,h1h2Length,uvoffset;
    half3 SliceDir,h1,h2,PlaneNormal,PlaneTangent,SliceNormal,BentNormal;
    half4 uvSlice;
    BentNormal=0;
    AO=0;
    [loop]
    for(int i=0;i<DIRECTIONCOUNT;i++){
        Angle=PI*i/DIRECTIONCOUNT+AngleOffset;
        SliceDir=half3(cos(Angle),sin(Angle),0);

        PlaneNormal=normalize(cross(SliceDir,ViewDir));
        PlaneTangent=cross(ViewDir,PlaneNormal);
        SliceNormal=NormalVs-PlaneNormal*dot(NormalVs,PlaneNormal);
        SliceLength=length(SliceNormal);

        cos_n=clamp(dot(normalize(SliceNormal),ViewDir),-1,1);
        n=-sign(dot(SliceNormal,PlaneTangent))*acos(cos_n);
        h=-1;

        half StepSize=max(1.0,lerp(0.9,1.1,Noise2D(uv))*GetUniformRadiusScale(uv)*RADIUSSCALE_GTAO*RADIUS / (STEPCOUNT + 1.0));
        [loop]
        for(int j=0;j<STEPCOUNT;j++){
            uvoffset=SliceDir.xy*(1+j)*StepSize;
            uvoffset=round(uvoffset)*ScreenParams.xy;
            uvSlice=uv.xyxy+half4(uvoffset,-uvoffset);

            h1=GetPositionVs(uvSlice.xy)-PositionVs;
            h2=GetPositionVs(uvSlice.zw)-PositionVs;

            h1h2=half2(dot(h1,h1),dot(h2,h2));
            h1h2Length=rsqrt(h1h2);
            falloff=saturate(h1h2*(2/((Pow2(1.1-AoDistanceAttenuation)))));

            H=half2(dot(h1,ViewDir),dot(h2,ViewDir))*h1h2Length;
            h.xy=(H.xy>h.xy)?lerp(H,h,falloff):h;
        }
        h=acos(clamp(h,-1,1));
        h.x=n+max(-h.x-n,-PI/2);
        h.y=n+min(h.y-n,PI/2);

        BentAngle=(h.x+h.y)*0.5;
        BentNormal+=ViewDir*cos(BentAngle)-PlaneTangent*sin(BentAngle);
        AO+=SliceLength*ComputeGTAO(h.x,h.y,n);
    }
    BentNormal=normalize(normalize(BentNormal)-ViewDir*0.5);
    AO=saturate(AO/DIRECTIONCOUNT);
    //return half4(BentNormal,AO);
    return AO;
}
void AccumulateHBAO(inout half Ao,inout half RayPixels,half StepSizePixels,half2 Direction,half2 FullResUv,half3 PositionVs,half3 NormalVs){
    half2 SnappedUv=round(RayPixels*Direction)*ScreenParams.xy+FullResUv;
    half3 S=GetPositionVs(SnappedUv);
    RayPixels+=StepSizePixels;
    Ao+=ComputeHBAO(PositionVs,NormalVs,S);
}
half GetHBAO(half2 FullResUv,half3 PositionVs,half3 NormalVs){
    half4 Rand=half4(1,0,1,1);
    Rand.xy=RotateDirection(Rand.xy,Noise2D(FullResUv));
    Rand.w=Noise2D(FullResUv);
    half StepSizePixels = max(1.0,lerp(0.8,1.2,Noise2D(FullResUv))*GetUniformRadiusScale(FullResUv)*RADIUSSCALE_HBAO*RADIUS / (STEPCOUNT + 1.0));
    half AngDelta=2.0*PI/DIRECTIONCOUNT;
    half Ao=0;
    [loop]
    for(int i=0;i<DIRECTIONCOUNT;i++){
        half Angle=i*AngDelta;
        half2 Direction=RotateDirection(Rand.xy,Angle);
        half RayPixels=(Rand.z*StepSizePixels+1.0);//引入随机
        [loop]
        for(int j=0;j<STEPCOUNT;j++){
            AccumulateHBAO(Ao,RayPixels,StepSizePixels,Direction,FullResUv,PositionVs,NormalVs);
        }
    }
    Ao/=STEPCOUNT*DIRECTIONCOUNT;
    return Ao;
}

half Frag_HBAO(VertexOutput i):SV_Target{
    [branch]
    if(GetSkyBoxMask(i.uv)){return 1.0;}
    //正确的世界坐标return mul(View2World_Matrix,half4(BuildViewPos(i.uv),1));
    half3 PositionVs = GetPositionVs(i.uv);
    //return half4(GetScreenUv(PositionVS),0,1);
    if (-PositionVs.z > MAXDISTANCE)
    {
        return 1;
    }
    half3 Norm=GetNormalVs(i.uv);
    half Ao=GetHBAO(i.uv,PositionVs,Norm);
    Ao=saturate(1.0-2.0*Ao);
    Ao=pow(Ao,Intensity);
    return Ao;
}

half Frag_GTAO(VertexOutput i):SV_Target{
    [branch]
    if(GetSkyBoxMask(i.uv)){return 1.0;}
    half3 PositionVs = GetPositionVs(i.uv);
    if (-PositionVs.z > MAXDISTANCE)
    {
        return 1;
    }
    half3 Norm=GetNormalVs(i.uv);
    half AO=GetGTAO(i.uv,PositionVs,Norm);
    AO=pow(AO,Intensity);
    return AO;
}
half Frag_Bilateral_X(VertexOutput i):SV_Target{
	[branch]
    if(GetSkyBoxMask(i.uv)){return 1.0;}
    half2 deltaUV=half2(1,0)*ScreenParams.xy;
    half totalAO;
	half depth;
	FetchAOAndDepth(i.uv, totalAO, depth,true);
	half totalW = 1.0;

	ProcessRadius(i.uv, -deltaUV, depth, totalAO, totalW,true);
	ProcessRadius(i.uv, +deltaUV, depth, totalAO, totalW,true);

	totalAO /= totalW;
	return totalAO;
}
half Frag_Bilateral_Y(VertexOutput i):SV_Target{
	[branch]
    if(GetSkyBoxMask(i.uv)){return 1.0;}
    half2 deltaUV=half2(0,1)*ScreenParams.xy;
    half totalAO;
	half depth;
	FetchAOAndDepth(i.uv, totalAO, depth,false);
	half totalW = 1.0;

	ProcessRadius(i.uv, -deltaUV, depth, totalAO, totalW,false);
	ProcessRadius(i.uv, +deltaUV, depth, totalAO, totalW,false);

	totalAO /= totalW;
	return totalAO;
}
half Frag_TemporalFilter(VertexOutput i):SV_Target{
	[branch]
    if(GetSkyBoxMask(i.uv)){return 1.0;}
	half2 Closest_uv=GetClosestUv(i.uv);
    half2 Velocity=_MotionVectorTexture.SampleLevel(Point_Clamp,Closest_uv,0).rg;
	
	//灰度的包围盒
	half AABBMin,AABBMax;
	GetBoundingBox(AABBMin,AABBMax,i.uv);
	half AO_Pre=_AO_Previous_RT.SampleLevel(Point_Clamp,i.uv-Velocity,0).r;
	half AO_Cur=RT_Temporal_In.SampleLevel(Point_Clamp,i.uv,0).r;
	AO_Pre=clamp(AO_Pre,AABBMin,AABBMax);
	half lum0 = AO_Cur;
	half lum1 = AO_Pre;
	half unbiased_diff = abs(lum0 - lum1) / max(lum0, max(lum1, 0.2));
	half unbiased_weight=saturate(1-unbiased_diff);
	half BlendFactor=saturate(pow(unbiased_weight,1.1-TemporalFilterIntensity))*saturate(rcp(0.8*Pow2(length(Velocity))+0.8));
	half AO=lerp(AO_Cur,AO_Pre,BlendFactor);
	return AO;
}
half4 Frag_BlendToScreen(VertexOutput i):SV_Target{
	#if defined MULTI_BOUNCE_AO
	half3 Ao=AmbientOcclusion.SampleLevel(Point_Clamp,i.uv,0).xyz;
	#else
	half3 Ao=AmbientOcclusion.SampleLevel(Point_Clamp,i.uv,0).xxx;
	#endif
	return half4(Ao,1);
}
half4 Frag_MultiBounce(VertexOutput i):SV_Target{
	[branch]
    if(GetSkyBoxMask(i.uv)){return 1.0;}
	half3 BaseColor=GBuffer0.SampleLevel(Point_Clamp,i.uv,0).xyz;
	half Ao=RT_MultiBounce_In.SampleLevel(Point_Clamp,i.uv,0).x;
	return half4(AOMultiBounce(BaseColor,Ao),1);
}