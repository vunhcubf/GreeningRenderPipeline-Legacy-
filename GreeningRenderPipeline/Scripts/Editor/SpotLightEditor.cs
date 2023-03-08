using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering.GreeningRP;

[CanEditMultipleObjects]
[CustomEditorForRenderPipeline(typeof(Light),typeof(GreeningRenderPipelineAsset))]
public class SpotLightEditor : LightEditor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if(!settings.lightType.hasMultipleDifferentValues && (LightType)settings.lightType.enumValueIndex is LightType.Spot)
        {
            settings.DrawInnerAndOuterSpotAngle();
            settings.ApplyModifiedProperties();
        }
    }
}
