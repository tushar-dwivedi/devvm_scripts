#!/bin/bash

# Function to count regex matches
count_regex_matches() {
  local regex="$1"
  local file="$2"
  local file_type="$3"
  local is_gzip="$4"

  case $file_type in
    "CMD")
    "$regex" "$file" | wc -l
      ;;
    "GREP")
      if [[ $file == *.gz ]] || [[ $is_gzip == "gzip" ]]; then
        zgrep -o "$regex" "$file" | wc -l
      else
        grep -o "$regex" "$file" | wc -l
      fi
      ;;
    "JSON")
      if [[ $file == *.gz ]] || [[ $is_gzip == "gzip" ]]; then
        zcat "$file" | jq -s | jq -r --arg regex "$regex" 'select(test($regex))' | wc -l
      else
        cat "$file" | jq -s | jq -r --arg regex "$regex" 'select(test($regex))' | wc -l
      fi
      ;;
    *)
      echo "Unsupported file type: $file_type"
      exit 1
      ;;
  esac
}

# Function to display matching values from a specific file
display_matching_values() {
  local regex="$1"
  local file="$2"
  local file_type="$3"
  local is_gzip="$4"

  case $file_type in
    "CMD")
    "$regex" "$file"
      ;;
    "GREP")
      if [[ $file == *.gz ]] || [[ $is_gzip == "gzip" ]]; then
        zgrep -o "$regex" "$file"
      else
        grep -o "$regex" "$file"
      fi
      ;;
    "JSON")
      if [[ $file == *.gz ]] || [[ $is_gzip == "gzip" ]]; then
        zcat "$file" | jq -s | jq -r --arg regex "$regex" 'select(test($regex))'
      else
        cat "$file" | jq -s | jq -r --arg regex "$regex" 'select(test($regex))'
      fi
      ;;
    *)
      echo "Unsupported file type: $file_type"
      exit 1
      ;;
  esac
}

# Read regex expressions and file paths from file1
while IFS=, read -r file regex file_type is_gzip; do
  # Remove leading/trailing spaces from file path, regex, and file type
  file=$(echo "$file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  regex=$(echo "$regex" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  file_type=$(echo "$file_type" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  is_gzip=$(echo "$is_gzip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')


  # Check if file path, regex, file type, and gzip parameter are non-empty
  if [[ -n $file && -n $regex && -n $file_type && -n $is_gzip ]]; then
    # Count matches for each regex
    count=$(count_regex_matches "$regex" "$file" "$file_type" "$is_gzip")
    echo "Regex: $regex | File type: $file_type | Matches: $count"

    # Ask if the user wants to display matching values for this regex
    read -rp "Do you want to display matching values for this regex (y/n)? " choice
    if [[ $choice == [yY] ]]; then
      display_matching_values "$regex" "$file" "$file_type" "$is_gzip"
    fi
  fi

done < $1
