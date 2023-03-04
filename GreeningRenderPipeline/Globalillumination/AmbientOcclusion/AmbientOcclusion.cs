using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using ProfilingScope = UnityEngine.Rendering.ProfilingScope;
using System;
using static Unity.Burst.Intrinsics.X86.Avx;
using System.Collections.Generic;

namespace UnityEngine.Rendering.GreeningRP
{
    public class AmbientOcclusion : ScriptableObject
    {
        [System.Serializable]
        public class AmbientOcclusionSetting
        {
            [Header("AO设置")]
            [InspectorToggleLeft] public bool EnableAo = false;
            [InspectorToggleLeft] public bool Debug = false;
            public bool FullPrecision = false;

            [Space(10)]
            [Header("AO设置")]
            public AO_Methods AOMethod = AO_Methods.GTAO;
            [InspectorToggleLeft] public bool TemporalJitter = true;
            [Range(0f, 5f)] public float Intensity = 1;
            [Range(0f, 1f)] public float Radius = 0.5f;
            [Range(1, 10)] public int Num_Direction = 4;
            [Range(3, 50)] public int Num_Step = 8;
            [Range(0f, 0.6f)] public float AngleBias = 0.1f;
            [Range(0f, 1f)] public float AoDistanceAttenuation = 0.1f;
            [Range(1, 2000)] public int MaxDistance = 1000;
            [InspectorToggleLeft] public bool MultiBounce = true;

            [Space(10)]
            [Header("降噪设置")]
            [InspectorToggleLeft] public bool SpatialFilter = true;
            [InspectorToggleLeft] public bool TemporalFilter = true;
            [Range(0f, 40f)] public float BlurSharpness = 1;
            [Range(2, 10)] public int Kernel_Radius = 5;
            [Range(0f, 1f)] public float TemporalFilterIntensity = 0.2f;
        }
        public enum AO_Methods
        {
            GTAO,
            HBAO_Plus
        };
        public AmbientOcclusionSetting Settings = new AmbientOcclusionSetting();

        public class RenderPass : ScriptableObject
        {
            private Mesh FullScreenMesh;

            private static readonly int P_RADIUS_ID = Shader.PropertyToID("RADIUS");
            private static readonly int P_DIRECTIONCOUNT_ID = Shader.PropertyToID("DIRECTIONCOUNT");
            private static readonly int P_STEPCOUNT_ID = Shader.PropertyToID("STEPCOUNT");
            private static readonly int P_MAXDISTANCE_ID = Shader.PropertyToID("MAXDISTANCE");
            private static readonly int P_AngleBias_ID = Shader.PropertyToID("AngleBias");
            private static readonly int P_AoDistanceAttenuation_ID = Shader.PropertyToID("AoDistanceAttenuation");
            private static readonly int P_Intensity_ID = Shader.PropertyToID("Intensity");

            private static readonly int P_BlurSharpness_ID = Shader.PropertyToID("BlurSharpness");
            private static readonly int P_KernelRadius_ID = Shader.PropertyToID("Kernel_Radius");
            private static readonly int P_TemporalFilterIntensity_ID = Shader.PropertyToID("TemporalFilterIntensity");

            private static readonly int RT_AoBase_ID = Shader.PropertyToID("_RT_AoBase");

            private static readonly int RT_AoBlur_Spatial_X_ID = Shader.PropertyToID("_RT_AoBlur_Spatial_X");
            private static readonly int RT_AoBlur_Spatial_Y_ID = Shader.PropertyToID("_RT_AoBlur_Spatial_Y");
            private static readonly int AO_Current_RT_ID = Shader.PropertyToID("_AO_Current_RT");
            private static readonly int RT_Temporal_In_ID = Shader.PropertyToID("RT_Temporal_In");
            private static readonly int AO_Previous_RT_ID = Shader.PropertyToID("_AO_Previous_RT");
            private static readonly int RT_Spatial_In_X_ID = Shader.PropertyToID("RT_Spatial_In_X");
            private static readonly int RT_Spatial_In_Y_ID = Shader.PropertyToID("RT_Spatial_In_Y");
            private static readonly int RT_MultiBounce_Out_ID = Shader.PropertyToID("RT_MultiBounce_Out");
            private static readonly int RT_MultiBounce_In_ID = Shader.PropertyToID("RT_MultiBounce_In");
            private static readonly int GLOBAL_RT_AmbientOcclusion_ID = Shader.PropertyToID("AmbientOcclusion");

            private RenderTexture AO_Previous_RT;
            private CommandBuffer Cmd_AO;

