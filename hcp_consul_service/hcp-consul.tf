resource "hcp_hvn" "example_hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
  cidr_block     = var.hvn_cidr_block
}
resource "hcp_consul_cluster" "example_hcp" {
  hvn_id          = hcp_hvn.example_hvn.hvn_id
  cluster_id      = var.cluster_id
  tier            = "development"
  min_consul_version = var.min_consul_version
  public_endpoint = true
}
resource "hcp_consul_cluster_root_token" "init" {
  cluster_id = var.cluster_id
  depends_on = [hcp_consul_cluster.example_hcp]
}