#!/bin/bash

# Script to stop nodes of CockroachDB insecure cluster


replicas=("172.31.38.96" "172.31.26.122" "172.31.5.33")

# Stop  node
for server in ${replicas[@]}
do
  ssh $server "killall -9 cockroach"
done



##
# Do not need it if run in memory
##

# Remove node's data store
#for server in ${replicas[@]}
#do
#  ssh  $server "rm -rf cockroach-data"
#done


