Shader "Unlit/CircleThingShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Assets/AudioLink/Shaders/AudioLink.cginc"

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
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                float4 vpos = v.vertex;
                o.vertex = UnityObjectToClipPos(vpos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 centeredUV = i.uv - 0.5;
                float r = length(centeredUV) * 2;
                float theta = atan2(centeredUV.x, centeredUV.y);
                float ringNum = floor(r * 9);
                float ringPercent = frac(r * 9);
                
                float4 chrono4 = float4(
                    (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(1, 0) % 628319) / 100000.0),
                    (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(1, 1) % 628319) / 100000.0),
                    (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(1, 2) % 628319) / 100000.0),
                    (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(1, 3) % 628319) / 100000.0)
                );
                float4 weights = float4(.25, -.25, .75, -.75);
                float chrono = dot(chrono4, weights);

                float phase = _Time.y * ringNum * 0.1;
                phase += sin(chrono + ringNum * 0.1);
                
                float placeInArc = AudioLinkRemap(frac(phase), 0, 1, -3.1415926, 3.1415926);
                float maskedArcDistance = glsl_mod(theta - placeInArc, 3.1415926 * 2);

                bool isRing1Or0 = (ringNum == 0 || ringNum == 1);
                bool ringMasked = (maskedArcDistance > 3.1415926 || ringPercent < 0.2);
                float4 col = 0;
                float3 c = float3(frac(ringNum / 9), .97, 1);
                col.rgb = AudioLinkHSVtoRGB(c);
                col = (isRing1Or0 || ringMasked) ? 0 : col;

                //AudioLinkHSVtoRGB
                // sample the texture
                // fixed4 col = .5 + tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}