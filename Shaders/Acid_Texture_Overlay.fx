#include "ReShadeUI.fxh"

uniform float Lerp_val1 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Mix Strength";
	ui_tooltip = "Interpolation value between texture and original image.";
> = 0.;

uniform float Lerp_val2 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Mix Strength (POST OVERLAY)";
	ui_tooltip = "Interpolation value between texture once overlayed and original image.";
> = 0.;

uniform int Is_add < __UNIFORM_SLIDER_INT1
	ui_label = "Add?";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Overlay image via addition. DOES NOT WORK WELL WITH OTHER OVERLAY METHODS";
> = 0;

uniform int Is_sub < __UNIFORM_SLIDER_INT1
	ui_label = "Subtract?";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Overlay image via subtraction. DOES NOT WORK WELL WITH OTHER OVERLAY METHODS";
> = 0;

uniform int Is_mul < __UNIFORM_SLIDER_INT1
	ui_label = "Multiply?";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Overlay image via multiplication. DOES NOT WORK WELL WITH OTHER OVERLAY METHODS";
> = 0;

uniform int Is_div < __UNIFORM_SLIDER_INT1
	ui_label = "Divide?";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Overlay image via division. DOES NOT WORK WELL WITH OTHER OVERLAY METHODS";
> = 0;

#include "ReShade.fxh"

#ifndef HATCH_SOURCE
#define HATCH_SOURCE "Acid_crosshatch.jpg"
#endif

texture New_Tex <
    source = HATCH_SOURCE;
> {
    Format = RGBA8;
    Width  = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
};

sampler New_Sampler
{
    Texture  = New_Tex;
    AddressU = REPEAT;
    AddressV = REPEAT;
};

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    //float3 tex_col = tex2Dfetch(New_Sampler, int4(round(((texcoord.x * HATCH_SIZE_X + HATCH_SIZE_X) % (HATCH_SIZE_X - .5))), round((texcoord.y * HATCH_SIZE_Y + HATCH_SIZE_Y) % (HATCH_SIZE_Y - .5)), 0, 0)).xyz;
    float3 tex_col = tex2D(New_Sampler, texcoord);
    float3 og_col = tex2D(ReShade::BackBuffer, texcoord);
    float3 col = og_col;

    col = (col * (1 - Is_add)) + ((col + tex_col) * Is_add);
    col = (col * (1 - Is_sub)) + ((col - tex_col) * Is_sub);
    col = (col * (1 - Is_mul)) + ((col * tex_col) * Is_mul);
    col = (col * (1 - Is_div)) + ((col / (tex_col + 0.001)) * Is_div);

	return lerp(lerp(col, tex_col, Lerp_val1), og_col, Lerp_val2);
}

technique Texture_Overlay
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}