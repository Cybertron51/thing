#!/bin/bash

# loop thru critical services and determine what to delete
# a little bit redundant when used with that second for loop lmao
#for line in $(cat malwarelist.txt)
#do
#    if [[ grep -Fq $line malwarelist.txt ]]
#    then
#        sudo apt-get autoremove --purge $line -y
#    fi
#done

# examine manually downloaded packages, if on malicious list, delete
for line in $(comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u))
do
        if grep -Fq "$line" /opt/thing-main/scripts/scriptfiles/malwarelist.txt && ! grep -Fq "$line" /opt/thing-main/scripts/scriptfiles/critical_services.txt
        then
                sudo apt-get autoremove --purge $line -y
        else
		if ! grep -Fq $line /opt/thing-main/scripts/scriptfiles/critical_services.txt
		then
                	echo -n "Delete "$line" ? [Y/n] "
                	read option
                	if [[ $option =~ ^[Yy]$ ]]
                	then
                	        sudo apt-get autoremove --purge $line -y
                	fi
		else
			sudo apt-get install $line -y
		fi
        fi
done

