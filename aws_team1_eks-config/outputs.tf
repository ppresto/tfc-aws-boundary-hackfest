output "consul_retry_join" {
  value = local.consul_retry_join
}

output "consul_config_yaml" {
  value = data.template_file.agent_config.rendered
}

#output "url" {
#  value = "http://${data.kubernetes_service.ingress.status[0].load_balancer[0].ingress[0].hostname}:8080"
#  depends_on = [data.kubernetes_service.ingress]
#}