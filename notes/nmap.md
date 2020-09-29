# Nmap notes

__SMB enumeration__

```
## Ports could be 139, 445.
nmap -p 445 --script=smb-enum-shares.nse,smb-enum-users.nse 10.10.161.57
```