			#######################
			#ignitionServer README#
			#######################
# $Id: readme.txt,v 1.4 2004/05/28 20:35:06 ziggythehamster Exp $


	===========++++++++===========++++++++===========

ignitionServer is (C)  Keith Gable and Nigel Jones.
----------------------------------------------------
You must include this notice in any modifications you make. You must additionally
follow the GPL's provisions for sourcecode distribution and binary distribution.
If you are not familiar with the GPL, please read LICENSE.TXT. 
(you are welcome to add a "Based On" line above this notice, but this notice must remain intact!)
Released under the GNU General Public License

Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>

ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>

	===========++++++++===========++++++++===========

Contents
1. License Info
2. Support Info
3. Installation
4. Frequently Asked Questions

	===========++++++++===========++++++++===========

1. License Info

The software you have download is OpenSource and protected under the GNU General Public 
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
http://sourceforge.net/docman/display_doc.php?docid=20437&group_id=96071

	===========++++++++===========++++++++===========

3. Installation

ignitionServer should have came with an installer. There are two versions of the installer, one
for Windows 9x and one for Windows NT. The Windows 9x installer will install on NT systems, but
the ignitionServer Monitor will not be installed. The Windows NT installer will ONLY work on NT
systems, because the ignitionServer Monitor uses critical NT system calls.

Windows 9x includes: Windows 95, Windows 98, Windows 98 SE, and Windows Millenium Edition
Windows NT includes: Windows NT 4, Windows 2000, Windows XP, and Windows Server 2003

This _might_ run under UNIX/Linux with Wine, but you will have to play with it yourself (i.e. do
not post to the support tracker; WE CAN NOT HELP YOU!)

Remember to disable DIE in your ircx.conf file.

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

Q: ignitionServer sends out Closing Link: (AutoKilled: Server Misconfigured) and disconnects users on 
   connection
A: A new feature was introduced to stop incorrectly configured servers to be used…(E.G. Using Default 
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

Q: Why doesn't MSN connect?
A: New versions of ignitionServer do not support the MSN Chat Control. We do not know if or when
   this capability will be added.

Q: Is ignitionServer free?
A: Absolutely. You should never pay for a copy of ignitionServer because it is released under the
   GNU General Public License and is avaliable for download for free from SourceForge.net and our
   own website. If you paid for ignitionServer (note: not ignitionServer hosting), we can't help
   you get your money back, but we can help prosecute the violator(s). There is one thing I
   should note: the GNU General Public License permits people to charge a reproduction fee to
   make you a copy. If you only paid for someone to send you a copy, you didn't get ripped off. If
   you paid because someone said it costed money (i.e. wasn't free), you did get ripped off :P

Q: How do I add IRC operators?
A: Adding operators is a bit harder than before, but the concept is the same as most IRCDs. Browse
   to where ignitionServer is installed and open ircx.conf in Notepad. Somewhere in the file, add
   an "O" line. It is formatted like this:
     O:<hostname>:<password>:<username>:<operator-flags>:<connection-class>
   Hostname is the standard IRC hostname of the user (wildcards permitted). For example, if someone
   used AOL, their hostname/hostmask would be *@*aol.com. Password and username are
   self-explanitory. Operator flags can be any of the following: osixkrRDCcKB. Most are standard
   operator flags, however there are a few you should be aware of. R and D allow the oper to
   restart and die (stop) the server. They still require the die/restart password.

If you have any more questions, see our forum at ignition-project.com.