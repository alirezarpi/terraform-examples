#!/bin/bash
# 
# user-data script for deploying Nomad on Amazon Linux 2
# 
# Using the user-data / cloud init ensures we don't run twice
#  

# Update system and install dependencies
sudo yum update -y
sudo install unzip curl vim jq -y
# make an archive folder to move old binaries into
if [ ! -d /tmp/archive ]; then
  sudo mkdir /tmp/archive/
fi

# Install docker
sudo amazon-linux-extras install docker -y
sudo systemctl restart docker

# Set up volumes
sudo mkdir /data /data/mysql /data/certs /data/prometheus /data/templates
sudo chown root -R /data

# Install Nomad
NOMAD_VERSION=1.1.2
sudo curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
if [ ! -d nomad ]; then
  sudo unzip nomad.zip
fi
if [ ! -f /usr/bin/nomad ]; then
  sudo install nomad /usr/bin/nomad
fi
if [ -f /tmp/archive/nomad ]; then
  sudo rm /tmp/archive/nomad
fi
sudo mv /tmp/nomad /tmp/archive/nomad
sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

# Nomad config file copy
sudo mkdir -p /tmp/nomad
sudo tee /tmp/nomad/server.hcl <<EOF
data_dir = "/opt/nomad/server"

server {
  enabled          = true
  bootstrap_expect = 3
  job_gc_threshold = "2m"
  server_join {
    retry_join = ["provider=aws tag_key=nomad_server tag_value=true region=us-west-2"]
    retry_max = 10
    retry_interval = "15s"
  }
}

datacenter = "dc-aws-1"
region = "region-aws-1"

advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

client {
  enabled           = true
  network_interface = "eth0"
  servers           = ["provider=aws tag_key=nomad_client tag_value=true region=us-west-2"]

  host_volume "certs" {
    path      = "/data/certs"
    read_only = "true"
  }

  host_volume "templates" {
    path      = "/data/templates"
    read_only = "true"
  }
}

acl {
  enabled = false
}

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

autopilot {
  cleanup_dead_servers      = true
  last_contact_threshold    = "200ms"
  max_trailing_logs         = 250
  server_stabilization_time = "10s"
  enable_redundancy_zones   = false
  disable_upgrade_migration = false
  enable_custom_upgrades    = false
}
EOF
sudo cp /tmp/nomad/server.hcl /etc/nomad.d/server.hcl

# Install Consul
CONSUL_VERSION=1.10.0
sudo curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip > consul.zip
if [ ! -d consul ]; then
  sudo unzip consul.zip
fi
if [ ! -f /usr/bin/consul ]; then
  sudo install consul /usr/bin/consul
fi
if [ -f /tmp/archive/consul ]; then
  sudo rm /tmp/archive/consul
fi
sudo mv /tmp/consul /tmp/archive/consul
sudo mkdir -p /etc/consul.d
sudo chmod a+w /etc/consul.d

# Consul config file copy
sudo mkdir -p /tmp/consul
sudo tee /tmp/consul/server.hcl <<EOF
data_dir = "/opt/consul/server"

server           = true
bootstrap_expect = 1
advertise_addr   = "{{ GetInterfaceIP \"eth0\" }}"
client_addr      = "0.0.0.0"
ui               = true
datacenter       = "dc-aws-1"
retry_join       = ["provider=aws tag_key=consul_server tag_value=true region=us-west-2"]
retry_max        = 10
retry_interval   = "15s"

acl = {
  enabled = false
  default_policy = "allow"
  enable_token_persistence = true
}
EOF
sudo cp /tmp/consul/server.hcl /etc/consul.d/server.hcl

for bin in cfssl cfssl-certinfo cfssljson
do
  echo "$bin Install Beginning..."
  if [ ! -f /tmp/${bin} ]; then
    curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 > /tmp/${bin}
  fi
  if [ ! -f /usr/local/bin/${bin} ]; then
    sudo install /tmp/${bin} /usr/local/bin/${bin}
  fi
done
cat /root/.bashrc | grep  "complete -C /usr/bin/nomad nomad"
retval=$?
if [ $retval -eq 1 ]; then
  nomad -autocomplete-install
fi

# Install Ansible for config management
sudo amazon-linux-extras install ansible2 -y

# Form Consul Cluster
ps -C consul
retval=$?
if [ $retval -eq 0 ]; then
  sudo killall consul
fi
sudo nohup consul agent --config-file /etc/consul.d/server.hcl >$HOME/consul.log &

# Form Nomad Cluster
ps -C nomad
retval=$?
if [ $retval -eq 0 ]; then
  sudo killall nomad
fi
sudo nohup nomad agent -config /etc/nomad.d/server.hcl >$HOME/nomad.log &

# Bootstrap Nomad and Consul ACL environment

# Write anonymous policy file 

sudo tee -a /tmp/anonymous.policy <<EOF
namespace "*" {
  policy       = "write"
  capabilities = ["alloc-node-exec"]
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

quota {
  policy = "write"
}

node {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}
EOF

