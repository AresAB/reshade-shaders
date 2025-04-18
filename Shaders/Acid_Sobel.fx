#include "ReShadeUI.fxh"

uniform bool Is_Colored <
	ui_label = "Add Color?";
	ui_tooltip = "Whether or not you want to blend in the original color.";
> = false;

uniform bool Is_Inverted <
	ui_label = "Invert Edges?";
	ui_tooltip = "Makes edges black and non-edges white.";
> = false;

#include "ReShade.fxh"

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    int kernal = 3;
    float2 pix_size = 1 / BUFFER_SCREEN_SIZE;

    float3x3 edge_horiz = float3x3(
        float3(1, 0, -1),
        float3(2, 0, -2),
        float3(1, 0, -1)
    );
    float3x3 edge_vert = float3x3(
        float3(1, 2, 1),
        float3(0, 0, 0),
        float3(-1, -2, -1)
    );
    
    float sobel_x = 0;
    float sobel_y = 0;

    for (int row = 0; row < kernal; row++){
        for (int col = 0; col < kernal; col++){
            float2 pixcoord = texcoord + float2((row - 1) * pix_size.x, (col - 1) * pix_size.y);
            float pix_lum = dot(tex2D(ReShade::BackBuffer, pixcoord).rgb, float3(0.2989, 0.589, 0.114));

            sobel_x += edge_horiz[row][col] * pix_lum;
            sobel_y += edge_vert[row][col] * pix_lum;
        }
    }

    float sobel_mag = sqrt(sobel_x * sobel_x + sobel_y * sobel_y);

    if (Is_Inverted) sobel_mag = 1. - sobel_mag;
    float3 col = float3(sobel_mag, sobel_mag, sobel_mag);
    if (Is_Colored) {
        if (Is_Inverted) col *= tex2D(ReShade::BackBuffer, texcoord).rgb;
        else col += tex2D(ReShade::BackBuffer, texcoord).rgb;
    }

	return col;
}

technique Sobel_Edge_Detector
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}