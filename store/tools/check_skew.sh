#!/bin/bash

# Script to measure clock skew between this machine and  remote machines
# Provide remote machines IPs
machines=("172.31.36.255" "172.31.46.100")


for server in ${machines[@]}
do
  echo "Measuring latency"
  ping -c 1 $server
  echo
  echo  "Measuring skew"
  ntpdate -q $server
  echo
done


