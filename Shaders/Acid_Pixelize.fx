#include "ReShadeUI.fxh"

uniform bool Is_Grayscale <
	ui_label = "Grayscale?";
	ui_tooltip = "Whether or not to make the image grayscale, triples # of colors if not.";
> = true;

uniform float Downscale < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Downscale Factor";
	ui_min = 1.; ui_max = 8.;
	ui_tooltip = "Adjust the factor in which the image is downscaled.";
> = 1.;

uniform int Num_Colors < __UNIFORM_SLIDER_INT1
	ui_label = "Number Of Colors";
	ui_min = 2; ui_max = 16;
	ui_tooltip = "Adjust number of colors PER COLOR CHANNEL in the image.";
> = 32;

uniform float Spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Dither Spread";
	ui_min = 0.; ui_max = 4.;
	ui_tooltip = "Adjust the spread of the dither pattern.";
> = 0.;

#include "ReShade.fxh"

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4x4 bayer = float4x4(
        float4(0, 8, 2, 10),
        float4(12, 4, 14, 6),
        float4(3, 11, 1, 9),
        float4(10, 6, 9, 5)
    );

    float2 quantized_coord = floor(texcoord / Downscale * BUFFER_SCREEN_SIZE) * Downscale / BUFFER_SCREEN_SIZE;

    float dither_noise = (bayer[int(texcoord.x * BUFFER_SCREEN_SIZE.x) % 4][int(texcoord.y * BUFFER_SCREEN_SIZE.y) % 4] / 16.) - 0.5;

	float3 col = tex2D(ReShade::BackBuffer, quantized_coord).rgb;

	if (Is_Grayscale){
    	float gray_scale = dot(float3(0.2989, 0.589, 0.114), col);
    	col = float3(gray_scale, gray_scale, gray_scale);
	}

	col += dither_noise * Spread;
    col = floor(col * (Num_Colors - 1.) + 0.5) / (Num_Colors - 1.);

	return col;
}

technique Pixelize
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}