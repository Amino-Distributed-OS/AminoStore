#! /usr/bin/env bash

##
#Start TiKV  servers start_servers.sh before you run this script
##


ycsb_machines=("172.31.42.111"  "172.31.29.240" "172.31.10.55")
# host av. zone: us1, us2, us3
nhosts=${#ycsb_machines[@]}

nserv=3

go_path="/home/ubuntu/TiKV-ycsb"
ycsb_wdir="$go_path/src/github.com/pingcap/go-ycsb"
logdir="/home/ubuntu/TiKV-ycsb/logs"


nthreads=9		# number of clients to run on each host
read_per=50		# read percentage, defines workload type
opcount=100000

need_setup=true		# true - copy workload files, load records and run workloads; false - run workloads  (if cluster is running)


cd $ycsb_wdir
if [[ "$need_setup" == true ]]; then
# Copy workloads
echo "Copying workloads"
  for host in  ${ycsb_machines[@]}
  do
    scp $ycsb_wdir/workloads/* ubuntu@$host:$ycsb_wdir/workloads
  done

# Load the records
  echo "Loading records"
  ./bin/go-ycsb load tikv -P workloads/workload100  > $logdir/load.log 2>&1
  sleep 10
fi


# Run workload
echo "$nthreads threads"
echo "Running workload: read percentage - $read_per"
for j in "${!ycsb_machines[@]}"
do
  echo " ${ycsb_machines[$j]} ./bin/go-ycsb run tikv -P workloads/workload$read_per  --threads $nthreads >  $logdir/run-rper$read_per-hst$nhosts-srv$nserv-thr$nthreads-this$j.log  2>&1"

  ssh  ${ycsb_machines[$j]} "cd $ycsb_wdir;\
      ./bin/go-ycsb run tikv -P workloads/workload$read_per  --threads $nthreads > $logdir/brun-rper$read_per-hst$nhosts-srv$nserv-thr$nthreads-this$j.log  2>&1" &
done



