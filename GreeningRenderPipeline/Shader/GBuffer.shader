Shader "GreeningRP/MainMaterial"
{
    Properties{
        [Header(ShadingModel)]
        [Enum(BasicPBR,0,Toon,1)]ShadingModel("ShadingModel",int)=0
        [Header(BaseColor)]
        BaseColorMap("BaseColor", 2D) = "white" {}
        [HDR]BaseColor_Tint("BaseColor_Tint",color)=(1,1,1,1)
        [Space(20)]
        [Header(Metallic)]
        [NoScaleOffset]MetallicMap("Metallic", 2D) = "white" {}
        Metallic_Multiplier("Metallic_Multiplier",range(0,2))=1
        [Space(20)]
        [Header(Roughness)]
        [NoScaleOffset]RoughnessMap("Roughness", 2D) = "white" {}
        Roughness_Multiplier("Roughness_Multiplier",range(0,2))=1
        [Space(20)]
        [Header(OcclusionMap)]
        [NoScaleOffset]OcclusionMap("OcclusionMap", 2D) = "white" {}
        OcclusionMap_Intensity("OcclusionMap_Intensity",range(0,4))=1
        [Space(20)]
        [Header(NormalMap)]
        [NoScaleOffset]NormalMap("NormalMap", 2D) = "bump" {}
        NormalMap_Intensity("NormalMap_Intensity",range(0,2))=1
        [Toggle]ReversedNormalMap("ReversedNormalMap",float)=0
        [Toggle]UseNormalMap("UseNormalMap",float)=0
    }
    SubShader
    {
        Pass
        {
        Tags{"LightMode"="GreeningRP_Deffered"}
            HLSLPROGRAM
            #include "Assets/GreeningRenderPipeline/ShaderLibrary/GreeningRP_GBuffer.hlsl"
            #pragma vertex Vert_GBuffer
            #pragma fragment Frag_GBuffer
            ENDHLSL
        }
    }
}
