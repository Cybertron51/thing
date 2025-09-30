import pwd, sys

user_list = []
with open('authusers.txt') as my_file:
    user_list=my_file.read().splitlines()

for i in user_list:
    i = i.strip()
    i = pwd.getpwnam(i)
    print((i.pw_name + ": " + i.pw_shell))
