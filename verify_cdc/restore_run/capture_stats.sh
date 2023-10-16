#!/bin/bash

display_restore_stats() {
  set -x

  count_sd_files_perf_test_only=$(sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from sd.files_perf_test_only" | awk 'NR == 2 {print $1}')
  count_sd_restore_files_perf_test_only=$(sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from sd_restore.files_perf_test_only" | awk 'NR == 2 {print $1}')

  echo "count_sd_files_perf_test_only: $count_sd_files_perf_test_only , count_sd_restore_files_perf_test_only : $count_sd_restore_files_perf_test_only"

  if [ "$count_sd_files_perf_test_only" -ne "$count_sd_restore_files_perf_test_only" ]; then
    echo "Mismatch in row counts of files_perf_test_only"
    exit 1
  else
    echo "Row counts match for files_perf_test_only"
  fi

  count_sd_files_perf_test_only__static=$(sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from sd.files_perf_test_only__static" | awk 'NR == 2 {print $1}')
  count_sd_restore_files_perf_test_only__static=$(sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select count(*) from sd_restore.files_perf_test_only__static" | awk 'NR == 2 {print $1}')

  echo "count_sd_files_perf_test_only__static: $count_sd_files_perf_test_only__static , count_sd_restore_files_perf_test_only__static : $count_sd_restore_files_perf_test_only__static"

  if [ "$count_sd_files_perf_test_only__static" -ne "$count_sd_restore_files_perf_test_only__static" ]; then
    echo "Mismatch in row counts of files_perf_test_only__static"
    exit 1
  else
    echo "Row counts match for files_perf_test_only__static"
  fi

  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select token__node_id, node_id, cast(cast(scan_timestamp/1000 as int) as timestamp), internal_timestamp, LENGTH(data_chunk_list), status from sd.node_cdc_data_chunks;"
  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select work_assignment_id, cast(cast(job_issue_timestamp/1000 as int) as timestamp), node_id, length(job_list), status from sd.cdc_data_publishing_jobs;"
  sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "select work_assignment_id, cast(cast(progress_report_timestamp/1000 as int) as timestamp), internal_timestamp, job_id_list, status from sd.cdc_data_publishing_progress_reports;"

  /opt/rubrik/deployment/cluster.sh localcluster exec all 'zgrep -i "isDeleted" /mnt/wwn-f*/internal/cass*/cdc_data/compressed/* | wc -l'
  #/opt/rubrik/deployment/cluster.sh localcluster exec all 'a=$(zgrep "records and deleted" /var/log/cdc_data_publisher/*\.s | wc -l) && b=$(grep "records and deleted" /var/log/cdc_data_publisher/current | wc -l); c=$(expr $a + $b); echo "a:$a, b:$b, c:$c"'

  set +x
}

display_restore_stats
