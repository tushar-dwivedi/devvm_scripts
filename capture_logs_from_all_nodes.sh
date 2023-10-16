#!/bin/bash

. ./skip_commit/common/bodega_order_details.sh

echo "bodega_ips: ${bodega_ips}"

first_node=${bodega_ips_arr[0]}

rm -rf ./skip_commit/verify_cdc/log_result
mkdir -p ./skip_commit/verify_cdc/log_result

for ip in "${bodega_ips_arr[@]}"; do
	echo $ip
	ssh-keyscan $ip >>~/.ssh/known_hosts

	# ssh -i $pem_file ubuntu@$ip 'cat /var/log/cdc_data_publisher/current | grep "processEvent: found no matching filter for tableName:\[files_perf_test_only\]"  > /tmp/rejected_data_events.log'
	ssh -i $pem_file ubuntu@$ip 'zcat /var/log/cdc_data_publisher/* |  grep 4115335172386270157 | grep "ph69yubRFW2ph69yu" | grep 1559394451855541 > /tmp/rejected_data_events.log'

	scp -i $pem_file ubuntu@$ip:/tmp/rejected_data_events.log ./skip_commit/verify_cdc/log_result/rejected_data_events_"$ip".log
done

output_log_file="./skip_commit/verify_cdc/log_result/rejected_data_events.log"
output_json_file="./skip_commit/verify_cdc/log_result/rejected_data_events.json"

echo "redirecting all node files to $output_log_file"

cat ./skip_commit/verify_cdc/log_result/*.log >$output_log_file

cat $output_log_file | jq '.message' | python skip_commit/verify_cdc/filter_log_2_json.py >$output_json_file

#Find delete count
# less $output_json_file | jq '.[] | .event' | jq -s 'map(select(.IsDeleted == true)) | length'

#cat ./skip_commit/verify_cdc/db_result/missing_entries_in_restored_table.txt | jq -R | jq -s 'crdb_records_json' > ./skip_commit/verify_cdc/db_result/missing_entries_in_restored_table.json
