#include "ReShadeUI.fxh"

//uniform float3 Color_Filter < __UNIFORM_COLOR_FLOAT3
	//ui_tooltip = "Multiply image with color.";
//> = float3(1., 1., 1.);

uniform int Num_Colors < __UNIFORM_SLIDER_INT1
	ui_label = "Number Of Colors";
	ui_min = 2; ui_max = 32;
	ui_tooltip = "Adjust number of colors in the image.";
> = 10;

uniform float Spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Dither Spread";
	ui_min = 0.; ui_max = 2.;
	ui_tooltip = "Adjust the spread of the dither pattern.";
> = 0.;

uniform float L_1 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Luminance";
	ui_tooltip = "Adjust luminance of first color.";
	ui_min = 0.; ui_max = 1.;
> = 0.5;

uniform float C_1 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Chroma";
	ui_tooltip = "Adjust chroma of first color.";
	ui_min = 0.; ui_max = 1.;
> = 0.15;

uniform float H_1 < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Hue";
	ui_tooltip = "Adjust hue of first color.";
	ui_min = 0.; ui_max = 360.;
> = 215.;

uniform float L_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Luminance Change";
	ui_tooltip = "Luminance difference between first color and final. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = 0.; ui_max = 1.;
> = 0.;

uniform float C_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Chroma Change";
	ui_tooltip = "Chroma difference between first color and final. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -1.; ui_max = 1.;
> = 0.;

uniform float H_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Hue Change";
	ui_tooltip = "Hue difference between first color and final. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -360.; ui_max = 360.;
> = 0.;

#include "ReShade.fxh"

float3 oklch_to_RGB(float3 LCH)
{
    // convert to oklab color space
    float L = LCH.x;
    float a = LCH.y * cos(LCH.z);
    float b = LCH.y * sin(LCH.z);

    // convert to lms color space
    float l = pow(L + a * 0.3963377774 + b * 0.2158037573, 3);
    float m = pow(L + a * -0.1055613458 + b * -0.0638541728, 3);
    float s = pow(L + a * -0.0894841775 + b * -1.2914855480, 3);

    float3 rgb;

    rgb.r = l * 4.0767416621 + m * -3.3077115913 + s * 0.2309699292;
    rgb.g = l * -1.2684380046 + m * 2.6097574011 + s * -0.3413193965;
    rgb.b = l * -0.0041960863 + m * -0.7034186147 + s * 1.7076147010;

    rgb = max(min(rgb, 1.), 0);

    return rgb;
}

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4x4 bayer = float4x4(
        float4(0, 8, 2, 10),
        float4(12, 4, 14, 6),
        float4(3, 11, 1, 9),
        float4(10, 6, 9, 5)
    );

    float dither_noise = (bayer[int(texcoord.x * BUFFER_SCREEN_SIZE.x) % 4][int(texcoord.y * BUFFER_SCREEN_SIZE.y) % 4] / 16.) - 0.5;

	// we can effectively use the grayscaled color as uv's for the new pallete
	float uv = dot(float3(0.2989, 0.589, 0.114), tex2D(ReShade::BackBuffer, texcoord).rgb);
	uv += (dither_noise * Spread);
	uv = floor(uv * (Num_Colors - 1.) + 0.5) / (Num_Colors - 1.);

	float3 oklch;
	oklch.x = L_1 + (L_spread * uv);
	oklch.y = C_1 + (C_spread * uv);
	oklch.z = H_1 + (H_spread * uv);

    oklch.x = max(min(oklch.x, 1.), 0);
    oklch.y = max(min(oklch.y, 1.), 0);
    oklch.z = (oklch.z + 360) % 360;
    oklch.z *= 3.14 / 180.; // convert from degrees to rads

	return oklch_to_RGB(oklch);
}

technique PalleteSwapper
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}