# VaVaMu
## Build a local 3-node Vault cluster on M1 architecture
This will deploy a three node [Vault](https://www.vaultproject.io/) (Raft) cluster using [Vagrant](https://www.vagrantup.com/) and [MultiPass](https://multipass.run/) on Apple hardware using an **M1 (ARM)** processor.

This is an attempt to automate the setup as much as possible. As a result you'll have the following post deployment:
- Vault started and unsealed.
- Two standby nodes joined to the cluster.
- Shamir unseal keys and root token written to `/home/vagrant/unseal.keys` on the `active` node.

# Disclaimer
Please do not use this for production employments. This is for lab/testing purposes only.

# Prerequisites
- [Vagrant](https://www.vagrantup.com/)
- [Multipass](https://multipass.run/)
- [Vagrant Multipass Provider](https://github.com/Fred78290/vagrant-multipass)
- [Vault Enterprise License](https://www.vaultproject.io/docs/enterprise/license) (In case you want install the Enterprise vesion)

# Usage
## Clone the project
```
$ git clone https://github.com/kwagga/vavamu
$ cd vavamu
```
## Setup OSS or Enterprise
   - For OSS run: `sed  -i "" 's/vault-enterprise/vault/g' Vagrantfile`
   - For Enterprise populate `vault.hclic` with your license.

## Fire up the vm's and bring up the cluster
```
$ vagrant up
$ ./cluster_up.sh

```
## Once the cluster is up the nodes can be accessed with `vagrant`:
```
$ vagrant ssh node[1-3]
```

# Limitations
Multipass for MacOS on M1 does not currently support network management. 
https://github.com/canonical/multipass/issues/2424
