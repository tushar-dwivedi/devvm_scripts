#!/bin/bash

# Define the arrays of source and destination IP addresses
#source_ips=("10.0.33.89" "10.0.34.56" "10.0.38.7" "10.0.38.138")		# jzsh5k-63vairc (restore testing 1)
#destination_ips=("10.0.36.143" "10.0.39.147" "10.0.38.247" "10.0.32.26")	# z8qaxd-q3te5ua (restore testing 2nd cluster)

# Arrays of IP addresses for the first and second servers
source_ips=("10.0.86.200", "10.0.210.109" "10.0.210.108" "10.0.210.110" "10.0.210.111" "10.0.86.200" "10.0.86.203" "10.0.86.201")
destination_ips=("10.0.115.2" "10.0.115.3" "10.0.115.4" "10.0.115.5" "10.0.115.130" "10.0.115.131" "10.0.115.132" "10.0.115.133")

# Source and destination paths on the servers
source_path="/mnt/wwn-*/internal/cassandra_snapshots/cdc_data/*_data.json.gz"
destination_path="/home/ubuntu/nebula_data/"

declare -A paths=(
          ["/mnt/wwn-*/internal/cassandra_snapshots/cdc_data/*_data.json.gz"]="/home/ubuntu/nebula_data/"
  )

# Loop through the array of tuples and copy files from source to destination
for source_path in "${!paths[@]}"; do
    destination_path="${paths[$source_path]}"
  for ((i=0; i<${#source_ips[@]}; i++)); do
    source_ip="${source_ips[i]}"
    destination_ip="${destination_ips[i]}"

    ssh-keyscan $source_ip >>~/.ssh/known_hosts
    ssh-keyscan $destination_ip >>~/.ssh/known_hosts

    # Perform scp to transfer the file
    ssh -i ~/Documents/projects/callisto/sdmain/deployment/ssh_keys/ubuntu.pem "ubuntu@$destination_ip" "set -x ; src=$(sudo jq '.cdc_store_path' /var/lib/cockroachdb/rubrik_cdc/cdc_store_path | tr -d \"); scp -i /opt/rubrik/deployment/ssh_keys/ubuntu.pem ubuntu@$source_ip:/home/ubuntu/data_files.tar.gz $src/cdc_data/; set +x"


#    scp -r -i ~/Documents/projects/callisto/sdmain/deployment/ssh_keys/ubuntu.pem "$file" "ubuntu@$source_ip:$source_path" "ubuntu@$destination_ip:$destination_path"

    # Check if the transfer was successful
    if [[ $? -eq 0 ]]; then
      echo "File transferred successfully: $file from $source_ip to $destination_ip"
    else
      echo "Failed to transfer file: $file from $source_ip to $destination_ip"
    fi
  done
done



'''
#run on source
rkcl exec all 'rm -rf /home/ubuntu/tushar/*; mkdir -p /home/ubuntu/tushar'; rkcl exec all 'cp -rf /mnt/*/internal/cassandra_snapshots/1693267398-BACK_UP_COCKROACH_GLOBAL-9907 /home/ubuntu/tushar/'

# run on destination
sudo bash -c "src=$(sudo jq '.cdc_store_path' /var/lib/cockroachdb/rubrik_cdc/cdc_store_path | tr -d \"); scp -r -i /opt/rubrik/deployment/ssh_keys/ubuntu.pem ubuntu@10.0.86.200:/home/ubuntu/tushar/1693281801-BACK_UP_COCKROACH_GLOBAL-9908 $src/"

'''
