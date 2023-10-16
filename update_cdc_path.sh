#!/bin/bash

. ./skip_commit/common/bodega_order_details.sh
. ./skip_commit/common/copy_remote_scripts.sh
echo "bodega_ips: ${bodega_ips}"

copy_all_remote_scripts

for ip in "${bodega_ips_arr[@]}"; do
	echo $ip
	ssh-keyscan $ip >>~/.ssh/known_hosts

	# ssh -i $pem_file ubuntu@$ip 'cat /var/log/cdc_data_publisher/current | grep "processEvent: found no matching filter for tableName:\[files_perf_test_only\]"  > /tmp/rejected_data_events.log'
	ssh -i $pem_file ubuntu@$ip 'sudo bash /home/ubuntu/verify_cdc/recreate_cdc_path.sh'

	# Check if the command execution was successful
	if [ $? -eq 0 ]; then
		# Check if the found path is not empty
		echo "Successfully created cdc_store_path with the following content:"

	else
		echo "Error: Failed to execute the command on the remote server."
	fi

done
