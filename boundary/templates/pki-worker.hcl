hcp_boundary_cluster_id = "a757c9c0-d7ab-435c-8998-2ae96fac9ada"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr = "54.212.22.123"
  auth_storage_path = "/home/ubuntu/boundary/worker1"
  tags {
    type = ["dev-worker", "ubuntu"]
  }
}
