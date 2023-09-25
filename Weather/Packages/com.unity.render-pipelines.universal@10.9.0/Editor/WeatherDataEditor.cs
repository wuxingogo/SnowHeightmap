using UnityEngine;
using UnityEditor;
using UnityEngine.Experimental.Rendering.Universal;

[CustomEditor(typeof(HeightmapRenderData), true)]
    public class WeatherRendererDataEditor : Editor
    {
        private static class Styles
        {
            public static readonly GUIContent RendererTitle = new GUIContent("Weather Renderer", "Weather Renderer for Universal RP.");
            public static readonly GUIContent FilterLayerMask = new GUIContent("Filter Layer Mask", "Controls which layers this renderer draws.");
        }

        SerializedProperty m_FilterLayerMask;

        protected virtual void OnEnable()
        {
            m_FilterLayerMask = serializedObject.FindProperty("m_FilterLayerMask");
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            // serializedObject.Update();

            // EditorGUILayout.Space();
            // EditorGUILayout.LabelField(Styles.RendererTitle, EditorStyles.boldLabel); // Title
            // EditorGUI.indentLevel++;
            // EditorGUILayout.PropertyField(m_FilterLayerMask, Styles.FilterLayerMask);
            // EditorGUI.indentLevel--;
            // EditorGUILayout.Space();
            // serializedObject.ApplyModifiedProperties();

            // Draw the base UI, contains ScriptableRenderFeatures list
        }
    }

