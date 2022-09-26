resource "aws_security_group" "consul_server" {
  name_prefix = "${var.region}-vpc3-consul"
  description = "Firewall for the consul server."
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "${var.region}-vpc3-consul" },
    { "Project" = var.region },
    { "Owner" = "presto" }
  )
}

#
###  HCP Consul Rules
#

resource "aws_security_group_rule" "consul_server_allow_server_8301" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [local.hvn_cidr_block]
  description       = "Used to handle gossip from server"
}
resource "aws_security_group_rule" "consul_server_allow_server_8301_udp" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [local.hvn_cidr_block]
  description       = "Used to handle gossip from server"
}

#
### Egress Rules
#
resource "aws_security_group_rule" "hcp_tcp_RPC_from_clients" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8300
  to_port           = 8300
  cidr_blocks       = [local.hvn_cidr_block]
  description       = "For RPC communication between clients and servers"
}
resource "aws_security_group_rule" "hcp_tcp_server_gossip" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [local.hvn_cidr_block]
  description       = "Server to server gossip communication"
}
resource "aws_security_group_rule" "hcp_udp_server_gossip" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [local.hvn_cidr_block]
  description       = "Server to server gossip communication"
}
resource "aws_security_group_rule" "hcp_tcp_https" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.hvn_cidr_block]
  description       = "The HTTPS API"
}
/*

#
### EKS Security Rules
#
Note:
These rules need to be applied to the EKS managed node interface for other consul clients
in 10.0.0.0/10 network space to monitor the node health.  Adding cluster or node rules directly within
the EKS module created new security groups that were not used by the node.
*/
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301" {
  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301_udp" {
  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "egress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
}

resource "aws_security_group_rule" "consul_server_allow_client_ingress_8301" {
  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_ingress_8301_udp" {
  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
}


#
### App Security Rules
#
resource "aws_security_group_rule" "eks_envoy" {
  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 20000
  to_port           = 20000
  cidr_blocks       = local.private_cidr_blocks
  description       = "Allow envoy traffic."
}
#resource "aws_security_group_rule" "eks_ingressgw" {
#  security_group_id = module.eks.cluster_primary_security_group_id
#  type              = "ingress"
#  protocol          = "tcp"
#  from_port         = 21000
#  to_port           = 21255
#  cidr_blocks       = local.private_cidr_blocks
#  description       = "ingress k8s HC."
#}

#resource "aws_security_group_rule" "eks_meshgw" {
#  security_group_id = module.eks.cluster_primary_security_group_id
#  type              = "ingress"
#  protocol          = "tcp"
#  from_port         = 8443
#  to_port           = 8443
#  cidr_blocks       = local.private_cidr_blocks
#  description       = "ingress k8s HC."
#}