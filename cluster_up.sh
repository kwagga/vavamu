#!/bin/bash
#
# Disclaimer - The worst bash script ever! It's messy, not well thought through and can probably be done 1000 times better. For what it's worth, it's an attempt and probably a good example of how NOT to do things.
#
# This script will gather the 3 ip addresses from node1..3 and then try to manipulate the /etc/vault.d/vault.hcl file on each node so that we can have a proper cluster working.
# We assume 3 nodes

nodename=node
nodecount=3

for ((j = 1 ; j <= $nodecount ; j++));
do
    node="$nodename$j"
    echo "Checking $node"
    vmstate=$(multipass info $node | grep State | awk '{print $2}')
        if [ $vmstate = "Running" ]
        then
            echo "$node is up and running"
            ipaddress=$(multipass info $node | grep IPv4 | awk '{print $2}')
            echo $node=$ipaddress
        else
            echo "$node is not running"
        fi

    for ((i = 1 ; i <= $nodecount ; i++));
    do
        echo "Updating leader_api_addr in /etc/vault.d/vault.hcl on $nodename$i with $ipaddress"
        multipass exec $nodename$i -- sudo sed -i 's/'$node'/'$ipaddress'/g' /etc/vault.d/vault.hcl
    done
done

# Need to start node1 and init Vault otherwise the rest of the cluster nodes cannot join the cluster.
# Setting activenode
active=1
activenode=$nodename$active

echo "Starting Vault on $activenode"
multipass exec $activenode -- sudo systemctl start vault.service
echo "Initializing Vault and exporting keys to /home/vagrant/unseal.keys - NEVER do this in production"
# Invoking Vagrant here as multipass chokes on the redirect.
vagrant ssh $activenode -c "vault operator init -key-shares=1 -key-threshold=1 >> /home/vagrant/unseal.keys"
# Let's unseal while we're at it...
# Read file into var
unseal=$(vagrant ssh $activenode -c "cat /home/vagrant/unseal.keys")
# Extract key
key=$(echo $unseal | grep Unseal | awk '{ print $4 }')
# Unseal now
echo "Vault unsealing on $activenode"
vagrant ssh $activenode -c "vault operator unseal $key"

for ((k = 1 ; k <= $nodecount ; k++));
    do
        if [ "$nodename$k" = "$activenode" ]
        then
            echo "This is $activenode and should be the active node, not restarting."
        else    
            echo "Restarting Vault on $nodename$k for changes to take affect."
            multipass exec $nodename$k -- sudo systemctl restart vault.service
            # Looks like we have to wait a while here for the node to join the cluster before we can unseal...
            sleep 8
            echo "Unsealing Vault on $nodename$k"
            # That is odd...turns out we have to do this twice..mmm
            vagrant ssh $nodename$k -c "vault operator unseal $key"
            vagrant ssh $nodename$k -c "vault operator unseal $key"
        fi
    done