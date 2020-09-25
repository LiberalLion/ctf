# TryHackMe: Blaster (Write-up)

## Nmap scan

Don't run nmap on all ports are you won't find the correct number of open ports (`2`).

```shell
kali@kali:~/Desktop/TryHackMe/blaster$ nmap 10.10.211.74
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-24 15:44 EDT
Nmap scan report for target.thm (10.10.211.74)
Host is up (0.051s latency).
Not shown: 994 closed ports
PORT     STATE SERVICE
80/tcp   open  http
135/tcp  open  msrpc
139/tcp  open  netbios-ssn
445/tcp  open  microsoft-ds
3306/tcp open  mysql
3389/tcp open  ms-wbt-server
```

A bunch of open ports; but notably, there are:
- Samba shares
- RPC ports
- HTTP server
- MySQL
- HTTP APIs

## Browsing to host

On browsing the host we say a default install page entitled `IIS Windows Server`

## Lets see if there's any directorys

And we find a WordPress install on directory `/retro`.

```
kali@kali:~/Desktop/TryHackMe/blaster$ gobuster dir -u http://target.thm -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -t 100
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://target.thm
[+] Threads:        100
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/24 15:47:38 Starting gobuster
===============================================================
/retro (Status: 301)
/Retro (Status: 301)
```

## Potential username

`Wade` is immediately obvious as a potentially attackable user.

## After crawling through posts we find a potential password

In post `http://target.thm/retro/index.php/2019/12/09/ready-player-one/#comment-2`

```
Wade
December 9, 2019

Leaving myself a note here just in case I forget how to spell it: parzival  
```

Wade reminds him self of a potential password: `parzival`.

## Lets try connect to the machine via RDP

We can connect using `xfreerdp`  on Kali..

```
http://target.thm/retro/index.php/2019/12/09/ready-player-one/#comment-2
```

This gives us RDP access. And then we're greated with a flag in `user.txt` file sat on Wade's desktop.

```
THM{HACK_PLAYER_ONE}
```

