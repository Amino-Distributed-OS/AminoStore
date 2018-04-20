#!/bin/bash

# Script to start nodes for CockroachDB insecure cluster


replicas=("172.31.43.8" "172.31.20.205" "172.31.8.131" "172.31.32.118" "172.31.26.209" "172.31.12.41"\
            "172.31.35.12" "172.31.30.218" "172.31.10.193")
locality=("us-1" "us-2" "us-3" "us-1" "us-2" "us-3" "us-1" "us-2" "us-3")



crdb_port=26257
crdb_http_port=8080



# Sync clock on replicas if needed
echo "Sync clock"
for server in ${replicas[@]}
do
  ssh  $server "sudo service ntp stop; sudo ntpd -b time.google.com; sudo service ntp start;"
done
sleep 10



# Start nodes
for i in "${!replicas[@]}"
do
  remote_cmd="cockroach start --background --insecure  --host=${replicas[$i]}\
      --port=$crdb_port --http-port=$crdb_http_port --store=type=mem,size=0.9 --logtostderr=NONE\
     --locality=datacenter=${locality[$i]}  --cache=25%"
  echo "$remote_cmd"

  if ((i==0)); then
    ssh ${replicas[$i]} "$remote_cmd" &
  else
    ssh  ${replicas[$i]} "$remote_cmd --join=${replicas[0]}:$crdb_port" &
  fi
  sleep 10
done


