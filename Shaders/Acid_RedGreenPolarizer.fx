#include "ReShadeUI.fxh"

uniform float Blue < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Adjust the blueness of the screen, which acts sorta like saturation";
> = 0.;

uniform float Strength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Adjust the strength of the effect.";
> = 1.;

#include "ReShade.fxh"

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float luminance = (col.r + col.g + col.b) / 3;
	float r = col.r * luminance;
    float g = col.g * (1. - luminance);
	float b = col.b * Blue * (1. - luminance);

	return float3(r, g, (g + b)/2);
}

float3 MyLerpPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float luminance = (col.r + col.g + col.b) / 3;
	float r = lerp(col.r, col.r * luminance, Strength);
    float g = lerp(col.g, col.g * (1. - luminance), Strength);
	float b = Blue * lerp(col.b, col.b * (1. - luminance), Strength);

	return float3(r, g, (g + b)/2);
}

technique RedGreenPolarizer
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyLerpPass;
	}
}
