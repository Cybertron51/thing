#!/bin/bash

unalias -a
echo "unalias -a" >> ~/.bashrc
echo "unalias -a" >> /root/.bashrc
chattr -Ria / 2> /dev/null

clearvulns() {

	clear
	
	SourcesList
	OtherPackagesToInstall
	PermissionsFix
	sudoersAuthentication
 	PasswordAudit
	UsersAndGroups
	DeleteAptPackages
	ManageSnapPackages
	FirewallStuff
	KernelStuff
	fstabstuff
	GDMChange
	LightDMChange
	FirefoxConfig
 	AuditdConfig
  	ApparmorConfig
	dconfSettings
 	Services
	Miscellaneous

}

OtherPackagesToInstall() {

	apt-get install dbus-x11 -y # works on ubuntu, done so that the dconf things work 
	apt-get install e2fsprogs -y
 	apt-get install mlocate -y
  	apt-get install plocate -y
  	apt-get install locate -y
	apt-get install ufw -y
	apt-get install bash -y
	apt-get install sudo -y
	apt-get install firefox -y

}

UsersAndGroups() {
	
	apt-get install usermod -y
    apt-get install passwd -y
	
	cat /opt/thing-main/default/ubu22/filesystem/etc/deluser.conf > /etc/deluser.conf
	
	cp /etc/passwd /opt/thing-main/backups/passwd
	cp /etc/shadow /opt/thing-main/backups/shadow
	cp /etc/group /opt/thing-main/backups/group
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
		useradd $line
	done
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
	do
		useradd $line
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
			echo $line >> /opt/thing-main/output/unauth.txt
			userdel -rf $line
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

	for i in $(cat /opt/thing-main/scripts/scriptfiles/users.txt) ; do echo $i:"CyberPatriot123!@#" | chpasswd ;  echo "Done changing password for: " $i " ...";  done
	for i in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt) ; do echo $i:"CyberPatriot123!@#" | chpasswd ;  echo "Done changing password for: " $i " ...";  done

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
			usermod -a -G adm $line
		fi
		
		if ! groups $line | grep -w '\bsudo\b'
		then
			usermod -a -G sudo $line
		fi
	done
	
	for line in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
		if groups $line | grep -w '\badm\b'
		then
			gpasswd -d $line adm
		fi
		
		if groups $line | grep -w '\bsudo\b'
		then
			gpasswd -d $line sudo
		fi
	done
	
	grep -Ev "Defaults|#|admin|sudo" /opt/thing-main/backups/sudoers | grep . | sed 's/%//' | sed -e 's/\s.*$//' >> /opt/thing-main/output/sudoers_groups.txt
	grep -Ev "Defaults|#|admin|sudo" /opt/thing-main/backups/sudoers.d/* | grep . | sed 's/%//' | sed -e 's/\s.*$//' | cut -d ":" -f 2 | grep . > /opt/thing-main/output/sudoers_groups.txt
	
	for group in $(cat /opt/thing-main/output/sudoers_groups.txt | sort -u)
	do
		gpasswd $group -M ''
	done
	
	passwd -l root
	
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
			apt-get autoremove --purge $line -y
		else
			if ! grep -Fq $line /opt/thing-main/scripts/scriptfiles/critical_services.txt
			then
				echo -n "Delete "$line" ? [Y/n] "
				read option
				if [[ $option =~ ^[Yy]$ ]]
				then
					apt-get autoremove --purge $line -y
					echo "$line" >> /opt/thing-main/backups/malwarelist.txt
				fi
			else
				apt-get install $line -y
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
			snap remove --purge $line
		fi
	done
	sh -c 'rm -rf /var/lib/snapd/cache/*' #this is overkill but whatever
	rm -rf /var/cache/snapd/ #this is overkill but whatever
	snap refresh #updating
}

FirewallStuff() {

	echo "y" | ufw reset
	ufw enable
	ufw default deny incoming
	ufw default allow outgoing
	ufw logging high
 	cat /opt/thing-main/default/ubu22/filesystem/etc/default/ufw > /etc/default/ufw

}

PasswordAudit() {

	cat /opt/thing-main/default/ubu22/filesystem/etc/login.defs > /etc/login.defs
	
	apt-get install libpam-cracklib -y
	#apt-get install libpam-pwquality -y
	
	cat /opt/thing-main/default/ubu22/filesystem/etc/pam.d/common-password > /etc/pam.d/common-password
	cat /opt/thing-main/default/ubu22/filesystem/etc/pam.d/common-auth > /etc/pam.d/common-auth
	
	#sudo apt-get install libpwquality-tools
	#echo "password required pam_pwquality.so" >> /etc/pam.d/login
	cat /opt/thing-main/default/ubu22/filesystem/etc/security/pwquality.conf > /etc/security/pwquality.conf
	sudo chmod 600 /etc/security/pwquality.conf

 	cp /etc/security/limits.conf /opt/thing-main/backups/limits.conf
 	cat /opt/thing-main/default/ubu22/filesystem/etc/security/limits.conf > /etc/security/limits.conf

}

KernelStuff() {

	cp /etc/sysctl.conf /opt/thing-main/backups/sysctl.conf
	cat /opt/thing-main/default/ubu22/filesystem/etc/sysctl.conf > /etc/sysctl.conf
	sysctl -ep
 	echo integrity > /sys/kernel/security/lockdown
  	echo 1 > /sys/kernel/security/evm
	cat /opt/thing-main/default/ubu22/filesystem/etc/host.conf > /etc/host.conf

}

sudoersAuthentication() {
	
	cp /etc/sudoers /opt/thing-main/backups/sudoers
	#cat /opt/thing-main/default/ubu22/filesystem/etc/sudoers > /etc/sudoers
	# above might break
	cp /etc/sudoers.d/ /opt/thing-main/backups/sudoers.d/
	#rm -rf /etc/sudoers.d/
	cp /etc/sudo.conf /opt/thing-main/backups/sudo.conf
	cat /opt/thing-main/default/ubu22/filesystem/etc/sudo.conf > /etc/sudo.conf
}

fstabstuff() {
	
	cp /etc/fstab /opt/thing-main/backups/fstab
	echo "tmpfs /run/shm tmpfs defaults,nodev,noexec,nosuid 0 0" >> /etc/fstab
	echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
	echo "tmpfs /var/tmp tmpfs defaults,nodev,noexec,nosuid 0 0" >> /etc/fstab
	echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" >> /etc/fstab

}

PermissionsFix() {

	cp -r /etc/ /opt/thing-main/backups/
		
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
 	chown -R root:root /var/log
	chmod 600 /boot/grub/grub.cfg
	chmod 600 /boot/grub2/grub.cfg
	chmod og-rwx /etc/grub/grub.cfg
 	chmod og-rwx /etc/grub2/grub.cfg
  
	chown -R root:root /etc/*cron*
	chmod -R 600 /etc/*cron*
	chown -R root:root /var/spool/cron
	chmod -R 600 /var/spool/cron
	chmod 700 /boot /usr/src /lib/modules /usr/lib/modules
	
	chown root:root /etc/login.defs
	chmod 644 /etc/login.defs

	chown root:root /*
 	chmod 600 /swapfile
 
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

: '
	for line in $(find / -path "/dev" -prune -o -path "/proc" -prune -o -perm /4000 -print)
	do
		if ! grep -Fxq $line /opt/thing-main/scripts/scriptfiles/suid.txt
		then
			echo "SUID: $line " >> /opt/thing-main/scripts/scriptfiles/specialperms.txt
		fi
	done

	for line in $(find / -path "/dev" -prune -o -path "/proc" -prune -o -perm /2000 -print)
	do
		if ! grep -Fxq $line /opt/thing-main/scripts/scriptfiles/sgid.txt
		then
			echo "SGID: $line " >> /opt/thing-main/scripts/scriptfiles/specialperms.txt
		fi
	done

	for line in $(find / -path "/dev" -prune -o -path "/proc" -prune -o -perm /1000 -print)
	do
		if ! grep -Fxq $line /opt/thing-main/scripts/scriptfiles/stickybit.txt
		then
			echo "STICKY BIT: $line " >> /opt/thing-main/scripts/scriptfiles/specialperms.txt
		fi
	done
'

}

SourcesList() {
	
	cp /etc/apt/sources.list /opt/thing-main/backups/sources.list
	cat /opt/thing-main/scripts/scriptfiles/ubu22sourceslist.txt > /etc/apt/sources.list
 	cp -r /etc/apt/sources.list.d /opt/thing-main/backups/
  	rm -rf /etc/apt/sources.list.d/

	for line in $(ls /etc/apt/apt.conf.d/)
	do
		if ! grep -Fq $line /opt/thing-main/scripts/scriptfiles/aptconfs.txt
		then
			echo "/etc/apt/apt.conf.d/$line" >> /opt/thing-main/output/diffaptconfs.txt
		fi
	done

	apt-get update
}

GDMChange() {
	if (cat /etc/X11/default-display-manager) | grep -q "gdm"
	then
		cp /etc/gdm3/custom.conf /opt/thing-main/backups/gdm3custom.conf.bak
		cp /etc/gdm3/greeter.dconf-defaults /opt/thing-main/backups/gdm3greeter.dconf.bak
		cat /opt/thing-main/default/ubu22/filesystem/etc/gdm3/custom.conf > /etc/gdm3/custom.conf
		cat /opt/thing-main/default/ubu22/filesystem/etc/gdm3/greeter.dconf-defaults > /etc/gdm3/greeter.dconf-defaults
		dconf update
	fi
}

LightDMChange() {
	if (cat /etc/X11/default-display-manager) | grep -q "lightdm"
	then
		cp -r /etc/lightdm /opt/thing-main/backups/lightdm.bak/
		cat /opt/thing-main/configfiles/lightdm/lightdm.conf > /etc/lightdm/lightdm.conf
		cat /opt/thing-main/configfiles/lightdm/lightdm-gtk-greeter.conf > /etc/lightdm/lightdm-gtk-greeter.conf
		cat /opt/thing-main/configfiles/lightdm/users.conf > /etc/lightdm/users.conf
	fi
}

FirefoxConfig() {

	killall firefox
	sed -i '/user_pref("app.shield.optoutstudies.enabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.discovery.enabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.safebrowsing.phishing.enabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.safebrowsing.malware.enabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.safebrowsing.downloads.enabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.preferences.defaultPerformanceSettings.enabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.search.update", false);/c\'/home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.startup.page", 3);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.tabs.loadInBackground", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("datareporting.healthreport.uploadEnabled", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("dom.disable_open_during_load", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("layers.acceleration.disabled", true);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("xpinstall.whitelist.required", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.startup.page", 3);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("urlclassifier.malwareTable","goog-malware-proto,test-harmful-simple,test-malware-simple");/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.contentblocking.category","standard");/c\user_pref("browser.contentblocking.category", "strict");' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	sed -i '/user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);/c\' /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("network.predictor.cleaned-up", true);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("media.autoplay.default", 1);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("accessibility.force_disabled", 1);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", true);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("browser.privatebrowsing.autostart", true);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("browser.urlbar.suggest.history", false);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("media.autoplay.default", 1);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("network.cookie.cookieBehavior", 4);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("network.cookie.lifetimePolicy", 2);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("privacy.donottrackheader.enabled", true);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("privacy.trackingprotection.enabled", true);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	echo 'user_pref("signon.rememberSignons", false);' | tee -a /home/$SUDO_USER/.mozilla/firefox/*.default*/prefs.js
	
}

