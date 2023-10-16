
pem_file="./deployment/ssh_keys/ubuntu.pem"

export default_bodega_order_id='' # 6 nodes cluster for restore testing

if [ -z "$bodega_order_id" ]; then
  echo "No bodega_order_id set in the env, exiting"
  exit 1
  # export bodega_order_id=$default_bodega_order_id
else
  echo "bodega_order_id set in the env as $bodega_order_id, using it."
fi

if [[ "$bodega_order_id" == "other" ]]; then
	#export bodega_ips='10.0.115.2,10.0.115.3,10.0.115.4,10.0.115.5,10.0.115.130,10.0.115.131,10.0.115.132,10.0.115.133'	# stress cluster
	#export bodega_ips='10.0.100.4,10.0.100.5,10.0.100.6,10.0.100.7'		# fury rktest_B-100144
	export bodega_ips='10.0.37.122'
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
