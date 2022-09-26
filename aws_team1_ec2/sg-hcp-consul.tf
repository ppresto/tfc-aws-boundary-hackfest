resource "aws_security_group" "consul_server" {
  name_prefix = "${var.region}-vpc2-consul"
  description = "Firewall for the consul server."
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "${var.region}-vpc2-consul" },
    { "Project" = var.region },
    { "Owner" = "presto" }
  )
}

#
###  Ingress Rules 
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


resource "aws_security_group_rule" "consul_server_allow_client_8301" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_8301_udp" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
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
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_egress_8301_udp" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = local.private_cidr_blocks
  description       = "Used to handle gossip between client agents"
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

resource "aws_security_group_rule" "ec2-svc-node_envoy" {
  security_group_id = aws_security_group.ec2-svc-node.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 20000
  to_port           = 20000
  cidr_blocks       = local.private_cidr_blocks
  description       = "Allow SSH traffic."
}