AuditdConfig() {
	apt install auditd -y
 	auditctl –e 1 # turn on auditing
	cp /etc/audit/auditd.conf /opt/thing-main/backups/auditd.conf
	cat /opt/thing-main/default/ubu22/filesystem/etc/audit/auditd.conf > /etc/audit/auditd.conf
 	cp /etc/audit/audit.rules /opt/thing-main/backups/audit.rules
  	cat /opt/thing-main/default/ubu22/filesystem/etc/audit/audit.rules > /etc/audit/audit.rules
}

ApparmorConfig() {
	apt install apparmor-utils apparmor-profiles -y
	aa-enforce /etc/apparmor.d/*
	echo 'session optional pam_apparmor.so order=user,group,default' > /etc/pam.d/apparmor
 	systemctl enable apparmor
  	systemctl restart apparmor
}

Services() {
	# echo is to clear the output every time the script is run so it doesn't stack
	echo > /opt/thing-main/output/diffservices.txt
	for line in $(systemctl --no-pager list-units | awk '{print $1}')
	do 
		if ! grep -Fq -- $line /opt/thing-main/scripts/scriptfiles/systemctlout.txt
		then 
			echo $line >> /opt/thing-main/output/diffservices.txt
		fi
	done

}

dconfSettings()
{
	dconf reset -f /
	sudo -u $SUDO_USER gsettings set org.gnome.desktop.privacy remember-recent-files false
	sudo -u $SUDO_USER gsettings set org.gnome.desktop.media-handling automount false
	sudo -u $SUDO_USER gsettings set org.gnome.desktop.media-handling automount-open false
	sudo -u $SUDO_USER gsettings set org.gnome.desktop.search-providers disable-external true
 	sudo -u $SUDO_USER gsettings set org.gnome.desktop.session idle-delay 300
 	sudo -u $SUDO_USER gsettings set org.gnome.desktop.screensaver lock-enabled true
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
	find / -iname '*password.txt' -delete
	find / -iname '*passwords.txt' -delete
	find /root -iname 'user*' -delete
	find / -iname 'users.csv' -delete
	find / -iname 'user.csv' -delete
	rm -f /usr/lib/gvfs/gvfs-trash
	rm -f /usr/lib/gvfs/*trash
	rm -f /var/timemachine
	rm -f /bin/ex1t
	rm -f /var/oxygen.html
	apt install fail2ban -y
	systemctl restart fail2ban.service
}

clearvulns
