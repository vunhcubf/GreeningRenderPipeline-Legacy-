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
        struct SpotLight
        {
            public Vector3 Color;
            public Vector3 PositionWS;
            public Vector3 Direction;
            public Vector2 SpotAngleAttenuation;
            public float Range;
        };

        ComputeBuffer PointLightBuffer;
        ComputeBuffer DirectionalLightBuffer;
        ComputeBuffer SpotLightBuffer;
        bool IsAnyDirectionalLight= true;
        bool IsAnyPointLight= true;
        bool IsAnySpotLight = true;
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
        SpotLight GetSpotLightProperties(VisibleLight One)
        {
            SpotLight Out;
            Out.Color = ColorToVector3(One.finalColor);
            Out.Direction = -One.localToWorldMatrix.GetColumn(2);
            Out.PositionWS= new Vector3(One.localToWorldMatrix.m03, One.localToWorldMatrix.m13, One.localToWorldMatrix.m23);
            Light spotlight = One.light;
            float InnerAngle = spotlight.innerSpotAngle;
            float OuterAngle = spotlight.spotAngle;
            InnerAngle=Mathf.Min(InnerAngle, OuterAngle-1f);
            float Cos_Inner_2=Mathf.Cos(InnerAngle * 0.5f* 0.0174532925199f);
            float Cos_Outer_2 = Mathf.Cos(OuterAngle * 0.5f* 0.0174532925199f);
            Out.SpotAngleAttenuation = new Vector2(1f/(Cos_Inner_2- Cos_Outer_2), -Cos_Outer_2 / (Cos_Inner_2 - Cos_Outer_2));
            Out.Range = spotlight.range;
            return Out;
        }
        private void SetLightProperties(ref CullingResults Culling_result)
        {
            List<PointLight> PointLightList = new List<PointLight>();
            List<DirectionalLight> DirectionalLightList = new List<DirectionalLight>();
            List<SpotLight> SpotLightList = new List<SpotLight>();

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
                    case LightType.Spot:
                        {
                            SpotLightList.Add(GetSpotLightProperties(one));
                            break;
                        }
                }
            }
            IsAnyDirectionalLight = true;
            IsAnyPointLight = true;
            if (PointLightList.Count == 0) { IsAnyPointLight = false; PointLightList.Add(new PointLight()); }
            else { IsAnyPointLight = true; }
            PointLightBuffer = new ComputeBuffer(PointLightList.Count, 28);
            PointLightBuffer.SetData(PointLightList);
            Shader.SetGlobalInt("PointLightCount", PointLightList.Count);
            PointLightList.Clear();

            if (DirectionalLightList.Count == 0) { IsAnyDirectionalLight = false; DirectionalLightList.Add(new DirectionalLight()); }
            else { IsAnyDirectionalLight = true;}
            DirectionalLightBuffer = new ComputeBuffer(DirectionalLightList.Count, 2 * 3 * 4);
            DirectionalLightBuffer.SetData(DirectionalLightList);
            Shader.SetGlobalInt("DirectionalLightCount", DirectionalLightList.Count);
            DirectionalLightList.Clear();

            if (SpotLightList.Count == 0) { IsAnySpotLight = false; SpotLightList.Add(new SpotLight()); }
            else { IsAnySpotLight = true;}
            SpotLightBuffer = new ComputeBuffer(SpotLightList.Count,3*3*4+2*4+4);
            SpotLightBuffer.SetData(SpotLightList);
            Shader.SetGlobalInt("SpotLightCount", SpotLightList.Count);
            SpotLightList.Clear();
        }
    }
}