            private AmbientOcclusionSetting Settings;
            public RenderPass(AmbientOcclusionSetting Settings)
            {
                this.Settings = Settings;
                FullScreenMesh = GetFullScreenMesh();
            }
            public void Instantiate(AmbientOcclusionSetting Settings)
            {
                this.Settings = Settings;
                FullScreenMesh = GetFullScreenMesh();
            }
            public static Mesh GetFullScreenMesh()
            {
                Mesh s_FullscreenMesh;
                float topV = 1.0f;
                float bottomV = 0.0f;

                s_FullscreenMesh = new Mesh { name = "Fullscreen Quad" };
                s_FullscreenMesh.SetVertices(new List<Vector3>
            {
                new Vector3(-1.0f, -1.0f, 0.0f),
                new Vector3(-1.0f,  1.0f, 0.0f),
                new Vector3(1.0f, -1.0f, 0.0f),
                new Vector3(1.0f,  1.0f, 0.0f)
            });

                s_FullscreenMesh.SetUVs(0, new List<Vector2>
            {
                new Vector2(0.0f, bottomV),
                new Vector2(0.0f, topV),
                new Vector2(1.0f, bottomV),
                new Vector2(1.0f, topV)
            });

                s_FullscreenMesh.SetIndices(new[] { 0, 1, 2, 2, 1, 3 }, MeshTopology.Triangles, 0, false);
                s_FullscreenMesh.UploadMeshData(true);
                return s_FullscreenMesh;
            }
            public void OnRenderPrepare(ScriptableRenderContext context, Camera camera)
            {
                Cmd_AO = CommandBufferPool.Get("GreeningRP_Ao");
                Cmd_AO.Clear();
                //历史信息
                if (AO_Previous_RT is null || AO_Previous_RT.IsDestroyed())
                {
                    AO_Previous_RT = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, GraphicsFormat.R16_UNorm);
                    AO_Previous_RT.Create();
                }
                if (camera.pixelWidth != AO_Previous_RT.width || camera.pixelHeight != AO_Previous_RT.height)
                {
                    AO_Previous_RT.DiscardContents();
                    AO_Previous_RT.Release();
                    DestroyImmediate(AO_Previous_RT);
                    AO_Previous_RT = null;

                    AO_Previous_RT = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, GraphicsFormat.R16_UNorm);
                    AO_Previous_RT.Create();
                }
            }
            public void Execute(ScriptableRenderContext context, Camera camera, RenderTargetIdentifier CameraColorTarget)
            {
                FullScreenMesh = GetFullScreenMesh();
                RenderTextureDescriptor AoTextureDesc = new RenderTextureDescriptor(camera.pixelWidth, camera.pixelHeight, GraphicsFormat.R16_UNorm, GraphicsFormat.None);
                RenderTextureDescriptor AoTextureDesc_Color = new RenderTextureDescriptor(camera.pixelWidth, camera.pixelHeight, GraphicsFormat.B10G11R11_UFloatPack32, GraphicsFormat.None);
                AoTextureDesc.depthBufferBits = 0;
                AoTextureDesc_Color.depthBufferBits = 0;

                var AoMaterial = new Material(Shader.Find("GreeningRP/AmbientOcclusion"));
                var BlurMaterial = new Material(Shader.Find("GreeningRP/AmbientOcclusion"));

                AoMaterial.SetFloat(P_RADIUS_ID, Settings.Radius);
                AoMaterial.SetInt(P_DIRECTIONCOUNT_ID, Settings.Num_Direction);
                AoMaterial.SetInt(P_STEPCOUNT_ID, Settings.Num_Step);
                AoMaterial.SetInt(P_MAXDISTANCE_ID, Settings.MaxDistance);

                AoMaterial.SetFloat(P_AngleBias_ID, Settings.AngleBias);
                AoMaterial.SetFloat(P_AoDistanceAttenuation_ID, Settings.AoDistanceAttenuation);
                AoMaterial.SetFloat(P_Intensity_ID, Settings.Intensity);

                BlurMaterial.SetFloat(P_BlurSharpness_ID, Settings.BlurSharpness);
                BlurMaterial.SetInt(P_KernelRadius_ID, Settings.Kernel_Radius);

                if (Settings.TemporalJitter) { AoMaterial.EnableKeyword("USE_TEMPORALNOISE"); }
                if (Settings.FullPrecision) { AoMaterial.EnableKeyword("FULL_PRECISION_AO"); BlurMaterial.EnableKeyword("FULL_PRECISION_AO"); }
                if (Settings.MultiBounce) { BlurMaterial.EnableKeyword("MULTI_BOUNCE_AO"); }

                using (new ProfilingScope(Cmd_AO, new ProfilingSampler("GreeningRP_AO")))
                {
                    Cmd_AO.Clear();
                    Cmd_AO.GetTemporaryRT(RT_AoBase_ID, AoTextureDesc, FilterMode.Point);
                    Cmd_AO.GetTemporaryRT(RT_AoBlur_Spatial_X_ID, AoTextureDesc, FilterMode.Point);
                    Cmd_AO.GetTemporaryRT(RT_AoBlur_Spatial_Y_ID, AoTextureDesc, FilterMode.Point);
                    Cmd_AO.GetTemporaryRT(AO_Current_RT_ID, AoTextureDesc, FilterMode.Point);
                    if (Settings.MultiBounce)
                    {
                        Cmd_AO.GetTemporaryRT(RT_MultiBounce_Out_ID, AoTextureDesc_Color, FilterMode.Point);
                    }
                    else
                    {
                        Cmd_AO.GetTemporaryRT(RT_MultiBounce_Out_ID, AoTextureDesc, FilterMode.Point);
                    }


                    //开始后处理
                    Cmd_AO.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                    //绘制AO
                    Cmd_AO.SetRenderTarget(RT_AoBase_ID);
                    if (Settings.AOMethod is AO_Methods.GTAO) { Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, AoMaterial, 0, 1); }
                    else if (Settings.AOMethod is AO_Methods.HBAO_Plus) { Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, AoMaterial, 0, 0); }

