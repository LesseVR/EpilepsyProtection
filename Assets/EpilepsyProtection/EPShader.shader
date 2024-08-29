Shader "EP/EP"
{
    Properties
    {
        _MinThreshold ("Min Threshold", Range(0.05, 1.0)) = 0.0
        _MaxThreshold ("Max Threshold", Range(0.1, 1.0)) = 1.0
        [Toggle]
        _Blackout ("Blackout", Float) = 0
        _NightMode ("Night Mode", Range(0.1, 1.0)) = 1.0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" }
        ZTest Always
        ZWrite Off
        LOD 100

        GrabPass
        {
            "_BackgroundTexture"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _BackgroundTexture;
            float _MinThreshold;
            float _MaxThreshold;
            float _Blackout;
            float _NightMode;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD0;
            };

            float luminance(float3 rgb)
            {
                return dot(rgb, float3(0.2126, 0.7152, 0.0722));
            }


            v2f vert(appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 col = tex2Dproj(_BackgroundTexture, i.grabPos);

                float lumMin = min(_MinThreshold, _MaxThreshold);
                float lumMax = max(_MinThreshold, _MaxThreshold);
                float lum = luminance(col.rgb);
                float range = lumMax - lumMin;

                if (lum > lumMin) {
                    float ratio = saturate((lum - lumMin) / range);

                    float3 dimmed = col.rgb;
                    dimmed *= lumMin / lum;
                    col.rgb = lerp(col.rgb, dimmed, (ratio / ratio));

                    if (_Blackout == 1) {
                        col.rgb *= 1 - ratio;
                    }
                }

                col *= _NightMode;
                return col;
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}