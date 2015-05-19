//// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
//// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
//// PARTICULAR PURPOSE.
////
//// Copyright (c) Microsoft Corporation. All rights reserved
////----------------------------------------------------------------------

Texture2D Texture : register(t0);
SamplerState Sampler : register(s0);

cbuffer ConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
	float4 marbleTrail[5];
    float3 marblePosition;
    float marbleRadius;
    float lightStrength;
};

struct sPSInput
{
    float4 pos : SV_POSITION;
    float3 norm : NORMAL;
    float2 tex : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
};

float4 main(sPSInput input) : SV_TARGET
{
	float3 lightDirection = float3(0, 0, -1);
	float3 ambientColor = float3(0.0, 0.1, 0.24);
	float3 lightColor = 1 - ambientColor;
	float spotRadius = 50;

	// Basic ambient (Ka) and diffuse (Kd) lighting from above.
	float3 N = normalize(input.norm);
	float NdotL = dot(N, lightDirection);
	float Ka = saturate(NdotL + 1);
	float Kd = saturate(NdotL);

	// Spotlight.
	float3 vec = input.worldPos - marblePosition;
	float dist2D = sqrt(dot(vec.xy, vec.xy));
	Kd = Kd * saturate(spotRadius / dist2D);
	
	//UNCOMMENT FOR SHADOWING
	// Shadowing from ball.
	//if (input.worldPos.z > marblePosition.z)
	//	Kd = Kd * saturate(dist2D / (marbleRadius * 1.5));

	// Trail from the ball
	float4 trail = float4(0.0f, 0.0f, 0.0f, 0.0f);
		if (input.worldPos.z > marblePosition.z && dist2D > marbleRadius)
		{
			for (int index = 0; index < 5; index++)
			{
				float2 vec2 = input.worldPos.xy - marbleTrail[index].xy;
					float distsqr2D = dot(vec2, vec2);
				if (distsqr2D < 3.0f)
					trail.xy = 0.5f / (6 - index);
			}
		}

			// Diffuse reflection of light off ball.
			float dist3D = sqrt(dot(vec, vec));
			float3 V = normalize(vec);
			Kd += saturate(dot(-V, N)) * saturate(dot(V, lightDirection))
				* saturate(marbleRadius / dist3D);

			// Final composite.
			float4 diffuseTexture = Texture.Sample(Sampler, input.tex);
			float3 color = diffuseTexture.rgb * ((ambientColor * Ka) + (lightColor * Kd));
			return float4(color * lightStrength, diffuseTexture.a) + trail;
		
}