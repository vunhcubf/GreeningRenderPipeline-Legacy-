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

namespace UnityEngine.Rendering.GreeningRP
{
    public partial class GreeningRenderPipeline
    {
        private void DrawGBuffer(ScriptableRenderContext context, Camera camera, CullingResults Culling_Result)
        {
            Profiler.BeginSample("DrawGBuffer");

            //ɸѡ��Ҫ��Ⱦ������
            ShaderTagId ShaderTagID_DefferedShading = new ShaderTagId("GreeningRP_Deffered");
            SortingSettings Sorting_Settings = new SortingSettings(camera);
            DrawingSettings Drawing_Settings = new DrawingSettings(ShaderTagID_DefferedShading, Sorting_Settings);
            FilteringSettings Filtering_Settings = FilteringSettings.defaultValue;

            Cmd_GBuffer.Clear();
            Cmd_GBuffer.GetTemporaryRT(RT_GBuffer0_ID, Width, Height, 0, FilterMode.Point, GraphicsFormat.R8G8B8A8_SRGB);//GBuffer0 rgb�Ƿ�����,a��AO��ͼ
            Cmd_GBuffer.GetTemporaryRT(RT_GBuffer1_ID, Width, Height, 0, FilterMode.Point, GraphicsFormat.R8G8B8A8_UNorm);//GBuffer1 rgb�Ƿ���,a�ǲ���ID
            Cmd_GBuffer.GetTemporaryRT(RT_GBuffer2_ID, Width, Height, 0, FilterMode.Point, GraphicsFormat.R8G8B8A8_UNorm);//GBuffer2 r�Ǵֲڶȣ�g�ǽ�����
            Cmd_GBuffer.GetTemporaryRT(RT_CameraDepth_ID, Width, Height, 32, FilterMode.Point, RenderTextureFormat.Depth);//���ͼ

            Cmd_GBuffer.SetRenderTarget(new RenderTargetIdentifier[3] {new RenderTargetIdentifier(RT_GBuffer0_ID),
                                                new RenderTargetIdentifier(RT_GBuffer1_ID),
                                                new RenderTargetIdentifier(RT_GBuffer2_ID)}, new RenderTargetIdentifier(RT_CameraDepth_ID));
            Cmd_GBuffer.ClearRenderTarget(true, true, Color.white);
            context.ExecuteCommandBuffer(Cmd_GBuffer);


            context.DrawRenderers(Culling_Result, ref Drawing_Settings, ref Filtering_Settings);
            context.Submit();

            Cmd_GBuffer.Clear();
            Cmd_GBuffer.SetGlobalTexture(RT_GBuffer0_ID, RT_GBuffer0_ID);
            Cmd_GBuffer.SetGlobalTexture(RT_GBuffer1_ID, RT_GBuffer1_ID);
            Cmd_GBuffer.SetGlobalTexture(RT_GBuffer2_ID, RT_GBuffer2_ID);
            Cmd_GBuffer.SetGlobalTexture(RT_CameraDepth_ID, RT_CameraDepth_ID);
            context.ExecuteCommandBuffer(Cmd_GBuffer);
            context.Submit();

            Profiler.EndSample();
        }
        private void ReleaseGBuffer()
        {
            Cmd_GBuffer.ReleaseTemporaryRT(RT_GBuffer0_ID);
            Cmd_GBuffer.ReleaseTemporaryRT(RT_GBuffer1_ID);
            Cmd_GBuffer.ReleaseTemporaryRT(RT_GBuffer2_ID);
            Cmd_GBuffer.ReleaseTemporaryRT(RT_CameraDepth_ID);
        }
    }
}

