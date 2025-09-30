#!/bin/bash

for line in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
do
	if  [ "$line" != "root" ]
	then
		chown $line /home/$line
		chgrp $line /home/$line
		chmod 700 /home/$line
	fi
done

for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
do
	chown $line /home/$line
	chgrp $line /home/$line
	chmod 700 /home/$line
done

for line in $(find / -perm /4000)
do
	if ! grep -Fxq $line /opt/thing-main/scripts/scriptfiles/suid.txt
	then
		echo "SUID: $line " >> /opt/thing-main/scripts/scriptfiles/specialperms.txt
	fi
done

for line in $(find / -perm /2000)
do
        if ! grep -Fxq $line /opt/thing-main/scripts/scriptfiles/sgid.txt
        then
                echo "SGID: $line " >> /opt/thing-main/scripts/scriptfiles/specialperms.txt
        fi
done

for line in $(find / -perm /1000)
do
        if ! grep -Fxq $line /opt/thing-main/scripts/scriptfiles/stickybit.txt
        then
                echo "STICKY BIT: $line " >> /opt/thing-main/scripts/scriptfiles/specialperms.txt
        fi
done

