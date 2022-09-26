# Define required Routes for Layer 3 connectivity from within the VPC to HCP.
#
# Note:  The "for_each" value depends on resource attributes that cannot be determined until apply,
#        so Terraform cannot predict how many instances will be created.
#        To work around this we put these routes into a new TFCB workspace.

# VPC private subnet route to HCP CIDR Block
resource "aws_route" "private" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = var.hvn_cidr_block
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}
# VPC public subnet route to HCP CIDR Block
resource "aws_route" "public" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = var.hvn_cidr_block
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}

# Shared VPC private network routes to other VPC's
resource "aws_route" "allVpcPublic" {
  for_each               = toset(var.private_cidr_blocks)
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = each.key
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}
resource "aws_route" "allVpcPrivate" {
  for_each               = toset(var.private_cidr_blocks)
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = each.key
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}
#resource "aws_route" "allVpcPublic2" {
#  route_table_id         = module.vpc.public_route_table_ids[0]
#  destination_cidr_block = "10.0.0.0/10"
#  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
#}