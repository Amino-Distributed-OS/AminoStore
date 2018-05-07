#!/bin/bash

# Script to install CockroachDB on claster nodes


replicas=("172.31.38.96" "172.31.26.122" "172.31.5.33")

# Download, extract and copy binary into the PATH
for server in ${replicas[@]}
do
  ssh $server "wget -qO- https://binaries.cockroachdb.com/cockroach-v2.0.1.linux-amd64.tgz | tar  xvz"
  ssh $server "sudo cp -i cockroach-v2.0.1.linux-amd64/cockroach /usr/local/bin"
done


