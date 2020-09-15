# TryHackMe: Hack Park

[Hack Park](https://tryhackme.com/room/hackpark) is a TryHackMe CTF. 

> Bruteforce a websites login with Hydra, identify and use a public exploit then escalate your privileges on this Windows machine!

	
## [Task 1] Deploy the vulnerable Windows machine

### Deploy the machine and access its web server.

Hit the Deploy button.

In this write-up, the hostname `target.thm` will be used where appropriate. This can be set in `/etc/hosts` file if you're unfamiliar.

Navigate to the server IP via FireFox. This fails, so lets run an `nmap` scan, and find what port the web-server is running on.


#### Nmap

After figuring that the box _isn't_ broken by reading the blurb, I saw that the box doesn't respond to ICMP packets.

##### No response to initial ping
So, of course, the initial `ping` failed.
```
$ ping target.thm
PING target.thm (10.10.49.211) 56(84) bytes of data.
^C
--- target.thm ping statistics ---
8 packets transmitted, 0 received, 100% packet loss, time 7147ms
```

##### No response to initial nmap
As such, we need to tailor our `nmap` scan to assume the host _is_ alive, despite no response. This can be done with the `-Pn` flag. 
```
$ nmap -sV -sC -Pn target.thm
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-14 18:20 EDT
Nmap scan report for target.thm (10.10.49.211)
Host is up.
All 1000 scanned ports on target.thm (10.10.49.211) are filtered

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 202.72 seconds

```
However, it seems the most popular ports aren't open. And after running a number of different nmap variations, I switched to `masscan` for better performance.

##### Masscan returns something!

I switched to `masscan` because I had no luck with `nmap`. This reveals port `993` as being open.

```
kali@kali:~/Documents/ctf/try-hack-me/hack-park$ sudo masscan 10.10.49.211 --ports 0-65535 --rate 1000 

Starting masscan 1.0.5 (http://bit.ly/14GZzcT) at 2020-09-14 23:44:08 GMT
 -- forced options: -sS -Pn -n --randomize-hosts -v --send-eth
Initiating SYN Stealth Scan
Scanning 1 hosts [65536 ports/host]
Discovered open port 993/tcp on 10.10.49.211                                   
```

##### Enumerated an `imaps`

```
kali@kali:~/Documents/ctf/try-hack-me/hack-park$ nmap target.thm -p 993 -Pn -A
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-14 19:48 EDT
Nmap scan report for target.thm (10.10.49.211)
Host is up.

PORT    STATE    SERVICE VERSION
993/tcp filtered imaps
```

##### Second masscan returns something else
But, after realising I couldn't access 993; I ran a second `masscan` scan: 
```
kali@kali:~/Documents/ctf/try-hack-me/hack-park$ sudo masscan 10.10.49.211 --ports 0-65535 --rate 1000 -sS -Pn

Starting masscan 1.0.5 (http://bit.ly/14GZzcT) at 2020-09-14 23:53:26 GMT
 -- forced options: -sS -Pn -n --randomize-hosts -v --send-eth
Initiating SYN Stealth Scan
Scanning 1 hosts [65536 ports/host]
Discovered open port 143/tcp on 10.10.49.211                                   
```

##### Enumerated an `imap`
Which revealed `143/tcp`, a less secure `imap`...
```
kali@kali:~/Documents/ctf/try-hack-me/hack-park$ nmap -Pn -p 143 -A target.thm
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-14 19:58 EDT
Nmap scan report for target.thm (10.10.49.211)
Host is up.

PORT    STATE    SERVICE VERSION
143/tcp filtered imap

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 3.26 seconds

```



#### Navigating to `http://target.thm:143`






### Whats the name of the clown displayed on the homepage? 

## [Task 2] Using Hydra to brute-force a login

_TBA_

## [Task 3] Compromise the machine

_TBA_

## [Task 4] Windows Privilege Escalation

_TBA_

## [Task 5] Privilege Escalation Without Metasploit 

_TBA_