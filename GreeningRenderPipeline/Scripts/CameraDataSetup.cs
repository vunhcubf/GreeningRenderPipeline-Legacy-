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
        private void InitializeCameraSettings(Camera camera)
        {
            Shader.SetGlobalFloat(Fov_ID, camera.fieldOfView);
            Shader.SetGlobalFloat(FarClipPlane_ID, camera.farClipPlane);
            Shader.SetGlobalFloat(NearClipPlane_ID, camera.nearClipPlane);
            Shader.SetGlobalFloat(Aspect_ID, camera.aspect);
            Width = camera.pixelWidth;
            Height = camera.pixelHeight;
            Shader.SetGlobalVector(ScreenParams_ID, new Vector4(1.0f / Width, 1.0f / Height, Width, Height));

            Matrix4x4 View2World_Matrix = GetViewToWorldMatrix(camera);
            Matrix4x4 World2View_Matrix = View2World_Matrix.inverse;
            Matrix4x4 Projection_Matrix = GetProjectionMatrix(camera);
            Matrix4x4 InvProjection_Matrix = GetProjectionMatrix(camera).inverse;
            Matrix4x4 CameraVP_Matrix = Projection_Matrix * World2View_Matrix;
            Matrix4x4 CameraInvVP_Matrix = CameraVP_Matrix.inverse;

            Shader.SetGlobalMatrix(World2View_Matrix_ID, World2View_Matrix);
            Shader.SetGlobalMatrix(View2World_Matrix_ID, View2World_Matrix);
            Shader.SetGlobalMatrix(Projection_Matrix_ID, Projection_Matrix);
            Shader.SetGlobalMatrix(InvProjection_Matrix_ID, InvProjection_Matrix);
            Shader.SetGlobalMatrix(CameraVP_Matrix_ID, CameraVP_Matrix);
            Shader.SetGlobalMatrix(CameraInvVP_Matrix_ID, CameraInvVP_Matrix);
        }
        private Matrix4x4 GetViewToWorldMatrix(Camera camera)//经过测试结果和unity_MatrixV一致
        {
            Vector3 CameraRotation = camera.transform.rotation.eulerAngles;
            CameraRotation /= 57.2957795131f;
            Matrix4x4 M_X = Matrix4x4.identity;
            Matrix4x4 M_Y = Matrix4x4.identity;
            Matrix4x4 M_Z = Matrix4x4.identity;
            M_X.m22 = -1.0f;
            M_Y.m22 = -1.0f;
            M_Z.m22 = -1.0f;
            M_X.m11 = Mathf.Cos(CameraRotation.x);
            M_X.m12 = -Mathf.Sin(CameraRotation.x);
            M_X.m21 = Mathf.Sin(CameraRotation.x);
            M_X.m22 = Mathf.Cos(CameraRotation.x);

            M_Y.m00 = Mathf.Cos(CameraRotation.y);
            M_Y.m02 = Mathf.Sin(CameraRotation.y);
            M_Y.m20 = -Mathf.Sin(CameraRotation.y);
            M_Y.m22 = Mathf.Cos(CameraRotation.y);

            M_Z.m00 = Mathf.Cos(CameraRotation.z);
            M_Z.m01 = -Mathf.Sin(CameraRotation.z);
            M_Z.m10 = Mathf.Sin(CameraRotation.z);
            M_Z.m11 = Mathf.Cos(CameraRotation.z);
            Matrix4x4 M_Rotate = M_Y * M_X * M_Z;
            M_Rotate.m03 = camera.transform.position.x;
            M_Rotate.m13 = camera.transform.position.y;
            M_Rotate.m23 = camera.transform.position.z;
            return M_Rotate;
        }
        Matrix4x4 GetProjectionMatrix(Camera camera)//经过测试，结果和glstate_projection_matrix一致
        {
            var f = camera.farClipPlane;
            var n = camera.nearClipPlane;
            Matrix4x4 M_Proj = Matrix4x4.identity;
            M_Proj.m00 = 1 / (Mathf.Tan(camera.fieldOfView / 114.591559026f) * camera.aspect);
            M_Proj.m11 = -1 / Mathf.Tan(camera.fieldOfView / 114.591559026f);
            M_Proj.m32 = -1;
            M_Proj.m33 = 0;
            M_Proj.m22 = n / (f - n);
            M_Proj.m23 = (f * n) / (f - n);
            return M_Proj;
        }
    }
}

