#!/bin/bash

trap '{
  echo "\nKilling all clients.. Please wait..";
  for host in ${clients[@]}
  do
    ssh $host "killall -9 $client";
    ssh $host "killall -9 $client";
  done

  echo "\nKilling all replicas.. Please wait..";
  for host in ${servers[@]}
  do
    ssh $host "killall -9 server";
  done
}' INT

# Paths to source code and logfiles.
srcdir="/home/ubuntu/DCAP-Tapir"
logdirOrig="/home/ubuntu/logs/tapir"
configdir="/home/ubuntu/DCAP-Tapir/store/tools"

# Machines on which replicas are running.
#replicas=("172.31.41.181" "172.31.41.181" "172.31.41.181")
replicas=("172.31.38.187" "172.31.30.122" "172.31.3.44")

nruns=1

port=50000

# Machines on which clients are running.
clients=("localhost")
#clients=("172.31.36.255" "172.31.46.100")

client="retwisClient"    # Which client (benchClient, retwisClient, etc)
store="tapirstore"      # Which store (strongstore, weakstore, tapirstore)
mode="txn-l"            # Mode for storage system.

nshard=10     # number of shards

ClientsPerHost=(5)    # number of clients to run per machine for different scenarios
nkeys=100000 # number of keys to use
rtime=30       # duration to run (in sec)

tlen=2       # transaction length
wper=50       # writes percentage
err=0        # error
skew=0       # skew
zalpha=0.75    # zipf alpha (-1 to disable zipf and enable uniform)

# Print out configuration being used.
echo "Configuration:"
echo "Shards: $nshard"
echo "Clients per host: ${ClientsPerHost[@]}"
#echo "Threads per client: $nthread"
echo "Keys: $nkeys"
#echo "Transaction Length: $tlen"
#echo "Write Percentage: $wper"
echo "Error: $err"
echo "Skew: $skew"
echo "Zipf alpha: $zalpha"
echo "Client: $client"
echo "Store: $store"
echo "Mode: $mode"


# Generate keys to be used in the experiment.
#echo "Generating random keys.."
#python3 $srcdir/store/tools/key_generator.py $nkeys >  $srcdir/store/tools/keys
#for server in ${replicas[@]}
#do
#  ssh $server "python3 $srcdir/store/tools/key_generator.py $nkeys >  $srcdir/store/tools/keys"
#done
#for host in ${clients[@]}
#do
#  ssh $host "python3 $srcdir/store/tools/key_generator.py $nkeys >  $srcdir/store/tools/keys"
#done



# Generate config files for replicas and timeserver
echo "Generating config files.."
$srcdir/store/tools/generate_configs.sh $configdir $nshard $port ${replicas[@]}
for server in ${replicas[@]}
do
  ssh $server "$srcdir/store/tools/generate_configs.sh $configdir $nshard $port ${replicas[@]}"
done
for host in ${clients[@]}
do
  ssh $host "$srcdir/store/tools/generate_configs.sh $configdir $nshard $port ${replicas[@]}"
done






for((j=0; j<$nruns; j++))
do
echo "Run" $j
logdir="$logdirOrig/run$j"

echo "Measure skew.."
ssh $clients  "$srcdir/store/tools/check_skew.sh > $logdir/skew.log"


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


# Wait a bit for all replicas to start up
  sleep 2


  for nclient in ${ClientsPerHost[@]}
  do

# Run the clients
    echo "Running the client(s)"
    count=0
    for host in ${clients[@]}
    do
      ssh $host "$srcdir/store/tools/start_client.sh \"$srcdir/store/benchmark/$client \
      -c $srcdir/store/tools/shard -N $nshard -f $srcdir/store/tools/keys \
      -d $rtime -k $nkeys -m $mode -e $err -s $skew -z $zalpha -r 0\" \
      $count $nclient $logdir"

      let count=$count+$nclient
    done


# Wait for all clients to exit
    echo "Waiting for client(s) to exit"
    for host in ${clients[@]}
    do
      ssh $host "$srcdir/store/tools/wait_client.sh $client"
    done


# Process logs
    echo "Processing logs"
    for host in ${clients[@]}
    do
      ssh $host "cat $logdir/client.*.log | sort -g -k 3 > $logdir/client.log"
      ssh $host "rm -f $logdir/client.*.log"
      ssh $host "python3 $srcdir/store/tools/process_logs.py $logdir/client.log $rtime >  $logdir/summary.$nclient.${#replicas[@]}.$rtime.log"
    done
  done


  # Kill all replicas
  echo "Cleaning up"
  $srcdir/store/tools/stop_replica.sh $srcdir/store/tools/shard.tss.config > /dev/null 2>&1
  for ((i=0; i<$nshard; i++))
  do
    $srcdir/store/tools/stop_replica.sh $srcdir/store/tools/shard$i.config > /dev/null 2>&1
  done
done










# Process logs
#echo "Processing logs"
#cat $logdir/client.*.log | sort -g -k 3 > $logdir/client.log
#rm -f $logdir/client.*.log

#python3 $srcdir/store/tools/process_logs.py $logdir/client.log $rtime >  $logdir/summary$nclient.log
