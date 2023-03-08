using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Profiling;
using static Unity.Burst.Intrinsics.X86.Avx;
using static UnityEngine.Rendering.GreeningRP.GreeningRenderPipelineAsset;
using Unity.Collections;
using System;
using Unity.Mathematics;

namespace UnityEngine.Rendering.GreeningRP
{
    public partial class GreeningRenderPipeline
    {
        private uint AverageOverlapLightCountPerCluster;
        bool DebugLightCount;
        int NumClusterX = 16;
        int NumClusterY = 16;
        int NumClusterZ = 32;
        bool UseClusterLight;
        ComputeBuffer GlobalValidLightList;
        ComputeBuffer GlobalValidLightCount_Buffer;//所有cluster总共可用的灯光数量，使用computebuffer来在所有的线程组间通信,相当于栈指针
        ComputeBuffer LightAssignTable;
        struct ClusterBox
        {
            public float3 p1;
            public float3 p2;
            public float3 p3;
            public float3 p4;
            public float3 p5;
            public float3 p6;
            public float3 p7;
            public float3 p8;
        };
        void ClusterIntersect(Camera MainCamera)
        {
            ComputeShader ClusterLight_Shader = shader_resources.ClusterLight_Shader;
            
            int ClusterIntersect = ClusterLight_Shader.FindKernel("ClusterIntersect");

            ClusterLight_Shader.SetInt("NumClusterX", NumClusterX);
            ClusterLight_Shader.SetInt("NumClusterY", NumClusterY);
            ClusterLight_Shader.SetInt("NumClusterZ", NumClusterZ);

            GlobalValidLightCount_Buffer = new ComputeBuffer(1,4);
            GlobalValidLightList = new ComputeBuffer((int)AverageOverlapLightCountPerCluster* NumClusterX * NumClusterY * NumClusterZ, 4);
            LightAssignTable = new ComputeBuffer(NumClusterX * NumClusterY * NumClusterZ,4*2);

            GlobalValidLightCount_Buffer.SetData(new uint[1]{1});

            ClusterLight_Shader.SetInt("GlobalValidLightList_Count", (int)AverageOverlapLightCountPerCluster * NumClusterX * NumClusterY * NumClusterZ);
            ClusterLight_Shader.SetBuffer(ClusterIntersect, "GlobalValidLightCount_Buffer", GlobalValidLightCount_Buffer);
            ClusterLight_Shader.SetBuffer(ClusterIntersect, "GlobalValidLightList", GlobalValidLightList);
            ClusterLight_Shader.SetBuffer(ClusterIntersect, "LightAssignTable", LightAssignTable);
            ClusterLight_Shader.SetBuffer(ClusterIntersect, "PointLightBuffer", PointLightBuffer);
            ClusterLight_Shader.Dispatch(ClusterIntersect, NumClusterX, NumClusterY, NumClusterZ);

            if (DebugLightCount)
            {
                int[] GlobalValidLightCount = new int[1];
                GlobalValidLightCount_Buffer.GetData(GlobalValidLightCount);
                Debug.Log("全局有效灯光数量:" + GlobalValidLightCount[0]);
                Debug.Log("平均每cluster灯光数量:" + (float)GlobalValidLightCount[0] / (float)(NumClusterX * NumClusterY * NumClusterZ));
                Debug.Log("全局灯光列表使用率:"+ 100f*(float)GlobalValidLightCount[0]/ (float)(NumClusterX * NumClusterY * NumClusterZ* (int)AverageOverlapLightCountPerCluster)+"%");
            }
        }
        int Index3DTo1D(int3 id)
        {
            return id.z * NumClusterX * NumClusterY + id.y * NumClusterX + id.x;
        }
        void DrawBox(ClusterBox Box ,Color color)
        {
            Debug.DrawLine(Box.p1, Box.p2, color, 0.05f);
            Debug.DrawLine(Box.p1, Box.p3, color, 0.05f);
            Debug.DrawLine(Box.p4, Box.p2, color, 0.05f);
            Debug.DrawLine(Box.p4, Box.p3, color, 0.05f);

            Debug.DrawLine(Box.p5, Box.p6, color, 0.05f);
            Debug.DrawLine(Box.p5, Box.p7, color, 0.05f);
            Debug.DrawLine(Box.p8, Box.p6, color, 0.05f);
            Debug.DrawLine(Box.p8, Box.p7, color, 0.05f);

            Debug.DrawLine(Box.p3, Box.p7, color, 0.05f);
            Debug.DrawLine(Box.p4, Box.p8, color, 0.05f);
            Debug.DrawLine(Box.p1, Box.p5, color, 0.05f);
            Debug.DrawLine(Box.p2, Box.p6, color, 0.05f);
        }
        bool IsContainSpecificLightIndex(int LightIndex, int[] ValidLight_Buffer_OneCluster)
        {
            return ValidLight_Buffer_OneCluster[0] == LightIndex || ValidLight_Buffer_OneCluster[2] == LightIndex || ValidLight_Buffer_OneCluster[3] == LightIndex || ValidLight_Buffer_OneCluster[4] == LightIndex || ValidLight_Buffer_OneCluster[5] == LightIndex || ValidLight_Buffer_OneCluster[6] == LightIndex || ValidLight_Buffer_OneCluster[7] == LightIndex || ValidLight_Buffer_OneCluster[1] == LightIndex;
        }
        float dot(float2 a,float2 b)
        {
            return a.x * b.x + a.y*b.y;
        }
        float2 normalize(float2 a)
        {
            float length = Mathf.Sqrt(dot(a,a));
            return a/ length;
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
    }
}