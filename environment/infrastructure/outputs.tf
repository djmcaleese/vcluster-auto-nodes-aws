output "private_subnet_ids" {
  description = "A list of private subnet ids"
  value       = module.vpc[local.region].private_subnets
}

output "public_subnet_ids" {
  description = "A list of public subnet ids"
  value       = module.vpc[local.region].public_subnets
}

output "availability_zones" {
  description = "A list of availability zones"
  value       = data.aws_availability_zones.available.names
}

output "security_group_id" {
  description = "Security group id to attach to worker nodes"
  value       = aws_security_group.workers.id
}

output "instance_profile_name" {
  description = "Instance profile name to attach to worker nodes"
  value       = aws_iam_instance_profile.vcluster_node.name
}

output "cluster_tag" {
  description = "Global tag of all provisioned AWS resources"
  value       = local.cluster_tag
}

output "control_plane_vpc_peering_connection_id" {
  description = "VPC peering connection ID to the vCluster control plane VPC (if enabled)"
  value       = try(aws_vpc_peering_connection.control_plane[0].id, null)
}
