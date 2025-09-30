#!/bin/bash

unalias -a
echo "unalias -a" >> ~/.bashrc
echo "unalias -a" >> /root/.bashrc
sudo updatedb

baseline() {

    MaliciousFilesBaseline
    MediaBaseline
    ArchiveBaseline
    BackdoorBaseline
    SSHKeyBaseline
	PasswordFilesBaseline
    PermissionsBaseline
    FilesBaseline
    KernelModulesBaseline
    
}

PermissionsBaseline() {
    find /etc -type f -exec ls -l {} + | awk '{print $1,$3,$4,$9}' > /opt/thing-main/output/vuln_etc_file_perms.txt
    find /var -type f -exec ls -l {} + | awk '{print $1,$3,$4,$9}' > /opt/thing-main/output/vuln_var_file_perms.txt
    find /usr/bin -type f -exec ls -l {} + | awk '{print $1,$3,$4,$9}' > /opt/thing-main/output/vuln_bin_file_perms.txt
    find /usr/sbin -type f -exec ls -l {} + | awk '{print $1,$3,$4,$9}' > /opt/thing-main/output/vuln_sbin_file_perms.txt
}

# We can check for potential file changes and any files that aren't default with this
FilesBaseline() {
    find /etc -type f -exec md5sum {} + | awk '{print $1,$2}' > /opt/thing-main/output/vuln_etc_file_hash.txt
    find /var -type f -exec md5sum {} + | awk '{print $1,$2}' > /opt/thing-main/output/vuln_var_file_hash.txt
    #hmm these two might be weird cuz same thing but more
    find /usr -type f -exec md5sum {} + | awk '{print $1,$2}' > /opt/thing-main/output/vuln_usr_file_hash.txt
    find /usr/lib -type f -exec md5sum {} + | awk '{print $1,$2}' > /opt/thing-main/output/vuln_lib_file_hash.txt
    find /usr/bin -type f -exec md5sum {} + | awk '{print $1,$2}' > /opt/thing-main/output/vuln_bin_file_hash.txt
    find /usr/sbin -type f -exec md5sum {} + | awk '{print $1,$2}' > /opt/thing-main/output/vuln_sbin_file_hash.txt
}

# Just outputs description of all of the kernel modules (at least found at lsmod)
KernelModulesBaseline() {
    lsmod | {
  read -r _ || exit 1 # Ignore header line
  while read -r name _; do
    modinfo -F description "$name" | {
      read -r desc || true # Ignore read failure if no description
      # Print at least a line per module
      printf '%-24s %s\n' "$name" "$desc"
      # Iterate remaining description lines if any
      while read -r desc; do
        # Print description line without repeating module name
        printf '%-24s %s\n' '' "$desc"
      done
    }
  done
} > /opt/thing-main/output/kernelmodules.txt

while IFS= read -r line || [ -n "$line" ]; do
    if ! grep -Fq -- "$line" /opt/thing-main/scripts/scriptfiles/defaultkernelmodules.txt; then
        echo "$line" >> /opt/thing-main/output/unknownkernelmodules.txt
    fi
done < /opt/thing-main/output/kernelmodules.txt
}

MediaBaseline() {
    sudo locate -r '\.mp3$\|\.3g2$\|\.avi$\|\.flv$\|\.h264$\|\.m4v$\|\.mkv$\|\.mov$\|\.jpeg$\|\.gif$\|\.tiff$\|\.bmp$\|\.aac$\|\.wav$\|\.wma$\|\.dts$\|\.aiff$\|\.asf$\|\.flac$\|\.adpcm$\|\.dsd$\|\.lpcm$\|\.ogg$\|\.mpeg-1$\|\.mpeg-2$\|\.mpeg-4$\|\.avchd$\|\.mp4$\|\.wmv$' > /opt/thing-main/output/mediafilessupposedtobedeleted.txt
}

ArchiveBaseline() {
    sudo locate -r '\.tar.gz$\|\.tar$\|\.zip$\|\.tgz$|\.deb$' > /opt/thing-main/output/archivefiles.txt
}

BackdoorBaseline() {

	sudo find /lib/systemd -type f -iname '*\.service' -exec ls -lart "{}" + > /opt/thing-main/output/service_backdoors.txt
	sudo find /etc/systemd -type f -iname '*\.service' -exec ls -lart "{}" + > /opt/thing-main/output/service_backdoors.txt

}

SSHKeyBaseline() {
	sudo locate -r '/\.ssh$\|/authorized_keys$\|/id_rsa\.pub$\|/id_rsa$' > /opt/thing-main/output/sshkeys.txt
}

