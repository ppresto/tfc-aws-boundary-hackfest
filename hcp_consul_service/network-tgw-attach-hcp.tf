# HVN belongs to an AWS organization managed by HashiCorp, first define an AWS resource share
# that allows the two organizations to share resources.
resource "aws_ram_resource_share" "hcpc" {
  name                      = "hcpc-${var.region}-share"
  allow_external_principals = true
}
resource "aws_ram_principal_association" "example" {
  resource_share_arn = aws_ram_resource_share.hcpc.arn
  principal          = hcp_hvn.example_hvn.provider_account_id
}

resource "aws_ram_resource_association" "example" {
  resource_share_arn = aws_ram_resource_share.hcpc.arn
  resource_arn       = module.tgw.ec2_transit_gateway_arn
}

# The aws tgw module is configured to auto accept attachments so just create the attachment.
resource "hcp_aws_transit_gateway_attachment" "example" {
  depends_on = [
    aws_ram_principal_association.example,
    aws_ram_resource_association.example,
  ]

  hvn_id                        = hcp_consul_cluster.example_hcp.hvn_id
  transit_gateway_attachment_id = "hcpc-tgw-${var.region}-attachment"
  transit_gateway_id            = module.tgw.ec2_transit_gateway_id
  resource_share_arn            = aws_ram_resource_share.hcpc.arn
}

#Finally define the HCP Route to the VPC CIDR
resource "hcp_hvn_route" "route" {
  for_each         = toset(var.private_cidr_blocks)
  hvn_link         = hcp_hvn.example_hvn.self_link
  hvn_route_id     = "hvn-to-tgw-${var.region}-attachment"
  destination_cidr = each.key
  target_link      = hcp_aws_transit_gateway_attachment.example.self_link
}