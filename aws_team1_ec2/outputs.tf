output "ec2_svc_node_ip" {
  value       = aws_instance.node.private_ip
  description = "IP address of node"
}

output "a_ssh_bastion_to_svcNode" {
  value       = "ssh -J ubuntu@${data.terraform_remote_state.hcp_consul.outputs.bastion_ip} ubuntu@${aws_instance.node.private_ip}"
  description = "ssh to bastion and then to private network ec2 svc node"
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}
