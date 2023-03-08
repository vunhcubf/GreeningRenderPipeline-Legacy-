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
        SkyBoxSetting skybox_settings;
        void DrawSkyBox()
        {
            //skybox_settings.SkyBoxMap.
            ComputeShader SkyBox_Shader = shader_resources.SkyBox_Shader;
            int Kernel_Main = SkyBox_Shader.FindKernel("SkyBoxShader");
            SkyBox_Shader.SetFloat("Exposure",skybox_settings.Exposure);
            SkyBox_Shader.SetFloat("Rotation", skybox_settings.Rotation/360f);
            SkyBox_Shader.SetTexture(Kernel_Main,"DrawSkyBox_Dest", RT_CameraTargetTexture_HDR);
            SkyBox_Shader.SetTexture(Kernel_Main, "SkyBoxMap", skybox_settings.SkyBoxMap);
            SkyBox_Shader.Dispatch(Kernel_Main, 1 + Width / 8, 1 + Height / 8, 1);
        }
    }
}