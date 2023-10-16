
def debug(msg): (msg | debug | empty), .;


def batch_of(n):
  . as $l
  # | debug(n)
  | [range(0;length/n) * n]
  | map($l[.:. + n]);

def crdb_records_json:
  split("\n")[:-1]    # this one fixes the issue of reading emply lines and failing
  | . as $d
  # | debug($d)
  | ($d | map(select(test("^-[ RECORD [0-9]+ ]$"))) | length) as $n
  # | debug($n)
  | $d
  | batch_of(($d | length / $n))
  | map(.
        | .[1:] 
        # | debug
        | map(.
              | gsub(" +"; " ")
              | split(" | ")
              | {key: .[0], value: .[1]})
        | from_entries);

def cdc_reduce_for_one_table(tableName):
  map(select(.TableName == tableName)) |
  map(
    if has("IsDeleted") then
      { Key: .Key, Timestamp: .Timestamp.WallTime, TableName: .TableName, EntryType: "data" }
    else
      { StartKey: .Span.Key, EndKey: .Span.EndKey, StartTS: .StartTS.WallTime, ResolvedTS: .ResolvedTS.WallTime, TableName: .TableName, EntryType: "checkpoint" }
    end
  );

def cdc_reduce_for_all_tables:
  map(
    if has("IsDeleted") then
      { Key: .Key, Timestamp: .Timestamp.WallTime, TableName: .TableName, EntryType: "data" }
    else
      { StartKey: .Span.Key, EndKey: .Span.EndKey, StartTS: .StartTS.WallTime, ResolvedTS: .ResolvedTS.WallTime, TableName: .TableName, EntryType: "checkpoint" }
    end
  );

def identify_db_operations:
{
  operation: ( if (.IsDeleted == "True") then "delete" else ( if (.ChangedCols | length) == (.Row | keys | length) then "insert" else "update" end ) end )
};

def group_by_pk:
  group_by(.Row.token__uuid, .Row.uuid, .Row.stripe_id) | map(sort_by(.Timestamp));


def analyze_entries:
  group_by_pk
  | .[] | {
      insert_count: map(select(.operation == "insert")) | length,
      update_count: map(select(.operation == "update")) | length,
      delete_count: map(select(.operation == "delete")) | length,
      #insert_with_multiple_updates_count: map(select(.operation == "insert")) | map(select(.operation == "update")) | length,
      #last_entry_delete_count: map(select(.operation == "delete")) | map(.[-1]) | length
    };

def sum_all_keys:
  map(to_entries)
      | add
      | group_by(.key)
      | map({
            key: .[0].key,
            value: map(.value) | add
        })
      | from_entries;

def highlight_operations:
  group_by(.Row.token__uuid, .Row.uuid, .Row.stripe_id) | map({
  Key: .[0].Key,
  PK: {
    "token__uuid": .[0].Row.token__uuid,
    "uuid": .[0].Row.uuid,
    "stripe_id": .[0].Row.stripe_id
  },
  operations: map({"operation" : (.operation), "timestamp": .Timestamp.WallTime}) | unique_by(.operation, .timestamp) | sort_by(.timestamp)
});


def find_underreplicated_events:
  group_by(.Row.token__uuid, .Row.uuid, .Row.stripe_id) | map({
  Key: .[0].Key,
  PK: {
    "token__uuid": .[0].Row.token__uuid,
    "uuid": .[0].Row.uuid,
    "stripe_id": .[0].Row.stripe_id
  },
  operations: map({"operation" : (.operation), "timestamp": .Timestamp.WallTime}) | group_by(.operation, .timestamp) | map({
    "operation": .[0].operation,
    "timestamp": .[0].timestamp,
    "count": length
  }) | sort_by(.timestamp)
});
