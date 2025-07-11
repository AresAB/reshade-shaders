#include "ReShadeUI.fxh"

uniform float Curvature < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0; ui_max = 10;
    ui_tooltip = "Strength of the spherical warping effect";
> = 7;

uniform float V_Width < __UNIFORM_SLIDER_INT1
    ui_label = "Vignette Width";
    ui_min = 0; ui_max = 90;
    ui_tooltip = "Width of the gradient border (vignette)";
> = 30;

uniform float G_Strength < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0; ui_max = 1;
    ui_tooltip = "Strength of the green on the screen lines";
> = 0.3;

uniform float P_Strength < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0; ui_max = 1;
    ui_tooltip = "Strength of the pink on the screen lines";
> = 0.3;

#include "ReShade.fxh"

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float2 ssc = texcoord * 2. - 1;
    float2 offset = ssc.yx / Curvature; // Note that the offset is scaled by the reverse axis
    ssc += ssc * offset * offset;
    float2 new_coords = ssc * 0.5 + 0.5;

    float3 color = tex2D(ReShade::BackBuffer, new_coords);
    //if (new_coords.x < 0 || new_coords.x > 1 || new_coords.y < 0 || new_coords.y > 1) color *= 0; //vignette logic already does this

    float2 pure_vignette = V_Width / BUFFER_SCREEN_SIZE;
    float2 vignette = float2(0, 0);
    ssc = 1 - abs(ssc);
    // ----------------------------
    // Idk how to do smoothstep in ReShade, so this is my replica of it
    if (ssc.x > 0)
    {
        vignette.x = 1;
        if (ssc.x <= pure_vignette.x) vignette.x = ssc.x / pure_vignette.x;
    }
    if (ssc.y > 0)
    {
        vignette.y = 1;
        if (ssc.y <= pure_vignette.y) vignette.y = ssc.y / pure_vignette.y;
    }
    // ----------------------------
    vignette = saturate(vignette); // clamps between 0 - 1

    color.g *= (sin(texcoord.y * BUFFER_SCREEN_SIZE.y * 2) + 1) * G_Strength + 1;
    color.rb *= (cos(texcoord.y * BUFFER_SCREEN_SIZE.y * 2) + 1) * P_Strength + 1;

    return saturate(color) * vignette.x * vignette.y;
}

technique CRT
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = MyPass;
    }
}