#!/bin/bash

display_restore_stats() {
  local table_name=$1
  local db_1=$2
  local db_2=$3
  set -x

  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from ${db_1}.${table_name}"
  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from ${db_2}.${table_name}"

  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from ${db_1}.${table_name}__static"
  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from ${db_2}.${table_name}__static"

  # sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select token__node_id, node_id, cast(cast(scan_timestamp/1000 as int) as timestamp), internal_timestamp, LENGTH(data_chunk_list), status from sd.node_cdc_data_chunks;"
  # sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select work_assignment_id, cast(cast(job_issue_timestamp/1000 as int) as timestamp), node_id, length(job_list), status from sd.cdc_data_publishing_jobs;"
  # sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select work_assignment_id, cast(cast(progress_report_timestamp/1000 as int) as timestamp), internal_timestamp, job_id_list, status from sd.cdc_data_publishing_progress_reports;"

  # /opt/rubrik/deployment/cluster.sh localcluster exec all 'zgrep -i "isDeleted" /mnt/wwn-*/internal/cass*/sharded/* | wc -l'
  # /opt/rubrik/deployment/cluster.sh localcluster exec all 'a=$(zgrep "records and deleted" /var/log/cdc_data_publisher/*\.s | wc -l) && b=$(grep "records and deleted" /var/log/cdc_data_publisher/current | wc -l); c=$(expr $a + $b); echo "a:$a, b:$b, c:$c"'

  set +x
}

display_restore_stats $1 $2 $3
