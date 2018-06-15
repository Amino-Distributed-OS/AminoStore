#!/bin/bash

# Script to stop nodes of TiKV  cluster


replicas=("172.31.38.96" "172.31.26.122" "172.31.5.33")
pd_vms=("172.31.42.111" "172.31.29.240" "172.31.10.55")

data_dir="/home/ubuntu/TiKV-ycsb/store"
log_dir="/home/ubuntu/TiKV-ycsb/logs"


# Stop  TiKV server
for i in "${!replicas[@]}"
do
  ssh ${replicas[$i]} "killall -9 tikv-server"
done
# Stop PD server
for i in "${!pd_vms[@]}"
do
  ssh ${pd_vms[$i]} "killall -9 pd-server"
done

 sleep 3

# Remove node's data store and log
for i in "${!replicas[@]}"
do
  ssh ${replicas[$i]} "sudo umount $data_dir; rm -rf $data_dir; rm $log_dir/tikv.log"
done

for i in "${!pd_vms[@]}"
do
  ssh ${pd_vms[$i]} "sudo umount $data_dir; rm -rf $data_dir; rm $log_dir/pd.log"
done





