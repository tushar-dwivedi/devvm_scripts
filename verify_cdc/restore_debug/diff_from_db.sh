#!/bin/bash

first_node=${bodega_ips_arr[0]}
crdb_bin="/opt/rubrik/src/scripts/cockroachdb/rkcockroach"

get_primary_keys() {
  local table_name=$1

  local pk_query="SHOW CONSTRAINTS FROM sd.${table_name}"

  local cmd="ssh -i $pem_file ubuntu@$first_node 'sudo $crdb_bin sql -e \"$pk_query\" --format=csv  | tail -n +2'"
  local output=$(bash -c "$cmd")
  local pk_columns=$(echo "$output" | awk -F'[()]' '{print $2}' | sed 's/ ASC//g')

  echo $pk_columns
}

get_all_columns() {
  local table_name=$1

  local pk_query="SHOW columns FROM sd.${table_name}"

  # rkcockroach sql -e "show columns from sd.files_perf_test_only"  --format=csv  | tail -n +2 | awk -F',' '{print $1}'

  local cmd="ssh -i $pem_file ubuntu@$first_node 'sudo $crdb_bin sql -e \"$pk_query\" --format=csv  | tail -n +2'"
  local output=$(bash -c "$cmd")
  local all_columns=$(echo "$output" | awk -F',' '{print $1}')

  echo $all_columns
}

get_join_conditions() {
  local pk_array=("$@")
  local condition=""
  for key in "${pk_array[@]}"; do
    # printf 'key: %s\n' "${key}"
    # echo
    if [ -n "$condition" ]; then
      condition+=" and "
    fi
    condition+="t1.${key} = t2.${key}"
  done

  echo "$condition"
}

get_select_fields() {
  local columns=("$@")
  local condition=""
  for key in "${columns[@]}"; do
    # printf 'key: %s\n' "${key}"
    # echo
    if [ -n "$condition" ]; then
      condition+=", "
    fi
    condition+="t1.${key} as t1_${key}"
  done

  for key in "${columns[@]}"; do
    # printf 'key: %s\n' "${key}"
    # echo
    if [ -n "$condition" ]; then
      condition+=", "
    fi
    condition+="t2.${key} as t2_${key}"
  done

  echo "$condition"
}

get_where_conditions() {
  local columns=("$@")
  local condition=""
  for key in "${columns[@]}"; do
    # printf 'key: %s\n' "${key}"
    # echo
    if [ -n "$condition" ]; then
      condition+=" or "
    fi
    condition+="t1.${key} <> t2.${key}"
  done

  echo "$condition"
}

get_orderby_string() {
  local pk_array=("$@")
  local order_by=""
  for key in "${pk_array[@]}"; do
    # printf 'key: %s\n' "${key}"
    # echo
    if [ -n "$order_by" ]; then
      order_by+=","
    fi
    order_by+="t1.${key}"
  done

  echo "order by $order_by"
}

