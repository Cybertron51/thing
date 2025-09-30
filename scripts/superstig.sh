#!/bin/sh

#the script that will script stigs hopefully maybe
#sudo su before, cuz this needs sudo perms everywhere

#stig 1
stig_one=$(grep -i password /boot/grub/grub.cfg)
if grep -q "password_pbkdf2" <<< "$stig_one"; then
        echo 'stig one secure'
else
        echo 'stig one not secure'
        hash=$(printf "[ebZ<8[YsW9]MzG$\n[ebZ<8[YsW9]MzG$" | grub-mkpasswd-pbkdf2)
        hash=${hash:68:${#hash}-69}
        sed -i '$i set superusers=\"root\"\npassword_pbkdf2 root'" $hash" /etc/grub.d/40_custom #this was the line that made me cry(not happy tears)
        update-grub
fi