                    //时间滤波
                    if (Settings.TemporalFilter)
                    {
                        Cmd_AO.SetGlobalTexture(RT_Temporal_In_ID, RT_AoBase_ID);
                        BlurMaterial.SetFloat(P_TemporalFilterIntensity_ID, Settings.TemporalFilterIntensity);
                        Cmd_AO.SetRenderTarget(AO_Current_RT_ID);
                        BlurMaterial.SetTexture(AO_Previous_RT_ID, AO_Previous_RT);
                        Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, BlurMaterial, 0, 4);
                        Cmd_AO.Blit(AO_Current_RT_ID, AO_Previous_RT);
                    }
                    else { Cmd_AO.CopyTexture(RT_AoBase_ID, AO_Current_RT_ID); }

                    //双边滤波
                    if (Settings.SpatialFilter)
                    {
                        Cmd_AO.SetGlobalTexture(RT_Spatial_In_X_ID, AO_Current_RT_ID);
                        Cmd_AO.SetRenderTarget(RT_AoBlur_Spatial_X_ID);
                        Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, BlurMaterial, 0, 2);

                        Cmd_AO.SetGlobalTexture(RT_Spatial_In_Y_ID, RT_AoBlur_Spatial_X_ID);
                        Cmd_AO.SetRenderTarget(RT_AoBlur_Spatial_Y_ID);
                        Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, BlurMaterial, 0, 3);
                    }
                    else { Cmd_AO.CopyTexture(AO_Current_RT_ID, RT_AoBlur_Spatial_Y_ID); }
                    //MultiBounce
                    if (Settings.MultiBounce)
                    {
                        Cmd_AO.SetGlobalTexture(RT_MultiBounce_In_ID, RT_AoBlur_Spatial_Y_ID);
                        Cmd_AO.SetRenderTarget(RT_MultiBounce_Out_ID);
                        Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, BlurMaterial, 0, 6);
                    }
                    else { Cmd_AO.CopyTexture(RT_AoBlur_Spatial_Y_ID, RT_MultiBounce_Out_ID); }

                    //拷贝到屏幕
                    Cmd_AO.SetGlobalTexture(GLOBAL_RT_AmbientOcclusion_ID, RT_MultiBounce_Out_ID);
                    if (Settings.Debug)
                    {
                        Cmd_AO.SetRenderTarget(CameraColorTarget);
                        Cmd_AO.DrawMesh(FullScreenMesh, Matrix4x4.identity, BlurMaterial, 0, 5);
                    }
                    //后处理结束
                    Cmd_AO.SetRenderTarget(CameraColorTarget);
                    Cmd_AO.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
                }
                context.ExecuteCommandBuffer(Cmd_AO);
                context.Submit();
            }
            public void OnRenderCleanup(ScriptableRenderContext context, Camera camera)
            {
                Cmd_AO.Clear();
                Cmd_AO.ReleaseTemporaryRT(RT_AoBlur_Spatial_Y_ID);
                Cmd_AO.ReleaseTemporaryRT(RT_AoBlur_Spatial_X_ID);
                Cmd_AO.ReleaseTemporaryRT(RT_AoBase_ID);
                Cmd_AO.ReleaseTemporaryRT(AO_Current_RT_ID);
                Cmd_AO.ReleaseTemporaryRT(RT_MultiBounce_Out_ID);
                context.ExecuteCommandBuffer(Cmd_AO);
                context.Submit();
                CommandBufferPool.Release(Cmd_AO);
            }

            ~RenderPass()
            {
                 Debug.Log("注销ao");
                AO_Previous_RT.DiscardContents();
                AO_Previous_RT.Release();
                if (!AO_Previous_RT.IsDestroyed())
                {
                    DestroyImmediate(AO_Previous_RT);
                }
                if (!FullScreenMesh.IsDestroyed())
                {
                    DestroyImmediate(FullScreenMesh);
                }
            }
        }
    }
}
