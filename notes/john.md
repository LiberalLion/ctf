# John the Ripper

ZIP
---
```shell
sudo zip2john 16162020_backup.zip > 16162020_backup.hash
```
```
john 16162020_backup.hash -v --wordlist=/usr/share/wordlist/rockyou.txt

```
