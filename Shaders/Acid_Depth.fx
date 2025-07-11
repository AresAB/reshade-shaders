#include "ReShadeUI.fxh"

uniform bool Is_Colored <
	ui_label = "Add Color?";
	ui_tooltip = "Whether or not you want to blend in the original color.";
> = false;

uniform float Near < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Range Beginning";
	ui_min = 0.1; ui_max = 2.;
	ui_tooltip = "Tune the depth's linearization by setting the closeness of the scene.";
> = 0.1;

uniform float Range < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Size of Range";
	ui_min = 0.; ui_max = 2.;
	ui_tooltip = "Tune the depth's linearization by setting the size of the depth range.";
> = 2.;

uniform float3 Color_Filter < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "Multiply image with color.";
> = float3(1., 1., 1.);

#include "ReShade.fxh"

texture2D texDepthBuffer : DEPTH;

sampler2D samplerDepth
{
	Texture = texDepthBuffer;
};

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 col = tex2D(ReShade::BackBuffer, texcoord);
    float depth = tex2D(samplerDepth, float2(texcoord.x, 1. - texcoord.y)).r;
    
    float far = Near + Range;

    depth = depth * 2. - 1.;
    depth = (2. * Near * far) / (far + Near - depth * Range);

    col.rgb = (col.rgb * Is_Colored) + depth.rrr * Color_Filter;

	return col;
}

technique Depth_Map
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}