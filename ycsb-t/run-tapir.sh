#! /usr/bin/env bash

##
#Start Tapir servers start_servers.sh before you run this script
##


ycsb_machines=("172.31.42.111"  "172.31.29.240" "172.31.10.55")
nhosts=${#ycsb_machines[@]}

closest_replica=(0 1 2)
ycsb_wdir="/home/ubuntu/DCAP-Tapir/ycsb-t"
nserv=9

nshards=8		# number of shards, must match number in start_servers.sh
reccount=1000000	# number of records to load
opcount=300000		# number of txn requests to make
read_per=50		# read percentage, defines type of workload
nthreads=(1)   		# number of  threads, use one value at a time

need_setup=true		# true - load records and run workloads; false - run workloads (if you have key-value store running)



if [[ "$need_setup" == true ]]; then
# Load the records in Tapir
  echo "Loading records"
  java -cp tapir-interface/target/tapir-interface-0.1.4.jar:core/target/core-0.1.4.jar:tapir/target/tapir-binding-0.1.4.jar:javacpp/target/javacpp.jar \
    -Djava.library.path=libs/ com.yahoo.ycsb.Client -P workloads/workload100 \
    -load -db com.yahoo.ycsb.db.TapirClient \
    -p tapir.configpath=../store/tools/shard -p tapir.nshards=$nshards -p tapir.closestreplica=0 \
    -p measurement.type=histogram -p histogram.buckets=25  -p recordcount=$reccount > load.log 2>&1
fi

# Run the YCSB workloads
for i in ${nthreads[@]}
do
  echo "$i threads"

  echo "Running workload: read percentage - $read_per"
  for j in "${!ycsb_machines[@]}"
  do
    echo " java -cp tapir-interface/target/tapir-interface-0.1.4.jar:core/target/core-0.1.4.jar:tapir/target/tapir-binding-0.1.4.jar:javacpp/target/javacpp.jar \
      -Djava.library.path=libs/ com.yahoo.ycsb.Client -P workloads/workload$read_per \
      -t -db com.yahoo.ycsb.db.TapirClient \
      -p tapir.configpath=../store/tools/shard -p tapir.nshards=$nshards -p tapir.closestreplica=${closest_replica[$j]}   \
      -p measurement.type=histogram -p histogram.buckets=25 -threads $i -p operationcount=$opcount > logs/run-rper$read_per-hst$nhosts-srv$nserv-thr$i-this$j.log  2>&1"

    ssh  ${ycsb_machines[$j]} "cd $ycsb_wdir;\
       java -cp tapir-interface/target/tapir-interface-0.1.4.jar:core/target/core-0.1.4.jar:tapir/target/tapir-binding-0.1.4.jar:javacpp/target/javacpp.jar \
      -Djava.library.path=libs/ com.yahoo.ycsb.Client -P workloads/workload$read_per \
      -t -db com.yahoo.ycsb.db.TapirClient \
      -p tapir.configpath=../store/tools/shard -p tapir.nshards=$nshards -p tapir.closestreplica=${closest_replica[$j]}   \
      -p measurement.type=histogram -p histogram.buckets=25 -threads $i -p operationcount=$opcount >  logs/run-rper$read_per-hst$nhosts-srv$nserv-thr$i-this$j.log  2>&1 &"

  done
done

