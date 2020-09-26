# Chisel notes

Useful for port forwarding; Windows/UNIX.

Client 
----
__Normal__
```console
chisel client SERVERIP:PORT 
```
__Reverse__
```console
chisel client SERVERIP:PORT R:8888:127.0.0.1:8888
```

Server
----
__Normal__
```console
chisel server --port PORT
```
__Reverse__
```console
chisel server --port PORT --reverse
```