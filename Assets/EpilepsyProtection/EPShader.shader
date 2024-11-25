Shader "EP/EP"
{
    Properties
    {
        _Threshold ("Threshold", Range(0.01, 1.0)) = 0.0
        _Softness ("Softness", Range(0.05, 1.0)) = 1.0
        [Toggle]
        _Blackout ("Blackout", Float) = 0
        [Toggle]
        _ClampHDR ("Clamp HDR", Float) = 0
        _NightMode ("Night Mode", Range(0.025, 1.0)) = 1.0
        _HideAfterDistance ("Hide After Distance", Float) = 0.25
    }

    SubShader
    {
        Tags { "Queue" = "Overlay+20000" "IgnoreProjector"="True" }
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
            float _Threshold;
            float _Softness;
            float _Blackout;
            float _ClampHDR;
            float _NightMode;
            float _HideAfterDistance;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            float luminance(float3 rgb)
            {
                return dot(saturate(rgb), float3(0.2126, 0.7152, 0.0722));
            }

            v2f vert(appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 col = tex2Dproj(_BackgroundTexture, i.grabPos);
                //float4 original = col;

                if (_ClampHDR == 1) {
                    col = saturate(col);
                }

                float lumMin = _Threshold;
                float lumMax = _Threshold + ((1.0 - _Threshold) * _Softness);
                float lum = luminance(col.rgb);
                lum = 1 - pow((1 - lum), 2);
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

                float distance = length(_WorldSpaceCameraPos - i.worldPos);
                float distanceFade = distance;
                if (distance > _HideAfterDistance) {
                    discard;
                }

                return col;
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}