import argparse
import json

import common

def find_time_interval(json_data, table_name, timestamp):
    for entry in json_data:
        for data_chunk in entry['DataChunks']:
            if data_chunk['TableName'] == table_name and data_chunk['StartTime'] <= timestamp <= data_chunk['EndTime']:
                return True, data_chunk
    return False, None


def min_max_resolved_timestamp(json_data, table_name):
    min_ts = float('-inf')
    max_ts = float('inf')

    for entry in json_data:
        for data_chunk in entry['DataChunks']:
            if data_chunk['TableName'] == table_name:
                start_time = data_chunk["StartTime"]
                end_time = data_chunk["EndTime"]

                if min_ts > start_time:
                    min_ts = start_time

                if max_ts < end_time:
                  max_ts = end_time
    
    return min_ts, max_ts


if __name__ == "__main__":

    input_file = "skip_commit/verify_cdc/restore_debug/debug_filters/results/scanner_chunks.json"

    with open(input_file, "r") as file:
        data = json.load(file)

    # Example: Find if timestamp 1690053663450000000 lies within the interval for table "files_perf_test_only"
    table_name = "files_perf_test_only"
    within, matched_data = find_time_interval(data, table_name, common.sample_ts)

    print("TS: {} found : {}".format(common.sample_ts, within))
    print("matched_data : ", matched_data)

    if not within:
        (min_ts, max_ts) = min_max_resolved_timestamp(data, table_name)
        print("(min_ts, max_ts) : ", (min_ts, max_ts))
