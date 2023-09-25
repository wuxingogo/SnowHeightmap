using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[ExecuteAlways]
public class HeightmapDrawer : MonoBehaviour
{
    public Camera heightCamera = null;
    public Material material = null;
    private static readonly int MatrixVPToHeightmap = Shader.PropertyToID("_Matrix_VP_To_Heightmap");
    private static readonly int MatrixVPInverseToWorld = Shader.PropertyToID("_Matrix_VPInverse_To_World");
    public float blurRange = 1;
    public int blurTimes = 1;

    RenderTexture tempRT = null;
    public Texture noiseTex = null;
    public float noiseIntensity = 1;

    public Texture2D destTexture = null;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    void OnPreCull()
    {
        Debug.Log("OnPreCull");
        
    }

    public void OnRenderImage(RenderTexture source, RenderTexture dest)
    {
        if(material != null)
        {
            dest.filterMode = FilterMode.Bilinear;
            material.SetFloat("_BlurRange", blurRange);

            if(tempRT == null)
            {
                tempRT = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0);
                tempRT.filterMode = FilterMode.Bilinear;
            }
            blurTimes = Mathf.Max(1, blurTimes);
            // Graphics.Blit(source, dest, material, 0);
            // for (int i = 0; i < blurTimes; i++)
            // {
            //     Graphics.Blit(dest,  tempRT, material, 0);
            //     //if(i != blurTimes - 1)
            //         Graphics.Blit(tempRT, dest, material, 0);
            // }    

            Graphics.Blit(source, dest);

            var rtSource = RenderTexture.active;
            RenderTexture.active = source;
            if(destTexture == null || destTexture.width != source.width)
                destTexture = new Texture2D(source.width, source.height, TextureFormat.RGB24, false);
            destTexture.ReadPixels(new Rect(0,0, source.width, source.height),0,0);
            destTexture.Apply();

            RenderTexture.active = rtSource;


            Shader.SetGlobalTexture("_SnowHeightMap", destTexture);
            Shader.SetGlobalTexture("_SnowNoise", noiseTex);
            Shader.SetGlobalFloat("_SnowNoiseIntensity", noiseIntensity);
        }

        
    }
    // Update is called once per frame
    void Update()
    {
        
        if(heightCamera == null)
            return ;
        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(heightCamera.projectionMatrix, false);
        var vp = projectionMatrix * heightCamera.worldToCameraMatrix;
        Shader.SetGlobalMatrix(MatrixVPToHeightmap, vp);
        Shader.SetGlobalMatrix(MatrixVPInverseToWorld, Matrix4x4.Inverse(vp));
        
    }
}
