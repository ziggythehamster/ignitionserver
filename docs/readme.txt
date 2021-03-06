			#######################
			#ignitionServer README#
			#######################
# $Id: readme.txt,v 1.15 2004/12/07 00:51:15 ziggythehamster Exp $
# TODO:
#  - format for 800x600 and not 1280x1024, it is too wide

	===========++++++++===========++++++++===========

ignitionServer is (C) Keith Gable and Contributors
----------------------------------------------------
You must include this notice in any modifications you make. You must additionally
follow the GPL's provisions for sourcecode distribution and binary distribution.
If you are not familiar with the GPL, please read LICENSE.TXT.
(you are welcome to add a "Based On" line above this notice, but this notice must
remain intact!)
Released under the GNU General Public License

Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
Contributors:        Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
                     Reid Burke  (Airwalk) <airwalk@ignition-project.com>

ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>

	===========++++++++===========++++++++===========

Contents
1. License Info
2. Support Info
3. Installation
4. Frequently Asked Questions

	===========++++++++===========++++++++===========

1. License Info

The software you have downloaded is open source and protected under the GNU General Public 
License. For more information, read LICENSE.TXT (you should have been presented this when you
installed).

We encourage you to read this file before making any changes to the ignitionServer source code.

	===========++++++++===========++++++++===========

2. Support Info

Support for any version of ignitionServer can be obtained via the SourceForge Support Tracker.
Support for a CVS version will be done on a Best-Effort basis (basically, you're on your own
unless it's a blatantly obvious error on your part or on our part)

The support tracker can be found at:
http://sourceforge.net/tracker/?group_id=96071&atid=613527

*** PLEASE DO NOT POST BUGS VIA THE SUPPORT TRACKER ***
For more information on reporting bugs, see:
http://sourceforge.net/tracker/?group_id=96071&atid=613526

Also, as a general rule, please make sure you follow these policies before asking questions:
http://www.catb.org/~esr/faqs/smart-questions.html

	===========++++++++===========++++++++===========

3. Installation

ignitionServer should have come with an installer. This installer runs on Windows 95, 98, Me, 
2000, XP, and 2003. (NOTE: the ignitionServer Monitor runs on all platforms now!)

This _might_ run under UNIX/Linux with Wine, but you will have to play with it yourself (i.e. do
not post to the support tracker; WE CAN NOT HELP YOU!)

After installing ignitionServer, you will need to configure it. To do this, browse to where you
installed ignitionServer and open ircx.conf in Notepad. To change the Message of the Day, edit
ircx.motd in Notepad.

Remember to disable X:DIE in your ircx.conf file. Failure to do so WILL result in messages like
"server misconfigured". This is a safety measure, so people don't just use default installs, which 
usually have O: lines with passwords like "admin".

	===========++++++++===========++++++++===========

4. Frequently Asked Questions

Older versions of ignitionServer were a bit easier to use/modify than this current version. This
version is MUCH more powerful, has more than enough commands to be useful, and is quite a bit
less buggy. Please make sure you read this FAQ before you post to the support tracker.

Q: When I start ignitionServer, nothing comes up!
A: It's supposed to do this! ignitionServer now runs as a full-fledged daemon. You will not get
   any interface at all (unless you are on Windows NT and you installed the ignitionServer
   Monitor). If you are not sure you started it properly, start your IRC client and type:
     /server localhost
   If you connect to something, the server is running. A less time-intensive method would be to
   hit Ctrl-Alt-Del and see if the ignitionServer process is running.

Q: Why doesn't ignitionServer start?
A: First, make sure you read the above question. Then, check the following things:
   1) Is ircx.conf in the same folder as ignitionServer?
   2) Did I modify ircx.conf improperly?
   3) Is ircx.conf named properly (it must be ircx.conf -- do not capitalize the extension or any
      other part of the name!)?
   If you diagnosed those things and still have a problem, make sure ignitionServer isn't running
   as another process (Ctrl-Alt-Del). ignitionServer will only start one time. All other times it
   will not allow it.

Q: Why does ignitionServer send out Closing Link: (AutoKilled: Server Misconfigured [see ircx.conf])
   and disconnect users on connection?
A: A new feature was introduced to stop incorrectly configured servers to be used. (E.G. Using Default 
   A Lines). To disable this feature simply find X:DIE in ircx.conf file and change the 1 to a 0

Q: What operating system is reccommended to run ignitionServer?
A: We reccommend you use Windows NT 4, Windows 2000, Windows XP, or Windows Server 2003. Windows
   95/98/ME is not reccommended at all.

Q: Does ignitionServer violate my EULA?
A: Probably. We can't answer this for you though. You need to read the End User License Agreement
   that came with your operating system. Most versions of Windows and Windows NT only allow 10
   simultaneous connections in the EULA. ignitionServer, by design, opens ports and connections
   as it needs to. At any one time, ignitionServer can have anywhere from 0 to 65535 connections
   open. You take full legal responsibility if you decide to violate your EULA.

