data "kubectl_path_documents" "web" {
  pattern = "${path.module}/templates/${var.consul_template}/release-web/*.yaml"
}
data "kubectl_path_documents" "apiv2" {
  pattern = "${path.module}/templates/${var.consul_template}/release-apiv2/*.yaml"
}
data "kubectl_path_documents" "apiv3" {
  pattern = "${path.module}/templates/${var.consul_template}/release-apiv3/*.yaml"
}
data "kubectl_path_documents" "consul-init" {
  pattern = "${path.module}/templates/${var.consul_template}/init-consul-config/*.yaml"
}

resource "kubectl_manifest" "consul-init" {
  for_each   = toset(data.kubectl_path_documents.consul-init.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}

resource "kubectl_manifest" "web" {
  for_each   = toset(data.kubectl_path_documents.web.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.consul-init]
}
resource "kubectl_manifest" "apiv2" {
  for_each   = toset(data.kubectl_path_documents.apiv2.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.web]
}
resource "kubectl_manifest" "apiv3" {
  for_each   = toset(data.kubectl_path_documents.apiv3.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.apiv2]
}