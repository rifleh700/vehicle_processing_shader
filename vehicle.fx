//
// Default GTA:SA vehicle processing shader
// 
// Authors: Ren712, rifleh700
// 

#include "mta-helper.fx"

float4x4 gTransformTexture1 < string transformState="TEXTURE1"; >; 
int gStage1ColorOp < string stageState="1,COLOROP"; >;
float4 gTextureFactor < string renderState="TEXTUREFACTOR"; >;

sampler Sampler0 = sampler_state {
	Texture = (gTexture0);
};

sampler Sampler1 = sampler_state {
	Texture = (gTexture1);
};

struct VSInput {
	float3 Position : POSITION0;
	float3 Normal : NORMAL0;
	float4 Diffuse : COLOR0;
	float3 TexCoord : TEXCOORD0;
	float3 ReflTexCoord : TEXCOORD1;
};

struct PSInput {
	float4 Position : POSITION0;
	float4 Diffuse : COLOR0;
	float4 Specular : COLOR1;
	float3 TexCoord : TEXCOORD0;
	float3 ReflTexCoord : TEXCOORD1;
};

PSInput VertexShaderFunction(VSInput VS)
{
	PSInput PS = (PSInput)0;

	// Make sure normal is valid
	MTAFixUpNormal(VS.Normal);

	// Set information to do specular calculation
	float3 worldNormal = mul(VS.Normal, (float3x3)gWorld);
	
	// Calculate screen pos of vertex
	PS.Position = MTACalcScreenPosition(VS.Position);

	// Main tex coords
	PS.TexCoord = VS.TexCoord;
 
	// Env reflection tex coords
	if (gStage1ColorOp == 14) PS.ReflTexCoord = mul(float3(VS.ReflTexCoord.xy, 1), (float3x3)gTransformTexture1);

	// Spherical reflection tex coords
	float3 viewNormal = mul(worldNormal, (float3x3)gView);
	if (gStage1ColorOp == 25) PS.ReflTexCoord = mul(viewNormal.xyz, (float3x3)gTransformTexture1);

	// Calculate GTA lighting for Vehicles
	PS.Diffuse = MTACalcGTACompleteDiffuse(worldNormal, VS.Diffuse);

	// Apply vehicle specular
	PS.Specular = gMaterialSpecular * MTACalculateVehicleSpecular(worldNormal);

	return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0 {

	// Apply diffuse lighting
	float4 mainTexel = tex2D(Sampler0, PS.TexCoord.xy);
	float4 finalColor = mainTexel * PS.Diffuse;
	
	// Apply env reflection
	// BlendFactorAlpha = 14,
	if (gStage1ColorOp == 14) {
		float4 envTexel = tex2D(Sampler1, PS.ReflTexCoord.xy);
		finalColor.rgb = finalColor.rgb * (1 - gTextureFactor.a) + envTexel.rgb * gTextureFactor.a;
	}

	// Apply spherical reflection
	// MultiplyAdd = 25
	if (gStage1ColorOp == 25) {
		float4 sphTexel = tex2D(Sampler1, PS.ReflTexCoord.xy/PS.ReflTexCoord.z);
		finalColor.rgb += sphTexel.rgb * gTextureFactor.r;
	}

	// Apply specular
	finalColor.rgb += PS.Specular.rgb;

	return finalColor;
};

technique vehicle {
	pass P0 {	
		VertexShader = compile vs_2_0 VertexShaderFunction();
		PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}

technique fallback {
	pass P0 {
	}
}