Q: Why can't I connect to my ignitionServer installation?
A: Are you connecting to the right place? Usually, you'll want to connect to "localhost" or 
   "127.0.0.1". In mIRC, you'd go /server localhost. Other people will want to connect to your
   hostname or IP address. See the next question. If you are trying to connect to localhost or 
   127.0.0.1, make sure ignitionServer is running and that it's running on port 6667.

Q: Why can't others connect to my ignitionServer installation?
A: Is your router or firewall allowing port 6667 through to your machine? Are you behind a proxy?
   If you are behind a proxy, you probably can't run iS except to your local network. If you 
   aren't, you need to make sure your firewall is properly configured and that your router is
   forwarding port 6667 to your machine (see the manual -- usually it's something like "port
   forwarding", "virtual server", "network applications", etc.). It also helps to have a dynamic 
   DNS, which you can get at No-IP.com or DynDNS.org.

Q: Why doesn't MSN connect?
A: ignitionServer does not support the MSN Chat Control. We will never add support for this unless 
   Microsoft decides to open their protocol and make it a "standard", and even then it's not really
   likely we will add it. At this moment, it is ILLEGAL to use the MSN Chat Control beyond its
   intended purpose (to connect to MSN) without official permission from Microsoft Corporation. In
   a nutshell, if you are wanting a server that supports the MSN Chat Control, you will probably be 
   committing a crime by using it. I am not a lawyer, so you will probably want to talk to someone
   that is if you really want to do the lame thing and use the MSN Chat Control.

Q: Is ignitionServer free?
A: Absolutely. You should never pay for a copy of ignitionServer because it is released under the
   GNU General Public License and is avaliable for download for free from SourceForge.net and our
   own website. If you paid for ignitionServer (note: not ignitionServer hosting), we can't help
   you get your money back, because it's legal (the GPL allows it, if source comes with it). 
   There is one thing I should note: the GNU General Public License permits people to charge a 
   reproduction fee to make you a copy. If you only paid for someone to send you a copy, you 
   didn't get ripped off. If you paid because someone said it costed money (i.e. wasn't free), 
   you did get ripped off, but there's nothing we can do to help you, because they legally can 
   do that under the GPL. Just, the source can't cost more than the binary, and the source has to
   be avaliable, too.

Q: How do I add IRC operators?
A: Look in ircx.conf and find "O: Lines - Operator Lines". The comments there will help you a lot.
   For a list of modes, see our website.

Q: What is the difference between oper flag P and p?
A: To be honest, NONE except that they both can be given different on-join-modes.
   To give a on-join-mode for P use
     X:HIGHPROT:[Q|O|V|NORM]
   To give a on-join-mode for p use
     X:LOWPROT:[Q|O|V|NORM]

Q: Where's ChanServ/NickServ/MemoServ?
A: Other IRCX servers (IRCXpro) include the services inside the server. This is a bad, bandwidth-wasting
   idea. ignitionServer, however, handles services like any other self-respecting IRC server should. You
   connect services as a link, and services does the job it needs to do. You need an IRC services that is
   compatible with standard RFC 1459 IRC (Anope works really good, I hear). You may also need to tweak
   some IRC server specific settings (i.e. you probably don't want to use Unreal's SVSMODE). If you want
   services specifically designed for Windows and ignitionServer, use ignitionServices. More information
   can be found at our website.

Q: What's the difference between IRCD and IRCX?
A: Simply put, nothing. There's a common misconception about these acronyms. An IRCX server is just as
   much an IRCD as any other type of IRC server. If you think that an IRCD is something that's not IRCX,
   I probably just confused the hell out of you. IRCD means "IRC server" (daemon is a word used by UNIX
   and UNIX-like systems [Linux] to mean "server"). IRCX means "Internet Relay Chat eXtensions". When
   IRCX is properly implemented, it is RFC 1459 (the IRC specification) plus the IRCX draft. IRCX is not
   a protocol, but an extension to a protocol. In theory, any regular RFC 1459-compliant server can add
   these extensions. Many people think that IRCDs have weird modes and are "not IRCX". However, you could
   easily turn something like UnrealIRCD into an IRCX server, because IRCX only defines additions to the
   IRC protocol.

   In most circumstances, the differences between regular IRC, and IRC with the extensions (IRCX) are as
   follows. First off, IRCX adds several security-oriented commands, like ACCESS (get/set/unset who has
   access to what levels in a channel) and AUTH (show proof you have credentials to access the server).
   IRCX also adds another level of channel users, the owner. In RFC 1459, only hosts (@) and voices (+)
   were defined. Since RFC 1459's conception in the 80's, IRC servers have added many extra levels, so
   this is somewhat irrelevant. However, in true IRCX (which is RFC 1459 + extensions), there are only 3
   levels: Owner (.), Host (@), and Voice (+). Well, that, and normal user, which has no prefix. You could,
   in theory, have more levels than this, but you may break some really crappy clients. IRCX also provides
   a mechanism for sending a message to a person WITHIN a channel. Before IRCX, any message you sent to a
   user was sent to them directly, out of any context of a channel. In IRCX, you can use the WHISPER
   command, and the message will only apply to that user within that channel.

   IRCX also has channel metadata, or "properties", which set various channel settings, like the language,
   the password required to be an owner, etc. Standard RFC 1459 IRC only has one key, and it's the key
   for getting into a locked room. The IRCX specification also calls for DATA/REQUEST/REPLY, which are
   very powerful commands. They are hardly used, but their applications are nearly limitless. You could use
   these commands for games, telling a special client to change the avatar displayed, and more. Microsoft
   Comic Chat uses these commands for displaying expressions of the comic characters, telling other users
   what character you're using, and a lot more. IRC is more flat, and is designed for text-based communication.
   IRCX allows a bit more dynamic conversation, and that's why some people prefer it. However, some people
   like IRC better because oftentimes IRC servers are a lot more powerful and have more modes and features.

