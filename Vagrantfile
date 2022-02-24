# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT

# Get and install dependencies.
echo "Installing dependencies ..."
sudo apt-get update -qq
sudo apt-get install -qq curl jq unzip


echo "Installing Vault Enterprise ..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get install -qq vault-enterprise
sudo systemctl enable vault.service

echo "Setting VAULT_ADDR environment variable ..."
#echo export VAULT_ADDR="http://$(hostname -i):8200" >> /home/vagrant/.profile
echo export VAULT_ADDR="http://127.0.0.1:8200" >> /home/vagrant/.profile

echo "Adding license ..."
mv /home/vagrant/vault.hclic /etc/vault.d/vault.hclic
echo "VAULT_LICENSE_PATH=/etc/vault.d/vault.hclic" >> /etc/vault.d/vault.env

echo "Setting VAULT_RAFT_NODE_ID environment variable ..."
echo VAULT_RAFT_NODE_ID="$(hostname)" >> /etc/vault.d/vault.env

echo "Getting external IPv4 address..."
IPADDRESS="$(hostname -I | awk '{ print $1 }')"
echo "IP address is:" $IPADDRESS

echo "Setting new Vault configuration ..."
sudo mv /etc/vault.d/vault.hcl /etc/vault.d/vault_hcl.old

tee /etc/vault.d/vault.hcl << EOF

ui = true
mlock = false
cluster_addr  = "http://$IPADDRESS:8201"
api_addr      = "http://$IPADDRESS:8200"

storage "raft" {
	path = "/opt/vault/data"

	retry_join {
   leader_api_addr = "http://node1:8200"
	}
	retry_join {
	  leader_api_addr = "http://node2:8200"
	}
	retry_join {
	  leader_api_addr = "http://node3:8200"
	}
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

EOF

sudo chown -R vault:vault /etc/vault.d/*

SCRIPT

# Specify a Vault box for the LAB
LAB_BOX_NAME = ENV['LAB_BOX_NAME'] || "multipass"

Vagrant.configure("2") do |config|
  config.vm.box = LAB_BOX_NAME

#config.vm.provision "shell", inline: $script
#config.vm.provision "file", source: "vault.hclic", destination: "/etc/vault.d/vault.hclic"

    (1..3).each do |i|
    config.vm.define "node#{i}" do |node|
	node.vm.hostname = "node#{i}"
        node.vm.synced_folder ".", "/vagrant", type: "rsync"
        node.vm.provision "file", source: "vault.hclic", destination: "$HOME/"
        node.vm.provision "shell", inline: $script
    config.vm.provider "multipass" do |multipass,override|
        multipass.hd_size = "10G"
        multipass.cpu_count = 1
        multipass.memory_mb = 1024
        multipass.image_name = "focal"
    end
    end
  end
end
