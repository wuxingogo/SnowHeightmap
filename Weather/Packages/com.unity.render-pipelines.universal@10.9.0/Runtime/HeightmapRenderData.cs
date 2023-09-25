#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
#endif
using System;
using UnityEngine.Scripting.APIUpdating;
using System.ComponentModel;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.Universal
{
    [Serializable, ExcludeFromPreset]

    public class HeightmapRenderData : ScriptableRendererData
    {
        [SerializeField] private LayerMask m_FilterLayerMask;
        public LayerMask FilterLayerMask
        {
            get { return m_FilterLayerMask; }
            set { m_FilterLayerMask = value; }
        }
        public RenderPassEvent renderEvent = RenderPassEvent.BeforeRenderingPrepasses;
        public string shaderTagID = "WeatherDepth";

        public Material blurMaterial = null;

        public override bool Equals(object other)
        {
            return base.Equals(other);
        }
        #if UNITY_EDITOR
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1812")]
        internal class CreateWeatherRendererAsset : EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var instance = CreateInstance<HeightmapRenderData>();
                AssetDatabase.CreateAsset(instance, pathName);
                ResourceReloader.ReloadAllNullIn(instance, UniversalRenderPipelineAsset.packagePath);
                Selection.activeObject = instance;
            }
        }

        [MenuItem("Assets/Create/Rendering/Universal Render Pipeline/WeatherRenderer", priority = CoreUtils.assetCreateMenuPriority2)]
        static void CreateForwardRendererData()
        {
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreateWeatherRendererAsset>(), "WeatherRenderer.asset", null, null);
        }
#endif
        public override int GetHashCode()
        {
            return base.GetHashCode();
        }

        public override string ToString()
        {
            return base.ToString();
        }

        protected override ScriptableRenderer Create()
        {
    //         #if UNITY_EDITOR
    //             if (!Application.isPlaying)
    //             {
    //                 ResourceReloader.TryReloadAllNullIn(this, UniversalRenderPipelineAsset.packagePath);
    //             }
    // #endif
                return new HeightmapRender(this);
        }

        protected override void OnEnable()
        {
            base.OnEnable();
        }

        protected override void OnValidate()
        {
            base.OnValidate();
        }

        internal override Material GetDefaultMaterial(DefaultMaterialType materialType)
        {
            return base.GetDefaultMaterial(materialType);
        }

        internal override Shader GetDefaultShader()
        {
            return base.GetDefaultShader();
        }



    }
}