Q: How do I reload a modified MOTD?
A: As an operator (with rehash privledges), type /rehash -MOTD. This will reload the Message of the Day.

Q: How do I edit the Message of the Day?
A: In the same folder as ignitionServer, there is a file called "ircx.motd". Open this file with Notepad and
   save it. If the server is currently running, you will need to type /rehash -MOTD (see above).

Q: How does the Auto VHost (X:AUTOVHOST) system work?
A: The Auto VHost system is very simple to use and set up. Basically, it changes the hostname of IRC operators
   to a specific Virtual Host (VHost) when they log in. For this to work, there has to be an O: line and a V: line,
   both with the same credentials (password/username/hostmask). The X:AUTOVHOST line also needs to be set to "1"
   (enabled). Once these things are completed, operators can log in (with /oper), and they'll automatically get
   their VHost if they have one. If an operator doesn't have a VHost, it will be the same as if X:AUTOVHOST is off (0).

Q: How come I'm getting this error: Error Opening File for Writing: "C:\Program Files\ignitionServer\ignitionServer.exe"?
A: You are attempting to update or uninstall ignitionServer while ignitionServer is running. This cannot be done.
   To exit ignitionServer, hit Ctrl-Alt-Del, and the ignitionServer.exe process (or the task, on Win9x).

Q: How come I'm getting this error: Error Opening File for Writing: "C:\Program Files\ignitionServer\monitor.exe"?
A: You are attempting to update or uninstall ignitionServer while the monitor is running. This cannot be done.
   To exit the monitor, bring it up (from the system tray or taskbar), and press the close button in the corner.

Q: Why don't my L: lines work anymore?
A: In 0.3.5, we reverted back to C: and N: lines for compatibility reasons. Please read ircx.conf for instructions on how to
   use C: and N: lines (they're nearly exactly the same). Sorry for any inconvenience.

Q: What is X:CREATEMODE and how do I use it?
A: X:CREATEMODE is a new X: line that we added to give server administrators greater control over their server. It allows
   the administrator to choose what group of users is able to create channels. In most cases, you will just want the default
   of 0, which allows all users to create channels. If you are setting up a premium chat service, or otherwise will only have
   a fixed set of channels, you will probably want to use 1, which will only allow IRC operators to create channels. In addition
   to this, you can force users to register and identify to NickServ before they can create channels. To do this, set X:CREATEMODE to
   2. For more information, please read ircx.conf in your favorite text editor.

Q: Why isn't ignitionServer working on Windows XP Service Pack 2?
A: Windows XP SP2 adds several security "enhancements", such as limiting the number of outbound connections, and
   introducing an artificial lag between the opening of outbound listening sockets. On a normal desktop system,
   these enhancements will probably prevent you from becoming a spam relay or zombie. When you're using your desktop
   system as a server by running ignitionServer, these enhancements become a serious bottleneck. It will also probably
   prevent ignitionServer from properly initializing (it will say "loaded OK" in the errorlog, becuase the Winsock
   subsystem is lying to ignitionServer). In order to make ignitionServer properly function on XP SP2, you must make
   changes to ircx.conf, and you must patch your TCP/IP subsystem to remove these security enhancements. WARNING:
   PATCHING TCPIP.SYS IS HIGHLY DISCOURAGED BY MICROSOFT AND IT MAY VOID YOUR WARRANTY. YOU ACCEPT ALL RISKS BY
   PATCHING YOUR TCP/IP SUBSYSTEM. BY PATCHING TCPIP.SYS, YOU AGREE NOT TO HOLD US LIABLE FOR ANY DAMAGES. That said,
   you can get the instructions for patching TCPIP.SYS and modifying ircx.conf by clicking Start > (All) Programs >
   ignitionServer > Documentation.

If you have any more questions, see our forum at http://www.ignition-project.com/forums/.