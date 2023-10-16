get_grep_string() {
  local pk_value_array=("$@")
  local grep_string=""
  for val in "${pk_value_array[@]}"; do
    # printf 'key: %s\n' "${key}"
    # echo
    if [ -n "$grep_string" ]; then
      grep_string+=" | "
    fi
    grep_string+=" grep ${val} "
  done

  echo "$grep_string"
}

fetch_relevant_logs_from_all_nodes_and_merge() {

  local result_dir_local=$1
  local __combined_log_json_file=$2

  local pk_value_array=("$@")

  for ip in "${bodega_ips_arr[@]}"; do
    echo $ip
    ssh-keyscan $ip >>~/.ssh/known_hosts

    # grep_str=$(get_grep_string 4115335172386270157 "ph69yubRFW2ph69yu" 1559394451855541)
    grep_str=$(grep 'processEvent: found no matching filter for tableName:')
    echo "grep_str: $grep_str"

    # ssh -i $pem_file ubuntu@$ip 'cat /var/log/cdc_data_publisher/current | grep "processEvent: found no matching filter for tableName:\[files_perf_test_only\]"  > /tmp/rejected_data_events.log'
    ssh -i $pem_file ubuntu@$ip "sudo zcat /var/log/cdc_data_publisher_old/* | $grep_str > /tmp/related_data_events.log"
    ssh -i $pem_file ubuntu@$ip "sudo cat /var/log/cdc_data_publisher_old/current | $grep_str >> /tmp/related_data_events.log"

    scp -i $pem_file ubuntu@$ip:/tmp/related_data_events.log $result_dir_local/related_data_events_"$ip".log
  done

  output_log_file="$result_dir_local/related_data_events.log"
  output_json_file="$result_dir_local/related_data_events.json"

  echo "redirecting all node files to $output_log_file"

  cat "$result_dir_local/related_data_events_*.log" >$output_log_file

  cat $output_log_file | jq '.message' >$output_json_file
  # cat $output_log_file | jq '.message' | python skip_commit/verify_cdc/filter_log_2_json.py >$output_json_file

  if [[ "$__combined_log_json_file" ]]; then
    eval $__combined_log_json_file="$output_json_file"
  fi
}
