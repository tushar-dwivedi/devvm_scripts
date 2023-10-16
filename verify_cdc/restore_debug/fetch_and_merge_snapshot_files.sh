fetch_cdc_files_from_all_nodes_and_merge() {

  local table_name=$1
  local result_dir_local=$2
  local result_dir_remote=$3
  local compressed=$4

  local __combined_cdc_json_file=$5

  for ip in "${bodega_ips_arr[@]}"; do
    node_json_file="$result_dir_remote/node_filtered_${table_name}_${ip}.json"
    # node_filtered_event_file="$result_dir/node_filtered_event_file_"$ip".json"

    ssh -i $pem_file ubuntu@$ip "rm -rf $result_dir_remote"
    ssh -i $pem_file ubuntu@$ip "mkdir -p $result_dir_remote"
    # ssh -i $pem_file ubuntu@$ip "sudo bash /home/ubuntu/verify_cdc/find_particular_event_in_cdc.sh $node_filtered_event_file"
    ssh -i $pem_file ubuntu@$ip "sudo bash /home/ubuntu/verify_cdc/fetch_cdc_files.sh $table_name $node_json_file $compressed"

    scp -i $pem_file ubuntu@$ip:$node_json_file $result_dir_local/

  done

  local filtered_for_table_json_file="$result_dir_local/node_filtered_${table_name}.json"
  cat $result_dir_local/node_filtered_${table_name}_* >$filtered_for_table_json_file

  # local projected_fields_json_file="${result_dir_local}/projected_${table_name}.json"
  # cat $filtered_for_table_json_file | \
  # jq -c '[. | {Timestamp: .Timestamp, TableName: .TableName, EntryType: .EntryType, token__uuid: .Row.token__uuid, uuid: .Row.uuid, stripe_id: .Row.stripe_id, cause: .cause}]'  > $projected_fields_json_file

  local final_grouped_file="${result_dir_local}/final_grouped_${table_name}.json"
  # cat $filtered_for_table_json_file | jq -s 'add' | jq -s '.[] | . + identify_db_operations' | jq -s 'highlight_operations' | jq '.[]' | jq -s '.' >$final_grouped_file
  cat $filtered_for_table_json_file | jq -s 'add' | jq 'map(. + identify_db_operations)' | jq 'highlight_operations' >$final_grouped_file

  if [[ "$__combined_cdc_json_file" ]]; then
    eval $__combined_cdc_json_file="$final_grouped_file"
  fi
}
