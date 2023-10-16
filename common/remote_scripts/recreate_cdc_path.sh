#!/bin/bash

set -x
found_path=$(find /mnt/wwn-f*/internal/cassandra_snapshots -type d -name "cdc_data" -print -quit)
cdc_store_path=$(echo "$found_path" | sed 's/\/cdc_data$//')
mkdir -p /var/lib/cockroachdb/rubrik_cdc/
echo "{\"cdc_store_path\": \"$cdc_store_path\"}" >/var/lib/cockroachdb/rubrik_cdc/cdc_store_path
cat /var/lib/cockroachdb/rubrik_cdc/cdc_store_path
set +x
