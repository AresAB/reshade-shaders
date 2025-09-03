#include "ReShadeUI.fxh"

uniform float Exposure < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.; ui_max = 5.;
	ui_tooltip = "Adjust exposure of image.";
> = 1.;

uniform float Temperature < __UNIFORM_SLIDER_FLOAT1
	ui_min = -2.; ui_max = 2.;
	ui_tooltip = "Adjust exposure of image.";
> = 0.;

uniform float Tint < __UNIFORM_SLIDER_FLOAT1
	ui_min = -2.; ui_max = 2.;
	ui_tooltip = "Adjust exposure of image.";
> = 0.;

uniform float Contrast < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.; ui_max = 5.;
	ui_tooltip = "Adjust contrast of image.";
> = 1.;

uniform float Brightness < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.; ui_max = 1.;
	ui_tooltip = "Adjust brightness of image.";
> = 0.;

uniform float3 Color_Filter < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "Multiply image with color.";
> = float3(1., 1., 1.);

uniform float Saturation < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.; ui_max = 10.;
	ui_tooltip = "Adjust saturation of image.";
> = 1.;

uniform bool Is_ACES <
    ui_label = "Narkowicz ACES Tone Map?";
    ui_tooltip = "Maps HDR color to the 0-1 color range, lighter than Tumblin Rushmeier. NOTE: Only do one tone map at a time.";
> = false;

uniform bool Is_Tumblin <
    ui_label = "Tumblin Rushmeier Tone Map?";
    ui_tooltip = "Maps HDR color to the 0-1 color range, darker than ACES. NOTE: Only do one tone map at a time.";
> = false;

uniform float Gamma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.; ui_max = 10.;
	ui_tooltip = "Adjust gamma of image.";
> = 1.;


float3 Narkowicz_ACES(float3 hdr)
{
    return saturate((hdr * (2.51 * hdr + 0.03)) / (hdr * (2.43 * hdr + 0.59) + 0.14));
}

float3 Tumblin_Rushmeier(float3 hdr, float3 avg)
{
    float Lin = dot(float3(0.2989, 0.589, 0.114), hdr);
    float Lavg = dot(float3(0.2989, 0.589, 0.114), avg);
    float _Ldmax = 1.; //luminance max (usually just 1)
    float _Cmax = 1000.; //contrast max //1000 //35 num for CRT

    float logLrw = log10(Lavg) + 0.84;
    float alphaRw = 0.4 * logLrw + 2.92;
    float betaRw = -0.4 * logLrw * logLrw - 2.584 * logLrw + 2.0208;
    float Lwd = _Ldmax / sqrt(_Cmax);
    float logLd = log10(Lwd) + 0.84;
    float alphaD = 0.4 * logLd + 2.92;
    float betaD = -0.4 * logLd * logLd - 2.584 * logLd + 2.0208;
    float Lout = pow(Lin, alphaRw / alphaD) / _Ldmax * pow(10., (betaRw / betaD) / alphaD) - (1.0 / _Cmax);

    return saturate(hdr / Lin * Lout);
}

float3 WhiteBalance(float3 col, float temp, float tint)
{
    float t1 = temp * 10. / 6.;
    float t2 = tint * 10. / 6.;

    float x = 0.31271 - t1 * (t1 < 0 ? 0.1 : 0.05);
    float standIlluminantY = 2.87 * x - 3 * x * x - 0.27509507;
    float y = standIlluminantY + t2 * 0.05;

    float3 w1 = float3(0.949237, 1.03542, 1.08728);

    float Y = 1;
    float X = Y * x / y;
    float Z = Y * (1 - x - y) / y;
    float L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
    float M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
    float S = 0.003 * X + 0.0136 * Y + 0.9834 * Z;
    float3 w2 = float3(L, M, S);

    float3 balance = float3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);

    float3x3 LIN_2_LMS_MAT = float3x3(
        float3(3.90405e-1, 5.49941e-1, 8.92632e-3),
        float3(7.08416e-2, 9.63172e-1, 1.35775e-3),
        float3(2.31082e-2, 1.28021e-1, 9.36245e-1)
    );

    float3x3 LMS_2_LIN_MAT = float3x3(
        float3(2.85847e+0, -1.62879e+0, -2.4891e-2),
        float3(-2.10182e-1, 1.1582e+0, 3.24281e-4),
        float3(-4.1812e-2, -1.18169e-1, 1.06867e+0)
    );

    float3 lms = mul(LIN_2_LMS_MAT, col);
    lms *= balance;
    return mul(LMS_2_LIN_MAT, lms);
}

#include "ReShade.fxh"

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

    col = max(col * Exposure, 0.);

    col = WhiteBalance(col, Temperature, Tint);

    col = max(Contrast * (col - 0.5) + 0.5 + Brightness, 0.);

    col = max(col * Color_Filter, 0.);

    float gray_scale = dot(float3(0.2989, 0.589, 0.114), col);
    col = lerp(float3(gray_scale, gray_scale, gray_scale), col, Saturation);

    // tone mapping
    col = Narkowicz_ACES(col) * Is_ACES + col * (1 - Is_ACES);
    col = Tumblin_Rushmeier(col, tex2Dlod(ReShade::BackBuffer, float4(texcoord.x, texcoord.y, 0., 10.)).rgb) * Is_Tumblin + min(col, 1.) * (1 - Is_Tumblin);

    col.r = pow(col.r, Gamma);
    col.g = pow(col.g, Gamma);
    col.b = pow(col.b, Gamma);

	return col;
}

technique ColorToolkit
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}