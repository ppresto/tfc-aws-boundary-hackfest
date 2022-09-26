data "template_file" "coredns_configmap_patch" {
  template = file("${path.module}/templates/coredns/coredns-patch.yaml")
  vars = {
    CONSUL_DNS_CLUSTER_IP = var.consul_dns_cluster_ip
  }
}
data "kubectl_file_documents" "docs" {
  content = data.template_file.coredns_configmap_patch.rendered
}
resource "kubectl_manifest" "test" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
}