#!/bin/bash

pem_file="~/Documents/projects/callisto/sdmain/deployment/ssh_keys/ubuntu.pem"

. ./skip_commit/common/bodega_order_details.sh
#echo "bodega_ips: ${bodega_ips}"

#IFS="," read -a myarray <<< ${bodega_ips}
IFS="," read -a bodega_ips_arr <<<$bodega_ips
#echo "bodega_ips_arr: ${bodega_ips_arr[@]}"

ip=${bodega_ips_arr[0]}

ssh-keyscan $ip >>~/.ssh/known_hosts

#ssh -i $pem_file ubuntu@$ip "zcat /var/log/cdc_data_publisher/* | grep 'Waiting for buffer at index'"

#ssh -i $pem_file ubuntu@$ip "cat /home/ubuntu/temp/sample_log | sed -E 's/^.*\"epochSecond\": ([0-9]+).*metric <(.*)>.*/\1 \2/' | awk '{print strftime(\"%Y-%m-%d %H:%M:%S\", $1),$2}' | sed 's/=/ /g'
ssh -i ~/Documents/projects/callisto/sdmain/deployment/ssh_keys/ubuntu.pem ubuntu@10.0.115.2 "cat /home/ubuntu/temp/sample_log" | sed -E 's/^.*"epochSecond": ([0-9]+).*metric <(.*)>.*/\1 \2/' | awk '{print strftime("%Y-%m-%d-%H:%M:%S", $1),$2}' | sed 's/=/ /g' | awk '{sum[$1]+=$3; count[$1]++; if ($3>max[$1]) max[$1]=$3} END {for (i in sum) {print i, sum[i]/count[i], max[i]}}' >~/gnuplot_stuff/data/tmp.txt
