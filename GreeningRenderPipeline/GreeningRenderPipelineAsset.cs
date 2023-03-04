using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using static UnityEngine.Rendering.GreeningRP.AmbientOcclusion;

namespace UnityEngine.Rendering.GreeningRP
{
    [CreateAssetMenu(menuName = "Rendering/GreeningRenderPipeline")]
    public class GreeningRenderPipelineAsset : RenderPipelineAsset
    {
        [System.Serializable]
        public class SprSettings
        {
            public bool UseSrpBatcher = true;
        }
        [System.Serializable]
        public class GlobalilluminationSettings
        {
            public AmbientOcclusionSetting AoSettings = new AmbientOcclusionSetting();
        }
        [System.Serializable]
        public class ShaderResource
        {
            [Header("延迟着色shader")]
            public ComputeShader DefferedShading_Shader;
            [Header("分簇光照shader")]
            public ComputeShader ClusterLight_Shader;
        }
        [System.Serializable]
        public class LightSetting
        {
            [Header("分簇光照设置")]
            public bool UseClusterLight;
            public int3 NumClusterXYZ=new int3(16,16,32);
        }
        [Header("依赖的着色器资源")]
        public ShaderResource ShaderResources = new ShaderResource();
        [Header("光照设置")]
        public LightSetting LightSettings = new LightSetting();
        [Header("Srp设置")]
        public SprSettings Srp = new SprSettings();
        [Space(15)]
        [Header("全局光照设置")]
        public GlobalilluminationSettings Globalillumination = new GlobalilluminationSettings();
        protected override RenderPipeline CreatePipeline()
        {
            return new GreeningRenderPipeline(Srp, Globalillumination, ShaderResources, LightSettings);
        }
    }
}
