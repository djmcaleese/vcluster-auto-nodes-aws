locals {
  control_plane_vpc_peering_enabled     = nonsensitive(try(tobool(var.vcluster.properties["vcluster.com/control-plane-vpc-peering"]), false))
  control_plane_vpc_id                  = nonsensitive(try(var.vcluster.properties["vcluster.com/control-plane-vpc-id"], ""))
  control_plane_vpc_peering_dns_enabled = nonsensitive(try(tobool(var.vcluster.properties["vcluster.com/control-plane-vpc-peering-dns"]), true))

  auto_nodes_private_route_table_ids = module.vpc[local.region].private_route_table_ids
}

data "aws_vpc" "control_plane" {
  count = local.control_plane_vpc_peering_enabled ? 1 : 0
  id    = local.control_plane_vpc_id
}

data "aws_route_tables" "control_plane" {
  count  = local.control_plane_vpc_peering_enabled ? 1 : 0
  vpc_id = data.aws_vpc.control_plane[0].id
}

resource "aws_vpc_peering_connection" "control_plane" {
  count       = local.control_plane_vpc_peering_enabled ? 1 : 0
  vpc_id      = module.vpc[local.region].vpc_id
  peer_vpc_id = data.aws_vpc.control_plane[0].id
  auto_accept = true

  requester {
    allow_remote_vpc_dns_resolution = local.control_plane_vpc_peering_dns_enabled
  }

  accepter {
    allow_remote_vpc_dns_resolution = local.control_plane_vpc_peering_dns_enabled
  }

  tags = merge(
    local.cluster_tag,
    {
      Name = "auto-nodes-to-control-plane-peering-${local.vcluster_name}"
    }
  )
}

resource "aws_route" "auto_nodes_to_control_plane" {
  for_each = local.control_plane_vpc_peering_enabled ? { for idx, id in local.auto_nodes_private_route_table_ids : tostring(idx) => id } : {}

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.control_plane[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane[0].id
}

resource "aws_route" "control_plane_to_auto_nodes" {
  for_each = local.control_plane_vpc_peering_enabled ? { for idx, id in data.aws_route_tables.control_plane[0].ids : tostring(idx) => id } : {}

  route_table_id            = each.value
  destination_cidr_block    = local.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.control_plane[0].id
}
