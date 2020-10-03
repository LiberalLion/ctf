# TryHackMe: ConvertMyVideo

## Info

- Apache/2.4.29 


## Nmap

Two services; 22 SSH, 80 HTTP.


```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/convertmyvideo$ nmap -A 10.10.44.51
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-03 18:43 BST
Nmap scan report for 10.10.44.51
Host is up (0.022s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   2048 65:1b:fc:74:10:39:df:dd:d0:2d:f0:53:1c:eb:6d:ec (RSA)
|   256 c4:28:04:a5:c3:b9:6a:95:5a:4d:7a:6e:46:e2:14:db (ECDSA)
|_  256 ba:07:bb:cd:42:4a:f2:93:d1:05:d0:b3:4c:b1:d9:b1 (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Site doesn't have a title (text/html; charset=UTF-8).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

## Gobuster

Found /admin


