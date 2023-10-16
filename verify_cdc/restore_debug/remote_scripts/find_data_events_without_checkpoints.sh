#!/bin/bash

# Directory path where the gzipped files are located
#directory="/mnt/wwn-f*/internal/cass*/cdc_data/compressed/*"
directory=`sudo cat /var/lib/cockroachdb/rubrik_cdc/cdc_store_path | jq .cdc_store_path | xargs -I{} echo {}/cdc_data/`

src_dir=$directory/compressed
dest_dir=$directory/../reversed

final_json_file=$1

sudo rm -rf $dest_dir
sudo mkdir -p $dest_dir
# Get the list of gzipped files in the directory, sorted by modification time in reverse order
files=$(find "$src_dir" -name "*.gz" -type f -printf "%T@\t%p\n" | sort -rn | cut -f2)

# Loop through each gzipped file in reverse order
for file in $files; do

  # Unzip the file and read its contents in reverse order
  file_temp_name=`basename $file`
  filename="${file_temp_name%.gz}"
  reversed_file="/tmp/reversed_$filename"
  sudo touch $reversed_file

  echo "Reversing file: $file > $reversed_file"
  sudo zcat "$file" | tac > $reversed_file

  reduced_file="$dest_dir/reduced_$filename"

  echo "Reducing file: $reversed_file > $reduced_file"
  sudo cat "$reversed_file" | jq --slurp 'map(select(.TableName == "files_perf_test_only")) | map(if has("IsDeleted") then {Key: .Key, IsDeleted: .IsDeleted, Timestamp: .Timestamp.WallTime, TableName: .TableName, EntryType: "data", Row: .Row, ChangedCols: .ChangedCols} else {StartKey: .Span.Key, EndKey: .Span.EndKey, StartTS: .StartTS.WallTime, ResolvedTS: .ResolvedTS.WallTime, TableName: .TableName, EntryType: "checkpoint"} end)' > "$reduced_file"

  echo "Processed file $file, reversed to $reversed_file, and then reduced to $reduced_file"


  diff_file="$dest_dir/diff_file_$filename"
  echo "Now creating diff file reduced_file:$reduced_file > $diff_file"
  sudo python3 /home/ubuntu/verify_cdc/find_data_events_without_checkpoints.py $reduced_file $diff_file

  echo
done


echo "Finally merging all files to $final_json_file"
cat $dest_dir/diff_file_* > $final_json_file


count=`cat $final_json_file | wc -l`

echo "event count: $count"
