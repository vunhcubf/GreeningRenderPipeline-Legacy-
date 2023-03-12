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
using System.Threading.Tasks;
using System.Numerics;

namespace UnityEngine.Rendering.GreeningRP
{
    public partial class GreeningRenderPipeline
    {
        private void DefferedShading()
        {
            ComputeShader DefferedShading_Shader = shader_resources.DefferedShading_Shader;
            int Kernel_Main = DefferedShading_Shader.FindKernel("DefferedShading");
            
            DefferedShading_Shader.SetTexture(Kernel_Main,"DefferedShading_Dest", RT_CameraTargetTexture_HDR);
            DefferedShading_Shader.SetBool("IsAnyPointLight", IsAnyPointLight);
            DefferedShading_Shader.SetBuffer(Kernel_Main, "PointLightPropertiesList", PointLightBuffer);
            DefferedShading_Shader.SetBool("IsAnyDirectionalLight", IsAnyDirectionalLight);
            DefferedShading_Shader.SetBuffer(Kernel_Main, "DirectionalLightPropertiesList", DirectionalLightBuffer);
            DefferedShading_Shader.SetBool("IsAnySpotLight", IsAnySpotLight);
            DefferedShading_Shader.SetBuffer(Kernel_Main, "SpotLightPropertiesList", SpotLightBuffer);

            Shader.SetGlobalTexture("Brdf_Lut", shader_resources.BrdfLut);
            DefferedShading_Shader.SetTexture(Kernel_Main, "SkyBoxMap", skybox_settings.SkyBoxMap);
            Shader.SetGlobalInt("SkyBoxMap_MaxMipLevel", skybox_settings.SkyBoxMap.mipmapCount);

            if (UseClusterLight)
            {
                Shader.EnableKeyword("CLUSTER_LIGHT");
                DefferedShading_Shader.SetInt("NumClusterX", NumClusterX);
                DefferedShading_Shader.SetInt("NumClusterY", NumClusterY);
                DefferedShading_Shader.SetInt("NumClusterZ", NumClusterZ);
                DefferedShading_Shader.SetBuffer(Kernel_Main, "GlobalValidLightList", GlobalValidLightList);
                DefferedShading_Shader.SetBuffer(Kernel_Main, "LightAssignTable", LightAssignTable);
            }
            else
            {
                Shader.DisableKeyword("CLUSTER_LIGHT");
            }
            

            DefferedShading_Shader.Dispatch(Kernel_Main, 1+Width/8,1+Height/8,1);
        }
    }
}
