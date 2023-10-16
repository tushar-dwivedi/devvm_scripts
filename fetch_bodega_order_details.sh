#!/bin/bash

order_id=''

if [ -z "$1" ]; then
  echo "No order_id \$1 provided on cmd line, picking  $bodega_order_id from env"
  order_id=$bodega_order_id
else
  echo "using order_id : $1"
  order_id=$1
fi

order_details=$(./lab/bin/bodega consume order $order_id)

# echo "$order_details"

echo "$order_details" | grep -i 'ipv4:' | awk -F": " '{print "\"" $2 "\","}' ORS=' '
echo
echo "$order_details" | grep -i 'ipv4:' | awk -F": " '{print $2 ","}' ORS=''
echo
echo "$order_details" | grep 'Filename' | grep -i 'ipv4' | awk -F": " '{print $2}' ORS=''
echo
