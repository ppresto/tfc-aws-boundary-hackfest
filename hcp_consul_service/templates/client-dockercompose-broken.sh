#!/bin/bash

# stored in: /var/lib/cloud/instances/instance-id/user-data.txt
# logged at: /var/log/cloud-init-output.log

CONFIG_FILE_64="${CONSUL_CONFIG_FILE}"
CONSUL_CA=$(echo ${CONSUL_CA_FILE}| base64 -d)

#
### Install Consul
#
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul-enterprise=1.12.0-1+ent unzip jq

#
### Install Envoy
#
curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
func-e versions -all
func-e use 1.20.2
cp $${HOME}/.func-e/versions/1.20.2/bin/envoy /usr/local/bin
envoy --version

#
### Install Docker, docker-compose
#
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Set variables with jq
GOSSIP_KEY=$(echo $CONFIG_FILE_64 | base64 -d | jq -r '.encrypt')
RETRY_JOIN=$(echo $CONFIG_FILE_64 | base64 -d | jq -r '.retry_join[]')
DATACENTER=$(echo $CONFIG_FILE_64 | base64 -d | jq -r '.datacenter')

# Grab instance IP
local_ip=`ip -o route get to 169.254.169.254 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

# Setup Consul Client for HCP
mkdir -p /opt/consul
mkdir -p /etc/consul.d/certs
touch /etc/consul.d/consul.env  #placeholder for env vars

cat > /etc/consul.d/certs/ca.pem <<- EOF
$CONSUL_CA
EOF

# Modify the default consul.hcl file
cat > /etc/consul.d/consul.hcl <<- EOF
datacenter = "$DATACENTER"
data_dir = "/opt/consul"
server = false
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
advertise_addr = "$local_ip"
retry_join = ["$RETRY_JOIN"]
encrypt = "$GOSSIP_KEY"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
log_level = "INFO"
ui = true
#verify_incoming = true
#verify_outgoing = true
#verify_server_hostname = true
ca_file = "/etc/consul.d/certs/ca.pem"
#cert_file = "/etc/consul.d/certs/client-cert.pem"
#key_file = "/etc/consul.d/certs/client-key.pem"
auto_encrypt = {
  tls = true
}

connect {
  enabled = true
}

ports {
  grpc = 8502
}
EOF

cat >/etc/consul.d/client_acl.hcl <<- EOF
acl = {
  enabled = true
  #down_policy = "async-cache"
  #default_policy = "deny"
  #enable_token_persistence = true
  tokens {
    agent = "${CONSUL_ACL_TOKEN}"
  }
}
EOF

# Configure systemd
cat >/etc/systemd/system/consul.service <<- EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Install fake-service (api)
mkdir -p /opt/consul/fake-service/central_config
mkdir /opt/consul/fake-service/service_config

cat >/opt/consul/fake-service/service_config/api_v1.hcl <<- EOF
service {
  name = "api"
  id = "api-v1"
  port = 9090
  token = ""
  connect {
    sidecar_service {
      port = 20000
      check {
        name = "Connect Envoy Sidecar"
        tcp = "0.0.0.0:20000"
        interval ="10s"
      }
      proxy {
      }
    }
  }
}
EOF


cat >/opt/consul/fake-service/central_config/api_defaults.hcl <<- EOF
Kind = "service-defaults"
Name = "api"
Protocol = "grpc"
EOF

cat >/opt/consul/fake-service/docker-compose.yml <<- EOF
---
version: "3.3"
services:
  api:
    image: nicholasjackson/fake-service:v0.21.0
    container_name: api
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      MESSAGE: "API response"
      NAME: "API"
      SERVER_TYPE: "grpc"
  api_proxy:
    image: nicholasjackson/consul-envoy:v1.6.0-v0.10.0
    container_name: api_proxy
    depends_on:
      - "api"
    environment:
      CONSUL_HTTP_ADDR: 172.17.0.1:8500
      CONSUL_GRPC_ADDR: 172.17.0.1:8502
      SERVICE_CONFIG: "/config/api_v1.hcl"
      CENTRAL_CONFIG: "/central_config/api_defaults.hcl"
      CONSUL_HTTP_TOKEN: "${CONSUL_ACL_TOKEN}"
    volumes:
    - "$${PWD}/service_config/:/config"
    - "$${PWD}/central_config/:/central_config"
    command: ["consul", "connect", "envoy", "-sidecar-for", "api-v1"]
    network_mode: "service:api"
EOF

# Start Consul
systemctl enable consul.service
systemctl start consul.service

# Start fake-service container using docker-compose
cd /opt/consul/fake-service
docker compose up -d
