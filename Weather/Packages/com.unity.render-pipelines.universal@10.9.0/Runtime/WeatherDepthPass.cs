using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


    /// <summary>
    /// Render all objects that have a 'DepthOnly' pass into the given depth buffer.
    ///
    /// You can use this pass to prime a depth buffer for subsequent rendering.
    /// Use it as a z-prepass, or use it to generate a depth buffer.
    /// </summary>
    public class WeatherDepthPass : ScriptableRenderPass
    {
        int kDepthBufferBits = 32;

        private static RenderTexture m_DepthTexture;
        FilteringSettings m_FilteringSettings;
        const string m_ProfilerTag = "Weather Depth Pass";
        ProfilingSampler m_ProfilingSampler = new ProfilingSampler(m_ProfilerTag);
        // ShaderTagId m_ShaderTagId = new ShaderTagId("DepthOnly");
        List<ShaderTagId> m_ShaderTagId = null;
        public static LayerMask LayerMask = -1;

        public HeightmapRenderData config;
        /// <summary>
        /// Create the DepthOnlyPass
        /// </summary>
        public WeatherDepthPass(HeightmapRenderData data)
        {
            RenderQueueRange m_renderQueueRange = RenderQueueRange.all;
            LayerMask = data.FilterLayerMask;
            m_FilteringSettings = new FilteringSettings(m_renderQueueRange, LayerMask);
            renderPassEvent = data.renderEvent;
            config = data;
            m_ShaderTagId = new List<ShaderTagId>()
            {
                new ShaderTagId(data.shaderTagID),
                
            };
        }

        public static void SetRT(RenderTexture rt)
        {
            m_DepthTexture = rt;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureTarget(m_DepthTexture);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        private float lodBias = 0;
        public static float LODBias = 3;

        private int maximumLODLevel = 0;
        public static int MaximumLODLevel = 0;
        public void FinishRendering()
        {
            //ResetCameraLOD();
        }
        public void RecordAndDisableCameraLOD()
        {
            Debug.Log("lod bias :" +
            QualitySettings.lodBias);
            lodBias = QualitySettings.lodBias;
            maximumLODLevel = QualitySettings.maximumLODLevel;

            QualitySettings.maximumLODLevel = MaximumLODLevel;
            QualitySettings.lodBias = LODBias;

            Debug.Log("lod bias :" +
            QualitySettings.lodBias);
            // Debug.Log("lod bias :" +
            // QualitySettings.maximumLODLevel);
        }
        public void ResetCameraLOD()
        {
            // QualitySettings.lodBias = lodBias;
            
            // QualitySettings.maximumLODLevel = maximumLODLevel;
        }
        public RenderTexture blurRenderTex;
        public RenderTexture blurRenderTex2;

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                //RecordAndDisableCameraLOD();
                cmd.SetRenderTarget(m_DepthTexture);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortFlags);
                drawSettings.perObjectData = PerObjectData.None;

                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);

                
            }
            context.ExecuteCommandBuffer(cmd);

            if(blurRenderTex == null)
            {
                blurRenderTex = RenderTexture.GetTemporary(512, 512, 0, RenderTextureFormat.RHalf);
                blurRenderTex.name = "_WeatherDepthBluredTexture";

                blurRenderTex2 = RenderTexture.GetTemporary(512, 512, 0, RenderTextureFormat.RHalf);
                blurRenderTex2.name = "_WeatherDepthBluredTexture2";
            }    
            
            //使用矩形模糊 5次
            cmd.Clear();
            cmd.SetRenderTarget(blurRenderTex);
            cmd.ClearRenderTarget(true, true, Color.black);
            cmd.Blit(m_DepthTexture, blurRenderTex, config.blurMaterial);
            cmd.Blit(blurRenderTex, blurRenderTex2, config.blurMaterial);
            cmd.Blit(blurRenderTex2, blurRenderTex, config.blurMaterial);
            cmd.Blit(blurRenderTex, blurRenderTex2, config.blurMaterial);
            cmd.Blit(blurRenderTex2, blurRenderTex, config.blurMaterial);
            
            cmd.SetGlobalTexture("_WeatherDepthBluredTexture", blurRenderTex);
            context.ExecuteCommandBuffer(cmd);

            
            CommandBufferPool.Release(cmd);
        }
    }

