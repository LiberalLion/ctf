# TryHackMe: Avengers Blog (Writeup)

IP: `10.10.225.140`

## [Task 1] Deploy

Pretty straight forward, just hit deploy and run the box. Ping and navigate to host. 

## [Task 2] Cookies

Hit `F12` in your browser. Goto `Storage`, `Cookies`, then pull the value for `flag1`... 

```
cookie_secrets
```

## [Task 3] HTTP headers

Hit `F12` goto `Network` tab; refresh the page to capture a `GET` request. Then find the flag in the _response headers_.

```
headers_are_important
```

## [Task 4] Enumeration and FTP

Run an `nmap` scan; enumerate all services. Then, connect the host's FTP server with credentials `groot:iamgroot` .

```shell
kali@kali:~$ ftp 10.10.225.140
Connected to 10.10.225.140.
220 (vsFTPd 3.0.3)
Name (10.10.225.140:kali): groot
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
dr-xr-xr-x    3 65534    65534        4096 Oct 04  2019 .
dr-xr-xr-x    3 65534    65534        4096 Oct 04  2019 ..
drwxr-xr-x    2 1001     1001         4096 Oct 04  2019 files
226 Directory send OK.
ftp> cd files
250 Directory successfully changed.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 1001     1001         4096 Oct 04  2019 .
dr-xr-xr-x    3 65534    65534        4096 Oct 04  2019 ..
-rw-r--r--    1 0        0              33 Oct 04  2019 flag3.txt
226 Directory send OK.

ftp> get flag3.txt
local: flag3.txt remote: flag3.txt
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for flag3.txt (33 bytes).
226 Transfer complete.
33 bytes received in 0.00 secs (6.8934 kB/s)

ftp> exit
221 Goodbye.

kali@kali:~$ ls
flag3.txt 
kali@kali:~$ cat flag3.txt 
8fc651a739befc58d450dc48e1f1fd2e

```

-----

### Nmap Enumeration

__Important__
- SSH on 22
- FTP on 21 (vsftpd 3.0.3)
- HTTP on 80 (Node.js)

```shell
kali@kali:~$ nmap 10.10.225.140 -A -p-
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-24 13:07 EDT                                                  
Nmap scan report for 10.10.225.140                                                                               
Host is up (0.059s latency).                                                                                     
Not shown: 65532 closed ports                                                                                    
PORT   STATE SERVICE VERSION                                                                                     
21/tcp open  ftp     vsftpd 3.0.3                                                                                
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)                                
| ssh-hostkey:                                                                                                   
|   2048 1e:3c:2b:9b:ee:03:e3:7a:69:8c:7d:25:b6:ea:72:91 (RSA)                                                   
|   256 72:dc:53:1a:e4:fc:1e:89:f9:b5:d6:5b:b6:a2:23:68 (ECDSA)                                                  
|_  256 f9:24:89:4d:7b:ff:bf:8b:5b:77:6b:b4:91:83:04:32 (ED25519)                                                
80/tcp open  http    Node.js Express framework                                                                   
|_http-title: Avengers! Assemble!                                                                                
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel                                                   
                                                                                                                 
Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 44.83 seconds
```

## [Task 5] Gobuster

Found a few files/directories; though `/portal` returns a login page.

```shell
kali@kali:~$ gobuster dir -u http://10.10.225.140 -w /usr/share/seclists/Discovery/Web-Content/common.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.225.140
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/24 13:19:06 Starting gobuster
===============================================================
/Home (Status: 302)
/assets (Status: 301)
/css (Status: 301)
/home (Status: 302)
/img (Status: 301)
/js (Status: 301)
/logout (Status: 302)
/portal (Status: 200)
===============================================================
2020/09/24 13:19:36 Finished
===============================================================
```

## [Task 6] SQL Injection

On page `/portal`, login with username `' or 1=1--` and password `' or 1=1--`.

The view page source with `Ctrl+U` (browser-depedant), just Right-Click -> View Source. Source viewer should count lines to be `223`.

## [Task 7] Remote Code Execution and Linux 

After trying numerous commands, such as `awk`, `grep`, `head`, `tail`, and trying to decode some base64, I eventually ran `less ../flag5.txt` to get the flag!

```
d335e2[REDACTED]718af7
```


