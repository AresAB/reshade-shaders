#include "ReShadeUI.fxh"

uniform float Curvature < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.01; ui_max = 10;
    ui_tooltip = "Strength of the spherical warping effect";
> = 3;

uniform float V_Width < __UNIFORM_SLIDER_INT1
    ui_label = "Vignette Width";
    ui_min = 0; ui_max = 90;
    ui_tooltip = "Width of the gradient border (vignette)";
> = 30;

#include "ReShade.fxh"

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float2 eq = (2 * texcoord.yx - 1) * (2 * texcoord.yx - 1) / (Curvature * Curvature);
    float2 new_coords = (-0.5 * eq - texcoord) / (-1 * eq - 1);

    float3 color = tex2D(ReShade::BackBuffer, new_coords);
    return color;
}

technique Reverse_CRT
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = MyPass;
    }
}