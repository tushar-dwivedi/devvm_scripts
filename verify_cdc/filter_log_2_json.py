import sys
import json
import re

# Regular expression pattern to match the event and filters values
#pattern = r'event=({.*?}), filters=(\[.*?\])'
pattern = r'.*event=({.*?}),filters=(\[.*?\]).*'
#pattern = r',event=({[^}]*}), filters=(\[.*?\])'


# Function to process the log file
def process_log_file(file):
    # Initialize an empty list to store the converted entries
    entries = []

    # Read the log file line by line
    for line in file:
        # Remove leading and trailing whitespace
        line = line.strip()
        # print("line:", line)


        # Extract the event and filters strings using regular expressions
        match = re.search(pattern, line)
        # print(match)
        if match:
            event_str = match.group(1)
            filters_str = match.group(2)

            # print("event_str:", event_str)
            # print("filters_str:", filters_str)

            unescaped_event_str = event_str.replace('\\\\', '\\')
            unescaped_filters_str = filters_str.replace('\\\\', '\\')

            event_str = unescaped_event_str.replace('\\"', '"')
            filters_str = unescaped_filters_str.replace('\\"', '"')

            # unescaped_event_str = bytes(event_str, 'utf-8').decode('unicode_escape')
            # unescaped_filters_str = bytes(filters_str, 'utf-8').decode('unicode_escape')
            # print("unescaped_event_str:", unescaped_event_str)
            # print("unescaped_filters_str:", unescaped_filters_str)

            # print("event_str 1:", event_str)
            # print("filters_str 1:", filters_str)

            # Unescape the event and filters strings
            event_unescaped = json.loads( event_str )
            filters_unescaped = json.loads( filters_str )
            #event_unescaped = json.loads("{" + event_str + "}")
            #filters_unescaped = json.loads("[" + filters_str + "]")

            # Create the entry dictionary
            entry = {
                'event': event_unescaped,
                'filters': filters_unescaped
            }

            # Append the entry to the list
            entries.append(entry)

    return entries

# Check if a filename is provided as an argument
if len(sys.argv) > 1:
    filename = sys.argv[1]

    # Open the file for reading
    with open(filename, 'r') as file:
        entries = process_log_file(file)
else:
    # Read input from stdin
    entries = process_log_file(sys.stdin)

# Write the converted entries to stdout
json.dump(entries, sys.stdout, indent=2)
