# Function to check the status of the job
function check_job_status() {

  local id=$1

  # Run the command and store the output in a variable
  output=$(sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py get_job_instance "$id")

  # Extract the "status" field from the output
  status=$(echo "$output" | jq -r '.status')

  # Check if the status is "SUCCEEDED"
  if [[ $status == "SUCCEEDED" ]]; then
    echo "Job $id completed successfully."
    return 0
  fi

  # Check if the status is "QUEUED"
  if [[ $status == "QUEUED" ]]; then
    echo "Job $id back to QUEUED."
    return 3
  fi

  # Check if the status is "ACQUIRING"
  if [[ $status == "ACQUIRING" ]]; then
    echo "Job $id is currently ACQUIRING."
    return 2
  fi

  if [[ $status == "FAILED" ]]; then
    echo "Error: Job $id failed with status '$status'."
    echo "Error Details: $output"
    exit 1
  fi

  # Check if the status is any value other than "RUNNING"
  if [[ $status != "RUNNING" ]]; then
    echo "Error: Job $id failed with unknown status '$status'."
    echo "Error Details: $output"
    return 1
  fi

  return 1
}

function run_backup_and_check_job_status() {

  # Run the command and store the output in a variable
  output=$(sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py get_job_instances BACK_UP_COCKROACH_GLOBAL)

  # Extract the "id" field of the last element in the list with status "QUEUED"
  set +x
  id=$(echo "$output" | jq -r '.[] | select(.status == "QUEUED") | .id')
  set -x

  # Check if the "id" field is empty (no elements with status "QUEUED")
  if [ -z "$id" ]; then
    echo "No job in QUEUED state found. Picking up any RUNNING job if found."
    id=$(echo "$output" | jq -r '.[] | select(.status == "RUNNING") | .id')
    if [ -z "$id" ]; then
      echo "No job in QUEUED or RUNNING state found. Exiting the script."
      exit 1
    fi

  else
    echo "Last QUEUED job ID: $id"
    # Execute the command and check the return code
    sudo /opt/rubrik/src/scripts/debug/QuicksilverTool.sh -cmd runJobImmediately -jobInstanceId "$id"
    return_value=$?
    if [[ $return_value != 0 ]]; then
      echo "An error occurred while executing 'sudo /opt/rubrik/src/scripts/debug/QuicksilverTool.sh -cmd runJobImmediately -jobInstanceId $id'. Exiting the script."
      exit 1
    fi
  fi

  # Initialize retry counter
  retry_count=0

  check_job_status $id

  # Loop until the status changes from "RUNNING" to "SUCCEEDED"
  while [[ $? -ne 0 ]]; do
    if [[ $? -eq 2 ]]; then
      ((retry_count++))
      if [[ $retry_count -gt 5 ]]; then
        echo "Maximum retries reached. Giving up."
        break
      fi
      echo "Job back to QUEUED/ACQUIRING, retry:$retry_count"
    fi
    # Back to QUEUED, try again
    if [[ $? -eq 3 ]]; then
      sudo /opt/rubrik/src/scripts/debug/QuicksilverTool.sh -cmd runJobImmediately -jobInstanceId "$id"
    fi

    sleep 60
    check_job_status $id
  done

  /opt/rubrik/deployment/cluster.sh localcluster exec all 'ls -lh /mnt/wwn-f*/internal/cass*/'
}

function EnableCDC() {
  # Command 1
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sed -i "s/\(enable_cdc(.*)\)/\1 or True/" /opt/rubrik/src/py/cockroachdb/start_cmd.py'
  return_value=$?
  if [[ $return_value != 0 ]]; then
    echo "An error occurred while executing 'sed' command. Exiting the script."
    exit 1
  fi

  /opt/rubrik/deployment/cluster.sh localcluster exec all 'cat /opt/rubrik/src/py/cockroachdb/start_cmd.py | grep "or True"'

  # Command 2
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl restart cockroachdb.service'
  return_value=$?
  if [[ $return_value != 0 ]]; then
    echo "An error occurred while executing 'sudo systemctl restart' command. Exiting the script."
    exit 1
  fi

  sleep 15
}

