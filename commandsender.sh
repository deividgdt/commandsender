#!/bin/bash
# dependencias: sshpass

# Comando a enviar a los dispositivos

commandToSend="touch commandSender.txt"
#read -p "Inserta el comando a enviar: " commandToSend

# ficheros de logs
logOK="/root/commsenderlogOK.txt"
logKO="/root/commsenderlogKO.txt"
# pass
pass_dev='password'

commandSender() {
	# Funcion principal encargada de enviar los comandos a los dispositivos
	# las ordenes pasadas con la variable $commandToSend
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
	# Funcion encargada de mostrar ayuda al usuario
	echo "-j [0-8000]"
	echo "	Numero de conexiones que se generan en paralelo. Cualquier numero entre 0 y 8000"
	echo "	Por ejemplo:"
	echo "		commandsender.sh -j 300"
	echo "	Establecera 300 conexiones en paralelo a 300 dispositivos, y entonces"
	echo "	esperara a que todos los comandos hayan sido ejecutados para continuar" 
	echo "	con las siguientes 300 conexiones."
	echo ""
	echo "	Valor por defecto: -j 100"
	echo ""
	echo "-f nombre_archivo"
	echo "	Si desea usar otro nombre escribalo usando esta opción."
	echo "	Por ejemplo:"
	echo "		commandsender.sh -f /tmp/direccionesips.txt"
	echo ""
	echo "	Valor por defecto: /root/ips.txt"
	echo ""
	echo "-h"
	echo "	Muestra la ayuda del script."
	echo ""

}

# se obtienen las valores pasados en las opciones
while getopts ":j:f:h" opt; do
	case "$opt" in
		j) maxJobs=$OPTARG							;;
		f) ipsFile=$OPTARG 							;;
		h) help; exit								;;
		*) echo "Opción invalida. -$OPTARG"; exit	;;
	esac
done

# si la variable $ipsFile es nula por que el usuario
# no la ha declarado, por defecto usamos /root/ips.txt
if [ -z $ipsFile ]; then 
	ipsFile="/root/ips.txt"; 
else 
	if [ ! -f $ipsFile ]; then 
		echo "El archivo $ipsFile no existe."; 
		exit 1; 
	fi
fi

# Si la variable $maxJobs es nula por que el usuario
# no ha pasado dicha opcion, por defecto usamos 100
if [ -z $maxJobs ]; then maxJobs=100; fi

# Obtenemos todas las IPs del fichero
listado_devices=$(cat $ipsFile)

for ip in $listado_devices; do
	runningJobs=$(($runningJobs + 1))
	commandSender $ip &

	if [ $runningJobs -eq $maxJobs ]; then 
		wait; 
		runningJobs=0; 
	fi
done
