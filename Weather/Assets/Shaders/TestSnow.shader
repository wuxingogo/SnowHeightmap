Shader "Unlit/TestSnow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("_BumpMap", 2D) = "bump" {}
        _SnowTex ("SnowTex", 2D) = "white" {}
        _SnowRange("SnowRange", Float) = 0.0
        _SnowExp("_SnowExp", Float) = 0.0
        _SnowIntensity("_SnowIntensity", Float) = 0.0
        _SnowNoise("_SnowNoise", 2D) = "white"{}
        _SnowNoiseIntensity("_SnowNoiseIntensity", Float) = 1
        _SnowHeight("_SnowHeight", Float) = 0.0
        // _SnowHeightMap("_SnowHeightmap", 2D) = "white" {}
        _HeightOffset ("_HeightOffset", Float) = 1.0
        _HeightOffsetHigh ("_HeightOffsetHigh", Float) = 1.0
        _HeightAlpha ("_HeightAlpha", Float) = 1.0
    }
    SubShader
    {
        
        LOD 100
        CGINCLUDE
            #define _NORMALMAP 1
            #define _TANGENT_TO_WORLD
            #define BLUR_HEIGHT_MAP
            #include "UnityCG.cginc"
            #include "UnityStandardCore.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
                 half4 tangent   : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 tex : TEXCOORD1;
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                
                float3 normal :NORMAL;
                
                float4 tangentToWorldAndPackedData[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
                float4 vertexOS : TEXCOORD5;
                float4 worldPos : TEXCOORD6;
            };
            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            float _SnowRange;
            sampler2D _SnowTex;
            sampler2D _WeatherDepthBluredTexture;
            sampler2D _WeatherCameraDepthTexture;
            float _SnowExp;
            float _SnowIntensity;
            float _SnowHeight;
            float _HeightOffset;
            float _HeightOffsetHigh;
            float _HeightAlpha;

            sampler2D _SnowNoise;
            float _SnowNoiseIntensity;

            sampler2D _SnowHeightMap;
            float4x4 _Matrix_VP_To_Heightmap;
            float4x4 _Matrix_VPInverse_To_World;
            
            float4 TexCoords(appdata v)
            {
                float4 texcoord;
                texcoord.xy = TRANSFORM_TEX(v.uv, _MainTex); // Always source from uv0
                texcoord.zw = TRANSFORM_TEX(v.uv, _MainTex);
                return texcoord;
            }

            

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.tex = TexCoords(v);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 normalWorld = UnityObjectToWorldNormal(v.normal);
                #ifdef _TANGENT_TO_WORLD
                    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
                    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
                    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
                    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
                #else
                    o.tangentToWorldAndPackedData[0].xyz = 0;
                    o.tangentToWorldAndPackedData[1].xyz = 0;
                    o.tangentToWorldAndPackedData[2].xyz = normalWorld;
                #endif
                o.vertexOS = v.vertex;
                // UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            float remap(float s, float a1, float a2, float b1, float b2)
            {
                return b1 + (s-a1)*(b2-b1)/(a2-a1);
            }
            float GetHeight(float worldPosY)
            {
                float fade = 0;
                return saturate(remap(worldPosY, _SnowHeight, _SnowHeight + fade, 0, 1));
            }
            float Remap(float x, float low, float high)
            { 
                return saturate((x-low)/(high-low)); 
            }    

            float GetHeightMap(float3 posWorld)
            {
                //_Matrix_VP_To_Heightmap 是高度图相机的VP矩阵
                //求出高度图相机的clipPos
                float4 weatherCood =  mul(_Matrix_VP_To_Heightmap, float4(posWorld, 1.0));
                //透视除法后 转到NDC (-1, 1)
                float2 heightMapUV = weatherCood.xy/weatherCood.w;

                
                heightMapUV = heightMapUV * 0.5 + 0.5; //(-1, 1)-->(0, 1)
                /*float depth = weatherCood.z / weatherCood.w;
                #if defined (SHADER_TARGET_GLSL)
                    depth = depth * 0.5 + 0.5; //(-1, 1)-->(0, 1)
                #elif defined (UNITY_REVERSED_Z)
                    depth = 1 - depth;       //(1, 0)-->(0, 1)
                #endif*/
                //此时的heightmap是clipspace.z
                #if defined (BLUR_HEIGHT_MAP)
                float depth = tex2Dlod(_WeatherDepthBluredTexture, float4(heightMapUV, 0, 0)).r;
                #else
                float depth = tex2Dlod(_WeatherCameraDepthTexture, float4(heightMapUV, 0, 0)).r;
                #endif
                
                // depth = Linear01Depth (depth);
                #if defined (SHADER_API_MOBILE) || defined (SHADER_API_GLES) || defined (SHADER_API_GLES3) || defined (SHADER_API_GLCORE) || defined (SHADER_TARGET_GLSL) 
                    depth = depth * 2.0  - 1.0; //(0, 1) --> (-1, 1)
                #endif
                /*#if defined (SHADER_TARGET_GLSL)
                    depth = depth * 2.0  - 1.0; //(0, 1) --> (-1, 1)
                #elif UNITY_REVERSED_Z
                    depth = 1 - depth;       //(0, 1) --> (1, 0)
                #endif*/
                //depth * clipPos.w = ndc space position
                float4 col = float4(weatherCood.xy, depth * weatherCood.w, weatherCood.w);
                //inverse VP -> world space
                float result = mul(_Matrix_VPInverse_To_World, col).y;
                
                return depth * result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 positionWS = i.worldPos;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //TO NORMAL_worldspace
                float3 normalWorld = PerPixelWorldNormal(i.tex, i.tangentToWorldAndPackedData);

                //顶部区域
                float topMask = saturate(pow(abs(saturate(normalWorld.y) + _SnowRange), _SnowExp) * _SnowIntensity);
                //雪高度 Mask
                float height = GetHeight(positionWS.y);
                //
                fixed4 noise = tex2D(_SnowNoise, positionWS.xz );
                //获得最高点高度
                float h = GetHeightMap(positionWS);
                
                half heightMaskName = saturate(positionWS.y - h + _HeightOffset);
                // half heightMaskName = saturate(remap(positionWS.y - h + 1.0, _HeightOffset, _HeightOffsetHigh, 1, 0));

                //高度图mask = 当前高度-当前像素最高高度 + 1
                // half heightMaskName = saturate( exp( _HeightOffset * (positionWS.y - h + 1))); 
                // heightMaskName = Remap(heightMaskName, 0, noise);
                //三种mask : 顶部区域、高度、高度贴图mask
                float mask = topMask  * (heightMaskName);
                fixed4 snowColor = tex2D(_SnowTex, i.uv);

                float4 finalColor = lerp(col.rgba , snowColor,  mask );
                return finalColor;
            }

            fixed4 fragHeight(v2f i) : SV_Target
            {
                
                float clipPos = i.vertex.xyz;
                // if(clipPos <= -1 || clipPos >= 1)
                // {
                //     return 0;
                // }
                float4 positionWS = i.worldPos;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //TO NORMAL_worldspace
                float3 normalWorld = PerPixelWorldNormal(i.tex, i.tangentToWorldAndPackedData);

                //顶部区域
                float topMask = saturate(pow(abs(saturate(normalWorld.y) + _SnowRange), _SnowExp) * _SnowIntensity);
                //雪高度 Mask
                float height = GetHeight(positionWS.y);
                //
                fixed4 noise = tex2D(_SnowNoise, positionWS.xz );
                //获得最高点高度
                float h = GetHeightMap(positionWS);
                
                // half heightMaskName = saturate(positionWS.y - h + _HeightOffset);
                // half heightMaskName = saturate(remap(positionWS.y - h + 1.0, _HeightOffset, _HeightOffsetHigh, 1, 0));

                //高度图mask = 当前高度-当前像素最高高度 + 1
                half heightMaskName = saturate( exp( _HeightOffset * (positionWS.y - h + 1))); 
                // heightMaskName = Remap(heightMaskName, 0, noise);
                //三种mask : 顶部区域、高度、高度贴图mask
                float mask = topMask * height * heightMaskName;
                fixed4 snowColor = tex2D(_SnowTex, i.uv);

                float4 finalColor = lerp(col.rgba , snowColor,  mask );
                finalColor *=_HeightAlpha;
                return half4(finalColor.r, 0,0,1);
            }
        ENDCG
        Pass
        {
            Name "ForawardPass"
            Tags { "RenderType"="Opaque" }

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            
            ENDCG
        }
        Pass
        {
            Name "WeatherDepth"
            Tags { "Lightmode"="WeatherDepth"  }

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment fragHeight
            // make fog work
            #pragma multi_compile_fog
            
            
            ENDCG
        }
    }
}
