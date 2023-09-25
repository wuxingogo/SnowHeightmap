Shader "Unlit/Heightmap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurRange("_BlurRange", Float) = 1

        //_SnowNoise("_SnowNoise", 2D) = "white"{}
        //_SnowNoiseIntensity("_SnowNoiseIntensity", Float) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _BlurRange;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            sampler2D _SnowNoise;
            float _SnowNoiseIntensity;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            half4 frag(v2f i):SV_TARGET
            {              
                half4 tex=tex2D(_MainTex,i.uv); //中心像素
                half noise = tex2D(_SnowNoise, i.uv * _SnowNoiseIntensity);
                //四角像素
                //注意这个【_BlurRange】，这就是扩大卷积核范围的参数
                tex+=tex2D(_MainTex,i.uv+float2(-1,-1)*_MainTex_TexelSize.xy*_BlurRange * noise); 
                tex+=tex2D(_MainTex,i.uv+float2(-1,0)*_MainTex_TexelSize.xy*_BlurRange * noise); 
                tex+=tex2D(_MainTex,i.uv+float2(-1,1)*_MainTex_TexelSize.xy*_BlurRange * noise);
                
                tex+=tex2D(_MainTex,i.uv+float2(1,-1)*_MainTex_TexelSize.xy*_BlurRange * noise);
                tex+=tex2D(_MainTex,i.uv+float2(1,0)*_MainTex_TexelSize.xy*_BlurRange * noise);
                tex+=tex2D(_MainTex,i.uv+float2(1,1)*_MainTex_TexelSize.xy*_BlurRange * noise);

                tex+=tex2D(_MainTex,i.uv+float2(0,-1)*_MainTex_TexelSize.xy*_BlurRange * noise);
                tex+=tex2D(_MainTex,i.uv+float2(0,1)*_MainTex_TexelSize.xy*_BlurRange * noise);

                
                
                return tex/9.0; //像素平均
            }
            ENDCG
        }
    }
}
