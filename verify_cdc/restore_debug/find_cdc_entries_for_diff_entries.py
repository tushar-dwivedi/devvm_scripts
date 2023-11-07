import json
import sys

# Check if the correct number of command-line arguments are provided
if len(sys.argv) != 4:
    print("Usage: python script.py file1.json file2.json output.json")
    sys.exit(1)

database_diff_file = sys.argv[1]
cdc_data_file = sys.argv[2]
output_file = sys.argv[3]
mismatched_entries_file = sys.argv[4]


def process_cdc_entry(data_dict, item, output_data, mismatched_entries_file):

    prefix = ""
    if mismatched_entries_file:
        prefix = "t1_"

    key = (item[prefix+'token__uuid'], item[prefix+'uuid'], item[prefix+'stripe_id'])
    grep_cmd_1 = """grep '{}' """.format(item[prefix+'token__uuid'])
    grep_cmd_2 = """grep '{}' | grep '{}' """.format(item[prefix+'uuid'], item[prefix+'stripe_id'])
    db_query = "select * from sd.files_perf_test_only where token__uuid={} and uuid='{}' and stripe_id={}".format(item['token__uuid'], item['uuid'], item['stripe_id']),

    if key in data_dict:
        primary_key_hash = data_dict[key]['Key']
        matched_entry = {
            'Key': primary_key_hash,
            'PK': {
                'token__uuid': item[prefix+'token__uuid'],
                'uuid': item[prefix+'uuid'],
                'stripe_id': item[prefix+'stripe_id'],
            },
            'operations': data_dict[key]['operations'],
            'check_orig_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-f*/internal/cassandra_snapshots/cdc_data/*", grep_cmd_2),
            'check_dedup_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-f*/internal/cassandra_snapshots/sharded/*", grep_cmd_2),
            # 'check_dedup_csv_snapshot_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-f*/internal/cass*/*-BACK_UP_COCKROACH_GLOBAL-*/*files_perf_test_only.csv.gz", grep_cmd_2),
            'db_query': db_query,
            # 'grep_logs_command': "z{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/*", grep_cmd_2),
            # 'grep_logs_commands_1': "{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/current ", grep_cmd_2),
            # 'grep_logs_command_key': "zgrep {} {}".format(primary_key_hash, "/var/log/cdc_data_publisher/*"),
            # 'grep_logs_commands_1_key': "grep {} {}".format(primary_key_hash, "/var/log/cdc_data_publisher/current ")
        }


    else:
        matched_entry = {
            'Key': 'NULL',
            'PK': {
                'token__uuid': item[prefix+'token__uuid'],
                'uuid': item[prefix+'uuid'],
                'stripe_id': item[prefix+'stripe_id'],
            },
            'operations': [],
            'check_orig_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-f*/internal/cassandra_snapshots/cdc_data/*", grep_cmd_2),
            'check_dedup_cdc_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-f*/internal/cassandra_snapshots/sharded/*", grep_cmd_2),
            # 'check_dedup_csv_snapshot_command': "sudo z{} {} | {}".format(grep_cmd_1, "/mnt/wwn-f*/internal/cass*/*-BACK_UP_COCKROACH_GLOBAL-17/*files_perf_test_only.csv.gz", grep_cmd_2),
            'db_query': db_query,
            # 'grep_logs_commands': "z{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/*", grep_cmd_2),
            # 'grep_logs_commands_1': "{} {} | {}".format(grep_cmd_1, "/var/log/cdc_data_publisher/current ", grep_cmd_2)
        }

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
        process_cdc_entry(data_dict, entry, output_data, mismatched_entries_file)
    except Exception as e:
        print("exception while processing entry:{}, exception: {}".format(entry, e))

# Write the output data to the specified output file
with open(output_file, 'w') as file:
    json.dump(output_data, file, indent=2)
