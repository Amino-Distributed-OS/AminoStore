#!/bin/bash


# Paths to source code and logfiles.
srcdir="/home/ubuntu/DCAP-Tapir"
logdir="/home/ubuntu/logs/tapir"
configdir="/home/ubuntu/DCAP-Tapir/store/tools"

this="172.31.42.111"
clients=("172.31.29.240" "172.31.10.55")

# Machines on which replicas are running.
replicas=("172.31.43.8" "172.31.20.205" "172.31.8.131" "172.31.32.118" "172.31.26.209" "172.31.12.41" "172.31.35.12" "172.31.30.218" "172.31.10.193")


store="tapirstore"      # Which store (strongstore, weakstore, tapirstore)
mode="txn-l"            # Mode for storage system.


port=50000	# port to start with, use if you generate config files by script

nkeys=0		# number of keys to use
nshard=8	# number of shards


# Print out configuration being used.
echo "Configuration:"
echo "Shards: $nshard"
echo "Keys: $nkeys"
echo "Store: $store"
echo "Mode: $mode"

# Make Tapir code if  needed
for server in ${replicas[@]}
do
  ssh $server "cd $srcdir; make"
done
for host in  ${clients[@]}
do
  ssh $host "cd $srcdir; make"
done

# Make java code if needed
for host in  ${clients[@]}
do
  ssh $host "cd $srcdir/ycsb-t; mkdir -p libs; cp ../libtapir/libtapir.so ./libs/; mvn clean package"
done



# Generate config files for replicas and timeserver
# !Use this block only if you have all shards on one server!
#echo "Generating config files.."
#$srcdir/store/tools/generate_configs.sh $configdir $nshard $port ${replicas[@]}
#for server in ${replicas[@]}
#do
#  ssh $server "$srcdir/store/tools/generate_configs.sh $configdir $nshard $port ${replicas[@]}"
#done
#for host in ${clients[@]}
#do
#  ssh $host "$srcdir/store/tools/generate_configs.sh $configdir $nshard $port ${replicas[@]}"
#done



# Copy config files and workloads
for host in  ${clients[@]}
do
  scp $configdir/*.config ubuntu@$host:$configdir
  scp $srcdir/ycsb-t/workloads/* ubuntu@$host:$srcdir/ycsb-t/workloads
done
for server in  ${replicas[@]}
do
  scp $configdir/*.config ubuntu@$server:$configdir
done



# Start all replicas and timestamp servers
echo "Starting TimeStampServer replicas.."
$srcdir/store/tools/start_replica.sh tss $srcdir/store/tools/shard.tss.config \
   "$srcdir/timeserver/timeserver" $logdir

for ((i=0; i<$nshard; i++))
do
  echo "Starting shard$i replicas.."
  $srcdir/store/tools/start_replica.sh shard$i $srcdir/store/tools/shard$i.config \
    "$srcdir/store/$store/server -m $mode -f $srcdir/store/tools/keys -k $nkeys -n $i -N $nshard" $logdir
done


