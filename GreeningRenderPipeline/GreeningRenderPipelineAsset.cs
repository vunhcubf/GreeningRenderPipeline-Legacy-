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
        }
        [System.Serializable]
        public class LightSetting
        {
            [Header("�ִع�������")]
            public bool UseClusterLight;
            public int3 NumClusterXYZ=new int3(16,16,32);
        }
        [Header("��������ɫ����Դ")]
        public ShaderResource ShaderResources = new ShaderResource();
        [Header("��������")]
        public LightSetting LightSettings = new LightSetting();
        [Header("Srp����")]
        public SprSettings Srp = new SprSettings();
        [Space(15)]
        [Header("ȫ�ֹ�������")]
        public GlobalilluminationSettings Globalillumination = new GlobalilluminationSettings();
        protected override RenderPipeline CreatePipeline()
        {
            return new GreeningRenderPipeline(Srp, Globalillumination, ShaderResources, LightSettings);
        }
    }
}
