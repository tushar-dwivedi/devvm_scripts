
pem_file="./deployment/ssh_keys/ubuntu.pem"

export default_bodega_order_id='' # 6 nodes cluster for restore testing

if [ -z "$bodega_order_id" ]; then
  echo "No bodega_order_id set in the env, exiting"
  exit 1
  # export bodega_order_id=$default_bodega_order_id
else
  echo "bodega_order_id set in the env as $bodega_order_id, using it."
fi

if [[ "$bodega_order_id" == "stress" ]]; then
	#export bodega_ips='10.0.115.130,10.0.115.131,10.0.115.132,10.0.115.133'	# stress cluster
	export bodega_ips='10.0.211.238,10.0.211.239,10.0.211.240,10.0.211.241,10.0.211.143,10.0.211.144,10.0.211.145,10.0.211.146'	# stress cluster (8 nodes)
	#export bodega_ips='10.0.100.4,10.0.100.5,10.0.100.6,10.0.100.7'		# fury rktest_B-100144
elif [[ "$bodega_order_id" == "fury" ]]; then
	export bodega_ips='10.0.115.130,10.0.115.131,10.0.115.132,10.0.115.133'
elif [[ "$bodega_order_id" == "mds1" ]]; then
	export bodega_ips='10.0.37.7,10.0.36.244,10.0.32.154,10.0.34.243'
elif [[ "$bodega_order_id" == "mds2" ]]; then
        export bodega_ips='10.0.34.19,10.0.39.19,10.0.33.113,10.0.38.6'
else
	export bodega_ips=$(./lab/bin/bodega consume order $bodega_order_id | grep -i 'ipv4:' | awk -F": " '{print $2 ","}' ORS='')
fi

bodega_ips=${bodega_ips%,}
# echo "bodega_ips: ${bodega_ips}"

# echo $bodega_ips

#IFS="," read -a myarray <<< ${bodega_ips}
IFS="," read -a bodega_ips_arr <<<$bodega_ips

echo "using bodega order: $bodega_order_id"
echo "bodega_ips_arr: ${bodega_ips_arr[@]}"

first_node=${bodega_ips_arr[0]}
