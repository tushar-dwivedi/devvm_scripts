. ./skip_commit/common/bodega_order_details.sh
. ./skip_commit/common/copy_remote_scripts.sh

set -x

run() {

  local min_ts=$1

  local __combined_cdc_json_file=$5

  for ip in "${bodega_ips_arr[@]}"; do

    ssh -i $pem_file ubuntu@$ip "sudo bash /home/ubuntu/verify_cdc/run_filter_cdc_files_on_timestamp.sh 1690056535894973604"

    # scp -i $pem_file ubuntu@$ip:$node_json_file $result_dir_local/
  done
}

copy_all_remote_scripts

run

set +x
