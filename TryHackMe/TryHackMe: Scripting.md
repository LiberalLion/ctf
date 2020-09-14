# Scripting

## [Task 1] Base 64

TBA, this was fairly easy... Will dig out the script in future for this task.

## [Task 2] Gotta catch'em all

My first attempt at this failed, it's a pretty touch challenge.

Anyway, we need to start out with an `nmap` scan.

### Port enumeration with nmap

It's important to include the `-p-` tag, because the port's changed.
```
kali@kali:~/Desktop/TryHackMe/picklerick$ nmap -sV -sC 10.10.181.243 -p-
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-13 12:07 EDT
Nmap scan report for 10.10.181.243
Host is up (0.039s latency).
Not shown: 65532 closed ports
PORT      STATE SERVICE    VERSION
22/tcp    open  ssh        OpenSSH 7.2p2 Ubuntu 4ubuntu2.7 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 dc:6d:6e:49:3a:c5:3d:82:86:82:fc:0e:6b:fd:62:1f (RSA)
|   256 2e:3d:77:b6:d1:59:b6:ca:39:86:6b:f8:96:7a:b7:ba (ECDSA)
|_  256 6e:e5:dd:15:83:e8:b5:57:97:a9:eb:41:61:39:b5:7b (ED25519)
3010/tcp  open  http       Werkzeug httpd 0.14.1 (Python 3.5.2)
|_http-title: Site doesn't have a title (text/html; charset=utf-8).
23456/tcp open  tcpwrapped
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 26.71 seconds
```

Note that the `http` server is on port `3010`.

### First browse to the http server.

Navigate the box on port `3010`. You'll find the intitial page.

### Start scripting the python script.

```

```