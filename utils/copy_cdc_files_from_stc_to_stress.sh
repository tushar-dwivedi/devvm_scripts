#!/bin/bash

# Arrays of IP addresses for the first and second servers
source_servers=("sjc-b40408-19-b", "B-100213-rt", "sjc-b40408-19-a", "B-100213-rb", "B-100213-lt", "sjc-b40408-19-d", "B-100213-lb", "sjc-b40408-19-c")
dest_servers=("10.0.115.2" "10.0.115.3" "10.0.115.4" "10.0.115.5" "10.0.115.130" "10.0.115.131" "10.0.115.132" "10.0.115.133")

# Source and destination paths on the servers
source_path="/mnt/wwn-*/internal/cassandra_snapshots/cdc_data"
destination_path="/mnt/wwn-*/internal/cassandra_snapshots/cdc_data"

# Loop through the arrays and perform the rsync operation
for i in {0..7}; do
    first_server="${source_servers[$i]}"
    second_server="${dest_servers[$i]}"
    
    echo "Copying files from $first_server to $second_server"
    
    # Use rsync to copy files
    rsync -avz -e "ssh" "$first_server:$source_path/" "$second_server:$destination_path/"
    
    echo "Done copying files"
done

echo "All files copied successfully"