function DisableCDC() {
  # Command 1
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sed -i s/" or True:"/":"/ /opt/rubrik/src/py/cockroachdb/start_cmd.py'
  return_value=$?
  if [[ $return_value -ne 0 ]]; then
    echo "An error occurred while executing 'sed' command. Exiting the script."
    exit 1
  fi

  /opt/rubrik/deployment/cluster.sh localcluster exec all 'grep "enable_cdc" /opt/rubrik/src/py/cockroachdb/start_cmd.py'

  # Command 2
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl restart cockroachdb.service'
  return_value=$?
  if [[ $return_value -ne 0 ]]; then
    echo "An error occurred while executing 'sudo systemctl restart' command. Exiting the script."
    exit 1
  fi

  sleep 15
}

function EnablePublisherAndValidator() {
  # Command 1
  output=$(sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py get_feature_toggle enableCDCDataPublisher)
  echo "Output of '/opt/rubrik/src/scripts/dev/rubrik_tool.py get_feature_toggle enableCDCDataPublisher':"
  echo "$output"

  # Command 2
  output=$(sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py update_feature_toggle enableCDCDataPublisher true)
  echo "Output of '/opt/rubrik/src/scripts/dev/rubrik_tool.py update_feature_toggle enableCDCDataPublisher true':"
  echo "$output"

  # Command 3
  output=$(sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py get_config callisto validateCDCDataFrequency)
  echo "Output of '/opt/rubrik/src/scripts/dev/rubrik_tool.py get_config callisto validateCDCDataFrequency':"
  echo "$output"

  # Command 4
  output=$(sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py update_config callisto validateCDCDataFrequency 1)
  echo "Output of '/opt/rubrik/src/scripts/dev/rubrik_tool.py update_config callisto validateCDCDataFrequency 1':"
  echo "$output"
}

function RestartDBServices() {
  # Command 1 with return value check
  echo "Executing '/opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl restart cockroachdb'..."
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl restart cockroachdb'
  return_code=$?
  if [ $return_code -ne 0 ]; then
    echo "Failed to start cockroachdb. Return code: $return_code"
    exit $return_code
  fi

  # Command 2 with return value check
  echo "Executing '/opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl restart cqlproxy'..."
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl restart cqlproxy'
  return_code=$?
  if [ $return_code -ne 0 ]; then
    echo "Failed to start cqlproxy. Return code: $return_code"
    exit $return_code
  fi

  sleep 15

  #     Command 3 with return value check
  #    /opt/rubrik/deployment/cluster.sh localcluster exec all 'sdservice.sh "*" restart'
  #    return_code=$?
  #    if [ $return_code -ne 0 ]; then
  #        echo "Failed to start sdservice. Return code: $return_code"
  #        exit $return_code
  #    fi
}

function Cleanup() {

  echo "Executing '/opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl stop rk-cdc_data_publisher.service'..."
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl stop rk-cdc_data_publisher.service'

  sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py update_config callisto validateCDCDataFrequency 0

  sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py update_config callisto tablesForCDCDataValidation "sd.files_perf_test_only"

  sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py get_config callisto tablesForCDCDataValidation

  sudo -u ubuntu /opt/rubrik/src/scripts/dev/rubrik_tool.py update_feature_toggle enableCDCDataPublisher false

  RestartDBServices

  /opt/rubrik/deployment/cluster.sh localcluster exec all "sdservice.sh 'job-fetcher' stop" # stop job-fetcher to keep logs clean

  /opt/rubrik/deployment/cluster.sh localcluster exec all 'chattr +i -V /mnt/wwn-f*/internal/cass*/cdc_data/*metadata.json.gz'
  /opt/rubrik/deployment/cluster.sh localcluster exec all 'chattr +i -V /mnt/wwn-f*/internal/cass*/cdc_data/compressed/*'
}

function log_milestone() {
  msg=$1
  echo "$msg , time: $(date +'%Y%m%d_%H%M%S')"
}

# log_milestone "Some milestone reached"
