#!/usr/bin/env python

import json
import sys

def convert_int_to_str(data):
    if isinstance(data, int):
        return str(data)
    elif isinstance(data, list):
        return [convert_int_to_str(item) for item in data]
    elif isinstance(data, dict):
        return {key: convert_int_to_str(value) for key, value in data.items()}
    else:
        return data

def main():

    # print(sys.argv)

    file_handle = None
    output_file = None
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else None
        file_handle = open(input_file, 'r')
    else:
        file_handle = sys.stdin


    input_data = file_handle.readlines()
    file_handle.close()
    converted_entries = []

    for line in input_data:
        try:
            json_entry = json.loads(line)
        # Convert integers to strings recursively
            converted_entry = convert_int_to_str(json_entry)
            converted_entries.append(converted_entry)
        except Exception as ex:
            print("invalid line:{}, ex: {}".format(line, ex))
            # print(f"Error: Invalid JSON entry: {line}")

    try:
        if output_file:
            with open(output_file, 'w') as file:
                json.dump(converted_entries, file, indent=2)
        else:
            json.dump(converted_entries, sys.stdout, indent=2)
    except Exception as ex:
            print("invalid converted_entries, ex: {}".format(ex))

if __name__ == "__main__":
    main()
