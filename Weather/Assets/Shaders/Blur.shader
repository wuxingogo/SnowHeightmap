Shader "Unlit/Blur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SnowNoise("_SnowNoise", 2D) = "white"{}
        _SnowNoiseIntensity("_SnowNoiseIntensity", Float) = 1
        _BlurRange("_BlurRange", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _SnowNoise;
            float4 _MainTex_ST;
            uniform float4 _MainTex_TexelSize;

            float _BlurRange;
            float _SnowNoiseIntensity;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                 float4 tex = tex2D(_MainTex, i.uv);

                

                //Blur
                half noise = tex2D(_SnowNoise, i.uv * _SnowNoiseIntensity).r;
                //noise = 1;
                // _BlurRange = 1;
                tex+=tex2D(_MainTex, i.uv+float2(-1,-1)*_MainTex_TexelSize.xy*_BlurRange * noise); 
                tex+=tex2D(_MainTex, i.uv+float2(-1,0)*_MainTex_TexelSize.xy*_BlurRange  * noise); 
                tex+=tex2D(_MainTex, i.uv+float2(-1,1)*_MainTex_TexelSize.xy*_BlurRange  * noise);
            
                tex+=tex2D(_MainTex, i.uv+float2(1,-1)*_MainTex_TexelSize.xy*_BlurRange  * noise);
                tex+=tex2D(_MainTex, i.uv+float2(1,0)*_MainTex_TexelSize.xy*_BlurRange    * noise);
                tex+=tex2D(_MainTex, i.uv+float2(1,1)*_MainTex_TexelSize.xy*_BlurRange    * noise);

                tex+=tex2D(_MainTex, i.uv+float2(0,-1)*_MainTex_TexelSize.xy*_BlurRange   * noise);
                tex+=tex2D(_MainTex, i.uv+float2(0,1)*_MainTex_TexelSize.xy*_BlurRange    * noise);
                tex/=9.0;

                return float4(tex);

            }
            ENDCG
        }
    }
}
