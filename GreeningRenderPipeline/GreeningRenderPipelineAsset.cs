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
            [Header("�ӳ���ɫshader")]
            public ComputeShader DefferedShading_Shader;
            [Header("�ִع���shader")]
            public ComputeShader ClusterLight_Shader;
            [Header("��պ�shader")]
            public ComputeShader SkyBox_Shader;
            public Texture2D BrdfLut;
        }
        [System.Serializable]
        public class LightSetting
        {
            [Header("�ִع�������")]
            public bool UseClusterLight;
            public int3 NumClusterXYZ=new int3(16,16,32);
            public uint AverageOverlapLightCountPerCluster = 20;
            public bool DebugLightCount=true;
        }
        [System.Serializable]
        public class SkyBoxSetting
        {
            public Cubemap SkyBoxMap;
            public enum SkyBoxtype
            {
                Panomanic,
                CubeMap
            };
            public SkyBoxtype SkyBoxType;
            [Range(0f,2f)]
            public float Exposure = 1f;
            [Range(0f, 360f)]
            public float Rotation = 0f;
        }
        [Header("��������ɫ����Դ")]
        public ShaderResource ShaderResources = new ShaderResource();
        [Header("��������")]
        public LightSetting LightSettings = new LightSetting();
        [Header("��պ�����")]
        public SkyBoxSetting SkyBoxSettings=new SkyBoxSetting();
        [Header("Srp����")]
        public SprSettings Srp = new SprSettings();
        [Space(15)]
        [Header("ȫ�ֹ�������")]
        public GlobalilluminationSettings Globalillumination = new GlobalilluminationSettings();
        protected override RenderPipeline CreatePipeline()
        {
            return new GreeningRenderPipeline(Srp, Globalillumination, ShaderResources, LightSettings, SkyBoxSettings);
        }
    }
}
