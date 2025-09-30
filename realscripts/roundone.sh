#!/bin/bash
# FOR ROUND ONE OF CYBERPATRIOT USE ONLY
# MAKE SURE TO MAKE SURE YOU ARE IMPORTING THE RIGHT KINDS OF FILES (UBUNTU 20 vs 22)

unalias -a
echo "unalias -a" >> ~/.bashrc
echo "unalias -a" >> /root/.bashrc

clearvulns() {

	clear
	
	#SourcesList
	OtherPackagesToInstall
 	RoundOneUpdates
	#PermissionsFix
	sudoersAuthentication
	UsersAndGroups
	DeleteAptPackages
	ManageSnapPackages
	FirewallStuff
	#PasswordAudit
	#NetworkStuff
	#fstabstuff
	#GDMChange
	FirefoxConfig
 	#AuditdConfig
  #ApparmorConfig
	#dconfSettings
	#Miscellaneous
 	MediaBaseline

}

MediaBaseline() {
	sudo locate -r '\.mp3$|\.3g2$|\.avi$|\.flv$|\.h264$|\.m4v$|\.mkv$|\.mov$|\.jpeg$|\.gif$|\.tiff$|\.bmp$|\.aac$|\.wav$|\.wma$|\.dts$|\.aiff$|\.asf$|\.flac$|\.adpcm$|\.dsd$|\.lpcm$|\.ogg$|\.mpeg-1$|\.mpeg-2$|\.mpeg-4$|\.avchd$|\.mp4$|\.wmv$' > /opt/thing-main/scripts/scriptfiles/mediafilessupposedtobedeleted.txt
}

RoundOneUpdates() {
	sudo apt-get install firefox -y
 	sudo apt-get install apt -y
}

OtherPackagesToInstall() {

	sudo apt-get install e2fsprogs -y
	sudo apt-get install ufw -y
	sudo apt-get install bash -y
	sudo apt-get install sudo -y
	sudo apt-get install firefox -y

}

