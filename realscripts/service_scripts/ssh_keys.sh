#!/bin/bash

for user in $(cat /opt/thing-main/scripts/scriptfiles/ssh_users.txt)
do
    sudo -i -u $user ssh-keygen -f /home/$user/.ssh/id_rsa -q -N '""'
    sudo -i -u $user cat /home/$user/.ssh/id_rsa.pub >> /home/$user/.ssh/authorized_keys
done