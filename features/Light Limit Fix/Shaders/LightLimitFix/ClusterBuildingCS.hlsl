#include "Common.hlsli"

//reference
//https://github.com/Angelo1211/HybridRenderingEngine/

RWStructuredBuffer<ClusterAABB> clusters : register(u0);

float3 IntersectionZPlane(float3 B, float z_dist)
{
	//Because this is a Z based normal this is fixed
	float3 normal = float3(0.0, 0.0, -1.0);
	float3 d = B;
	//Computing the intersection length for the line and the plane
	float t = z_dist / d.z;  //dot(normal, d);

	//Computing the actual xyz position of the point along the line
	float3 result = t * d;

	return result;
}

[numthreads(1, 1, 1)] void main(uint3 groupId
								: SV_GroupID,
								uint3 dispatchThreadId
								: SV_DispatchThreadID,
								uint3 groupThreadId
								: SV_GroupThreadID,
								uint groupIndex
								: SV_GroupIndex) {
	uint clusterIndex = groupId.x +
	                    groupId.y * CLUSTER_BUILDING_DISPATCH_SIZE_X +
	                    groupId.z * (CLUSTER_BUILDING_DISPATCH_SIZE_X * CLUSTER_BUILDING_DISPATCH_SIZE_Y);

	float2 clusterSize = rcp(float2(CLUSTER_BUILDING_DISPATCH_SIZE_X, CLUSTER_BUILDING_DISPATCH_SIZE_Y));

	float3 maxPointVS = GetPositionVS((groupId.xy + 1) * clusterSize, 1.0f);
	float3 minPointVS = GetPositionVS(groupId.xy * clusterSize, 1.0f);

	float clusterNear = CameraNear * pow(CameraFar / CameraNear, groupId.z / float(CLUSTER_BUILDING_DISPATCH_SIZE_Z));
	float clusterFar = CameraNear * pow(CameraFar / CameraNear, (groupId.z + 1) / float(CLUSTER_BUILDING_DISPATCH_SIZE_Z));

	float3 minPointNear = IntersectionZPlane(minPointVS, clusterNear);
	float3 minPointFar = IntersectionZPlane(minPointVS, clusterFar);
	float3 maxPointNear = IntersectionZPlane(maxPointVS, clusterNear);
	float3 maxPointFar = IntersectionZPlane(maxPointVS, clusterFar);

	float3 minPointAABB = min(min(minPointNear, minPointFar), min(maxPointNear, maxPointFar));
	float3 maxPointAABB = max(max(minPointNear, minPointFar), max(maxPointNear, maxPointFar));

	clusters[clusterIndex].minPoint = float4(minPointAABB, 0.0);
	clusters[clusterIndex].maxPoint = float4(maxPointAABB, 0.0);
}