#!/bin/bash

replicas=("172.31.38.187" "172.31.30.122" "172.31.3.44")


for server in ${replicas[@]}
do
  echo "Measuring latency"
  ping -c 1 $server
  echo
  echo  "Measuring skew"
  ntpdate -q $server
  echo
done

echo "Forcing clock update for replicas"
for server in ${replicas[@]}
do
  ssh $server "sudo service ntp stop ; sudo ntpdate -s us.pool.ntp.org ; sudo service ntp start "
done

echo "Forcing clock update for client"
sudo service ntp stop
sudo ntpdate -s us.pool.ntp.org
sudo service ntp start 

sleep 5

for server in ${replicas[@]}
do
  echo "Measuring latency"
  ping -c 1 $server
  echo
  echo  "Measuring skew"
  ntpdate -q $server
  echo
done

