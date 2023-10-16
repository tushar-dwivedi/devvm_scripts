#!/bin/bash

set -x

filter_cdc_files_on_timestamp() {
  local min_ts=$1

  # Directory path where the CDC files are located
  directory=$(sudo cat /var/lib/cockroachdb/rubrik_cdc/cdc_store_path | jq .cdc_store_path | xargs -I{} echo {}/)

  src_dir=$directory/cdc_data/

  # cp -rf $src_dir $directory/cdc_data_1/

  backup_dir="$src_dir/../backup"
  mkdir -p $backup_dir

  python /home/ubuntu/verify_cdc/filter_cdc_files_on_timestamp.py $src_dir $backup_dir --threshold $min_ts
}

filter_cdc_files_on_timestamp $1

set +x
