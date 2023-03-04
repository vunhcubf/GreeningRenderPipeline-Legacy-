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
        int NumClusterX = 16;
        int NumClusterY = 16;
        int NumClusterZ = 32;
        bool UseClusterLight;
        ComputeBuffer ClusterBox_Buffer;
        ComputeBuffer ValidLightIndex_Buffer;
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
            
            int GetCluster_Pass = ClusterLight_Shader.FindKernel("GetCluster");
            int ClusterIntersect = ClusterLight_Shader.FindKernel("ClusterIntersect");

            ClusterLight_Shader.SetInt("NumClusterX", NumClusterX);
            ClusterLight_Shader.SetInt("NumClusterY", NumClusterY);
            ClusterLight_Shader.SetInt("NumClusterZ", NumClusterZ);

            ClusterLight_Shader.SetBuffer(GetCluster_Pass, "PointLightPropertiesList", PointLightBuffer);
            ClusterBox_Buffer = new ComputeBuffer(NumClusterX* NumClusterY* NumClusterZ,8*3*4);
            ValidLightIndex_Buffer = new ComputeBuffer(NumClusterX * NumClusterY * NumClusterZ,4*2);
            ClusterLight_Shader.SetBuffer(GetCluster_Pass, "ClusterBox_Buffer", ClusterBox_Buffer);
            ClusterLight_Shader.Dispatch(GetCluster_Pass, NumClusterX / 8, NumClusterY / 8, NumClusterZ / 8);

            ClusterLight_Shader.SetBuffer(ClusterIntersect, "ValidLightIndex_Buffer", ValidLightIndex_Buffer);
            ClusterLight_Shader.SetBuffer(ClusterIntersect, "ClusterBox_Buffer", ClusterBox_Buffer);
            ClusterLight_Shader.SetBuffer(ClusterIntersect, "PointLightBuffer", PointLightBuffer);
            ClusterLight_Shader.Dispatch(ClusterIntersect, NumClusterX / 8, NumClusterY / 8, NumClusterZ / 8);
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
        void DrawCluster()
        {
            ClusterBox[] A=new ClusterBox[NumClusterX * NumClusterY * NumClusterZ];
            ClusterBox_Buffer.GetData(A);
            foreach (var one in A)
            {
                DrawBox(one,Color.white);
            }
        }
        void DrawIntersectCluster()
        {
            uint2[] A = new uint2[NumClusterX * NumClusterY * NumClusterZ];

            ClusterBox[] B = new ClusterBox[NumClusterX * NumClusterY * NumClusterZ];
            ClusterBox_Buffer.GetData(B);
            ValidLightIndex_Buffer.GetData(A);
            for(int i=0;i< NumClusterX * NumClusterY * NumClusterZ; i++)
            {
                int[] ValidLight_Buffer_OneCluster = new int[8];
                int4 Decode_1 = Decodeuint32To4Byte(A[i].x);
                int4 Decode_2 = Decodeuint32To4Byte(A[i].y);
                ValidLight_Buffer_OneCluster[0] = Decode_1.x;
                ValidLight_Buffer_OneCluster[1] = Decode_1.y;
                ValidLight_Buffer_OneCluster[2] = Decode_1.z;
                ValidLight_Buffer_OneCluster[3] = Decode_1.w;
                ValidLight_Buffer_OneCluster[4] = Decode_2.x;
                ValidLight_Buffer_OneCluster[5] = Decode_2.y;
                ValidLight_Buffer_OneCluster[6] = Decode_2.z;
                ValidLight_Buffer_OneCluster[7] = Decode_2.w;
                if (IsContainSpecificLightIndex(1, ValidLight_Buffer_OneCluster))
                {
                    DrawBox(B[i], Color.red);
                }
                if (IsContainSpecificLightIndex(2, ValidLight_Buffer_OneCluster))
                {
                    DrawBox(B[i], Color.blue);
                }
                if (IsContainSpecificLightIndex(3, ValidLight_Buffer_OneCluster))
                {
                    DrawBox(B[i], Color.green);
                }
                if (IsContainSpecificLightIndex(4, ValidLight_Buffer_OneCluster))
                {
                    DrawBox(B[i], Color.yellow);
                }
            }
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