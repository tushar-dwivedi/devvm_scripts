#!/bin/bash

set -x

if [ -f ~/verify_restore/restore_utils.sh ]; then
    . ~/verify_restore/restore_utils.sh
else
    . ./skip_commit/verify_cdc/restore_run/remote_scripts/restore_utils.sh
fi

log_milestone "starting first backup using BACK_UP_COCKROACH_GLOBAL"

# Run the initial status check
run_backup_and_check_job_status

# Loop until the status changes from "RUNNING" to "SUCCEEDED"
while [[ $? -eq 1 ]]; do
    sleep 10
    check_job_status
done

log_milestone "done with first backup using BACK_UP_COCKROACH_GLOBAL"

EnableCDC

log_milestone "enabled CDC after taking first backup"

sleep 20

/opt/rubrik/deployment/cluster.sh localcluster exec all 'sudo systemctl start cqlproxy'
/opt/rubrik/deployment/cluster.sh localcluster exec all "sdservice.sh '*' start"

sleep 120

# Additional commands can be added here

#sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "insert into sd.files_perf_test_only select * from sd.files_perf_test_only_bkp"
#sudo /opt/rubrik/src/scripts/cockroachdb/rkcockroach sql -e "insert into sd.files_perf_test_only__static select * from sd.files_perf_test_only__static_bkp"

# sleep 30

# End of the script
set +x
