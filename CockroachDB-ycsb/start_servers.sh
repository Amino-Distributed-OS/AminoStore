#!/bin/bash

# Script to start nodes for CockroachDB insecure cluster


replicas=("172.31.38.96" "172.31.26.122" "172.31.5.33")
locality=("us-1" "us-2" "us-3")



crdb_port=26257
crdb_http_port=8080

function joinBy {
  delimiter="$1"

  local IFS="$delimiter"
  shift
  echo "$*"
}


# Sync clock on replicas if needed
echo "Sync clock"
for server in ${replicas[@]}
do
  ssh  $server "sudo service ntp stop; sudo ntpd -b time.google.com; sudo service ntp start;"
done
sleep 10


join_urls=()
for i in "${!replicas[@]}"
do
  join_urls+=("${replicas[$i]}:$crdb_port")
done


# Start nodes
for i in "${!replicas[@]}"
do
  remote_cmd="cockroach start --background --insecure  --host=${replicas[$i]}\
      --port=$crdb_port --http-port=$crdb_http_port --store=type=mem,size=0.9 --logtostderr=NONE\
      --locality=datacenter=${locality[$i]}  --cache=25% --log-dir=''  --join=`joinBy , ${join_urls[@]}` "
  echo "$remote_cmd"
  ssh ${replicas[$i]} "$remote_cmd" &
  sleep 5
done

echo "cockroach init --insecure --host=${replicas[0]} --log-dir='' --logtostderr=NONE"
ssh ${replicas[0]} "cockroach init --insecure --host=${replicas[0]} --log-dir='' --logtostderr=NONE" &
