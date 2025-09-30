#!/bin/bash

while true
do
	echo "Bad process: "
	
	read bad_input
	
	if [ "$bad_input" != "no" ]
	then
		for line in $(sudo grep -Ril "$bad_input" /etc 2> /dev/null)
		do
			echo $line >> /opt/thing-main/scripts/scriptfiles/backdoor_files.txt		
		done

		for line in $(sudo grep -Ril "$bad_input" /var/spool 2> /dev/null)
		do
			echo $line >> /opt/thing-main/scripts/scriptfiles/backdoor_files.txt
		done

		for line in $(sudo grep -Ril "$bad_input" /bin 2> /dev/null)
		do
			echo $line >> /opt/thing-main/scripts/scriptfiles/backdoor_files.txt
		done
		
		sudo pkill -9 -f "$bad_input"
	else
		break
	fi
done
