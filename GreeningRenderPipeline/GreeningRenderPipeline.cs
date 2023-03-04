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
using Unity.Mathematics;

namespace UnityEngine.Rendering.GreeningRP
{
    public partial class GreeningRenderPipeline : RenderPipeline
    {
        private delegate void OnRenderCleanup(ScriptableRenderContext context, Camera camera);
        private delegate void Execute(ScriptableRenderContext context, Camera camera, RenderTargetIdentifier CameraColorTarget);
        private delegate void OnRenderPrepare(ScriptableRenderContext context, Camera camera);

        private CommandBuffer Cmd_GBuffer;
        private CommandBuffer Cmd_RenderPrepare;
        private CommandBuffer Cmd_Debug;


        private GreeningRenderPipelineAsset.SprSettings srp_settings;
        private GlobalilluminationSettings gi_settings;
        private ShaderResource shader_resources;

        private AmbientOcclusion.RenderPass ao;

        private RenderTexture DefferedShading_Dest_RT;

        private int Width;
        private int Height;
        ~GreeningRenderPipeline()
        {
            Debug.Log("注销渲染管线");
        }
        //渲染入口
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            Cmd_GBuffer = CommandBufferPool.Get("DrawGBuffer");
            Cmd_RenderPrepare = CommandBufferPool.Get("RenderPrepare");
            Cmd_Debug = CommandBufferPool.Get("Debug");
            //一切的准备工作
            //BuiltinRenderTextureType.CameraTarget是相机渲染的默认纹理
            Camera MainCamera = cameras[0];
            context.SetupCameraProperties(MainCamera);
            //开启Srp Batcher
            GraphicsSettings.useScriptableRenderPipelineBatching = srp_settings.UseSrpBatcher;

            

            if (gi_settings.AoSettings.EnableAo)
            {
                ao.OnRenderPrepare(context, MainCamera);
            }

            Cmd_RenderPrepare.Clear();
            Cmd_RenderPrepare.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            Cmd_RenderPrepare.ClearRenderTarget(true, true, new Color(0.0f, 1.0f, 1.0f));
            context.ExecuteCommandBuffer(Cmd_RenderPrepare);
            context.Submit();

            //设置和相机相关的参数
            InitializeCameraSettings(MainCamera);
            //进行视锥剔除和boundingbox剔除
            MainCamera.TryGetCullingParameters(out var CullingParams);
            CullingResults Culling_Result = context.Cull(ref CullingParams);

            //设置灯光信息
            SetLightProperties(ref Culling_Result);
            if (UseClusterLight)
            {
                ClusterIntersect(MainCamera);
            }

            //初始化渲染纹理
            if (DefferedShading_Dest_RT is null)
            {
                DefferedShading_Dest_RT = RenderTexture.GetTemporary(Width, Height, 0, RenderTextureFormat.DefaultHDR);
                DefferedShading_Dest_RT.enableRandomWrite = true;
            }
            if(DefferedShading_Dest_RT.width!=Width || DefferedShading_Dest_RT.height != Height)
            {
                RenderTexture.ReleaseTemporary(DefferedShading_Dest_RT);
                DefferedShading_Dest_RT = RenderTexture.GetTemporary(Width, Height, 0, RenderTextureFormat.DefaultHDR);
                DefferedShading_Dest_RT.enableRandomWrite = true;
            }

            //绘制GBuffer
            DrawGBuffer(context, MainCamera, Culling_Result);

            if (gi_settings.AoSettings.EnableAo)
            {
                ao.Execute(context, MainCamera, BuiltinRenderTextureType.CameraTarget);
            }

            //进行延迟着色
            DefferedShading();
            Cmd_Debug.Blit(DefferedShading_Dest_RT, BuiltinRenderTextureType.CameraTarget);
            context.ExecuteCommandBuffer(Cmd_Debug);
            context.Submit();


            ////绘制天空球
            //context.DrawSkybox(MainCamera);
            //context.Submit();
            //绘制Gizmos
            if (Handles.ShouldRenderGizmos())
            {
                context.DrawGizmos(MainCamera, GizmoSubset.PreImageEffects);
                context.DrawGizmos(MainCamera, GizmoSubset.PostImageEffects);
            }
            context.Submit();


            //完成绘制后
            ReleaseGBuffer();
            if (gi_settings.AoSettings.EnableAo)
            {
                ao.OnRenderCleanup(context, MainCamera);
            }

            

            //释放指令缓冲
            CommandBufferPool.Release(Cmd_Debug);
            CommandBufferPool.Release(Cmd_RenderPrepare);
            CommandBufferPool.Release(Cmd_GBuffer);

            //释放computebuffer
            PointLightBuffer.Dispose();
            DirectionalLightBuffer.Dispose();
            if (UseClusterLight)
            {
                ClusterBox_Buffer.Dispose();
                ValidLightIndex_Buffer.Dispose();
            }
            
        }
        public GreeningRenderPipeline(GreeningRenderPipelineAsset.SprSettings srp_settings, GlobalilluminationSettings gi_settings, ShaderResource shader_resources, LightSetting light_settings)
        {
            Debug.Log("创建渲染管线");
            this.srp_settings = srp_settings;
            this.shader_resources = shader_resources;
            this.gi_settings = gi_settings;
            if (gi_settings.AoSettings.EnableAo)
            {
                ao = ScriptableObject.CreateInstance<AmbientOcclusion.RenderPass>();
                ao.Instantiate(gi_settings.AoSettings);
            }
            UseClusterLight = light_settings.UseClusterLight;
            NumClusterX = light_settings.NumClusterXYZ.x;
            NumClusterY = light_settings.NumClusterXYZ.y;
            NumClusterZ = light_settings.NumClusterXYZ.z;
        }
        
    }
}
