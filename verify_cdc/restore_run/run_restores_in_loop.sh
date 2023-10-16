#!/bin/bash

set -x

. skip_commit/common/bodega_order_details.sh
# Define the number of times to run the original script
num_runs=$1

log_dir="skip_commit/verify_cdc/loop_results/${bodega_order_id}/"
rm -rf $log_dir
mkdir -p $log_dir

# Loop to run the script multiple times
for ((i = 1; i <= num_runs; i++)); do

  # Get the start time of the run in a suitable format for the filename
  start_time=$(date +'%Y%m%d_%H%M%S')

  # Define the log filename with incremental serial number and start time
  log_filename="${i}_${start_time}.log"

  echo "Starting iteration $i, logs in $log_filename"

  # Run your original script and capture stdout and stderr to the log file
  ./skip_commit/verify_cdc/restore_run/test_restore.sh >"$log_dir/$log_filename" 2>&1
  if [ $? -eq 0 ]; then
    echo "test_restore.sh executed successfully with no errors."
  else
    echo "test_restore.sh exited with an error (exit status 1 or higher)."
    exit 1
    # Take appropriate action here
  fi

  # Optionally, you can print a separator between each run's output
  echo "========================" >>"$log_filename"

  echo "Completed iteration $i, logs in $log_filename"

  ./skip_commit/verify_cdc/restore_debug/start_restore_debug.sh "files_perf_test_only"
  if [ $? -eq 0 ]; then
    echo "files_perf_test_only restored successfully with no errors."
  else
    echo "files_perf_test_only failed to restore, check result files."
    exit 1
    # Take appropriate action here
  fi

  ./skip_commit/verify_cdc/restore_debug/start_restore_debug.sh "files_perf_test_only__static"
  if [ $? -eq 0 ]; then
    echo "files_perf_test_only restored successfully with no errors."
  else
    echo "files_perf_test_only failed to restore, check result files."
    exit 1
    # Take appropriate action here
  fi

done

set +x
