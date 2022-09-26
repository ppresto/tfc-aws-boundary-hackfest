# Admin Partitions and Namespaces
resource "consul_admin_partition" "pci" {
  name        = "pci"
  description = "PCI compliant environment"
}
resource "consul_namespace" "pci-payments" {
  name        = "payments"
  description = "Team 2 payments"
  partition   = consul_admin_partition.pci.name
  meta = {
    foo = "bar"
  }
}
resource "consul_namespace" "default-app-web" {
  name        = "web"
  description = "Web service"
  partition   = "default"
  meta = {
    foo = "bar"
  }
}
resource "consul_namespace" "default-app-api" {
  name        = "api"
  description = "api service"
  partition   = "default"
}

# Service Policies and Tokens (api)
resource "consul_acl_policy" "api-service" {
  name        = "api-service"
  datacenters = [hcp_consul_cluster.example_hcp.datacenter]
  rules       = <<-RULE
    service "api*" {
      policy = "write"
      intenstions = "read"
    }

    service "api-sidecar-proxy" {
      policy = "write"
    }

    service_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }
  RULE
}

# Create Default DNS Lookup policy and attach to anonymous token.
resource "consul_acl_policy" "dns-request" {
  name  = "dns-request-policy"
  rules = <<-RULE
    namespace_prefix "" {
      node_prefix "" {
        policy = "read"
      }
      service_prefix "" {
        policy = "read"
      }
      # prepared query rules are not allowed in namespaced policies
      #query_prefix "" {
      #  policy = "read"
      #}
    }
    RULE
}

resource "consul_acl_token_policy_attachment" "attachment" {
  token_id = "00000000-0000-0000-0000-000000000002"
  policy   = consul_acl_policy.dns-request.name
}

resource "consul_acl_token" "api-service" {
  description = "my api service token"
  policies    = ["${consul_acl_policy.api-service.name}"]
  local       = true
}
data "consul_acl_token_secret_id" "api-service" {
  accessor_id = consul_acl_token.api-service.id
  #pgp_key     = "keybase:my_username"
}
output "consul_service_api_token" {
  value = nonsensitive(data.consul_acl_token_secret_id.api-service.secret_id)
}