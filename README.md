# ogose
cyberpatriot omegalul

## branches
- main - ubuntu 18
- debian - debian 10
- ubu20 - ubuntu 20
- services - service configuration files

## how to run
1. Edit `scripts/scriptfiles/admins.txt` and `scripts/scriptfiles/users.txt`. Update also `critical_services.txt` with the exact critical service package names (Ex: `openssh-server`, `apache2`, `mysql-server`).
2. fill in 'scripts/scriptfiles/admin_passwords.txt'
3. run `realscripts/master.sh`
4. Once master.sh has finished running, run the `realscripts/shelldestroyer.sh` file with sudo and look at the output files after
