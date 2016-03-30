#include "globals.hlsli"

RWTexture2D<float> tex : register(u0);


#define SIZEX 64
#define SIZEY 16
#define GROUPSIZE SIZEX*SIZEY
groupshared float accumulator[SIZEX* SIZEY];

[numthreads(SIZEX, SIZEY, 1)]
void main(
	uint3 groupId : SV_GroupID,
	uint3 groupThreadId : SV_GroupThreadID,
	uint3 dispatchThreadId : SV_DispatchThreadID, // 
	uint groupIndex : SV_GroupIndex)
{
	float2 dim = g_xWorld_ScreenWidthHeight / float2(16, 16);
	accumulator[groupIndex] = groupIndex > asuint(dim.x*dim.y) ? 0.0f : tex.Load(dispatchThreadId.xy); //bounds check
	GroupMemoryBarrierWithGroupSync();

	[unroll]
	for (uint iy = GROUPSIZE >> 1; iy > 0; iy = iy >> 1) {
		if (groupIndex < iy) {
			accumulator[groupIndex] = (accumulator[groupIndex] + accumulator[groupIndex + iy]) * .5;
		}
		GroupMemoryBarrierWithGroupSync();
	}
	if (groupIndex != 0) { return; }

	tex[uint2(0,0)] = accumulator[0];
}