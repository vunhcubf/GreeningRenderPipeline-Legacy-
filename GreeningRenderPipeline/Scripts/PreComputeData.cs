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
        ComputeBuffer MainSkyBox_SH;
        struct SH_Light
        {
            public float3 SH_1;
            public float3 SH_2;
            public float3 SH_3;
            public float3 SH_4;
            public float3 SH_5;
            public float3 SH_6;
            public float3 SH_7;
            public float3 SH_8;
            public float3 SH_9;
        };
        private void InitializePreComputeData(SkyBoxSetting SkyBoxSettings, ShaderResource ShaderResources, LightSetting LightSettings)
        {
            float b = 114.514f;
            int a = (int)(b * 16777216f);
            float c = (float)a / 16777216f;
            //计算球谐光照
            if (MainSkyBox_SH is not null)
            {
                MainSkyBox_SH.Dispose();
            }
            MainSkyBox_SH = new ComputeBuffer(1,9*3*4);
            ComputeShader SH_Shader = ShaderResources.IBL_Shader;
            int Kernel_SH = SH_Shader.FindKernel("GetSHCoefficientfromCubeMap");

            int CubeMapSize = SkyBoxSettings.SkyBoxMap.height / 2;
            int MipLevel;
            for(MipLevel=0; MipLevel< SkyBoxSettings.SkyBoxMap.mipmapCount; MipLevel++)
            {
                if (CubeMapSize > 16)
                {
                    CubeMapSize /= 2;
                }
                else
                {
                    break;
                }
            }

            SH_Shader.SetTexture(Kernel_SH,"SkyBoxMap", SkyBoxSettings.SkyBoxMap);
            SH_Shader.SetInt("CubeMapSize", CubeMapSize);
            SH_Shader.SetInt("MaxMipLevel", MipLevel);
            SH_Shader.SetFloat("Exposure", SkyBoxSettings.Exposure);
            SH_Shader.SetBuffer(Kernel_SH, "MainSkyBox_SH", MainSkyBox_SH);
            SH_Shader.SetFloat("Rotation", SkyBoxSettings.Rotation* 0.0174532925199f);
            SH_Shader.Dispatch(Kernel_SH,1,1,1);
        }
    }
}