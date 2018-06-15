#!/bin/bash

# Script to install TiKV on claster nodes

# Provide node ips
replicas=("172.31.36.25" "172.31.20.161" "172.31.7.44" "172.31.39.122" "172.31.21.175" "172.31.4.205")

# Download, extract 
for server in ${replicas[@]}
do
  echo "Installing TiKV on $server"
  ssh $server "wget http://download.pingcap.org/tidb-latest-linux-amd64.tar.gz"
  ssh $server "wget http://download.pingcap.org/tidb-latest-linux-amd64.sha256"
  ssh $server "tar -xzf tidb-latest-linux-amd64.tar.gz"
done

# Set up work directory
for server in ${replicas[@]}
do
  ssh $server "mkdir /home/ubuntu/TiKV-ycsb; mkdir /home/ubuntu/TiKV-ycsb/logs; mkdir /home/ubuntu/TiKV-ycsb/config"
done


