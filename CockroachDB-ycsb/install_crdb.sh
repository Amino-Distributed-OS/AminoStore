#!/bin/bash

# Script to install CockroachDB on claster nodes


replicas=("172.31.35.12"  "172.31.30.218" "172.31.10.193")

# Download, extract and copy binary into the PATH
for server in ${replicas[@]}
do
  ssh  $server "wget -qO- https://binaries.cockroachdb.com/cockroach-v1.1.7.linux-amd64.tgz | tar  xvz"
  ssh $server "sudo cp -i cockroach-v1.1.7.linux-amd64/cockroach /usr/local/bin"
done


