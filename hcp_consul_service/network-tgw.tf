# https://registry.terraform.io/modules/terraform-aws-modules/transit-gateway/aws/latest
module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "2.5.0"

  name            = "${var.region}-vpcss-tgw"
  description     = "My TGW shared with several other AWS accounts"
  amazon_side_asn = 64532

  enable_auto_accept_shared_attachments = true # When "true" there is no need for RAM resources if using multiple AWS accounts

  vpc_attachments = {
    vpc = {
      vpc_id     = module.vpc.vpc_id          #data.aws_vpc.default.id
      subnet_ids = module.vpc.private_subnets #data.aws_subnet_ids.this.ids

      tgw_routes = [
        {
          destination_cidr_block = "10.0.0.0/8"
        },
        {
          blackhole              = true
          destination_cidr_block = "10.10.10.10/32"
        }
      ]
    },
  }

  ram_allow_external_principals = true
  #ram_principals                = [711129375688]
  tgw_default_route_table_tags = {
    name = "${var.region}-tgw-default_rt"
  }
  tags = {
    project = "${var.region}-vpcss-tgw"
  }
}