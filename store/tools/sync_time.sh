#!/bin/bash

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

echo "Forcing clock update on remote machines"
for server in ${machines[@]}
do
  ssh $server "sudo service ntp stop ; sudo ntpdate -s us.pool.ntp.org ; sudo service ntp start "
done

echo "Forcing clock update on local machine"
sudo service ntp stop
sudo ntpdate -s us.pool.ntp.org
sudo service ntp start 

sleep 5

for server in ${machines[@]}
do
  echo "Measuring latency"
  ping -c 1 $server
  echo
  echo  "Measuring skew"
  ntpdate -q $server
  echo
done

