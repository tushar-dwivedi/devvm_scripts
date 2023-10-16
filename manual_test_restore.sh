#!/bin/bash

set -x

. ./skip_commit/common/bodega_order_details.sh

ip=${bodega_ips_arr[0]}

echo "running commands on : $ip"

ssh-keyscan $ip >>~/.ssh/known_hosts

ssh -i $pem_file ubuntu@$ip "bash -s" <skip_commit/cleanup_previous_run.sh

# You must disable backup job before starting backup tool's manual testing, to avoid jobs getting triggered, every now & then (this is ne time)
cqlsh -k sd -e "select job_id, instance_id, status, skip, is_disabled from job_instance where job_id='BACK_UP_COCKROACH_GLOBAL'"
cqlsh -k sd -e "update job_instance set skip=true where job_id='BACK_UP_COCKROACH_GLOBAL'"
# Set skip to false to enable it again
cqlsh -k sd -e "update job_instance set skip=false where job_id='BACK_UP_COCKROACH_GLOBAL'"

rkcl exec all 'sudo systemctl stop rk-cdc_data_publisher.service'
rkcl exec all 'sudo rm -rf /var/log/cdc_data_publisher/* /var/log/cockroach_backup_tool/cdc_restore_tool/* /var/log/cockroach_backup_tool/* '
rkcl exec all 'mkdir -p /var/log/cockroach_backup_tool/cdc_restore_tool'

rkcockroach sql -e "TRUNCATE sd.node_cdc_data_chunks"
rkcockroach sql -e "TRUNCATE sd.cdc_data_publishing_jobs"
rkcockroach sql -e "TRUNCATE sd.cdc_data_publishing_progress_reports"
#rkcockroach sql -e "TRUNCATE sd.files_perf_test_only CASCADE"
#rkcockroach sql -e "TRUNCATE sd.files_perf_test_only__static CASCADE"
rkcockroach sql -e "DROP DATABASE sd_restore CASCADE"

sudo /opt/rubrik/src/scripts/dev/rubrik_tool.py update_feature_toggle enableCDCDataPublisher true

On every node:
sudo chattr -i -RV /mnt/wwn-f*/internal/cass*/cdc_data/
ls -ltr /mnt/wwn-f*/internal/cass*/cdc_data
cd /mnt/wwn-f*/internal/cass*/cdc_data/
cd ..

ls -ltrh intermediate_cdc_data/cdc_orig/ && sudo mv intermediate_cdc_data/cdc_orig/* cdc_data/ && sudo rm -rf cdc_data/compressed/ cdc_data/reversed/ && sudo rm -rf intermediate_cdc_data/* && ls -ltrh cdc_data/

rkcl exec all 'ls -ltrh /mnt/wwn-*/internal/cassandra_snapshots/intermediate_cdc_data/cdc_orig/ ' &&
  rkcl exec all 'ls -ltrh /mnt/wwn-*/internal/cassandra_snapshots/cdc_data/' &&
  rkcl exec all 'ls -ltrh /mnt/wwn-*/internal/cassandra_snapshots/cdc_data/compressed'

rkcl exec all 'sudo chattr -i -RV /mnt/wwn-f*/internal/cass*/cdc_data/' &&
  rkcl exec all 'mv /mnt/wwn-*/internal/cassandra_snapshots/intermediate_cdc_data/cdc_orig/* /mnt/wwn-*/internal/cassandra_snapshots/cdc_data/' &&
  rkcl exec all 'rm -rf /mnt/wwn-*/internal/cassandra_snapshots/cdc_data/compressed/' &&
  rkcl exec all 'rm -rf /mnt/*/internal/cassandra_snapshots/intermediate_cdc_data/'


# sudo cp /opt/rubrik/conf/cdc_data_publisher/config_used.json /opt/rubrik/conf/cdc_data_publisher/config.json
ls -ltr /mnt/wwn-f*/internal/cass*/
# /mnt/wwn-f51dae90-bd38-4b92-ad50-303f4181ce89/internal/cassandra_snapshots/
#take the last 2 timestamps of backup folders, before restored:
# ubuntu@vm-machine-ytbyio-tnc4mjs:/mnt/wwn-f51d0f9e-d16e-4fb3-87b0-89bd5bf4b825/internal/cassandra_snapshots$ ls -ltr /mnt/wwn-f*/internal/cass*/
# /mnt/wwn-f51dae90-bd38-4b92-ad50-303f4181ce89/internal/cassandra_snapshots/:
# total 1064
# drwxr-xr-x 2 root root 106496 Jul 15 12:24 1689421377-BACK_UP_COCKROACH_GLOBAL-21
# drwxr-xr-x 2 root root 110592 Jul 15 16:12 1689435809-BACK_UP_COCKROACH_GLOBAL-22
# drwxr-xr-x 2 root root 106496 Jul 15 17:18 1689438991-BACK_UP_COCKROACH_GLOBAL-23
# drwxr-xr-x 2 root root   4096 Jul 15 18:13 1689444811-BACK_UP_COCKROACH_GLOBAL_RESTORED-23

time sudo /opt/rubrik/src/go/bin//cockroach_backup_tool restore --timestamp 1692558665 --restore_cdc_end_time 1692565299 --restore_cdc_data --tables_to_restore sd.files_perf_test_only

find . -type f -name "*_metadata.json.gz" -exec sudo bash -c 'file="{}"; filename="${file##*/}"; filename="${filename%%.gz}"; zgrep 'files_perf_test_only' $file > filtered/$filename; gzip filtered/$filename' \;

find . -type f -name "*_metadata.json.gz" -exec sudo bash -c 'file="{}"; filename="${file##*/}"; new_filename="${filename%%.gz}"; zgrep 'files_perf_test_only' $file > filtered/$new_filename; gzip filtered/$new_filename' \;

sudo chattr -i -RV /mnt/wwn-f*/internal/cass*/cdc_data/

cd /mnt/wwn-f*/internal/cass*/cdc_data
cd ..
#sudo rm -rf last_saved_cdc_files/*
#sudo mkdir last_saved_cdc_files
sudo mv intermediate_cdc_data/cdc_orig/* last_saved_cdc_files/
sudo mv cdc_data/*metadata.json.gz last_saved_cdc_files/
sudo cp -rf *BACK_UP_COCKROACH_GLOBAL* last_saved_cdc_files/

sudo chattr +i -RV last_saved_cdc_files

set+x
