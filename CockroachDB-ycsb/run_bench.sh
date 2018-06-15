#!/bin/bash

# Script to run YCSB workloads on CockroachDB insecure cluster


replicas=("172.31.38.96" "172.31.26.122" "172.31.5.33")
# replica av. zone: us1, us2, us3
nserv=${#replicas[@]}

crdb_port=26257
crdb_http_port=8080

ycsb_machines=("172.31.42.111" "172.31.29.240" "172.31.10.55")
# host av. zone: us1, us2, us3
nhosts=${#ycsb_machines[@]}

db_name="test"			# default database name for YCSB
workload="workloads/workload100"

ycsb_wdir="/home/ubuntu/CockroachDB-ycsb"
jdbc_binding_jar="/home/ubunutu/CockroachDB-ycsb/lib/jdbc-binding-0.12.0.jar"
postgresql_jar="/home/ubuntu/CockroachDB-ycsb/postgresql-42.2.2.jar"

need_setup=true			# true - create database and table, load records and run workloads; false - run workloads  (if cluster is running)

follow_the_workload=false	# true - all workload goes through one server (clients connect to one server); false - balanced workload (client connects to a server in its av.zone)
range_max_bytes=25000000 	# effects number of shards (less renge_max_bytes, more shards); current number gives 8 shards for workload (1 mln keys, 1 field, field length 100)
nthreads=(5)			# number of clients to run on each host
opcount=300000			# number of txn requests to make
read_per=50			# read percentage, defines workload type


# Construct postgresql urls
pg_urls=()
for i in "${!replicas[@]}"
do
  pg_urls+=("postgresql://root@${replicas[$i]}:$crdb_port/$db_name?sslmode=disable")
done
# Construct jdbc urls
jdbc_urls=()
for i in "${!replicas[@]}"
do
  jdbc_urls+=("jdbc:postgresql://${replicas[$i]}:$crdb_port/$db_name")
done

# Construct db urls
db_urls=()
for i in  "${!ycsb_machines[@]}"
do
  if [[ "$follow_the_workload" == true ]]; then
    db_urls+=("${jdbc_urls[0]}")
  else
    db_urls+=("${jdbc_urls[$i]}")
  fi
done


function joinBy {
  delimiter="$1"

  local IFS="$delimiter"
  shift
  echo "$*"
}


if [[ "$need_setup" == true ]]; then
# Change range_max_bytes, effects number of shards
  ssh ${replicas[0]} "echo 'range_max_bytes: $range_max_bytes' | cockroach zone set .default --host=${replicas[0]} --insecure -f -"

# Create database and table
  ssh ${replicas[0]} "cockroach sql --url='${pg_urls[0]}' --execute='create database $db_name'"
  ssh ${replicas[0]} "cockroach sql --url='${pg_urls[0]}' --execute='create table usertable (YCSB_KEY VARCHAR(255) PRIMARY KEY, FIELD0 TEXT);'"


# Load workload
# Sending record to all nodes in the cluster. It takes longer to load but provides evenly distributed  raft group leaders
  db_url=`joinBy , ${jdbc_urls[@]}`
  echo "Loading records"
  ycsb/bin/ycsb load jdbc -P $workload -P cockroachdb.properties -p db.url=$db_url \
       -p measurementtype=histogram -p histogram.buckets=25 -s -cp $postgresql_jar > load.log 2>&1 
fi

sleep 10


# Run workload
for i in ${nthreads[@]}
do 
  echo $i "threads"


  echo "Running workload: read percentage - $read_per"
  for j in "${!ycsb_machines[@]}"
  do
    echo  "${ycsb_machines[$j]} $ycsb_wdir/ycsb/bin/ycsb run jdbc -P $ycsb_wdir/workloads/workload$read_per -P $ycsb_wdir/cockroachdb.properties -threads $i  -p db.url=${db_urls[$j]} \
         -p measurementtype=histogram  -p histogram.buckets=25 -cp $postgresql_jar -p operationcount=$opcount > \
         $ycsb_wdir/logs/run-rper$read_per-hst$nhosts-srv$nserv-thr$i-this$j.log 2>&1"

    ssh  ${ycsb_machines[$j]} "$ycsb_wdir/ycsb/bin/ycsb run jdbc -P $ycsb_wdir/workloads/workload$read_per -P $ycsb_wdir/cockroachdb.properties -threads $i  -p db.url=${db_urls[$j]} \
         -p measurementtype=histogram  -p histogram.buckets=25 -cp $postgresql_jar -p operationcount=$opcount > \
         $ycsb_wdir/logs/run-rper$read_per-hst$nhosts-srv$nserv-thr$i-this$j.log 2>&1 &" 
  done
done
