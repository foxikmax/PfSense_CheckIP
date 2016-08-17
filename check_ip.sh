#!/usr/local/bin/bash

INTERFACE='pppoe0'
FILE_LOCK='/tmp/checkip'

validateIP(){
	 local ip=$1
	 validIP=0
	 
	 if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
		&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		validIP=1
	fi
}

valid_class_ip(){
	local ip=$1
	validClassIP=1

	OIFS=$IFS
	IFS='.'
	ip=($ip)
	IFS=$OIFS
	
	if [[ ${ip[0]} == 10 ||  ${ip[0]} == 127 || \
	     ( ${ip[0]} == 100 && ${ip[1]} -le 127 && ${ip[1]} -ge 64 ) || \
	     ( ${ip[0]} == 172 && ${ip[1]} -le 31 && ${ip[1]} -ge 16 ) || \
		 ( ${ip[0]} == 192 && ${ip[1]} == 168 ) ]]; then
		validClassIP=0
	fi
}

if [ -f $FILE_LOCK ]
then
	logger "CHECK_IP: Process blocked";
	exit
fi

touch /tmp/checkip

while [ 1 ]; do
    ip=`ifconfig $INTERFACE | grep 'inet' | cut -d: -f2 | awk '{print $2}' | tr -d '[[:space:]]'`
	validateIP $ip
	if [[ $validIP == 0 ]];then
		logger "CHECK_IP: Incorrect IP Address ($ip)";
		sleep 5
	else
		#logger "CHECK_IP: IP is a Correct ($ip)";
		valid_class_ip $ip
		if [[ $validClassIP == 0 ]];then
			logger "CHECK_IP: wan restart ($ip)";
			/usr/local/sbin/pfSctl -c 'interface reload wan'
			sleep 60
		else
			rm $FILE_LOCK
			break
		fi
	fi
done 
