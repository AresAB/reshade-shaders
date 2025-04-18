#include "ReShadeUI.fxh"

uniform bool Is_Colored <
	ui_label = "Add Color?";
	ui_tooltip = "Whether or not you want the base color to blend into the hatch crossing.";
> = false;

uniform int Layer_Count < __UNIFORM_SLIDER_INT1
	ui_label = "Cross Layer Count";
	ui_min = 2; ui_max = 16;
	ui_tooltip = "Adjust how many layers of cross hatch there are, effectively determining the number of colors.";
> = 4;

uniform float Hatch_Scale < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Hatch Line Scale";
	ui_min = 0.01; ui_max = 32.0;
	ui_tooltip = "Adjust the size of the hatch lines.";
> = 1.;

#include "ReShade.fxh"

#ifndef HATCH_SOURCE
#define HATCH_SOURCE "Acid_crosshatch.jpg"
#endif
#ifndef HATCH_SIZE
#define HATCH_SIZE 360
#endif
#ifndef TEXFORMAT
#define TEXFORMAT RGBA8
#endif

texture Hatch_Tex <
    source = HATCH_SOURCE;
> {
    Format = TEXFORMAT;
    Width  = HATCH_SIZE;
    Height = HATCH_SIZE;
};

sampler Hatch_Sampler
{
    Texture  = Hatch_Tex;
    AddressU = REPEAT;
    AddressV = REPEAT;
};

float2 rotate2d(float2 uv, float angle){
    float2x2 rotation = float2x2(cos(angle), -sin(angle),
						sin(angle), cos(angle));
    
    return 0.5 + mul((uv - 0.5), rotation);
}

float3 MyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float gray_scale = dot(float3(0.2989, 0.589, 0.114), col);

    int hatch_index = Layer_Count - floor(gray_scale * Layer_Count + 0.5);

	if (hatch_index <= 1) return float3(1., 1., 1.);
    else if (hatch_index == Layer_Count) return float3(0., 0., 0.);
	else{
		float3 result = 1.;

		[loop]
        for (int i = 0; i < hatch_index - 1; i++){
            float angle = (3.14 * i * 1.618) % 1;
            float2 offset = rotate2d(texcoord, angle * 3.14 * 2);
			// tex2Dfetch is used cause "gradient functions" can't be used in for loops, and turns out mipmap interpolation is a "gradient function"
            float3 hatch = tex2Dfetch(Hatch_Sampler, int4(round((Hatch_Scale * (offset.x * HATCH_SIZE + HATCH_SIZE)) % (HATCH_SIZE - .5)), round((Hatch_Scale * (offset.y * HATCH_SIZE + HATCH_SIZE)) % (HATCH_SIZE - .5)), 0, 0)).xyz;

            result *= hatch;
        }

		if (Is_Colored) result *= col;
		return result;
	}
}

technique CrossHatch
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MyPass;
	}
}
