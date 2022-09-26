output "provider_account_id" {
  value = hcp_hvn.example_hvn.provider_account_id
}
output "hvn_cidr_block" {
  value = var.hvn_cidr_block
}
output "hvn_id" {
  value = var.hvn_id
}
output "hvn_self_link" {
  value = hcp_hvn.example_hvn.self_link
}
output "hcpc_versions" {
  value = data.hcp_consul_versions.default
}
output "consul_public_endpoint_url" {
  value = hcp_consul_cluster.example_hcp.consul_public_endpoint_url
}
output "consul_private_endpoint_url" {
  value = hcp_consul_cluster.example_hcp.consul_private_endpoint_url
}

output "datacenter" {
  value = hcp_consul_cluster.example_hcp.datacenter
}

output "organization_id" {
  value = hcp_consul_cluster.example_hcp.organization_id
}

output "project_id" {
  value = hcp_consul_cluster.example_hcp.project_id
}

output "scale" {
  value = hcp_consul_cluster.example_hcp.scale
}

output "consul_version" {
  value = hcp_consul_cluster.example_hcp.consul_version
}

output "consul_self_link" {
  value = hcp_consul_cluster.example_hcp.self_link
}

output "consul_root_token_secret_id" {
  value = nonsensitive(hcp_consul_cluster_root_token.init.secret_id)
}
output "consul_ca_file" {
  value = hcp_consul_cluster.example_hcp.consul_ca_file
}
output "consul_config_file" {
  value = hcp_consul_cluster.example_hcp.consul_config_file
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "vpc_cidr_block" {
  value = var.vpc_cidr_block
}
output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}
output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}
output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}
output "vpc_default_security_group_id" {
  value = module.vpc.default_security_group_id
}

#
### Transit Gateway
#

# aws_ec2_transit_gateway
output "ec2_transit_gateway_arn" {
  description = "EC2 Transit Gateway Amazon Resource Name (ARN)"
  value       = module.tgw.ec2_transit_gateway_arn
}

output "ec2_transit_gateway_association_default_route_table_id" {
  description = "Identifier of the default association route table"
  value       = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

output "ec2_transit_gateway_id" {
  description = "EC2 Transit Gateway identifier"
  value       = module.tgw.ec2_transit_gateway_id
}

output "ec2_transit_gateway_owner_id" {
  description = "Identifier of the AWS account that owns the EC2 Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_owner_id
}

output "ec2_transit_gateway_propagation_default_route_table_id" {
  description = "Identifier of the default propagation route table"
  value       = module.tgw.ec2_transit_gateway_propagation_default_route_table_id
}

output "ec2_transit_gateway_route_table_default_association_route_table" {
  description = "Boolean whether this is the default association route table for the EC2 Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_route_table_default_association_route_table
}

output "ec2_transit_gateway_route_table_default_propagation_route_table" {
  description = "Boolean whether this is the default propagation route table for the EC2 Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_route_table_default_propagation_route_table
}

# aws_ec2_transit_gateway_route_table
output "ec2_transit_gateway_route_table_id" {
  description = "EC2 Transit Gateway Route Table identifier"
  value       = module.tgw.ec2_transit_gateway_route_table_id
}

# aws_ec2_transit_gateway_route
output "ec2_transit_gateway_route_ids" {
  description = "List of EC2 Transit Gateway Route Table identifier combined with destination"
  value       = module.tgw.ec2_transit_gateway_route_ids
}

# aws_ec2_transit_gateway_vpc_attachment
output "ec2_transit_gateway_vpc_attachment_ids" {
  description = "List of EC2 Transit Gateway VPC Attachment identifiers"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment_ids
}

output "ec2_transit_gateway_vpc_attachment" {
  description = "Map of EC2 Transit Gateway VPC Attachment attributes"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment
}

# aws_ec2_transit_gateway_route_table_association
output "ec2_transit_gateway_route_table_association_ids" {
  description = "List of EC2 Transit Gateway Route Table Association identifiers"
  value       = module.tgw.ec2_transit_gateway_route_table_association_ids
}

output "ec2_transit_gateway_route_table_association" {
  description = "Map of EC2 Transit Gateway Route Table Association attributes"
  value       = module.tgw.ec2_transit_gateway_route_table_association
}

# aws_ec2_transit_gateway_route_table_propagation
output "ec2_transit_gateway_route_table_propagation_ids" {
  description = "List of EC2 Transit Gateway Route Table Propagation identifiers"
  value       = module.tgw.ec2_transit_gateway_route_table_propagation_ids
}

output "ec2_transit_gateway_route_table_propagation" {
  description = "Map of EC2 Transit Gateway Route Table Propagation attributes"
  value       = module.tgw.ec2_transit_gateway_route_table_propagation
}

# aws_ram_resource_share
output "ram_resource_share_id" {
  description = "The Amazon Resource Name (ARN) of the resource share"
  value       = module.tgw.ram_resource_share_id
}

# aws_ram_principal_association
output "ram_principal_association_id" {
  description = "The Amazon Resource Name (ARN) of the Resource Share and the principal, separated by a comma"
  value       = module.tgw.ram_principal_association_id
}

output "consul_server_sg_id" {
  value = aws_security_group.consul_server.id
}

output "bastion_ssh_sg_id" {
  value = aws_security_group.bastion.id
}

output "env" {
  value = var.env
}