#!/bin/bash

. ./devvm_scripts/common/bodega_order_details.sh

ip=${bodega_ips_arr[0]}

ssh -i $pem_file ubuntu@$ip "bash -s" <./devvm_scripts/capture_stats.sh
return_value=$?

if [[ $return_value != 0 ]]; then
    echo "An error occurred while running prepare_initial_data_for_restore. Exiting the script."
    exit 1
fi
