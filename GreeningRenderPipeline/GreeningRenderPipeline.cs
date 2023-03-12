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

        private RenderTexture RT_CameraTargetTexture_HDR;

        private int Width;
        private int Height;
        ~GreeningRenderPipeline()
        {
            Debug.Log("ע����Ⱦ����");
        }
        //��Ⱦ���
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            Cmd_GBuffer = CommandBufferPool.Get("DrawGBuffer");
            Cmd_RenderPrepare = CommandBufferPool.Get("RenderPrepare");
            Cmd_Debug = CommandBufferPool.Get("Debug");
            //һ�е�׼������
            //BuiltinRenderTextureType.CameraTarget�������Ⱦ��Ĭ������
            Camera MainCamera = cameras[0];
            context.SetupCameraProperties(MainCamera);
            //����Srp Batcher
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

            //���ú������صĲ���
            InitializeCameraSettings(MainCamera);
            //������׶�޳���boundingbox�޳�
            MainCamera.TryGetCullingParameters(out var CullingParams);
            CullingResults Culling_Result = context.Cull(ref CullingParams);

            //���õƹ���Ϣ
            SetLightProperties(ref Culling_Result);
            if (UseClusterLight)
            {
                ClusterIntersect(MainCamera);
            }

            //��ʼ����Ⱦ����
            if (RT_CameraTargetTexture_HDR is null)
            {
                RT_CameraTargetTexture_HDR = RenderTexture.GetTemporary(Width, Height, 0, GraphicsFormat.B10G11R11_UFloatPack32);
                RT_CameraTargetTexture_HDR.enableRandomWrite = true;
            }
            if(RT_CameraTargetTexture_HDR.width!=Width || RT_CameraTargetTexture_HDR.height != Height)
            {
                RenderTexture.ReleaseTemporary(RT_CameraTargetTexture_HDR);
                RT_CameraTargetTexture_HDR = RenderTexture.GetTemporary(Width, Height, 0, GraphicsFormat.B10G11R11_UFloatPack32);
                RT_CameraTargetTexture_HDR.enableRandomWrite = true;
            }

            //����GBuffer
            DrawGBuffer(context, MainCamera, Culling_Result);

            if (gi_settings.AoSettings.EnableAo)
            {
                ao.Execute(context, MainCamera, BuiltinRenderTextureType.CameraTarget);
            }

            //�����ӳ���ɫ
            DefferedShading();

            //���������
            DrawSkyBox();
            Cmd_Debug.Blit(RT_CameraTargetTexture_HDR, BuiltinRenderTextureType.CameraTarget);
            context.ExecuteCommandBuffer(Cmd_Debug);
            context.Submit();

            //����Gizmos
            if (Handles.ShouldRenderGizmos())
            {
                context.DrawGizmos(MainCamera, GizmoSubset.PreImageEffects);
                context.DrawGizmos(MainCamera, GizmoSubset.PostImageEffects);
            }
            context.Submit();


            //��ɻ��ƺ�
            ReleaseGBuffer();
            if (gi_settings.AoSettings.EnableAo)
            {
                ao.OnRenderCleanup(context, MainCamera);
            }

            //�ͷ�ָ���
            CommandBufferPool.Release(Cmd_Debug);
            CommandBufferPool.Release(Cmd_RenderPrepare);
            CommandBufferPool.Release(Cmd_GBuffer);

            //�ͷ�computebuffer
            PointLightBuffer.Dispose();
            DirectionalLightBuffer.Dispose();
            SpotLightBuffer.Dispose();
            if (UseClusterLight)
            {
                LightAssignTable.Dispose();
                GlobalValidLightCount_Buffer.Dispose();
                GlobalValidLightList.Dispose();
            }
            
        }
        public GreeningRenderPipeline(GreeningRenderPipelineAsset.SprSettings srp_settings, GlobalilluminationSettings gi_settings, ShaderResource shader_resources, LightSetting light_settings, SkyBoxSetting SkyBoxSettings)
        {
            Debug.Log("������Ⱦ����");
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
            this.AverageOverlapLightCountPerCluster = light_settings.AverageOverlapLightCountPerCluster;
            this.DebugLightCount = light_settings.DebugLightCount;
            this.skybox_settings = SkyBoxSettings;
        }
        
    }
}
