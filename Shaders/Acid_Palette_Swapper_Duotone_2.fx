#include "ReShadeUI.fxh"

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

uniform float Divider < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Color Pallete Divider";
	ui_min = 0.; ui_max = 1.;
	ui_tooltip = "Adjust when the color palletes switch.";
> = 0.5;

uniform float3 I_col_1 < __UNIFORM_COLOR_FLOAT3
	ui_label = "Initial Color 1";
	ui_tooltip = "Initial color from which the first color pallete is derived.";
> = float3(0.5, 0.5, 0.5);

uniform float L_1_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Luminance Change 1";
	ui_tooltip = "Luminance difference between first color and final in first color palette. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -1.; ui_max = 1.;
> = 0.;

uniform float C_1_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Chroma Change 1";
	ui_tooltip = "Chroma difference between first color and final in first color palette. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -1.; ui_max = 1.;
> = 0.;

uniform float H_1_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Hue Change 1";
	ui_tooltip = "Hue difference between first color and final in first color palette. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -360.; ui_max = 360.;
> = 0.;

uniform float3 I_col_2 < __UNIFORM_COLOR_FLOAT3
	ui_label = "Initial Color 2";
	ui_tooltip = "Initial color from which the second color pallete is derived.";
> = float3(0.5, 0.5, 0.5);

uniform float L_2_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Luminance Change 2";
	ui_tooltip = "Luminance difference between first color and final in second color palette. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -1.; ui_max = 1.;
> = 0.;

uniform float C_2_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Chroma Change 2";
	ui_tooltip = "Chroma difference between first color and final in second color palette. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -1.; ui_max = 1.;
> = 0.;

uniform float H_2_spread < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Hue Change 2";
	ui_tooltip = "Hue difference between first color and final in second color palette. NOTE: harmonic color palletes generally have 1 of the change sliders remain at 0.";
	ui_min = -360.; ui_max = 360.;
> = 0.;

uniform float Lerp_val < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Mix Strength";
	ui_tooltip = "Interpolation value between original color and newly generated colors, with 1 being only new colors and 0 being only original colors";
> = 1.;

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

float3 RGB_to_oklch(float3 rgb)
{
    float l = 0.4122214708 * rgb.r + 0.5363325363 * rgb.g + 0.0514459929 * rgb.b;
    float m = 0.2119034982 * rgb.r + 0.6806995451 * rgb.g + 0.1073969566 * rgb.b;
    float s = 0.0883024619 * rgb.r + 0.2817188376 * rgb.g + 0.6299787005 * rgb.b;

    l = pow(l, 0.33);
    m = pow(m, 0.33);
    s = pow(s, 0.33);

    float L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    float a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    float b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;

    float C = pow(a * a + b * b, 0.5);
    float h = atan2(b, a);

    return float3(L, C, h);
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

	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// we can effectively use the grayscaled color as uv's for the new pallete
	float uv = dot(float3(0.2989, 0.589, 0.114), col);
	uv += (dither_noise * Spread);
	uv = floor(uv * (Num_Colors - 1.) + 0.5) / (Num_Colors - 1.);

	float divider = floor(Divider * Num_Colors) / Num_Colors;
	float is_pal_1 = floor(uv + divider);

	float3 lch_1 = RGB_to_oklch(I_col_1);
    lch_1.z *= 180. / 3.14;
	float3 lch_2 = RGB_to_oklch(I_col_2);
    lch_2.z *= 180. / 3.14;

	float3 oklch;
	oklch.x = (lch_1.x + (L_1_spread * uv / divider)) * is_pal_1 + (lch_2.x + (L_2_spread * uv / (1. - divider))) * (1 - is_pal_1);
	oklch.y = (lch_1.y + (C_1_spread * uv / divider)) * is_pal_1 + (lch_2.y + (C_2_spread * uv / (1. - divider))) * (1 - is_pal_1);
	oklch.z = (lch_1.z + (H_1_spread * uv / divider)) * is_pal_1 + (lch_2.z + (H_2_spread * uv / (1. - divider))) * (1 - is_pal_1);

	/*float3 lch_spread_1 = float3(L_1_spread, C_1_spread, H_1_spread) * uv;
	float3 lch_spread_2 = float3(L_2_spread, C_2_spread, H_2_spread) * uv;

	float3 oklch = (lch_1 + lch_spread_1) * is_pal_1 + (lch_2 + lch_spread_2) * (1 - is_pal_1);
	*/

    oklch.x = max(min(oklch.x, 1.), 0);
    oklch.y = max(min(oklch.y, 1.), 0);
    oklch.z = (oklch.z + 360) % 360;
    oklch.z *= 3.14 / 180.; // convert from degrees to rads

	return lerp(col, oklch_to_RGB(oklch), Lerp_val);
}

technique PaletteSwapperDuoToneDeluxe
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}