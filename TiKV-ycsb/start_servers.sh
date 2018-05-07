#!/bin/bash

replicas=("172.31.38.96" "172.31.26.122" "172.31.5.33")
locality=("us1" "us2" "us3")
nserv=${#replicas[@]}

pd_vms=("172.31.42.111" "172.31.29.240" "172.31.10.55")
nhosts=${#pd_vms[@]}
#echo $nhosts

bin_dir="/home/ubuntu/tidb-latest-linux-amd64/bin"
data_dir="/home/ubuntu/TiKV-ycsb/store"
config_dir="/home/ubuntu/TiKV-ycsb/config"
log_dir="/home/ubuntu/TiKV-ycsb/logs"


# default ports
pd_port1=2379
pd_port2=2380
kv_port=20160

mem_size=3G			# max size of RAM memory to use for storage
log_level="fatal"		# log level for pd-servers


need_clocksync=true		# if true, clock willbe synchronized with time.google.com


function joinBy {
  delimiter="$1"

  local IFS="$delimiter"
  shift
  echo "$*"
}




# Construct pd cluster urls
pdcl_urls=()
pd_urls=()
for i in "${!pd_vms[@]}"
do
  pd_urls+=("${pd_vms[$i]}:$pd_port1")
  pdcl_urls+=("pd$i=http://${pd_vms[$i]}:$pd_port2")
done



# Sync clock on replicas if needed
if [[ "$need_clocksync" == true ]]; then
  echo "Sync clock"
  for server in ${replicas[@]}
  do
    ssh  $server "sudo service ntp stop; sudo ntpd -b time.google.com; sudo service ntp start;"
  done
  for server in ${pd_vms[@]}
  do
    ssh  $server "sudo service ntp stop; sudo ntpd -b time.google.com; sudo service ntp start;"
  done
  sleep 10
fi




echo "Copying config files for PD servers..."
# Copy config file for PD servers
for server in  ${pd_vms[@]}
do
  scp $config_dir/pd-config.toml ubuntu@$server:$config_dir
done

echo "Starting Placement Drivers..."
#start  placement drivers
for i in "${!pd_vms[@]}"
do
  ssh  ${pd_vms[$i]} "mkdir $data_dir; \
                sudo mount -t tmpfs -o size=$mem_size,mode=0755 tmpfs $data_dir; \
		sudo chown ubuntu:ubuntu $data_dir "
  echo "$bin_dir/pd-server --name=pd$i \
                --data-dir=$data_dir/pd$i \
                --client-urls=http://${pd_vms[$i]}:$pd_port1 \
                --peer-urls=http://${pd_vms[$i]}:$pd_port2 \
                --initial-cluster=`joinBy , ${pdcl_urls[@]}` \
		-L $log_level \
		--config=$config_dir/pd-config.toml \
                --log-file=$log_dir/pd.log"
  ssh ${pd_vms[$i]} "$bin_dir/pd-server --name=pd$i \
                --data-dir=$data_dir/pd$i \
                --client-urls=http://${pd_vms[$i]}:$pd_port1 \
                --peer-urls=http://${pd_vms[$i]}:$pd_port2 \
                --initial-cluster=`joinBy , ${pdcl_urls[@]}` \
                --config=$config_dir/pd-config.toml \
		-L $log_level \
                --log-file=$log_dir/pd.log" &
done

echo "Waiting for PDs to start..."
sleep 15



echo "Copying config files for TiKV servers..."
# Copy config file for TiKV servers
for server in  ${replicas[@]}
do
  scp $config_dir/tikv-config.toml ubuntu@$server:$config_dir
done

echo "Starting TiKV servers..."

# Start TiKV servers
for i in "${!replicas[@]}"
do
  ssh ${replicas[$i]}  "mkdir $data_dir; \
                sudo mount -t tmpfs -o size=$mem_size,mode=0755 tmpfs $data_dir; \
		sudo chown ubuntu:ubuntu $data_dir "
  echo "$bin_dir/tikv-server --pd=`joinBy , ${pd_urls[@]}` \
                  --addr=${replicas[$i]}:$kv_port \
                  --data-dir=$data_dir/tikv$i \
                  --log-file=$log_dir/tikv.log \
		  --config=$config_dir/tikv-config.toml \
		  --labels zone=${locality[$i]}"
  ssh ${replicas[$i]} "$bin_dir/tikv-server --pd=`joinBy , ${pd_urls[@]}` \
                  --addr=${replicas[$i]}:$kv_port \
                  --data-dir=$data_dir/tikv$i \
                  --log-file=$log_dir/tikv.log \
                  --config=$config_dir/tikv-config.toml \
		  --labels zone=${locality[$i]}" &
done

