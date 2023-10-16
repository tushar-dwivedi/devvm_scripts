import json
import sys
from typing import Dict, Any, List, Tuple

# Step 1: Create the checkpointMem dictionary
checkpointMem: Dict[str, Dict[str, List[Tuple[int, int]]]] = {}

# Method to process checkpoint entries
def process_checkpoint_entry(entry: Dict[str, Any]) -> None:
    start_key = entry.get('StartKey')
    end_key = entry.get('EndKey')
    start_ts = entry.get('StartTS')
    resolved_ts = entry.get('ResolvedTS')
    table_name = entry.get('TableName')

    if table_name not in checkpointMem:
        checkpointMem[table_name] = {}

    key = f"{start_key}-{end_key}"

    if key in checkpointMem[table_name]:
        checkpointMem[table_name][key].append((start_ts, resolved_ts))
    else:
        checkpointMem[table_name][key] = [(start_ts, resolved_ts)]


# Method to process data entries
def process_data_entry(entry: Dict[str, Any]) -> Tuple[bool, str]:
    key_value = entry.get('Key')
    timestamp = entry.get('Timestamp')
    table_name = entry.get('TableName')

    if table_name not in checkpointMem:
        print(f"Invalid data entry(checkpoint not seen with this table): {entry}")
        return False, "table_not_seen"
    
    for key, timestamps in checkpointMem[table_name].items():
        start_key, end_key = key.split('-')
        if start_key <= key_value < end_key:
            for timestamp_tuple in timestamps:
                (start_ts, resolved_ts) = timestamp_tuple
                if start_ts <= timestamp < resolved_ts:
                    return True, "all_good"
            # print(f"Key:{key_value}:{timestamp} falls in [{start_key}:{end_key}), but {timestamp} doesn't fall in [{start_ts}:{resolved_ts})")
            return False, "timestamp_mismatch"
    print(f"Key:{key_value}:{timestamp} doesn't fall in any seen checkpoints")
    return False, "range_mismatch"


# Step 2: Read the JSON file entry by entry
file_path: str = sys.argv[1]
out_file_path: str = sys.argv[2]


with open(out_file_path, 'w') as out_file, open(file_path, 'r') as json_file:
    entries: List[Dict[str, Any]] = json.load(json_file)

    for entry in entries:
        entry_type: str = entry.get('EntryType')

        if entry_type == 'checkpoint':
            process_checkpoint_entry(entry)
        elif entry_type == 'data':
            correct, cause = process_data_entry(entry)
            if not correct:
                entry["cause"] = cause
                out_file.write(json.dumps(entry)+"\n")
