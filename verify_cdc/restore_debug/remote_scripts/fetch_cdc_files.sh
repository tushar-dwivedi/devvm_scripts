#!/bin/bash

# set -x

fetch_all_cdc_files_for_table() {
  local table_name=$1
  local final_json_file=$2
  local compressed=$3

  # Directory path where the CDC files are located
  directory=$(sudo cat /var/lib/cockroachdb/rubrik_cdc/cdc_store_path | jq .cdc_store_path | xargs -I{} echo {}/)

  src_dir=""
  if [ $compressed -eq 1 ]; then
    src_dir=$directory/sharded
  else
    src_dir=$directory/cdc_data
  fi

  echo "src_dir: $src_dir"
  # Get the list of gzipped files in the directory, sorted by modification time in reverse order
  files=$(find "$src_dir" -name "*_data.json.gz" -type f -printf "%T@\t%p\n" | sort -rn | cut -f2)
  echo "files: $files"

  tmp_dir=/tmp/filtered_files
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"

  for file in $files; do
    filename_with_extension=$(basename "$file")
    filename_without_extension=${filename_with_extension%.gz}
    # echo "filename_without_extension: $filename_without_extension"
    zcat $file | grep 'IsDeleted' | python /home/ubuntu/verify_cdc/convert_int_to_string.py | jq "map(select(.TableName == \"$table_name\"))" >"$tmp_dir/$filename_without_extension"
    # zcat $src_dir/* | jq -s 'map(select(.TableName == "$table_name" and .Row.token__uuid == 795040664722155752 and .Row.uuid == "HkgH9PhImohHkgH9P" and .Row.stripe_id == 210771189210275445))' > $final_json_file
  done

  cat $tmp_dir/* >$final_json_file

  count=$(cat $final_json_file | jq 'length')
  echo "event count: $count"
}

fetch_all_cdc_files_for_table $1 $2 $3

# set +x
