#!/bin/bash

. ./skip_commit/common/bodega_order_details.sh

echo "bodega_ips: ${bodega_ips}"

#IFS="," read -a myarray <<< ${bodega_ips}
IFS="," read -a bodega_ips_arr <<<$bodega_ips
echo "bodega_ips_arr: ${bodega_ips_arr[@]}"

file_to_copy=$1

for ip in "${bodega_ips_arr[@]}"; do
        echo $ip
        ssh-keyscan $ip >>~/.ssh/known_hosts
        ssh -i $pem_file ubuntu@$ip 'mkdir -p /home/ubuntu/tushar_upload/'
        scp -i $pem_file $file_to_copy ubuntu@$ip:/home/ubuntu/tushar_upload/      #       ~/tushar_bin/cockroach       # /usr/local/bin/cockroach
done
