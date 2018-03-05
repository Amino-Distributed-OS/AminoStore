#!/bin/bash

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 configdir nshard port replicas" >&2
  exit 1
fi

dir=$1		# dir for cofig files
shift

nshard=$1       # number of shards
shift

port=$1		# port to start with
shift

#echo "port" $port
#echo "number of shards" $nshard
#echo "dir"	# dir for cofig files

replicas=($@)	# list of replica addresses 
#echo "replicas" ${replicas[@]}


# number of replicas
let "n =  ${#replicas[@]}"

# Generate configs for shards
for ((i=0; i<$nshard; i++))
do
  echo "f" $((n/2)) >  $dir/shard$i.config
  for server  in ${replicas[@]}
  do
    echo "replica" $server":"$port >> $dir/shard$i.config
    let "port++"
  done
done

# Generate config for timeserver
echo "f" $((n/2)) >  $dir/shard.tss.config
for server  in ${replicas[@]}
do
    echo "replica" $server":"$port >> $dir/shard.tss.config
    let "port++"
done
