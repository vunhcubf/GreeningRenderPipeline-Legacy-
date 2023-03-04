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
        private static readonly int RT_GBuffer0_ID = Shader.PropertyToID("GBuffer0");
        private static readonly int RT_GBuffer1_ID = Shader.PropertyToID("GBuffer1");
        private static readonly int RT_GBuffer2_ID = Shader.PropertyToID("GBuffer2");
        private static readonly int RT_CameraDepth_ID = Shader.PropertyToID("SceneDepth");

        private static readonly int Fov_ID = Shader.PropertyToID("fov");
        private static readonly int FarClipPlane_ID = Shader.PropertyToID("FarClipPlane");
        private static readonly int NearClipPlane_ID = Shader.PropertyToID("NearClipPlane");
        private static readonly int Aspect_ID = Shader.PropertyToID("Aspect");
        private static readonly int ScreenParams_ID = Shader.PropertyToID("ScreenParams");
        private static readonly int World2View_Matrix_ID = Shader.PropertyToID("World2View_Matrix");
        private static readonly int View2World_Matrix_ID = Shader.PropertyToID("View2World_Matrix");
        private static readonly int InvProjection_Matrix_ID = Shader.PropertyToID("InvProjection_Matrix");
        private static readonly int Projection_Matrix_ID = Shader.PropertyToID("Projection_Matrix");
        private static readonly int CameraVP_Matrix_ID = Shader.PropertyToID("CameraVP_Matrix");
        private static readonly int CameraInvVP_Matrix_ID = Shader.PropertyToID("CameraInvVP_Matrix");
    }
}

