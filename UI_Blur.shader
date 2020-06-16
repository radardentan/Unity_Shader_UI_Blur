Shader "Custom/Blur"
{
    Properties
    {
        [PreRenderData]_MainTex("Texture", 2D) = "white" {}
        _Blur("Blur", Float) = 10
        _Color("Color", Color) = (1, 1, 1, 1)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
    }
        SubShader
        {

            Tags
            {   "Queue" = "Transparent" 
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"
                "PreviewType" = "Plane"
                "CanUseSpriteAtlas" = "True"
            }

              Stencil
            {
                Ref[_Stencil]
                Comp[_StencilComp]
                Pass[_StencilOp]
                ReadMask[_StencilReadMask]
                WriteMask[_StencilWriteMask]
            }

             Cull Off
             Lighting Off
             ZWrite Off
             ZTest[unity_GUIZTestMode]
             Blend SrcAlpha OneMinusSrcAlpha
             ColorMask[_ColorMask]

            GrabPass
            {
            }

            Pass
            {
                CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "UnityUI.cginc"

                #pragma multi_compile __ UNITY_UI_CLIP_RECT
                #pragma multi_compile __ UNITY_UI_ALPHACLIP

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    fixed4 color : COLOR;
                };

                struct v2f
                {
                    float4 grabPos : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float4 vertColor : COLOR;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.grabPos = ComputeGrabScreenPos(o.pos);
                    o.vertColor = v.color;
                    return o;
                }

                sampler2D _GrabTexture;
                fixed4 _GrabTexture_TexelSize;

                float _Blur;

                half4 frag(v2f i) : SV_Target
                {
                    float blur = _Blur;
                    blur = max(1, blur);

                    fixed4 col =(0,0,0,0);
                    float weight_total = 0;

                    [loop]
                    for (float x = -blur; x <= blur; x += 1)
                    {
                        float distance_normalized = abs(x / blur);
                        float weight = exp(-0.5 * pow(distance_normalized, 2) * 5.0);
                        weight_total += weight;
                        col += tex2Dproj(_GrabTexture, i.grabPos + float4(x * _GrabTexture_TexelSize.x, 0, 0, 0)) * weight;
                    }

                    col /= weight_total;
                    return col;
                }
                ENDCG
            }
            GrabPass
            {
            }

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
                    fixed4 color : COLOR;
                };

                struct v2f
                {
                    float4 grabPos : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float4 vertColor : COLOR;
                    float2 worldPos : TEXCOORD1;
                    float4 posb : TEXCOORD2;
                };
                sampler2D _MainTex;
                sampler2D _GrabTexture;
                fixed4 _GrabTexture_TexelSize;
                float4 _MainTex_ST;
                half4 _Color;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.grabPos = ComputeGrabScreenPos(o.pos);
                    o.worldPos = TRANSFORM_TEX(v.uv, _MainTex);
                    o.vertColor = v.color * _Color;
                    o.posb = ComputeScreenPos(o.pos);
                    return o;
                }


                float _Blur;
                

                half4 frag(v2f i) : SV_Target
                {
                    float blur = _Blur;
                    blur = max(1, blur);

                    fixed4 col = (0, 0, 0, 0);
                    float weight_total = 0;
                    half4 color = _Color;
                    half _Alpha;

                    [loop]
                    for (float y = -blur; y <= blur; y += 1)
                    {
                        float distance_normalized = abs(y / blur);
                        float weight = exp(-0.5 * pow(distance_normalized, 2) * 5.0);
                        weight_total += weight;
                        col += tex2Dproj(_GrabTexture, i.grabPos + float4(0, y * _GrabTexture_TexelSize.y, 0, 0)) * weight;
                    }

                    col /= weight_total;
                    col *= color;

                    #ifdef UNITY_UI_CLIP_RECT
                    col.a *= UnityGet2DClipping(i.worldPos.xy, _ClipRect);
                    #endif

                    #ifdef UNITY_UI_ALPHACLIP
                    clip(col.a - 0.001);
                    #endif

                    half4 mask = tex2D(_MainTex, i.worldPos);
                    col.a *= mask.a;

                    return col;
                }
                ENDCG
            }


        }
}
