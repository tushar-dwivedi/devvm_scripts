#!/bin/bash

. ./devvm_scripts/common/bodega_order_details.sh
. ./devvm_scripts/common/copy_remote_scripts.sh
# . ./devvm_scripts/verify_cdc/capture_stats.sh
. ./devvm_scripts/verify_cdc/restore_debug/diff_from_db.sh
. ./devvm_scripts/verify_cdc/restore_debug/fetch_and_merge_cdc_files.sh
. ./devvm_scripts/verify_cdc/restore_debug/fetch_and_merge_log_files.sh

remote_node_script_dir="/home/ubuntu/verify_cdc/"

table_name=$1
# compressed=$2
db_1=$2
db_2=$3
only_check_db_diff=$4

if [ -z "$1" ]; then
  table_name="files_perf_test_only"
# exit 1
fi

if [ -z "$4" ]; then
  only_check_db_diff=0
# exit 1
fi

display_restore_stats() {
  local table_name=$1
  local db_1=$2
  local db_2=$3

  #ssh -i $pem_file ubuntu@$ip "bash -s" < devvm_scripts/verify_cdc/remote_scripts/display_stats.sh "files_perf_test_only"
  ssh -i $pem_file ubuntu@$first_node "bash ${remote_node_script_dir}/display_stats.sh $table_name $db_1 $db_2"
}

# Copy all remote scripts to all nodes
copy_all_remote_scripts

# table_name="files_perf_test_only"
# table_name=$1
display_restore_stats $table_name $db_1 $db_2
# display_restore_stats "files_perf_test_only__static"

# set -x

pk_columns=$(get_primary_keys "$table_name")
IFS=', ' read -ra primary_keys <<<"$pk_columns"

echo "pk_columns: $pk_columns"
echo "primary_keys: $primary_keys[@]"

# result_dir="./devvm_scripts/verify_cdc/results/"
result_dir="devvm_scripts/verify_cdc/results/${bodega_order_id}"

db_result_dir="$result_dir/db_result/${db_1}-${db_2}"
rm -rf $db_result_dir
mkdir -p $db_result_dir

########################################################################
# Collect details of missing and extra rown in restored DB
########################################################################
find_diff_for_table $table_name $db_result_dir $db_1 $db_2 extra_entries_file missing_entries_file mismatching_entries_file
echo "extra_entries_file: $extra_entries_file"
echo "missing_entries_file: $missing_entries_file"
echo "mismatching_entries_file: $mismatching_entries_file"

# exit 0

extra_count=$(jq length $extra_entries_file)
missing_count=$(jq length $missing_entries_file)
mismatching_count=$(jq length $mismatching_entries_file)

echo "extra_count: $extra_count , missing_count : $missing_count , mismatching_count : $mismatching_count"

if [ "$extra_count" -eq 0 ] && [ "$missing_count" -eq 0 ] && [ "$mismatching_count" -eq 0 ]; then
  echo "No extra/missing/mismatches."
  exit 0
fi

if [ $only_check_db_diff -eq 1 ]; then
  exit 0
fi

echo "Errors found, need to debug further ..."

cdc_result_dir_deduped="$result_dir/cdc_result_deduped"
# rm -rf $cdc_result_dir_deduped
# mkdir -p $cdc_result_dir_deduped

cdc_result_dir_orig="$result_dir/cdc_result_orig"
# rm -rf $cdc_result_dir_orig
# mkdir -p $cdc_result_dir_orig

combined_result_dir="$result_dir/combined_result"
rm -rf $combined_result_dir
mkdir -p $combined_result_dir

logs_result_dir="$result_dir/logs_result"
rm -rf $logs_result_dir
mkdir -p $logs_result_dir

# exit 0

########################################################################
# Process all the deduped CDC files, and convert them to JSON files
########################################################################
# fetch_cdc_files_from_all_nodes_and_merge $table_name $cdc_result_dir_deduped "/tmp/cdc_result_deduped" 1 combined_deduped_cdc_json_file
echo "0. combined_deduped_cdc_json_file: $combined_deduped_cdc_json_file"

set -x
extra_entries_vs_deduped_cdc_file="$combined_result_dir/extra_entries_vs_deduped_cdc.json"
python3 devvm_scripts/verify_cdc/restore_debug/find_cdc_entries_for_diff_entries.py $extra_entries_file $combined_deduped_cdc_json_file $extra_entries_vs_deduped_cdc_file 0
echo "1. extra_entries_vs_deduped_cdc_file: $extra_entries_vs_deduped_cdc_file"

missing_entries_vs_deduped_cdc_file="$combined_result_dir/missing_entries_vs_deduped_cdc.json"
python3 devvm_scripts/verify_cdc/restore_debug/find_cdc_entries_for_diff_entries.py $missing_entries_file $combined_deduped_cdc_json_file $missing_entries_vs_deduped_cdc_file 0
echo "2. missing_entries_vs_deduped_cdc_file: $missing_entries_vs_deduped_cdc_file"

mismatching_entries_vs_deduped_cdc_file="$combined_result_dir/mismatching_entries_vs_deduped_cdc.json"
python3 devvm_scripts/verify_cdc/restore_debug/find_cdc_entries_for_diff_entries.py $mismatching_entries_file $combined_deduped_cdc_json_file $mismatching_entries_vs_deduped_cdc_file 1
echo "3. mismatching_entries_vs_deduped_cdc_file: $mismatching_entries_vs_deduped_cdc_file"

set +x

########################################################################
# Process all the original CDC files, and convert them to JSON files
########################################################################

# fetch_cdc_files_from_all_nodes_and_merge $table_name $cdc_result_dir_orig "/tmp/cdc_result_orig" 0 combined_orig_cdc_json_file
echo "1. combined_orig_cdc_json_file: $combined_orig_cdc_json_file"

extra_entries_vs_orig_cdc_file="$combined_result_dir/extra_entries_vs_orig_cdc.json"
python3 devvm_scripts/verify_cdc/restore_debug/find_cdc_entries_for_diff_entries.py $extra_entries_file $combined_orig_cdc_json_file $extra_entries_vs_orig_cdc_file
echo "2. extra_entries_vs_orig_cdc_file: $extra_entries_vs_orig_cdc_file"

missing_entries_vs_orig_cdc_file="$combined_result_dir/missing_entries_vs_orig_cdc.json"
python3 devvm_scripts/verify_cdc/restore_debug/find_cdc_entries_for_diff_entries.py $missing_entries_file $combined_orig_cdc_json_file $missing_entries_vs_orig_cdc_file
echo "3. missing_entries_vs_orig_cdc_file: $missing_entries_vs_orig_cdc_file"

########################################################################
########################################################################

exit 0

fetch_relevant_logs_from_all_nodes_and_merge $logs_result_dir combined_log_json_file
echo "combined_log_json_file: $combined_log_json_file"

# 1. pick up few of the extra/missing entries file from the above, and debug with them.
# look up these
# Generate the keys string for the jq command
keys_string=$(printf '.[0] | .["%s"]' "${primary_keys[@]}")

# Extract the values of the specified keys from the first JSON entry
extra_pk_values=($(cat $extra_entries_file | jq -r "$keys_string"))
echo "extra_pk_values: $extra_pk_values"

exit 0

# Print the values
# for value in "${values[@]}"; do
#   echo "$value"
# done

# set +x
