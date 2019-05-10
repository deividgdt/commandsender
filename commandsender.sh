#!/bin/bash
# dependencies: sshpass

# Command to send:
commandToSend="touch commandSender.txt"

# It is possible to use the next line in order to ask the user for the command to send
#read -p "Inserta el comando a enviar: " commandToSend

# Logs files
logOK="/root/commsenderlogOK.txt"
logKO="/root/commsenderlogKO.txt"

# The password for the devices
pass_dev='password'

commandSender() {
	# Main function that will send the commands stored in the $commandToSend variable to the devices
	if [[ ! $(ping -w1 $1 | grep "100% packet loss") ]]; then
		echo "DEV: $ip UP" 
		echo "$ip" >> $logOK;
		`sshpass -p $pass_dev ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $1 "$commandToSend" 2> /dev/null 1>&2`
	else
		echo "DEV: $ip DOWN" 
		echo "$ip" >> $logKO;
	fi
}

help() {
	# Function shows the help
	echo "-j [0-8000]"
	echo "	Number of maximum connections to generate in parallel. Any number between 0 and 8000"
	echo "	For example:"
	echo "		commandsender.sh -j 300"
	echo "	It will set 300 connections in parallel to 300 devices then"
	echo "	will wait until all the commands have been executed. Once the commands have been executed" 
	echo "	on the 300 devices, it will continue with the next 300."
	echo ""
	echo "	Value by default: -j 100"
	echo ""
	echo "-f filename"
	echo "	If you want to use a different filename change it using this option."
	echo "	For example:"
	echo "		commandsender.sh -f /tmp/ipaddresses.txt"
	echo ""
	echo "	Value by default: /root/ips.txt"
	echo ""
	echo "-h"
	echo "	Show the help."
	echo ""

}

# We get the values passed by the user
while getopts ":j:f:h" opt; do
	case "$opt" in
		j) maxJobs=$OPTARG							;;
		f) ipsFile=$OPTARG 							;;
		h) help; exit								;;
		*) echo "Invalid option. -$OPTARG"; exit				;;
	esac
done

# If the variable $ipsFile is null, we use by default /root/ips.txt
if [ -z $ipsFile ]; then 
	ipsFile="/root/ips.txt"; 
else 
	if [ ! -f $ipsFile ]; then 
		echo "The file $ipsFile does not exists."; 
		exit 1; 
	fi
fi

# If the variable $maxJobs is null, by default we use 100 
if [ -z $maxJobs ]; then maxJobs=100; fi

# We get the ip addresses from the file 
allDevices=$(cat $ipsFile)

for ip in $allDevices; do
	runningJobs=$(($runningJobs + 1))
	commandSender $ip &

	if [ $runningJobs -eq $maxJobs ]; then 
		wait; 
		runningJobs=0; 
	fi
done
