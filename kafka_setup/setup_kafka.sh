#!/bin/bash

. ./devvm_scripts/common/bodega_order_details.sh

echo "bodega_ips: ${bodega_ips}"

#IFS="," read -a myarray <<< ${bodega_ips}
IFS="," read -a bodega_ips_arr <<<$bodega_ips
echo "bodega_ips_arr: ${bodega_ips_arr[@]}"

config_path="/home/ubuntu/kafka_cfg"
upload_dir="/home/ubuntu/upload"
kafka_bin_path="/opt/"
kafka_data_dir="/var/log/kafka"

# Common configuration values
common_config=""

# Generate controller.quorum.voters value
controller_quorum_voters=""
for i in "${!bodega_ips_arr[@]}"; do
	controller_quorum_voters+="$((i + 1))@${bodega_ips_arr[$i]}:9093,"
done
controller_quorum_voters=${controller_quorum_voters%,} # Remove trailing comma

# echo "controller_quorum_voters:$controller_quorum_voters"

for i in "${!bodega_ips_arr[@]}"; do

	ip=${bodega_ips_arr[$i]}

	echo $ip
	ssh-keyscan $ip >>~/.ssh/known_hosts

	ssh -i $pem_file ubuntu@$ip "rm -rf ${upload_dir}"

	ssh -i $pem_file ubuntu@$ip "mkdir -p ${config_path}"
	ssh -i $pem_file ubuntu@$ip "mkdir -p ${upload_dir}"

	ssh -i $pem_file ubuntu@$ip "sudo rm -rf ${kafka_data_dir}"
	ssh -i $pem_file ubuntu@$ip "sudo mkdir -p ${kafka_data_dir}"
	ssh -i $pem_file ubuntu@$ip "sudo chown -R ubuntu:ubuntu ${kafka_data_dir}"

	config_file="./devvm_scripts/kafka_setup/config_$i.properties"

	# write common config
	echo "$common_config" >$config_file

	# Append configurations
	echo "process.roles=broker,controller" >$config_file
	echo "node.id=$((i + 1))" >>$config_file
	echo "log.dirs=${kafka_data_dir}" >>$config_file
	echo "" >>$config_file
	echo "controller.quorum.voters=$controller_quorum_voters" >>$config_file
	echo "controller.listener.names=CONTROLLER" >>$config_file
	echo "" >>$config_file
	echo "listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL" >>$config_file
	echo "listeners=PLAINTEXT://${ip}:9092,CONTROLLER://${ip}:9093" >>$config_file
	echo "advertised.listeners=PLAINTEXT://${ip}:9092" >>$config_file
	echo "" >>$config_file
	echo "num.partitions=4" >>$config_file
	echo "delete.topic.enable=true" >>$config_file

	remote_config_file=$config_path/kafka_server.properties

	ssh -i $pem_file ubuntu@$ip "rm -f $remote_config_file"
	scp -i $pem_file $config_file "ubuntu@$ip:$remote_config_file"

	scp -i $pem_file ./devvm_scripts/kafka_setup/kafka.service "ubuntu@$ip:$upload_dir/"
	ssh -i $pem_file ubuntu@$ip "sudo cp -f ${upload_dir}/kafka.service /etc/systemd/system/kafka.service"

	ssh -i $pem_file ubuntu@$ip "rm -rf $upload_dir/kafka"
	ssh -i $pem_file ubuntu@$ip "sudo rm -rf ${kafka_bin_path}/kafka"

	scp -i $pem_file -r ./devvm_scripts/kafka_setup/kafka "ubuntu@$ip:$upload_dir/"
	ssh -i $pem_file ubuntu@$ip "sudo cp -rf ${upload_dir}/kafka ${kafka_bin_path}/"
	ssh -i $pem_file ubuntu@$ip "sudo chown -R ubuntu:ubuntu ${kafka_bin_path}/kafka"

	ssh -i $pem_file ubuntu@$ip "${kafka_bin_path}/kafka/bin/kafka-storage.sh format --config $remote_config_file --cluster-id 'GK6FXIMSQrmpC1j4q3AZTA' --ignore-formatted"

	ssh -i $pem_file ubuntu@$ip "sudo systemctl daemon-reload"

	ssh -i $pem_file ubuntu@$ip "sudo systemctl stop kafka"
	ssh -i $pem_file ubuntu@$ip "sudo systemctl start kafka"
	ssh -i $pem_file ubuntu@$ip "sudo systemctl enable kafka"

done
