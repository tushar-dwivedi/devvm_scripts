#!/bin/bash

set -x

. ./devvm_scripts/common/bodega_order_details.sh
. ./devvm_scripts/common/copy_remote_scripts.sh
. ./devvm_scripts/verify_cdc/restore_run/remote_scripts/restore_utils.sh

kafka_string="kafka://"

for ip in "${bodega_ips_arr[@]}"; do
    kafka_string="${kafka_string}${ip}:9092,"
done

# Remove the trailing comma
bootstrap_servers=${kafka_string%,}

echo "bootstrap_servers: $bootstrap_servers"

#exit 0

remote_node_script_dir=~/verify_restore/

copy_all_remote_scripts

first_node_ip=${bodega_ips_arr[0]}

# Iterate over the array and format the string

echo "running commands on : $first_node_ip"

ssh -i $pem_file ubuntu@$first_node_ip "echo $bootstrap_servers > /home/ubuntu/kafka_bootstrap_servers"

ssh -i $pem_file ubuntu@$first_node_ip "bash -s" <./devvm_scripts/verify_cdc/restore_run/cleanup_previous_run.sh
return_value=$?
if [[ $return_value != 0 ]]; then
    echo "An error occurred while running cleanup_previous_run. Exiting the script."
    exit 1
fi

# Add some data with CDC disabled
# BAZEL_USE_REMOTE_WORKERS=0 python3 -m jedi.tools.sdt_runner --bodega_sid ${bodega_order_id} --test_target //jedi/e2e/callisto:crdb_load_test -- -k "test_perf_files" --crdb_load_duration "30m" --crdb_skip_cdc_enable

ssh -i $pem_file ubuntu@$first_node_ip "bash -s" <./devvm_scripts/verify_cdc/restore_run/take_first_backup.sh
return_value=$?
if [[ $return_value != 0 ]]; then
    echo "An error occurred while running take_first_backup. Exiting the script."
    exit 1
fi

# Add some data with CDC enabled
# BAZEL_USE_REMOTE_WORKERS=0
# python3 -m jedi.tools.sdt_runner --bodega_sid ${bodega_order_id} --test_target //jedi/e2e/callisto:crdb_load_test -- -k "test_perf_files" --crdb_load_duration "30m" --crdb_skip_cdc_enable
python3 -m jedi.tools.sdt_runner --test_target //jedi/e2e/callisto:crdb_load_test --bodega_sid ${bodega_order_id} -- -k "test_custom_perf" --crdb_populate_rows 100000 --crdb_load_duration 120m --crdb_load_name files --crdb_load_type cqlproxy

# run load on stress cluster
#python3 -m jedi.tools.sdt_runner --test_target //jedi/e2e/callisto:crdb_load_test --bodega_fulfilled_items cdm_stress_cluster.json -- -k "test_custom_perf" --crdb_populate_rows 100000 --crdb_load_duration 60m --crdb_load_name files --crdb_load_type cqlproxy

#python3 -m jedi.tools.sdt_runner --test_target //jedi/e2e/callisto:crdb_load_test --bodega_fulfilled_items ~/Documents/projects/callisto/sdmain/cdc_cluster.json -- -k "test_custom_perf" --crdb_populate_rows 100000 --crdb_load_duration 60m --crdb_load_name files --crdb_load_type cqlproxy
#python3 -m jedi.tools.sdt_runner --test_target //jedi/e2e/callisto:crdb_load_test --bodega_sid ${bodega_order_id} -- -k "test_custom_perf" --crdb_populate_rows 50000 --crdb_load_duration 60m --crdb_load_name mix_load --crdb_load_type cockroach

sleep 300

ssh -i $pem_file ubuntu@$first_node_ip "bash -s" <./devvm_scripts/verify_cdc/restore_run/stop_cdc_and_take_second_backup.sh

ssh -i $pem_file ubuntu@$first_node_ip "bash -s" <./devvm_scripts/verify_cdc/restore_run/capture_stats.sh
if [ $? -eq 0 ]; then
    echo "capture_stats.sh executed successfully with no errors."
else
    echo "capture_stats.sh exited with an error (exit status 1 or higher)."
#    exit 1
    # Take appropriate action here
fi

#ssh -i $pem_file ubuntu@$first_node_ip "bash -s" <./devvm_scripts/verify_cdc/restore_run/dump_kafka_data.sh
#if [ $? -eq 0 ]; then
#    echo "dump_kafka_data.sh executed successfully with no errors."
#else
#    echo "dump_kafka_data.sh exited with an error (exit status 1 or higher)."
#    exit 1
#    # Take appropriate action here
#fi

#bash ./devvm_scripts/verify_cdc/restore_debug/start_restore_debug.sh "files_perf_test_only"
#bash ./devvm_scripts/verify_cdc/restore_debug/start_restore_debug.sh "files_perf_test_only__static"

bash ./devvm_scripts/verify_cdc/restore_debug/start_restore_debug.sh "files_perf_test_only" sd sd_restore 0
# bash ./devvm_scripts/verify_cdc/restore_debug/start_restore_debug.sh "files_perf_test_only" sd sd_restore_kafka 1
# echo -e '\a'

set +x
