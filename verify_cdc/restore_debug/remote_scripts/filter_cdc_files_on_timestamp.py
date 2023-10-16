import os
import json
import argparse
import shutil
import gzip

def process_json(input_file, output_file, threshold):
    with gzip.open(input_file, 'rt') as f_in, open(output_file, 'w') as f_out:
        for line in f_in:
            data = json.loads(line)
            if 'IsDeleted' not in data:
                f_out.write(line)
            else:
                wall_time = data['Timestamp']['WallTime']
                if wall_time >= threshold:
                    f_out.write(line)

def main(src_dir, backup_dir, threshold):
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)

    for filename in os.listdir(src_dir):
        if filename.endswith('_data.json.gz'):
            input_file = os.path.join(src_dir, filename)
            backup_file = os.path.join(backup_dir, filename)

            print("Moving %s to %s" % (input_file, backup_file))
            shutil.move(input_file, backup_file)

            filtered_file = os.path.join(src_dir, filename.replace('_data.json.gz', '_data.json'))

            print("Filtering %s to %s" % (backup_file, filtered_file))

            process_json(backup_file, filtered_file, threshold)

            print("Gzipping %s" % (filtered_file))
            os.system("gzip {}".format(filtered_file))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Filter and transform JSON files.')
    parser.add_argument('src_dir', type=str, help='Path to the directory containing input JSON files')
    parser.add_argument('backup_dir', type=str, help='Path to the directory for backup of original files')
    # parser.add_argument('--threshold', type=int, default=0, help='Timestamp threshold for filtering IsDeleted entries')
    parser.add_argument('-t', '--threshold', type=int, default=0, help='Timestamp threshold for filtering IsDeleted entries')


    args = parser.parse_args()
    main(args.src_dir, args.backup_dir, args.threshold)
