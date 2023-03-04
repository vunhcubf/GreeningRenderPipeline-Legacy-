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
        struct PointLight
        {
            public Vector3 Color;
            public Vector3 PositionWS;
            public float Range;
        };
        struct DirectionalLight
        {
            public Vector3 Color;
            public Vector3 Direction;
        };

        ComputeBuffer PointLightBuffer;
        ComputeBuffer DirectionalLightBuffer;
        bool IsAnyDirectionalLight= true;
        bool IsAnyPointLight= true;
        Vector3 ColorToVector3(Color color)
        {
            return new Vector3(color.r, color.g, color.b);
        }
        PointLight GetPointLightProperties(VisibleLight One)
        {
            PointLight Out;
            Out.Color = ColorToVector3(One.finalColor);
            Out.PositionWS = new Vector3(One.localToWorldMatrix.m03, One.localToWorldMatrix.m13, One.localToWorldMatrix.m23);
            Out.Range = One.range;
            return Out;
        }
        DirectionalLight GetDirectionalLightProperties(VisibleLight One)
        {
            DirectionalLight Out;
            Out.Color= ColorToVector3(One.finalColor);
            Out.Direction = -One.localToWorldMatrix.GetColumn(2);
            return Out;
        }
        private void SetLightProperties(ref CullingResults Culling_result)
        {
            List<PointLight> PointLightList = new List<PointLight>();
            List<DirectionalLight> DirectionalLightList = new List<DirectionalLight>();

            var Visible_Light = Culling_result.visibleLights;
            foreach (var one in Visible_Light)
            {
                switch (one.lightType)
                {
                    case LightType.Point:
                        {
                            PointLightList.Add(GetPointLightProperties(one));
                            break;
                        }
                    case LightType.Directional:
                        {
                            DirectionalLightList.Add(GetDirectionalLightProperties(one));
                            break;
                        }
                }
            }
            IsAnyDirectionalLight = true;
            IsAnyPointLight = true;
            if (PointLightList.Count == 0) { IsAnyPointLight = false; PointLightList.Add(new PointLight()); }
            PointLightBuffer = new ComputeBuffer(PointLightList.Count, 28);
            PointLightBuffer.SetData(PointLightList);
            Shader.SetGlobalInt("PointLightCount", PointLightList.Count);
            PointLightList.Clear();

            if (DirectionalLightList.Count == 0) { IsAnyDirectionalLight = false; DirectionalLightList.Add(new DirectionalLight()); }
            DirectionalLightBuffer = new ComputeBuffer(DirectionalLightList.Count, 2 * 3 * 4);
            DirectionalLightBuffer.SetData(DirectionalLightList);

            Shader.SetGlobalInt("DirectionalLightCount", DirectionalLightList.Count);
            DirectionalLightList.Clear();
        }
    }
}