UsersAndGroups() {
	
	sudo apt-get install usermod -y
    sudo apt-get install passwd -y
	
	cat /opt/thing-main/default/ubu22/filesystem/etc/deluser.conf > /etc/deluser.conf
	
	cp /etc/passwd /opt/thing-main/backups/passwd
	cp /etc/shadow /opt/thing-main/backups/shadow
	cp /etc/group /opt/thing-main/backups/group
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
		sudo useradd $line
	done
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
	do
		sudo useradd $line
	done
	
	#for line in $(cat /etc/passwd | grep .sh | cut -d ":" -f 1)
	#do
	#	if [ "$line" != "$SUDO_USER" ]
	#	then
	#		rm -rf /home/$line
	#	fi
	#done
	
	for line in $(cat /etc/passwd | grep -E "sh$" | cut -d ":" -f 1)
	do
		if ! grep -w $line /opt/thing-main/scripts/scriptfiles/users.txt && ! grep -w $line /opt/thing-main/scripts/scriptfiles/admins.txt
		then
			echo $line >> /opt/thing-main/scripts/scriptfiles/unauth.txt
			userdel -r $line
		else
			usermod -s /bin/bash $line
		fi
	done

	for line in $(cat /etc/passwd | grep -E "sh$" | cut -d ":" -f 1)
	do
		if [ $(id -u $line) -lt 1000 ]
		then
			if [ $line != "root" ]
			then
				usermod -s /bin/false $line
			fi
		fi
	done

	for i in $(cat /opt/thing-main/scripts/scriptfiles/users.txt) ; do echo $i:"CyberPatriot123!@#" | sudo chpasswd ;  echo "Done changing password for: " $i " ...";  done
	for i in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt) ; do echo $i:"CyberPatriot123!@#" | sudo chpasswd ;  echo "Done changing password for: " $i " ...";  done

	for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
        	chage -M 15 -m 6 -W 7 -I 5 $line
	done

	for line in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
	do
        	chage -M 15 -m 6 -W 7 -I 5 $line
	done

	# Fix permissions for all users and on their home directories
	for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
			chown -R $line:$line /home/$line/
	done

	for line in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
	do
			if $line == "root"
			then
				chown -R root:root /root/
			else
				chown -R $line:$line /home/$line/
			fi
	done
	
	# To add user to group: sudo usermod -a -G group user
	# To delete user from group: sudo gpasswd -d user group
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
	do
		if ! groups $line | grep -w '\badm\b'
		then
			sudo usermod -a -G adm $line
		fi
		
		if ! groups $line | grep -w '\bsudo\b'
		then
			sudo usermod -a -G sudo $line
		fi
	done
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
		if groups $line | grep -w '\badm\b'
		then
			sudo gpasswd -d $line adm
		fi
		
		if groups $line | grep -w '\bsudo\b'
		then
			sudo gpasswd -d $line sudo
		fi
	done
	
	grep -Ev "Defaults|#|admin|sudo" /opt/thing-main/backups/sudoers | grep . | sed 's/%//' | sed -e 's/\s.*$//' >> /opt/thing-main/scripts/scriptfiles/sudoers_groups.txt
	grep -Ev "Defaults|#|admin|sudo" /opt/thing-main/backups/sudoers.d/* | grep . | sed 's/%//' | sed -e 's/\s.*$//' | cut -d ":" -f 2 | grep . > /opt/thing-main/scripts/scriptfiles/sudoers_groups.txt
	
	for group in $(cat /opt/thing-main/scripts/scriptfiles/sudoers_groups.txt | sort -u)
	do
		gpasswd $group -M ''
	done
	
	sudo passwd -l root
	
	get_dups() {
		awk -F':' '$3 == 0 { if (dup++) print } END { exit(dup > 1) }' /etc/passwd
	}
	
	dups = "$(get_dups)"
	nonroot="$(echo $dups | cut -d ":" -f1)"
	userdel -f $nonroot
}

DeleteAptPackages() {

	for line in $(comm -23 <(apt-mark showmanual | sort -u) <((awk '{print $1}' /opt/thing-main/scripts/scriptfiles/ubu22manifest) | sort -u))
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
					echo "$line" >> /opt/thing-main/backups/malwarelist.txt
				fi
			else
				sudo apt-get install $line -y
			fi
		fi
	done

}

ManageSnapPackages() {

	for line in $(snap list | awk 'NR>1' | grep -v canonical | awk '{print $1;}')
	do
		snap info $line
		echo "Delete "$line" ? (snap package) [Y/n] " 
		read option
		if [[ $option =~ ^[Yy]$ ]]
		then
			sudo snap remove --purge $line
		fi
	done
	sudo sh -c 'rm -rf /var/lib/snapd/cache/*' #this is overkill but whatever
	sudo rm -rf /var/cache/snapd/ #this is overkill but whatever
	snap refresh #updating
}

FirewallStuff() {

	echo "y" | sudo ufw reset
	sudo ufw enable
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw logging high

}

PasswordAudit() {

	cat /opt/thing-main/default/ubu22/filesystem/etc/login.defs > /etc/login.defs
	
	apt-get install libpam-cracklib -y
	#apt-get install libpam-pwquality -y
	
	cat /opt/thing-main/default/ubu22/filesystem/etc/pam.d/common-password > /etc/pam.d/common-password
	cat /opt/thing-main/default/ubu22/filesystem/etc/pam.d/common-auth > /etc/pam.d/common-auth
	
	#sudo apt-get install libpwquality-tools
	#echo "password required pam_pwquality.so" >> /etc/pam.d/login
	#cat /opt/thing-main/default/ubu22/filesystem/etc/security/pwquality.conf > /etc/security/pwquality.conf
	#sudo chmod 600 /etc/security/pwquality.conf

 	cp /etc/security/limits.conf /opt/thing-main/backups/limits.conf
 	cat /opt/thing-main/default/ubu22/filesystem/etc/security/limits.conf > /etc/security/limits.conf

}

NetworkStuff() {

	cp /etc/sysctl.conf /opt/thing-main/backups/sysctl.conf
	cat /opt/thing-main/default/ubu22/filesystem/etc/sysctl.conf > /etc/sysctl.conf
	sudo sysctl -ep
	cat /opt/thing-main/default/ubu22/filesystem/etc/host.conf > /etc/host.conf

}

sudoersAuthentication() {
	
	cp /etc/sudoers /opt/thing-main/backups/sudoers
	cat /opt/thing-main/default/ubu22/filesystem/etc/sudoers > /etc/sudoers
	# above might break
	cp /etc/sudoers.d/ /opt/thing-main/backups/sudoers.d/
	rm -rf /etc/sudoers.d/
}

fstabstuff() {
	
	cp /etc/fstab /opt/thing-main/backups/fstab
	sudo echo "tmpfs /run/shm tmpfs defaults,nodev,noexec,nosuid 0 0" >> /etc/fstab
	sudo echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
	sudo echo "tmpfs /var/tmp tmpfs defaults,nodev,noexec,nosuid 0 0" >> /etc/fstab
	sudo echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" >> /etc/fstab

}

PermissionsFix() {
	
	sudo chattr -Ria / 2> /dev/null
	
	chmod 600 /etc/shadow
	chmod 644 /etc/passwd
	chmod 600 /etc/gshadow
	chmod 644 /etc/group
	chown root /etc/shadow
	chown root /etc/passwd
	chown root /etc/group
	chmod u-s /bin/bash
	chmod g-s /bin/bash
	chmod u-s /bin/dash
	chmod g-s /bin/dash
	chmod 755 /bin/bash
	chmod 755 /bin/dash
	chown root /bin/dash
	chown root /bin/bash
	chgrp adm /var/log/syslog
	chmod 0750 /var/log
	chmod 600 /boot/grub/grub.cfg
	sudo chown -R root:root /etc/*cron*
	sudo chmod -R 600 /etc/*cron*
	sudo chown -R root:root /var/spool/cron
	sudo chmod -R 600 /var/spool/cron
	chmod 700 /boot /usr/src /lib/modules /usr/lib/modules
	
	chown root:root /etc/login.defs
	chmod 644 /etc/login.defs

	chown root:root /etc/sudoers
	chmod 640 /etc/sudoers
	chown root:root /tmp
	chmod 1777 /tmp
	chown root:root /var/tmp
	chmod 1777 /var/tmp
	chown -R root:root /etc/security
	chmod 755 /etc/security
	chmod go-w /etc/security
	chown root:root /etc/anacrontab
	chmod 640 /etc/anacrontab
	
	chown root:root /etc/crontab
	chmod 600 /etc/crontab

	chown -R root:root /etc/cron.hourly
	chmod 700 /etc/cron.hourly

	chown -R root:root /etc/cron.daily
	chmod 700 /etc/cron.daily

	chown -R root:root /etc/cron.weekly
	chmod 700 /etc/cron.weekly

	chown -R root:root /etc/cron.monthly
	chmod 700 /etc/cron.monthly

	chown -R root:root /etc/cron.d
	chmod 700 /etc/cron.d
	# http://www.faqs.org/docs/securing/chap5sec40.html
	chmod 644 /etc/services
	chattr +i /etc/services 

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

}

SourcesList() {
	
	sudo chattr =e /etc/apt/sources.list
	cp /etc/apt/sources.list /opt/thing-main/backups/sources.list
	cat /opt/thing-main/scripts/scriptfiles/ubu22sourceslist.txt > /etc/apt/sources.list
 	cp /etc/apt/sources.list.d /opt/thing-main/backups/
  	rm -rf /etc/apt/sources.list.d/
	sudo apt-get update
}

GDMChange() {
	
	cp /etc/gdm3/custom.conf /opt/thing-main/backups/gdm3custom.conf.bak
	cp /etc/gdm3/greeter.dconf-defaults /opt/thing-main/backups/gdm3greeter.dconf.bak
	cat /opt/thing-main/default/ubu22/filesystem/etc/gdm3/custom.conf > /etc/gdm3/custom.conf
	cat /opt/thing-main/default/ubu22/filesystem/etc/gdm3/greeter.dconf-defaults > /etc/gdm3/greeter.dconf-defaults
	dconf update
}

FirefoxConfig() {

	sudo killall firefox
	sudo sed -i '/user_pref("app.shield.optoutstudies.enabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.discovery.enabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.safebrowsing.phishing.enabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.safebrowsing.malware.enabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.safebrowsing.downloads.enabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.preferences.defaultPerformanceSettings.enabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.search.update", false);/c\'~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.startup.page", 3);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.tabs.loadInBackground", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("datareporting.healthreport.uploadEnabled", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("dom.disable_open_during_load", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("layers.acceleration.disabled", true);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("xpinstall.whitelist.required", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.startup.page", 3);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("urlclassifier.malwareTable","goog-malware-proto,test-harmful-simple,test-malware-simple");/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.contentblocking.category","standard");/c\user_pref("browser.contentblocking.category", "strict");' ~/.mozilla/firefox/*.default/prefs.js
	sudo sed -i '/user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);/c\' ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("network.predictor.cleaned-up", true);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("media.autoplay.default", 1);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("accessibility.force_disabled", 1);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", true);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("browser.privatebrowsing.autostart", true);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("browser.urlbar.suggest.history", false);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("media.autoplay.default", 1);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("network.cookie.cookieBehavior", 4);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("network.cookie.lifetimePolicy", 2);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("privacy.donottrackheader.enabled", true);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("privacy.trackingprotection.enabled", true);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	sudo echo 'user_pref("signon.rememberSignons", false);' | sudo tee -a ~/.mozilla/firefox/*.default/prefs.js
	
}

AuditdConfig() {
	sudo apt install auditd
 	sudo auditctl –e 1 # turn on auditing
}

ApparmorConfig() {
	sudo apt install apparmor-utils apparmor-profiles -y
	aa-enforce /etc/apparmor.d/*
	echo 'session optional pam_apparmor.so order=user,group,default' > /etc/pam.d/apparmor
 	systemctl enable apparmor
  	systemctl restart apparmor
}

Services() {
	for line in $(systemctl list-units)
	do 
		if ! grep -Fq $line /opt/thing-main/scripts/scriptfiles/systemctlout.txt
		then 
			echo $line >> /opt/thing-main/scripts/scriptfiles/diffservices.txt
		fi
	done

}

dconfSettings()
{
	dconf reset -f /
	gsettings set org.gnome.desktop.privacy remember-recent-files false
	gsettings set org.gnome.desktop.media-handling automount false
	gsettings set org.gnome.desktop.media-handling automount-open false
	gsettings set org.gnome.desktop.search-providers disable-external true
	dconf update /

}

Miscellaneous() {

	find / -name ".rhosts" -exec rm -rf {} \;
	find / -name "hosts.equiv" -exec rm -rf {} \;
	# prevent users from overriding core dumps
	# reduce startup time of binaries
	prelink -ua
	apt-get remove -y prelink
	systemctl mask ctrl-alt-del.target
	systemctl daemon-reload
	# only root is allowed to login on tty1
	echo > /etc/securetty
	echo "TMOUT=300" >> /etc/profile
	echo "readonly TMOUT" >> /etc/profile
	echo "export TMOUT" >> /etc/profile
	echo "" > /etc/updatedb.conf
	echo "blacklist usb-storage" >> /etc/modprobe.d/blacklist.conf
	echo "install usb-storage /bin/false" > /etc/modprobe.d/usb-storage.conf
	rm -f /usr/lib/gvfs/gvfs-trash
	rm -f /usr/lib/svfs/*trash
	sudo find / -iname '*password.txt' -delete
	sudo find / -iname '*passwords.txt' -delete
	sudo find /root -iname 'user*' -delete
	sudo find / -iname 'users.csv' -delete
	sudo find / -iname 'user.csv' -delete
	sudo rm -f /usr/share/wordpress/info.php
	sudo rm -f /usr/share/wordpress/wp-admin/webroot.php
	sudo rm -f /usr/share/wordpress/index.php
	sudo rm -f /usr/share/wordpress/r57.php
	sudo rm -f /usr/share/wordpress/phpinfo.php
	sudo rm -f /var/www/html/phpinfo.php
	sudo rm -f /var/www/html/webroot.php
	sudo rm -f /var/www/html/index.php
	sudo rm -f /var/www/html/info.php
	sudo rm -f /var/www/html/r57.php
	sudo rm -f /usr/lib/gvfs/gvfs-trash
	sudo rm -f /usr/lib/gvfs/*trash
	sudo rm -f /var/timemachine
	sudo rm -f /bin/ex1t
	sudo rm -f /var/oxygen.html
	sudo apt install fail2ban -y
	sudo systemctl restart fail2ban.service
}

clearvulns
