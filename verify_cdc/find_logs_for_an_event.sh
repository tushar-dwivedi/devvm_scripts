#!/bin/bash

# Read the first entry from the JSON file
entry=$(jq -c '.[0]' ./skip_commit/verify_cdc/db_result/extra_entries_in_restored_table_files_perf_test_only.json)

# Extract the values of token__uuid, uuid, and stripe_id
token__uuid=$(jq -r '.token__uuid' <<<"$entry")
uuid=$(jq -r '.uuid' <<<"$entry")
stripe_id=$(jq -r '.stripe_id' <<<"$entry")

# Form the shell command with the extracted values
command="zgrep '*' | grep '$token__uuid' | grep '$uuid' | grep '$stripe_id'"

/opt/rubrik/deployment/cluster.sh localcluster exec all 'bash -c "grep -v UffService /var/lib/rubrik/iptables/rules.v4 > /tmp/rules.v4; cat /tmp/rules.v4 > /var/lib/rubrik/iptables/rules.v4"'

# Print the formed command
echo "$command"
