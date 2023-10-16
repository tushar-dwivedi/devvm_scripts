#!/bin/bash

set -x

if [ -f ~/verify_restore/restore_utils.sh ]; then
    . ~/verify_restore/restore_utils.sh
else
    . ./skip_commit/verify_cdc/restore_run/remote_scripts/restore_utils.sh
fi

# Logical flow of operations

/opt/rubrik/deployment/cluster.sh localcluster exec all 'ls -lh /mnt/wwn-f*/internal/cass*/cdc_data'

DisableCDC

sleep 10

log_milestone "disabled CDC before taking second backup"

/opt/rubrik/deployment/cluster.sh localcluster exec all 'ls -lh /mnt/wwn-f*/internal/cass*/cdc_data'

EnablePublisherAndValidator

log_milestone "enabled Publisher before taking second backup"

echo "Executing 'rkcl exec all 'sudo systemctl start rk-cdc_data_publisher.service'..."
/opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl start rk-cdc_data_publisher.service'
return_code=$?
if [ $return_code -ne 0 ]; then
    echo "Failed to start rk-cdc_data_publisher.service. Return code: $return_code"
    exit $return_code
fi

log_milestone "starting second backup using BACK_UP_COCKROACH_GLOBAL"

run_backup_and_check_job_status

log_milestone "done with second backup + restore using BACK_UP_COCKROACH_GLOBAL"



# Disable backup jobs
# /usr/bin/cqlsh -k sd -e "update job_instance set skip=true where job_id='BACK_UP_COCKROACH_GLOBAL'"
# /usr/bin/cqlsh -k sd -e "select job_id, instance_id, status, skip, is_disabled from job_instance where job_id='BACK_UP_COCKROACH_GLOBAL'"

# Call the cleanup function
Cleanup

set +x