PasswordFilesBaseline() {

	for password in $(cat /opt/thing-main/scripts/scriptfiles/admin_passwords.txt)
	do
		sudo grep -rins $password /etc/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /var/ >>/opt/thing-main/output/password_files.txt
		sudo grep -rins $password /usr/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /home/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /root/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /opt/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /lib/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /lib32/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /lib64/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /libx32/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /sbin/ >> /opt/thing-main/output/password_files.txt
		sudo grep -rins $password /bin/ >> /opt/thing-main/output/password_files.txt
	done
	
}

MaliciousFilesBaseline() {

	sudo ls -lart /bin/ >> /opt/thing-main/output/potentially_malicious_files_time/bin.txt
 	sudo ls -lart /boot/ >> /opt/thing-main/output/potentially_malicious_files_time/boot.txt
	sudo ls -lart /cdrom/ >> /opt/thing-main/output/potentially_malicious_files_time/cdrom.txt
	sudo ls -lart /dev/ >> /opt/thing-main/output/potentially_malicious_files_time/dev.txt
	sudo ls -lart /etc/ >> /opt/thing-main/output/potentially_malicious_files_time/etc.txt
	sudo ls -lart /home/ >> /opt/thing-main/output/potentially_malicious_files_time/home.txt
 	sudo ls -lart /lib/ >> /opt/thing-main/output/potentially_malicious_files_time/lib.txt
	sudo ls -lart /lib32/ >> /opt/thing-main/output/potentially_malicious_files_time/lib32.txt
	sudo ls -lart /lib64/ >> /opt/thing-main/output/potentially_malicious_files_time/lib64.txt
	sudo ls -lart /libx32/ >> /opt/thing-main/output/potentially_malicious_files_time/libx32.txt
	sudo ls -lart /lost+found/ >> /opt/thing-main/output/potentially_malicious_files_time/lost+found.txt
	sudo ls -lart /media/ >> /opt/thing-main/output/potentially_malicious_files_time/media.txt
	sudo ls -lart /mnt/ >> /opt/thing-main/output/potentially_malicious_files_time/mnt.txt
	sudo ls -lart /opt/ >> /opt/thing-main/output/potentially_malicious_files_time/opt.txt
	sudo ls -lart /proc/ >> /opt/thing-main/output/potentially_malicious_files_time/proc.txt
	sudo ls -lart /root/ >> /opt/thing-main/output/potentially_malicious_files_time/root.txt
	sudo ls -lart /run/ >> /opt/thing-main/output/potentially_malicious_files_time/run.txt
	sudo ls -lart /sbin/ >> /opt/thing-main/output/potentially_malicious_files_time/sbin.txt
	sudo ls -lart /snap/ >> /opt/thing-main/output/potentially_malicious_files_time/snap.txt
	sudo ls -lart /srv/ >> /opt/thing-main/output/potentially_malicious_files_time/srv.txt
	sudo ls -lart /sys/ >> /opt/thing-main/output/potentially_malicious_files_time/sys.txt
 	sudo ls -lart /tmp/ >> /opt/thing-main/output/potentially_malicious_files_time/tmp.txt
	sudo ls -lart /usr/ >> /opt/thing-main/output/potentially_malicious_files_time/usr.txt
	sudo ls -lart /var/ >> /opt/thing-main/output/potentially_malicious_files_time/var.txt
 
 	sudo find / -type f -mtime -1000 -exec ls -lart --time-style="+%Y%m%d%H%M%S" "{}" + | grep -Ev "^(/home|/proc|/run|/sys|/etc/alternatives|/var/lib/dpkg/info|/usr/lib/x86_64-linux-gnu|/var/log|/root/.bash_history|/root/.cache|/root/.config|/root/.dbus|/root/.profile|/dev|/etc/rc|/opt/thing-main)" | sort -k6 > /opt/thing-main/output/potentially_malicious_files.txt

	for user in $(cat /opt/thing-main/scripts/scriptfiles/users.txt)
	do
		sudo find / -type f -mtime -1000 -exec ls -lart --time-style="+%Y%m%d%H%M%S" "{}" + | grep "/home/$user" | grep -Ev "^(/home/$user/.bash_logout|/home/$user/.profile|/home/$user/.config|/home/$user/.mozilla|/home/$user/.cache)" | sort -k6 >> /opt/thing-main/output/potentially_malicious_files.txt
	done

	for user in $(cat /opt/thing-main/scripts/scriptfiles/admins.txt)
	do
		sudo find / -type f -mtime -1000 -exec ls -lart --time-style="+%Y%m%d%H%M%S" "{}" + | grep "/home/$user" | grep -Ev "^(/home/$user/.bash_logout|/home/$user/.profile|/home/$user/.config|/home/$user/.mozilla|/home/$user/.cache)" | sort -k6 >> /opt/thing-main/output/potentially_malicious_files.txt
	done

}

baseline