find_diff_for_table() {
  local table_name=$1
  local db_result_dir=$2
  local db_1=$3
  local db_2=$4

  # local pem_file=$2
  # local first_node=$3

  # result variables
  local __extra_entries_file=$5
  local __missing_entries_file=$6
  local __mismatching_entries_file=$7

  extra_entries_query_select="SELECT t1.* FROM ${db_2}.$table_name AS t1 LEFT JOIN ${db_1}.$table_name AS t2 "
  missing_entries_query_select="SELECT t1.* FROM ${db_1}.$table_name AS t1 LEFT JOIN ${db_2}.$table_name AS t2 "

  sql_query_where="t2.token__uuid IS NULL "

  primary_keys=$(get_primary_keys "$table_name")
  # echo "primary_keys: ${primary_keys[@]}"
  IFS=', ' read -ra pk_columns <<<"$primary_keys"

  all_keys=$(get_all_columns "$table_name")
  # echo "primary_keys: ${primary_keys[@]}"
  #    IFS=', ' read -ra all_columns <<<"$all_keys"
  IFS=$'\n' read -d '' -r -a all_columns <<<"$all_keys"
  IFS=' ' read -ra all_keys_arr <<<"$all_columns"

  sql_query_select_for_mismatch=$(get_select_fields "${all_keys_arr[@]}")
  mismatch_entries_query_select="SELECT $sql_query_select_for_mismatch FROM ${db_1}.$table_name AS t1 JOIN ${db_2}.$table_name AS t2 "
  echo "mismatch_entries_query_select: $mismatch_entries_query_select"
  sql_query_where_mismatch=$(get_where_conditions "${all_keys_arr[@]}")

  join_condition=$(get_join_conditions "${pk_columns[@]}")
  # echo "join_condition: $join_condition"
  order_by=$(get_orderby_string "${pk_columns[@]}")
  # echo "order_by: $order_by"

  extra_entries_query="${extra_entries_query_select} ON ${join_condition} WHERE ${sql_query_where} ${order_by}"
  missing_entries_query="${missing_entries_query_select} ON ${join_condition} WHERE ${sql_query_where} ${order_by}"
  mismatch_query="${mismatch_entries_query_select} ON ${join_condition} WHERE ${sql_query_where_mismatch} ${order_by}"

  # echo "extra_entries_query: $extra_entries_query"
  # echo "missing_entries_query: $missing_entries_query"
  echo "mismatch_query: $mismatch_query"

  extra_entries_file_remote="/tmp/extra_entries_in_restored_table_${table_name}.txt"
  missing_entries_file_remote="/tmp/missing_entries_in_restored_table_${table_name}.txt"
  mismatched_entries_file_remote="/tmp/mismatched_entries_in_restored_table_${table_name}.txt"

  ssh -i $pem_file ubuntu@$first_node "sudo $crdb_bin sql -e '$extra_entries_query' --format=records > $extra_entries_file_remote"
  ssh -i $pem_file ubuntu@$first_node "sudo $crdb_bin sql -e '$missing_entries_query' --format=records > $missing_entries_file_remote"
  ssh -i $pem_file ubuntu@$first_node "sudo $crdb_bin sql -e '$mismatch_query' --format=records > $mismatched_entries_file_remote"

  scp -i $pem_file ubuntu@$first_node:$extra_entries_file_remote $db_result_dir/
  scp -i $pem_file ubuntu@$first_node:$missing_entries_file_remote $db_result_dir/
  scp -i $pem_file ubuntu@$first_node:$mismatched_entries_file_remote $db_result_dir/

  extra_entries_file_local="$db_result_dir/extra_entries_in_restored_table_${table_name}.txt"
  missing_entries_file_local="$db_result_dir/missing_entries_in_restored_table_${table_name}.txt"

  extra_entries_json_local="$db_result_dir/extra_entries_in_restored_table_${table_name}.json"
  missing_entries_json_local="$db_result_dir/missing_entries_in_restored_table_${table_name}.json"

  mismatched_entries_file_local="$db_result_dir/mismatched_entries_in_restored_table_${table_name}.txt"
  mismatched_entries_json_local="$db_result_dir/mismatched_entries_in_restored_table_${table_name}.json"

  extra_entries=0
  if [ $(wc -l <$extra_entries_file_local) -gt 0 ]; then
    # cat $extra_entries_file_local | jq -sR 'crdb_records_json' | skip_commit/verify_cdc/restore_debug/remote_scripts/convert_int_to_string.py >$extra_entries_json_local
    cat $extra_entries_file_local | jq -sR 'crdb_records_json' >$extra_entries_json_local
    extra_entries=$(cat $extra_entries_json_local | jq 'length')
  # echo "$extra_entries_json_local: $length"
  else
    touch $extra_entries_json_local
  fi

  if [[ "$__extra_entries_file" ]]; then
    eval $__extra_entries_file="'$extra_entries_json_local'"
  fi

  missing_entries=0
  if [ $(wc -l <$missing_entries_file_local) -gt 0 ]; then
    # cat $missing_entries_file_local | jq -sR 'crdb_records_json' | skip_commit/verify_cdc/restore_debug/remote_scripts/convert_int_to_string.py >$missing_entries_json_local
    cat $missing_entries_file_local | jq -sR 'crdb_records_json' >$missing_entries_json_local
    missing_entries=$(cat $missing_entries_json_local | jq 'length')
  # echo "$missing_entries_json_local: $length"
  else
    touch $missing_entries_json_local
  fi

  if [[ "$__missing_entries_file" ]]; then
    eval $__missing_entries_file="'$missing_entries_json_local'"
  fi

  mismatching_entries=0
  if [ $(wc -l <$mismatched_entries_file_local) -gt 0 ]; then
    # cat $missing_entries_file_local | jq -sR 'crdb_records_json' | skip_commit/verify_cdc/restore_debug/remote_scripts/convert_int_to_string.py >$missing_entries_json_local
    cat $mismatched_entries_file_local | jq -sR 'crdb_records_json' >$mismatched_entries_json_local
    mismatching_entries=$(cat $mismatched_entries_json_local | jq 'length')
  # echo "$missing_entries_json_local: $length"
  else
    touch $mismatched_entries_json_local
  fi

  if [[ "$__mismatching_entries_file" ]]; then
    eval $__mismatching_entries_file="'$mismatched_entries_json_local'"
  fi

  echo "Comparison for table $table_name after restore:"
  echo "extra_entries: $extra_entries, missing_entries: $missing_entries, mismatching_entries: $mismatching_entries"
}

# db_result_dir=./skip_commit/verify_cdc/db_result
# rm -rf $db_result_dir
# mkdir -p $db_result_dir

# find_diff_for_table "files_perf_test_only" sd sd_restore $db_result_dir extra_entries_file missing_entries_file mismatching_entries_file
# echo "extra_entries_file: $extra_entries_file"
# echo "missing_entries_file: $missing_entries_file"
# echo "mismatching_entries_file: $mismatching_entries_file"

# echo "extra_entries_file: $extra_entries_file"
# echo "missing_entries_file: $missing_entries_file"

# find_diff_for_table "files_perf_test_only__static" sd sd_restore
