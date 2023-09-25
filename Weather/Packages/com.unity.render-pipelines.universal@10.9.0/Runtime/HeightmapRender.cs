using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;


    public class HeightmapRender : ScriptableRenderer
    {
        public string MatrixVPToHeightmap = "_Matrix_VP_To_Heightmap";
        public string MatrixVPInverseToWorld = "_Matrix_VPInverse_To_World";
        public static bool Active;
        public static bool EnableRealtimeMap = false;
        private WeatherDepthPass m_DepthPass;
        public static RenderTexture m_DepthTexture;
        public HeightmapRenderData renderConfig = null;
        public HeightmapRender(HeightmapRenderData data) : base(data)
        {
            renderConfig = data;
            if(m_DepthPass == null)
            {
                m_DepthPass = new WeatherDepthPass(data);
            }
            GetTemporaryDepthRT();
            supportedRenderingFeatures = new RenderingFeatures()
            {
                cameraStacking = true,
            };
        }

        private void GetTemporaryDepthRT()
        {
            if(m_DepthTexture == null)
            {
                #if UNITY_EDITOR
                m_DepthTexture = RenderTexture.GetTemporary(2048, 2048, 16, RenderTextureFormat.Depth);
                #else
                m_DepthTexture = RenderTexture.GetTemporary(1024, 1024, 16, RenderTextureFormat.Depth);
                #endif
            }
            
            Shader.SetGlobalTexture("_WeatherCameraDepthTexture",  m_DepthTexture);
            m_DepthTexture.name = "_WeatherCameraDepthTexture";
        }

        public static void ReleseTemporaryDepthRT()
        {
            if (m_DepthTexture != null)
            {
                RenderTexture.ReleaseTemporary(m_DepthTexture);
                m_DepthTexture = null;
                
            }
            //m_CustomDepthTexture = null;
        }

        /// <inheritdoc />
        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //if (Active)
            {
                    if (m_DepthTexture == null)
                    {
                        GetTemporaryDepthRT();
                        
                        
                        
                    }
                    WeatherDepthPass.SetRT(m_DepthTexture);
                    
                    // EnvironmentManager.SetWeatherCameraVPMatrix();
                    var _weatherCamera = renderingData.cameraData.camera;
                    Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(_weatherCamera.projectionMatrix, false);
                    var vp = projectionMatrix * _weatherCamera.worldToCameraMatrix;
                    Shader.SetGlobalMatrix(MatrixVPToHeightmap, vp);
                    Shader.SetGlobalMatrix(MatrixVPInverseToWorld, Matrix4x4.Inverse(vp));

                    EnqueuePass(m_DepthPass);
                
                    Shader.SetGlobalTexture("_WeatherCameraDepthTexture", m_DepthTexture);
                
                Active = false;
            }
        }

        

        /// <inheritdoc />
        public override void SetupLights(ScriptableRenderContext context, ref RenderingData renderingData)
        {
        }

        /// <inheritdoc />
        public override void SetupCullingParameters(ref ScriptableCullingParameters cullingParameters,
            ref CameraData cameraData)
        {
        }

        /// <inheritdoc />
        public override void FinishRendering(CommandBuffer cmd)
        {
        }
    }
