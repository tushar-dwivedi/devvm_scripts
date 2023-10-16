#!/bin/bash

# Directory path where the gzipped files are located
#directory="/mnt/wwn-f*/internal/cass*/cdc_data/compressed/*"
directory=`sudo cat /var/lib/cockroachdb/rubrik_cdc/cdc_store_path | jq .cdc_store_path | xargs -I{} echo {}/cdc_data/`

src_dir=$directory/compressed
dest_dir=$directory/../filtered_event

final_json_file=$1

sudo rm -rf $dest_dir
sudo mkdir -p $dest_dir

zcat $src_dir/* | jq -s 'map(select(.TableName == "files_perf_test_only" and .Row.token__uuid == 795040664722155752 and .Row.uuid == "HkgH9PhImohHkgH9P" and .Row.stripe_id == 210771189210275445))' > $final_json_file


# Get the list of gzipped files in the directory, sorted by modification time in reverse order
# files=$(find "$src_dir" -name "*.gz" -type f -printf "%T@\t%p\n" | sort -n | cut -f2)

# # Loop through each gzipped file in reverse order
# for file in $files; do

#   # Unzip the file and read its contents in reverse order
#   file_temp_name=`basename $file`
#   filename="${file_temp_name%.gz}"
#   filtered_file="$dest_dir/filtered_event_file_$filename"

#   # cat $file | grep 4115335172386270157 | grep ph69yubRFW2ph69yu | grep 1559394451855541 > $filtered_file


#   sudo zcat "$file" | jq --slurp 'map(select(.TableName == "files_perf_test_only" and .Row.token__uuid == 4115335172386270157 and .Row.uuid == "ph69yubRFW2ph69yu" and .Row.stripe_id == 1559394451855541 ))' > "$filtered_file"

#   echo "Processed file $file, filtered to $filtered_file"

#   echo
# done


# echo "Finally merging all files to $final_json_file"
# cat $dest_dir/filtered_event_file_* | jq '.[]' > $final_json_file

count=`cat $final_json_file | jq 'length'`

echo "event count: $count"
