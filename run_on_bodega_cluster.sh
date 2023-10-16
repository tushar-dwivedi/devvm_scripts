#!/bin/bash

. ./skip_commit/common/bodega_order_details.sh

ip=${bodega_ips_arr[0]}

ssh -i $pem_file ubuntu@$ip "bash -s" <./skip_commit/capture_stats.sh
return_value=$?

if [[ $return_value != 0 ]]; then
    echo "An error occurred while running prepare_initial_data_for_restore. Exiting the script."
    exit 1
fi
