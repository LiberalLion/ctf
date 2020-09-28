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
----

Admin --> Bludit
---
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


Null byte breaks?
----
http://10.10.10.191/usb%0
```
Bad Request

Your browser sent a request that this server could not understand.
Apache/2.4.41 (Ubuntu) Server at 10.10.10.191 Port 80
```

