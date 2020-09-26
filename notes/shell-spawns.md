# Shell spawns

__Python__
```python
python -c 'import pty; pty.spawn("/bin/sh")' 
```

__sh interactive shell__
```sh
/bin/sh -i
```

__Vim__
```shell
vim
vim>:!
vim>:!bash
vim>:!sh
vim>:set shell=/bin/bash:shell
```

__perl__
```shell
perl —e 'exec "/bin/sh";'
```

__nmap__
```console
nmap --interactive
nmap> !sh
```