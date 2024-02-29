import json
import sys

# Check if the correct number of command-line arguments are provided
if len(sys.argv) != 4:
    print("Usage: python script.py file1.json file2.json output.json")
    sys.exit(1)

database_diff_file = sys.argv[1]
cdc_data_file = sys.argv[2]
output_file = sys.argv[3]


def process_cdc_entry(data_dict, item, output_data):
    key = (item['token__uuid'], item['uuid'], item['stripe_id'])
    grep_cmd_1 = """grep '{}' """.format(item['token__uuid'])
    grep_cmd_2 = """grep '{}' | grep '{}' """.format(item['uuid'], item['stripe_id'])
    db_query = "select * from sd.files_perf_test_only where token__uuid={} and uuid='{}' and stripe_id={}".format(item['token__uuid'], item['uuid'], item['stripe_id']),

    if key in data_dict:
        primary_key_hash = data_dict[key]['Key']
        matched_entry = {
            'Key': primary_key_hash,
            'PK': {
                'token__uuid': item['token__uuid'],
                'uuid': item['uuid'],
                'stripe_id': item['stripe_id'],
            },
            'operations': data_dict[key]['operations'],
            'check_orig_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-*/internal/cassandra_snapshots/cdc_data/*", grep_cmd_2),
            'check_dedup_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-*/internal/cassandra_snapshots/sharded/*", grep_cmd_2),
            # 'check_dedup_csv_snapshot_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-*/internal/cass*/*-BACK_UP_COCKROACH_GLOBAL-*/*files_perf_test_only.csv.gz", grep_cmd_2),
            'db_query': db_query,
            # 'grep_logs_command': "z{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/*", grep_cmd_2),
            # 'grep_logs_commands_1': "{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/current ", grep_cmd_2),
            # 'grep_logs_command_key': "zgrep {} {}".format(primary_key_hash, "/var/log/cdc_data_publisher/*"),
            # 'grep_logs_commands_1_key': "grep {} {}".format(primary_key_hash, "/var/log/cdc_data_publisher/current ")
        }
        if "cdc_event_timestamp_d984f2ededb" in item.keys():
            matched_entry['cdc_event_timestamp_d984f2ededb'] = item['cdc_event_timestamp_d984f2ededb']

    else:
        matched_entry = {
            'Key': 'NULL',
            'PK': {
                'token__uuid': item['token__uuid'],
                'uuid': item['uuid'],
                'stripe_id': item['stripe_id'],
            },
            'operations': [],
            'check_orig_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-*/internal/cassandra_snapshots/cdc_data/*", grep_cmd_2),
            'check_dedup_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-*/internal/cassandra_snapshots/sharded/*", grep_cmd_2),
            # 'check_dedup_csv_snapshot_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-*/internal/cass*/*-BACK_UP_COCKROACH_GLOBAL-17/*files_perf_test_only.csv.gz", grep_cmd_2),
            'db_query': db_query,
            # 'grep_logs_commands': "z{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/*", grep_cmd_2),
            # 'grep_logs_commands_1': "{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/current ", grep_cmd_2)
        }
        # if "cdc_event_timestamp_d984f2ededb" in item.keys():
        #     matched_entry['cdc_event_timestamp_d984f2ededb'] = item['cdc_event_timestamp_d984f2ededb']
    output_data.append(matched_entry)


# Read data from the second file and create a dictionary
with open(cdc_data_file, 'r') as file:
    data2 = json.load(file)

data_dict = {}
for item in data2:
    key = (str(item['PK']['token__uuid']), item['PK']['uuid'], str(item['PK']['stripe_id']))
    data_dict[key] = {
        'Key': item['Key'],
        'operations': item['operations']
    }

# Read data from the first file and create the output data
output_data = []
with open(database_diff_file, 'r') as file:
    data1 = json.load(file)


for entry in data1:
    try:
        process_cdc_entry(data_dict, entry, output_data)
    except Exception as e:
        print("exception while processing entry:{}, exception: {}".format(entry, e))

# Write the output data to the specified output file
with open(output_file, 'w') as file:
    json.dump(output_data, file, indent=2)
