# TryHackMe: CTF Collection Vol.1 (Write-up)

A collection of tasks useful for CTFs. [CTF Vol.1](https://tryhackme.com/room/ctfcollectionvol1) is a TryHackMe box.



# Task 1

Read the author note and hit complete.

# Task 2

Decode the encrypted base64 text

```shell
$ echo 'VEhNe2p1NTdfZDNjMGQzXzdoM19iNDUzfQ==' | base64 -d
THM{ju57_d3c0d3_7h3_b453}
```

# Task 3

Download the file.
It's a JPG file.
To extract _meta_ data from an image, use `exiftool`.
The flag is hidden in the Owner Type.

```shell
$ exiftool Findme.jpg 
ExifTool Version Number         : 12.06
File Name                       : Findme.jpg
Directory                       : .
File Size                       : 34 kB
File Modification Date/Time     : 2020:09:25 22:26:33+01:00
File Access Date/Time           : 2020:09:25 22:26:33+01:00
File Inode Change Date/Time     : 2020:09:25 22:26:55+01:00
File Permissions                : rw-r--r--
File Type                       : JPEG
File Type Extension             : jpg
MIME Type                       : image/jpeg
JFIF Version                    : 1.01
X Resolution                    : 96
Y Resolution                    : 96
Exif Byte Order                 : Big-endian (Motorola, MM)
Resolution Unit                 : inches
Y Cb Cr Positioning             : Centered
Exif Version                    : 0231
Components Configuration        : Y, Cb, Cr, -
Flashpix Version                : 0100
Owner Name                      : THM{3x1f_0r_3x17}
Comment                         : CREATOR: gd-jpeg v1.0 (using IJG JPEG v62), quality = 60.
Image Width                     : 800
Image Height                    : 480
Encoding Process                : Progressive DCT, Huffman coding
Bits Per Sample                 : 8
Color Components                : 3
Y Cb Cr Sub Sampling            : YCbCr4:2:0 (2 2)
Image Size                      : 800x480
Megapixels                      : 0.384
```

# Task 4

Download the image file [Extinction.jpg](Extinction.jpg).
And search for hidden text.

```shell
$ steghide extract -sf Extinction.jpg
Enter passphrase: 
wrote extracted data to "Final_message.txt".
$ ls
Extinction.jpg  Final_message.txt  Findme.jpg  README.md
$ cat Final_message.txt
It going to be over soon. Sleep my child.

THM{500n3r_0r_l473r_17_15_0ur_7urn}
```

# Task 5

The flag is hidden in the text, but coloured in white.
Double click and highlight to reveal this text on THM.

```
Huh, where is the flag? THM{wh173_fl46}
```

# Task 6

This task requires you to read a [QR code](QR.png).
I found a good toolset to do [read QR codes](https://askubuntu.com/questions/22871/software-to-read-a-qr-code) with.

```shell
$ sudo apt-get install zbar-tools
...
$ zbarimg QR.png
QR-Code:THM{qr_m4k3_l1f3_345y}
scanned 1 barcode symbols from 1 images in 0.01 seconds
```

# Task 7

Download the file `hello.hello`. And try to _reverse it or read it_. I chose to read it.

```shell
# strings hello.hello
/lib64/ld-linux-x86-64.so.2
libc.so.6
puts
printf
__cxa_finalize
__libc_start_main
GLIBC_2.2.5
_ITM_deregisterTMCloneTable
__gmon_start__
_ITM_registerTMCloneTable
u/UH
[]A\A]A^A_
THM{345y_f1nd_345y_60}
Hello there, wish you have a nice day
;*3$"
GCC: (Debian 9.2.1-21) 9.2.1 20191130
crtstuff.c
deregister_tm_clones
__do_global_dtors_aux
completed.7447
```

# Task 8

Decode the following `3agrSy1CewF9v8ukcSkPSYm3oKUoByUpKG4L`.

```sh
$ apt install base58
...
$ echo '3agrSy1CewF9v8ukcSkPSYm3oKUoByUpKG4L' | base58 -d
THM{17_h45_l3553r_l3773r5}
```

# Task 9 

Decode the text `MAF{atbe_max_vtxltk}`.
It's a encoded with a Caesar Cipher. 
You can crack it with [an online tool that cracks Caesar ciphers](https://www.xarg.org/tools/caesar-cipher/).
This particular ciphertext is shifted 7 places.

```
ZNS{ngor_znk_igkygx}
```

# Task 10

A _comment_ is referenced, so check the question's source code.


```html
THM{4lw4y5_ch3ck_7h3_c0m3mn7} 
```

# Task 11

A broken png file.

Fix the PNG header with a hex editor.
I used a HexEditor in Visual Studio Code.
And changed first line to read
```
.PNG........IHDR
```

This [fixed the image](spoil.png), then revealed the flag.

```
THM{y35_w3_c4n}
```

# Task 12

Some hidden flag in TryHackMe social account.
Check all social media accounts. 

[Reddit account has a post](https://www.reddit.com/r/tryhackme/comments/eizxaq/new_room_coming_soon/?utm_source=share&utm_medium=web2x&context=3) for when the room was released.

```
THM{50c14l_4cc0un7_15_p4r7_0f_051n7}
```

# Task 13

Asked to decode 
```
++++++++++[>+>+++>+++++++>++++++++++<<<<-]>>>++++++++++++++.------------.+++++.>+++++++++++++++++++++++.<<++++++++++++++++++.>>-------------------.---------.++++++++++++++.++++++++++++.<++++++++++++++++++.+++++++++.<+++.+.>----.>++++.
```

Pretty sure I recognize this as [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck). 
We'll need a [Brainfuck decoder](https://www.dcode.fr/brainfuck-language) for this.

```
THM{0h_my_h34d}
```

# Task 14

Question hints towards _exclusivity_. Write an script that rans exclusive or operator `^` against the two strings.
>
>    ```
>    $ python
>    >>> s1 = "44585d6b2368737c65252166234f20626d"
>    >>> s2 = "1010101010101010101010101010101010"
>    >>> h = hex(int(s1, 16) ^ int(s2, 16))[2:]
>    >>> bytes.fromhex(h).decode('utf-8')
>    THM{3xclu51v3_0r}
>    ```
>    By [Aldeid](https://www.aldeid.com/wiki/TryHackMe-CTF-collection-Vol1#.5BTask_13.5D_Spin_my_head_02.2F01.2F2020)

# Task 15

Exfiltrate data from the given JPG.
We can use `binwalk` to extract a hidden file.

```shell
$ binwalk -e hell.jpg 

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             JPEG image data, JFIF standard 1.02
30            0x1E            TIFF image data, big-endian, offset of first image directory: 8
265845        0x40E75         Zip archive data, at least v2.0 to extract, uncompressed size: 69, name: hello_there.txt
266099        0x40F73         End of Zip archive, footer length: 22

$ ls -lah
total 444K
drwxr-xr-x  3 kali kali 4.0K Sep 25 23:44 .
drwxr-xr-x 22 kali kali 4.0K Sep 25 22:22 ..
-rw-r--r--  1 kali kali  28K Sep 25 22:29 Extinction.jpg
-rw-r--r--  1 root root   79 Sep 25 22:31 Final_message.txt
-rw-r--r--  1 kali kali  35K Sep 25 22:26 Findme.jpg
-rw-r--r--  1 kali kali 260K Sep 25 23:43 hell.jpg
drwxr-xr-x  2 root root 4.0K Sep 25 23:44 _hell.jpg.extracted
-rw-r--r--  1 kali kali  17K Sep 25 22:37 hello.hello
-rw-r--r--  1 kali kali 2.0K Sep 25 22:33 QR.png
-rw-r--r--  1 kali kali 5.3K Sep 25 23:43 README.md
-rw-r--r--  1 kali kali  70K Sep 25 23:16 spoil.png

$ cd _hell.jpg.extracted/

$ ls
40E75.zip  hello_there.txt

$ cat hello_there.txt 
Thank you for extracting me, you are the best!

THM{y0u_w4lk_m3_0u7}
```

_TBC_ ...

