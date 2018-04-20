#!/bin/bash

# Script to stop nodes of CockroachDB insecure cluster


replicas=("172.31.43.8" "172.31.20.205" "172.31.8.131" "172.31.32.118" "172.31.26.209" "172.31.12.41"\
           "172.31.35.12" "172.31.30.218" "172.31.10.193")

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


