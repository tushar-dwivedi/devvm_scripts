remote_node_script_dir="/home/ubuntu/verify_cdc/"

copy_all_remote_scripts() {
  for ip in "${bodega_ips_arr[@]}"; do
    # echo $ip
    ssh-keyscan $ip >>~/.ssh/known_hosts
    ssh -i $pem_file ubuntu@$ip "mkdir -p $remote_node_script_dir/"
    # for script in "jq" "display_stats.sh" "fetch_cdc_files.sh" "find_data_events_without_checkpoints.sh" "find_data_events_without_checkpoints.py"; do
    scp -i $pem_file ./skip_commit/verify_cdc/restore_run/remote_scripts/* ubuntu@$ip:$remote_node_script_dir/
    scp -i $pem_file ./skip_commit/verify_cdc/restore_debug/remote_scripts/* ubuntu@$ip:$remote_node_script_dir/
    scp -i $pem_file ./skip_commit/common/remote_scripts/* ubuntu@$ip:$remote_node_script_dir/
    # scp -i $pem_file ./skip_commit/common/remote_scripts/jq.sh ubuntu@$ip:$remote_node_script_dir/jq
    # done

    ssh -i $pem_file ubuntu@$ip "rm -f /home/ubuntu/.jq"
    ssh -i $pem_file ubuntu@$ip "cp $remote_node_script_dir/jq.sh /home/ubuntu/.jq"

  done

  rm -f /home/ubuntu/.jq
  cp ./skip_commit/common/remote_scripts/jq.sh /home/ubuntu/.jq
}
