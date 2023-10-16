import argparse
import json

import common

def is_timestamp_within_interval(data, table_name, timestamp):
    for nested_list in data:
        for entry in nested_list:
            if entry["DataChunk"]["TableName"] == table_name:
                start_time = entry["DataChunk"]["StartTS"]["WallTime"]
                end_time = entry["DataChunk"]["ResolvedTS"]["WallTime"]
                if start_time <= timestamp <= end_time:
                    return True, entry
    return False, None

def min_max_resolved_timestamp(data, table_name):
    min_ts = float('-inf')
    max_ts = float('inf')
    for nested_list in data:
        for entry in nested_list:
            if entry["DataChunk"]["TableName"] == table_name:
                start_time = entry["DataChunk"]["StartTS"]["WallTime"]
                end_time = entry["DataChunk"]["ResolvedTS"]["WallTime"]

                if min_ts > start_time:
                    min_ts = start_time

                if max_ts < end_time:
                  max_ts = end_time
    return min_ts, max_ts

if __name__ == "__main__":
    
    input_file = "skip_commit/verify_cdc/restore_debug/debug_filters/results/coordinator_job_list.json"

    with open(input_file, "r") as file:
        data = json.load(file)

    # Example: Find if timestamp 1690053663450000000 lies within the interval for table "files_perf_test_only"
    table_name = "files_perf_test_only"
    within, matched_data = is_timestamp_within_interval(data, table_name, common.sample_ts)
    print("TS: {} found : {}".format(common.sample_ts, within))
    print("matched_data : ", matched_data)

    if not within:
        (min_ts, max_ts) = min_max_resolved_timestamp(data, table_name)
        print("(min_ts, max_ts) : ", (min_ts, max_ts))
