#!/bin/bash

. ./skip_commit/common/bodega_order_details.sh
echo "bodega_ips: ${bodega_ips}"

# #IFS="," read -a myarray <<< ${bodega_ips}
# IFS="," read -a bodega_ips_arr <<< $bodega_ips
# echo "bodega_ips_arr: ${bodega_ips_arr[@]}"

# pem_file="~/Documents/projects/callisto/sdmain/deployment/ssh_keys/ubuntu.pem"

for ip in "${bodega_ips_arr[@]}"; do
	echo $ip
	ssh-keyscan $ip >>~/.ssh/known_hosts
	ssh -i $pem_file ubuntu@$ip 'mkdir -p /home/ubuntu/verify_cdc/'
	for script in "find_particular_event_in_cdc.sh"; do
		scp -i $pem_file ./skip_commit/verify_cdc/$script ubuntu@$ip:/home/ubuntu/verify_cdc/
	done
done

result_dir="/home/ubuntu/verify_cdc/cdc_result/"

rm -rf $result_dir
mkdir -p $result_dir

for ip in "${bodega_ips_arr[@]}"; do
	node_filtered_event_file="$result_dir/node_filtered_event_file_"$ip".json"

	ssh -i $pem_file ubuntu@$ip "rm -rf $result_dir"
	ssh -i $pem_file ubuntu@$ip "mkdir -p $result_dir"
	ssh -i $pem_file ubuntu@$ip "sudo bash /home/ubuntu/verify_cdc/find_particular_event_in_cdc.sh $node_filtered_event_file"

	scp -i $pem_file ubuntu@$ip:$node_filtered_event_file $result_dir

done

merged_file=$result_dir/node_filtered_event_file.json
cat $result_dir/node_filtered_event_file_* >"$merged_file"

cat $merged_file | jq -s 'sort_by(.Timestamp.WallTime)'
echo $merged_file
# cat ./skip_commit/verify_cdc/result/final.json | jq -s  '.[] | . + identify_db_operations' | jq -s 'group_by_pk' > ./skip_commit/verify_cdc/result/final_cdc_diff_1.json
