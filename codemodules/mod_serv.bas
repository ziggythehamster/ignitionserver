Attribute VB_Name = "mod_serv"
'ignitionServer is (C) Keith Gable and Contributors
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'Contributors:        Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'                     Reid Burke  (Airwalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: mod_serv.bas,v 1.28 2004/08/01 10:46:12 ziggythehamster Exp $
'
'
'This program is free software.
'You can redistribute it and/or modify it under the terms of the
'GNU General Public License as published by the Free Software Foundation; either version 2 of the License,
'or (at your option) any later version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
'Without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
'See the GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License along with this program.
'if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#Const CanDie = 1
#Const CanRestart = 1
#Const Debugging = 0
'DANGER! ENABLING DEBUGGING HERE MAY MAKE HUGE LOG FILES!
'(300KB per event per person in some cases)
'Turn it on at your own risk.

'to prevent sending events multiple times
Public Event_LastEventTime As Long
Public Event_LastEventType As String
Public Event_LastEventName As String
Public Event_LastEventArgs As String

Option Explicit

Public Function ProcNumeric&(cptr As clsClient, sptr As clsClient, parv$(), Num&)
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- PROCNUMERIC called! (" & cptr.Nick & ")"
#End If
Dim Args$, I&
For I = 1 To UBound(parv)
    If UBound(parv) > I Then
        Args = Args & parv(I) & " "
    Else
        Args = Args & ":" & parv(I)
    End If
Next I
If cptr.AccessLevel < 4 Then Exit Function
Dim Recp As clsClient
Set Recp = GlobUsers(parv(0))
If Recp.Hops > 0 Then
    SendWsock Recp.FromLink.index, ":" & cptr.ServerName & " " & Num & " " & Recp.Nick & " " & Args, vbNullString, , True
Else
    SendWsock Recp.index, Num & " " & Recp.Nick, Args, ":" & cptr.ServerName
End If
End Function

'/*
'** m_version
'**  parv$()[0] = sender prefix
'**  parv$()[1] = remote server
'*/
Public Function m_version(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- VERSION called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
    Dim Target As clsClient
    Set Target = Servers(parv(0))
    If Target.ServerName = ServerName Then
        SendWsock cptr.index, RPL_VERSION & " " & sptr.Nick & " ignitionServer-" & AppVersion & "." & BuildDate & ".0" & " " & ServerName, ":" & AppComments
    Else
        SendWsock Target.FromLink.index, "VERSION", ":" & Target.ServerName, ":" & sptr.Nick
    End If
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_VERSION & " " & cptr.Nick & " ignitionServer-" & AppVersion & "." & BuildDate & ".0" & " " & ServerName, ":" & AppComments
    Else
        Set sptr = GetServer(parv(0))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(0))
          Exit Function
        End If
        SendWsock sptr.FromLink.index, "VERSION", ":" & sptr.ServerName, ":" & cptr.Nick
    End If
End If
End Function
Public Function m_info(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- INFO called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
    Dim Target As clsClient
    Set Target = Servers(parv(0))
    If Target.ServerName = ServerName Then
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":ignitionServer --"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":Based on pureIRCd, written by Ben Affleck, Dennis Fisch,"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":Johnny aka Pern, and Eric Dickman. Aside from the network core"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":being the same, most of the code has been improved or tweaked."
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":The entire IRCX core is completely from scratch."
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":This program is free software; you can redistribute it and/or"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":modify it under the terms of the GNU General Public License as"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":published by the Free Software Foundation; either version 2, or"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":(at your option) any later version."
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":ignitionServer is actively developed by mainly one person,"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":Keith Gable <ziggy@ignition-project.com>, but there have been"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":a few other contributors, namely Reid Burke <airwalk@airwalklogik.com>"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":and Nigel Jones <digi_guy@users.sourceforge.net>. In fact, without Reid and"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":Nigel's help, ignitionServer would definitely not be as practical"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":as it is."
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":ignitionServer updates, releases, help, and information can be"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":received at our website, http://www.ignition-project.com/. If you"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":want to report a bug, please report it on our SourceForge bug"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":tracker: http://sourceforge.net/tracker/?group_id=96071&atid=613526"
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":Additional credits can be found in credits.txt in the docs directory."
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":Version: " & AppVersion & "." & BuildDate
        SendWsock cptr.index, RPL_INFO & " " & sptr.Nick, ":On-line Since: " & StartUpDate
        SendWsock cptr.index, RPL_ENDOFINFO & " " & sptr.Nick, ":End of /INFO list."
    Else
        SendWsock Target.FromLink.index, "INFO", ":" & Target.ServerName, ":" & sptr.Nick
    End If
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":ignitionServer --"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":Based on pureIRCd, written by Ben Affleck, Dennis Fisch,"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":Johnny aka Pern, and Eric Dickman. Aside from the network core"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":being the same, most of the code has been improved or tweaked."
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":The entire IRCX core is completely from scratch."
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":This program is free software; you can redistribute it and/or"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":modify it under the terms of the GNU General Public License as"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":published by the Free Software Foundation; either version 2, or"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":(at your option) any later version."
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":ignitionServer is actively developed by mainly one person,"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":Keith Gable <ziggy@ignition-project.com>, but there have been"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":a few other contributors, namely Reid Burke <airwalk@airwalklogik.com>"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":and Nigel Jones <digi_guy@users.sourceforge.net>. In fact, without Reid and"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":Nigel's help, ignitionServer would definitely not be as practical"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":as it is."
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":ignitionServer updates, releases, help, and information can be"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":received at our website, http://www.ignition-project.com/. If you"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":want to report a bug, please report it on our SourceForge bug"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":tracker: http://sourceforge.net/tracker/?group_id=96071&atid=613526"
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":Additional credits can be found in credits.txt in the docs directory."
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ": "
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":Version: " & AppVersion & "." & BuildDate
        SendWsock cptr.index, RPL_INFO & " " & cptr.Nick, ":On-line Since: " & StartUpDate
        SendWsock cptr.index, RPL_ENDOFINFO & " " & cptr.Nick, ":End of /INFO list."
    Else
        Set sptr = GetServer(parv(0))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(0))
          Exit Function
        End If
        SendWsock sptr.FromLink.index, "INFO", ":" & sptr.ServerName, ":" & cptr.Nick
    End If
End If
End Function
Public Function m_isircx(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- ISIRCX called! (" & cptr.Nick & ")"
#End If
Dim SomeNick As String
Dim IRCXState As Long

If Len(cptr.Nick) = 0 Then
  SomeNick = "Anonymous"
Else
  SomeNick = cptr.Nick
End If

If cptr.IsIRCX Then
  IRCXState = 1
Else
  IRCXState = 0
End If

'/mode isircx and /isircx only return if the server supports IRCX or not
'it does not enable it, but if IRCX is already enabled, it's supposed to tell you

SendWsock cptr.index, SPrefix & " 800 " & SomeNick & " " & IRCXState & " 0 " & AuthPackages & " 512 " & Capabilities, vbNullString, , True
End Function
Public Function m_ircx(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- IRCX called! (" & cptr.Nick & ")"
#End If
Dim SomeNick As String
Dim IRCXState As Long

If Len(cptr.Nick) = 0 Then
  SomeNick = "Anonymous"
Else
  SomeNick = cptr.Nick
End If

'/ircx enables IRCX
'so this will always return 1 (on)

SendWsock cptr.index, SPrefix & " 800 " & SomeNick & " 1 0 " & AuthPackages & " 512 " & Capabilities, vbNullString, , True
cptr.IsIRCX = True
If cptr.HasRegistered Then SendDirect cptr.index, cptr.Prefix & " MODE " & cptr.Nick & " +x" & vbCrLf
End Function

'/*
'** m_squit
'**  parv$()[0] = sender prefix
'**  parv$()[1] = server name
'**  parv$()[2] = comment
'*/
Public Function m_squit(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- SQUIT called! (" & cptr.Nick & ")"
#End If
'    /*
'    ** SQUIT semantics is tricky, be careful...
'    **
'    ** The old (irc2.2PL1 and earlier) code just cleans away the
'    ** server client from the links (because it is never true
'    ** "cptr as clsClient == acptr as clsClient".
'    **
'    ** This logic here works the same way until "SQUIT host" hits
'    ** the server having the target "host" as local link. Then it
'    ** will do a real cleanup spewing SQUIT's and QUIT's to all
'    ** directions, also to the link from which the orinal SQUIT
'    ** came, generating one unnecessary "SQUIT host" back to that
'    ** link.
'    **
'    ** One may think that this could be implemented like
'    ** "hunt_server" (e.g. just pass on "SQUIT" without doing
'    ** nothing until the server having the link as local is
'    ** reached). Unfortunately this wouldn't work in the real life,
'    ** because either target may be unreachable or may not comply
'    ** with the request. In either case it would leave target in
'    ** links--no command to clear it away. So, it's better just
'    ** clean out while going forward, just to be sure.
'    **
'    ** ...of course, even better cleanout would be to QUIT/SQUIT
'    ** dependant users/servers already on the way out, but
'    ** currently there is not enough information about remote
'    ** clients to do this...   --msa
'    */
Dim Target As clsClient, User() As clsClient, I&, z&
If cptr.AccessLevel = 4 Then
    If sptr.AccessLevel = 4 Then
        If Not sptr Is cptr Then
            'We lost a server (recieved from a server, but message wasnt originated from it) -Dill
            KillStruct parv(0), enmTypeServer
            SendSvrMsg "*** Notice -- Recieved SQUIT for " & parv(0) & " from " & sptr.ServerName
            SendToServer_ButOne "SQUIT :" & parv(0), cptr.ServerName, sptr.ServerName
        Else
            'cptr wants to close it's connection to us -Dill
            KillStruct parv(0), enmTypeServer
            SendSvrMsg "*** Notice -- Recieved SQUIT for " & parv(0) & " from " & sptr.ServerName
            SendToServer_ButOne "SQUIT :" & parv(0), cptr.ServerName, sptr.ServerName
        End If
    Else
        'A message is forwarded to us to squit a server off,
        'if target is local to us, do the job, if not forward it. -Dill
        Set Target = Servers(parv(0))
        If Target Is Nothing Then Exit Function
        If Target.Hops = 1 Then
            User = GlobUsers.Values
            'remove all users (behind and/or directly from) this link -Dill
            For I = LBound(User) To UBound(User)
                If User(I).FromLink Is Target Then
                    For z = 1 To User(I).OnChannels.Count
                        SendToChan User(I).OnChannels.Item(z), User(I).Prefix & " QUIT :" & ServerName & " " & Target.ServerName, vbNullString
                    Next z
                    KillStruct User(I).Nick
                    SendToServer "QUIT :" & ServerName & " " & Target.ServerName, User(I).Nick
                    '#If Debugging = 1 Then
                        SendSvrMsg "*** Notice -- User " & User(I).Nick & " lost during netsplit"
                    '#End If
                    Set User(I) = Nothing
                End If
            Next I
            User = Servers.Values
            For I = LBound(User) To UBound(User)
                If User(I).FromLink Is cptr Then
                    Servers.Remove User(I).ServerName
                    SendToServer "SQUIT :" & User(I).ServerName, ServerName
                    Set User(I).FromLink = Nothing
                    '#If Debugging = 1 Then
                        SendSvrMsg "*** Notice -- Server " & User(I).ServerName & " lost during netsplit"
                    '#End If
                    Set User(I) = Nothing
                End If
            Next I
            Servers.Remove cptr.ServerName
            SendToServer "SQUIT :" & cptr.ServerName, cptr.ServerName
            Sockets.CloseIt Target.index
            IrcStat.LocServers = IrcStat.LocServers - 1
            IrcStat.GlobServers = IrcStat.GlobServers - 1
        Else
            SendWsock Target.FromLink.index, "SQUIT " & parv(0), sptr.Nick
        End If
    End If
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "SQUIT")
        Exit Function
    End If
    If UBound(parv) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "SQUIT")
        Exit Function
    End If
    If Not (cptr.CanLocRoute Or cptr.CanGlobRoute) Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    Set Target = GetServer(parv(0))
    If Target.ServerName = ServerName Then Exit Function
    If Target Is Nothing Then
        SendWsock cptr.index, ERR_NOSUCHSERVER & " " & cptr.Nick, TranslateCode(ERR_NOSUCHSERVER, parv(0))
        Exit Function
    End If
    If Target.Hops > 1 Then
        If cptr.CanGlobRoute Then
            SendWsock Target.FromLink.index, "SQUIT " & Target.ServerName, ":" & parv(1), cptr.Prefix
            SendSvrMsg "*** Notice -- Recieved SQUIT for " & Target.ServerName & " from " & cptr.Prefix
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    Else
        If cptr.CanLocRoute Or cptr.CanGlobRoute Then
            SendSvrMsg "*** Notice -- Recieved SQUIT for " & Target.ServerName & " from " & cptr.Prefix
'            Dim x&
'            User = GlobUsers.Values
'            For i = LBound(User) To UBound(User)
'                If User(i).FromLink Is Target Then
'                    For x = 1 To User(i).OnChannels.Count
'                        SendToChan User(i).OnChannels.Item(x), User(i).Prefix & " QUIT :" & ServerName & " " & Target.ServerName, vbNullString
'                    Next x
'                    KillStruct User(i).Nick
'                    SendToServer "QUIT :" & ServerName & " " & Target.ServerName, User(i).Nick
'                    #If Debugging = 1 Then
'                        SendSvrMsg "*** Notice -- User " & User(i).Nick & " lost during netsplit"
'                    #End If
'                    Set User(i).FromLink = Nothing
'                    Set User(i) = Nothing
'                End If
'            Next i
'            User = Servers.Values
'            For i = LBound(User) To UBound(User)
'                If User(i).FromLink Is cptr Then
'                    Servers.Remove User(i).ServerName
'                    SendToServer "SQUIT :" & User(i).ServerName, ServerName
'                    Set User(i).FromLink = Nothing
'                    #If Debugging = 1 Then
'                        SendSvrMsg "*** Notice -- Server " & User(i).ServerName & " lost during netsplit"
'                    #End If
'                    Set User(i) = Nothing
'                End If
'            Next i
'            Servers.Remove Target.ServerName
'            SendToServer "SQUIT :" & Target.ServerName, Target.ServerName
'            Sockets.CloseIt Target.Index
'            IrcStat.LocServers = IrcStat.LocServers - 1
'            IrcStat.GlobServers = IrcStat.GlobServers - 1
            SendWsock Target.index, "SQUIT", vbNullString, , True
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    End If
End If
End Function

'/*
'** m_server
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'**  parv$()[2] = serverinfo/hopcount
'**  parv$()[3] = token/serverinfo (2.9)
'**  parv$()[4] = serverinfo
'*/
Public Function m_server(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- SERVER called! (" & cptr.Nick & ")"
#End If
Dim NewSptr As clsClient, User As clsClient, SendAuth As LLines, Outgoing$, SendInfo As Boolean
If Not cptr.HasRegistered Then
    If cptr.AccessLevel = 4 Then
        SendInfo = False
    Else
        SendInfo = True
    End If
        
    If cptr.PassOK = False Then
      KillStruct cptr.Nick, , False, cptr.IP
      m_error cptr, "Closing Link: (Bad Password)"
      Exit Function
    End If
    
    If Not cptr.LLined Then
        If DoLLine(cptr) Then
            Exit Function
        End If
        cptr.LLined = True
    End If
    Set NewSptr = Servers(parv(0))
'    If Not NewSptr Is Nothing Then
'        If Not NewSptr.ServerName = ServerName Then
'            If Not parv(0) = cptr.ServerName Then
'                If Not cptr.ServerName = parv(0) Then
'                    SendSvrMsg "Server " & parv(0) & " already exists from " & NewSptr.FromLink.ServerName
'                    Exit Function
'                End If
'            End If
'        End If
'    End If
    IrcStat.LocServers = IrcStat.LocServers + 1
    IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
    cptr.ServerName = parv(0)
    cptr.Hops = parv(1)
    cptr.RealHost = cptr.Host '<-- fix any kind of weirdness
    Servers.Add cptr.ServerName, cptr
    cptr.UpLink = ServerName
    With cptr
        .Nick = parv(0)
        .ServerDescription = parv(2)
        Set .FromLink = cptr
        .HasRegistered = True
        SendAuth = GetLLineC(.ServerName)
        If Len(SendAuth.Server) = 0 Then
            Servers.Remove cptr.ServerName
            m_error cptr, "Closing Link: (Unauthorized Connection)"
            Exit Function
        End If
        SendSvrMsg "*** Notice -- Link with " & .ServerName & " accepted."
        If SendInfo Then
            SendWsock .index, "PASS " & SendAuth.Pass, vbNullString, vbNullString, True
            SendWsock .index, "SERVER " & ServerName & " 1 :" & ServerDescription, vbNullString, vbNullString, True
        End If
        Dim I As Long, Vals() As clsClient, x As Long, chans() As clsChannel, Membrs$, ChM() As clsChanMember, y&
        Dim c&, s&, u&
        Vals = Servers.Values
        'propragrate servers
        If Not Vals(0) Is Nothing Then
            For I = 0 To UBound(Vals)
                If Vals(I).Hops > 0 Then
                    SendWsock .index, "SERVER" & " " & Vals(I).ServerName & " " & Vals(I).Hops + 1, ":" & Vals(I).ServerDescription, ":" & Vals(I).UpLink
                    s = s + 1
                End If
            Next I
        End If
        Vals = GlobUsers.Values
        'propragrate users
        If Not Vals(0) Is Nothing Then
            For I = 0 To UBound(Vals)
                SendWsock .index, "NICK" & " " & Vals(I).Nick & " " & Vals(I).Hops + 1 & " " & Vals(I).SignOn & _
                " " & Vals(I).User & " " & Vals(I).Host & " " & Vals(I).FromLink.ServerName, ":" & Vals(I).Name
                u = u + 1
            Next I
        End If
        chans = Channels.Values
        Dim ChanStructs As Long
        Dim A As Long
        If Not chans(0) Is Nothing Then
            ChanStructs = UBound(chans)
            For I = 0 To UBound(chans)
                ChM = chans(I).Member.Values
                For y = 0 To UBound(ChM)
                    'add another record to the njoin buffer
                    x = x + 1
                    c = c + 1
                    If ChM(y).IsOwner Then 'I think Ziggy Missed this bit...DAM - DG
                        Membrs = Membrs & "." & ChM(y).Member.Nick & " "
                    ElseIf ChM(y).IsOp Then
                        Membrs = Membrs & "@" & ChM(y).Member.Nick & " "
                    ElseIf ChM(y).IsVoice Then
                        Membrs = Membrs & "+" & ChM(y).Member.Nick & " "
                    Else
                        Membrs = Membrs & ChM(y).Member.Nick & " "
                    End If
                    If x = 11 Or y = UBound(ChM) Then
                        'flush
                        SendWsock .index, "NJOIN " & chans(I).Name, ":" & Trim$(Membrs)
                        Membrs = vbNullString
                        x = 0
                    End If
                Next y
            'now send other information
            'this might take a little while :)
            SendWsock .index, "PROP " & chans(I).Name & " ACCOUNT", ":" & chans(I).Prop_Account
            SendWsock .index, "PROP " & chans(I).Name & " CLIENT", ":" & chans(I).Prop_Client
            SendWsock .index, "PROP " & chans(I).Name & " CREATION", ":" & chans(I).Prop_Creation
            SendWsock .index, "PROP " & chans(I).Name & " HOSTKEY", ":" & chans(I).Prop_Hostkey
            SendWsock .index, "PROP " & chans(I).Name & " LANGUAGE", ":" & chans(I).Prop_Language
            SendWsock .index, "PROP " & chans(I).Name & " MEMBERKEY", ":" & chans(I).Prop_Memberkey
            SendWsock .index, "PROP " & chans(I).Name & " ONJOIN", ":" & chans(I).Prop_OnJoin
            SendWsock .index, "PROP " & chans(I).Name & " ONPART", ":" & chans(I).Prop_OnPart
            SendWsock .index, "PROP " & chans(I).Name & " OWNERKEY", ":" & chans(I).Prop_Ownerkey
            SendWsock .index, "PROP " & chans(I).Name & " SUBJECT", ":" & chans(I).Prop_Subject
            SendWsock .index, "PROP " & chans(I).Name & " TOPIC", ":" & chans(I).Prop_Topic
            If chans(I).Bans.Count > 0 Then
              'by the way -- we are sending the prefix as the person who set it's nick, so data's not lost
              'in a netsplit (not like data would be lost in the first place, but new channels will not
              'have this info)
              
              'the delete line makes the other server purge its access list
              'you know, if for some reason entries get added, they get cleared
              'this isn't done if there's no entries, because it would be very
              'awful to make a new server erase the list of a server that didn't
              'split from the network, thus making this code irrelevant :)
              SendWsock .index, "ACCESS " & chans(I).Name & " DELETE", "DENY *!*@*"
              For A = 1 To chans(I).Bans.Count
                SendWsock .index, "ACCESS " & chans(I).Name & " ADD DENY " & chans(I).Bans.Item(A).Mask & " " & chans(I).Bans.Item(A).Duration, ":" & chans(I).Bans.Item(A).Reason, ":" & chans(I).Bans.Item(A).SetBy
              Next A
            End If
            If chans(I).Grants.Count > 0 Then
              SendWsock .index, "ACCESS " & chans(I).Name & " DELETE", "GRANT *!*@*"
              For A = 1 To chans(I).Grants.Count
                SendWsock .index, "ACCESS " & chans(I).Name & " ADD GRANT " & chans(I).Grants.Item(A).Mask & " " & chans(I).Grants.Item(A).Duration, ":" & chans(I).Grants.Item(A).Reason, ":" & chans(I).Grants.Item(A).SetBy
              Next A
            End If
            If chans(I).Voices.Count > 0 Then
              SendWsock .index, "ACCESS " & chans(I).Name & " DELETE", "VOICE *!*@*"
              For A = 1 To chans(I).Voices.Count
                SendWsock .index, "ACCESS " & chans(I).Name & " ADD VOICE " & chans(I).Voices.Item(A).Mask & " " & chans(I).Voices.Item(A).Duration, ":" & chans(I).Voices.Item(A).Reason, ":" & chans(I).Voices.Item(A).SetBy
              Next A
            End If
            If chans(I).Hosts.Count > 0 Then
              SendWsock .index, "ACCESS " & chans(I).Name & " DELETE", "HOST *!*@*"
              For A = 1 To chans(I).Hosts.Count
                SendWsock .index, "ACCESS " & chans(I).Name & " ADD HOST " & chans(I).Hosts.Item(A).Mask & " " & chans(I).Hosts.Item(A).Duration, ":" & chans(I).Hosts.Item(A).Reason, ":" & chans(I).Hosts.Item(A).SetBy
              Next A
            End If
            If chans(I).Owners.Count > 0 Then
              SendWsock .index, "ACCESS " & chans(I).Name & " DELETE", "OWNER *!*@*"
              For A = 1 To chans(I).Owners.Count
                SendWsock .index, "ACCESS " & chans(I).Name & " ADD OWNER " & chans(I).Owners.Item(A).Mask & " " & chans(I).Owners.Item(A).Duration, ":" & chans(I).Owners.Item(A).Reason, ":" & chans(I).Owners.Item(A).SetBy
              Next A
            End If
            Next I
        End If
        
        SendSvrMsg "*** Notice -- " & s & " server(s), " & u & " user(s), and " & ChanStructs & " channel structures sent to " & .ServerName
        SendSvrMsg "*** Notice -- Link with " & .ServerName & " established."
        SendToServer_ButOne "SERVER " & .ServerName & " " & .Hops + 1 & " :" & .ServerDescription, .ServerName, ServerName
    End With
Else
    'make sure the sender isn't a local client
    '-> stupid local clients!
    If cptr.Hops = 0 Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, ":Permission Denied"
        Exit Function
    End If
    
    Set NewSptr = Servers(parv(0))
    If Not NewSptr Is Nothing Then
        If Not NewSptr.ServerName = ServerName Then
            If Not parv(0) = cptr.ServerName Then
                If Not cptr.ServerName = parv(0) Then
                    SendSvrMsg "*** Notice -- Server " & parv(0) & " already exists from " & NewSptr.FromLink.ServerName, True
                    Exit Function
                End If
            End If
        End If
    End If
'    'Check if Server already exists
'    If parv(0) = ServerName Then Exit Function
'    If parv(0) = cptr.ServerName Then Exit Function
'    If NewSptr Is Nothing Then
'        Set User = GlobUsers(parv(0))
'        'Check if a User is impersonating a server
'        If Not User Is Nothing Then
'            m_error User, "Nick Collision with a Server"
'            KillStruct User.Nick
'            SendSvrMsg "Nick Collision with a Server"
'        End If
'    Else
'        If Not NewSptr.ServerName = ServerName Then
'            If Not cptr.ServerName = parv(0) Then
'                m_error cptr, "Server " & parv(0) & " already exists from " & NewSptr.FromLink.ServerName
'                Sockets.CloseIt NewSptr.FromLink.Index
'                KillStruct parv(0), enmTypeServer
'                SendSvrMsg "Server " & parv(0) & " already exists from " & NewSptr.FromLink.ServerName
'            End If
'        End If
'        Exit Function
'    End If
    If sptr Is Nothing Then Set sptr = cptr
    Set NewSptr = New clsClient
    NewSptr.Hops = parv(1)
    Call Servers.Add(parv(0), NewSptr)
    With NewSptr
        .AccessLevel = 4
        Set .FromLink = cptr
        .ServerName = parv(0)
        .ServerDescription = parv(2)
        .UpLink = sptr.ServerName
        SendToServer_ButOne "SERVER " & .ServerName & " " & .Hops + 1 & " :" & .ServerDescription, .ServerName, sptr.ServerName
    End With
    IrcStat.GlobServers = IrcStat.GlobServers + 1
End If
End Function

'/*
'** m_info
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
'Public Function m_info(cptr As clsClient, sptr As clsClient, parv$()) As Long
'TODO: Credits, Debug statuses, etc
'End Function

'/*
'** m_links
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername mask
'** or
'**  parv$()[0] = sender prefix
'**  parv$()[1] = server to query
'**      parv$()[2] = servername mask
'*/
Public Function m_links(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- LINKS called! (" & cptr.Nick & ")"
#End If
'SendWsock cptr.Index, "NOTICE " & cptr.Nick, ":LINKS has been disabled"
Dim I&, Links() As clsClient
Links = Servers.Values
If Not Links(0) Is Nothing Then
    For I = 0 To UBound(Links)
        SendWsock cptr.index, RPL_LINKS & " " & cptr.Nick & " " & Links(I).ServerName & " " & Links(I).UpLink, ":" & Links(I).Hops & " " & Links(I).ServerDescription
    Next I
End If
SendWsock cptr.index, RPL_ENDOFLINKS & " " & cptr.Nick, ":End of /LINKS list"
End Function

'/*
'** m_summon should be redefined to ":prefix SUMMON host user" so
'** that "hunt_server"-function could be used for this too!!! --msa
'** As of 2.7.1e, this was the case. -avalon
'**
'**  parv$()[0] = sender prefix
'**  parv$()[1] = user
'**  parv$()[2] = server
'**  parv$()[3] = channel (optional)
'*/
Public Function m_summon(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- SUMMON called! (" & cptr.Nick & ")"
#End If
SendWsock cptr.index, ERR_SUMMONDISABLED & " " & cptr.Nick, ":SUMMON has been disabled"
End Function

'/*
'** m_stats
'**  parv$()[0] = sender prefix
'**  parv$()[1] = statistics selector (defaults to Message frequency)
'**  parv$()[2] = server name (current server defaulted, if omitted)
'**
'**  Currently supported are:
'**      M = Message frequency (the old stat behaviour)
'**      L = Local Link statistics
'**      C = Report C and N configuration lines
'*/
'/*
'** m_stats/stats_conf
'**    Report N/C-configuration lines from this server. This could
'**    report other configuration lines too, but converting the
'**    status back to "char" is a bit akward--not worth the code
'**    it needs...
'**
'**    Note:   The info is reported in the order the server uses
'**        it--not reversed as in ircx.conf!
'*/
Public Function m_stats(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- STATS called! (" & cptr.Nick & ")"
#End If
Dim Target As clsClient
If cptr.AccessLevel = 4 Then
  If parv(1) = ServerName Then
    SendWsock cptr.index, GetStats(sptr.Nick, cptr.AccessLevel, parv(0)), vbNullString, , True
  Else
    Set Target = Servers(parv(1))
    SendWsock Target.FromLink.index, "STATS " & parv(0), ":" & parv(1), ":" & sptr.Nick
  End If
Else
  If Len(parv(0)) = 0 Then
    'SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "STATS")
    SendWsock cptr.index, "210 " & cptr.Nick, ":STATS Flags" & vbCrLf
    If cptr.AccessLevel = 3 Then
      SendWsock cptr.index, "210 " & cptr.Nick, ":o - List Operators"
      SendWsock cptr.index, "210 " & cptr.Nick, ":k - List K/Z lines"
    End If
    SendWsock cptr.index, "210 " & cptr.Nick, ":u - Uptime information"
    SendWsock cptr.index, "210 " & cptr.Nick, ":m - Command Bandwidth Usage"
    Exit Function
  End If
  If parv(0) = "*" Then
    SendWsock cptr.index, "210 " & cptr.Nick, ":STATS Flags" & vbCrLf
    If cptr.AccessLevel = 3 Then
      SendWsock cptr.index, "210 " & cptr.Nick, ":o - List Operators"
      SendWsock cptr.index, "210 " & cptr.Nick, ":k - List K/Z lines"
    End If
    SendWsock cptr.index, "210 " & cptr.Nick, ":u - Uptime information"
    SendWsock cptr.index, "210 " & cptr.Nick, ":m - Command Bandwidth Usage"
    Exit Function
  End If
  If UBound(parv) = 0 Then
    Dim tmpAL As Long
    tmpAL = cptr.AccessLevel
    'for remote opers to access stats -zg
    If cptr.IsGlobOperator = True Then tmpAL = 3
    If cptr.IsLocOperator = True Then tmpAL = 3
    SendWsock cptr.index, GetStats(cptr.Nick, tmpAL, parv(0)), vbNullString, , True
  Else
    Set sptr = GetServer(parv(1))
    If sptr Is Nothing Then
      SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(1))
      Exit Function
    End If
    SendWsock sptr.FromLink.index, "STATS " & parv(0), ":" & sptr.ServerName, ":" & cptr.Nick
  End If
End If
End Function

'/*
'** m_users
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
Public Function m_users(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- USERS called! (" & cptr.Nick & ")"
#End If
'i dont know how this one works -Dill
SendWsock cptr.index, ERR_USERSDISABLED & " " & cptr.Nick, ":USERS has been disabled"
End Function

'/*
'** Note: At least at protocol level ERROR has only one parameter,
'** although this is called internally from other functions
'** --msa
'**
'**  parv$()[0] = sender prefix
'**  parv$()[*] = parameters
'*/
Public Function m_error(cptr As clsClient, Message$) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- ERROR called! (" & Message & ")"
#End If
If cptr.AccessLevel < 4 Then
  Dim bArr() As Byte
  bArr = StrConv("ERROR :" & Message & vbCrLf, vbFromUnicode)
  Call Send(cptr.SockHandle, bArr(0), UBound(bArr) + 1, 0)
  cptr.IsKilled = True
  Sockets.TerminateSocket cptr.SockHandle
Else
  SendSvrMsg "*** Notice -- Recieved ERROR from/for " & cptr.ServerName & ": " & Message
End If
End Function



'/*
' * parv$()[0] = sender
' * parv$()[1] = host/server mask.
' * parv$()[2] = server to query
' */
Public Function m_lusers(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- LUSERS called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
    Dim Target As clsClient
    Set Target = Servers(parv(0))
    If Target.ServerName = ServerName Then
        SendWsock cptr.index, GetLusers(sptr.Nick), vbNullString, , True
    Else
        SendWsock Target.FromLink.index, "LUSERS", Target.ServerName, ":" & sptr.Nick
    End If
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, GetLusers(cptr.Nick), vbNullString, , True
    Else
        Set sptr = GetServer(parv(0))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(0))
          Exit Function
        End If
        SendWsock sptr.FromLink.index, "LUSERS", ":" & sptr.ServerName, ":" & cptr.Nick
    End If
End If
End Function

'/***********************************************************************
' * m_connect() - Added by Jto 11 Feb 1989
' ***********************************************************************/
'
'/*
'** m_connect
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'**  parv$()[2] = port number
'**  parv$()[3] = remote server
'*/
Public Function m_connect(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- CONNECT called! (" & cptr.Nick & ")"
#End If
Dim Target As clsClient, ConnAuth As LLines
If cptr.AccessLevel = 4 Then
    
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CONNECT")
        Exit Function
    End If
    If Not (cptr.CanGlobRoute Or cptr.CanLocRoute) Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    If UBound(parv) = 0 Then 'Connect to specified server
        If cptr.CanLocRoute Then
            Set Target = GetServer(parv(0))
            If Not Target Is Nothing Then
                SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Server " & parv(0) & " exists already."
                Exit Function
            End If
            ConnAuth = GetLLineC(parv(0))
            If Len(ConnAuth.Server) = 0 Then
                SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Server " & parv(0) & " is not listed in conf file."
                Exit Function
            End If
            Sockets.Connect ConnAuth.Host, CInt(ConnAuth.Port)
            SendSvrMsg "*** Notice -- Connecting to " & ConnAuth.Host & " on port " & ConnAuth.Port
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    ElseIf UBound(parv) = 1 Then 'connect to specified server on specified port
        If cptr.CanLocRoute Then
            If Len(parv(1)) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS, TranslateCode(ERR_NEEDMOREPARAMS, , , "CONNECT")
                Exit Function
            End If
            ConnAuth = GetLLineC(parv(0))
            If Len(ConnAuth.Server) = 0 Then
                SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Server " & parv(0) & " is not listed in conf file."
                Exit Function
            End If
            Sockets.Connect ConnAuth.Host, CInt(parv(1))
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    'forward message to remote server to make it connect to an specified server on a speciefied port
    ElseIf UBound(parv) = 2 Then
        If cptr.CanGlobRoute Then
            If Len(parv(1)) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CONNECT")
                Exit Function
            End If
            If Len(parv(2)) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CONNECT")
                Exit Function
            End If
            Set sptr = Servers(parv(1))
            SendWsock sptr.FromLink.index, "CONNECT " & sptr.ServerName, ":" & parv(2)
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    End If
End If
End Function

'/*
'** m_time
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
Public Function m_time(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- TIME called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
    Dim Target As clsClient
    Set Target = Servers(parv(0))
    If Target.ServerName = ServerName Then
        SendWsock cptr.index, RPL_TIME & " " & sptr.Nick, ":" & Date & " -- " & Time$ & " " & GetZone
    Else
        SendWsock Target.FromLink.index, "TIME", Target.ServerName, ":" & sptr.Nick
    End If
Else
    'maybe a different format would be better, this should be correct too though -Dill
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_TIME & " " & cptr.Nick, ":" & Date & " -- " & Time$ & " " & GetZone
    Else
        Set sptr = GetServer(parv(0))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(0))
          Exit Function
        End If
        SendWsock sptr.FromLink.index, "TIME", ":" & sptr.ServerName, ":" & cptr.Nick
    End If
End If
End Function

'/*
'** m_admin
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
Public Function m_admin(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- ADMIN called! (" & cptr.Nick & ")"
#End If

If cptr.AccessLevel = 4 Then
    Dim Target As clsClient
    Set Target = Servers(parv(0))
    If Target.ServerName = ServerName Then
        SendWsock cptr.index, GetAdmin(sptr.Nick), vbNullString, , True
    Else
        SendWsock Target.FromLink.index, "ADMIN", Target.ServerName, ":" & sptr.Nick
    End If
Else
    'TODO: ERR_NOADMININFO should be sent if there is no info available here
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, GetAdmin(cptr.Nick), vbNullString, , True
    Else
        Set sptr = GetServer(parv(0))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(0))
          Exit Function
        End If
        SendWsock sptr.FromLink.index, "ADMIN", ":" & sptr.ServerName, ":" & cptr.Nick
    End If
End If
End Function

'/*
'** m_rehash
'**
'*/
Public Function m_rehash(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- REHASH called! (" & cptr.Nick & ")"
#End If
If cptr.CanRehash Then
    Dim msgText As String
    msgText = ""
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_REHASHING & " " & cptr.Nick, "ircx.conf :Rehashing Server Configuration"
        msgText = "*** Notice -- " & ServerName & " has rehashed on the request of: " & cptr.Nick
    ElseIf StrComp(UCase$(parv(0)), "-MOTD") = 0 Then
        SendWsock cptr.index, RPL_REHASHING & " " & cptr.Nick, "ircx.motd :Rehashing Message of the Day"
        msgText = "*** Notice -- " & ServerName & " has reloaded the Message of the Day on the request of: " & cptr.Nick
    ElseIf StrComp(UCase$(parv(0)), "-GC") = 0 Then
        msgText = "*** Notice -- " & ServerName & " has cleaned up on the reqest of: " & cptr.Nick
    End If
    Rehash parv(0)
    SendSvrMsg msgText
Else
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
End Function

'/*
'** m_restart
'**
'*/
#If CanRestart = 1 Then
    Public Function m_restart(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- RESTART called! (" & cptr.Nick & ")"
#End If
    If cptr.CanRestart Then
        If Len(parv(0)) = 0 Then
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "RESTART")
            Exit Function
        End If
        If parv(0) = RestartPass Then
            Dim I As Long   'close all connections properly -Dill
            For I = 1 To UBound(Users)
                If Not Users(I) Is Nothing Then
                    m_error Users(I), "Closing Link: (" & ServerName & " is restarting on the request of " & cptr.Nick & ")"
                End If
            Next I
            Terminate False: Main
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    Else
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    End Function
#End If

'/*
'** m_trace
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
'Public Function m_trace(cptr As clsClient, sptr As clsClient, parv$()) As Long
'TODO: /TRACE
'End Function

'/*
'** m_motd
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
Public Function m_motd(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- MOTD called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
If cptr.AccessLevel = 4 Then
    Dim Target As clsClient
    Set Target = Servers(parv(0))
    If Target.ServerName = ServerName Then
        SendWsock cptr.index, ReadMotd(sptr.Nick), vbNullString, , True
    Else
        SendWsock Target.FromLink.index, "MOTD", Target.ServerName, ":" & sptr.Nick
    End If
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, ReadMotd(cptr.Nick), vbNullString, , True
    Else
        Set sptr = GetServer(parv(0))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHSERVER, cptr.Nick & " " & TranslateCode(ERR_NOSUCHSERVER, parv(0))
          Exit Function
        End If
        SendWsock sptr.FromLink.index, "MOTD", ":" & sptr.ServerName, ":" & cptr.Nick
    End If
End If
End Function
#If CanDie = 1 Then
    Public Function m_die(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- DIE called! (" & cptr.Nick & ")"
#End If
    On Error Resume Next
    If cptr.CanDie Then
        If Len(parv(0)) = 0 Then
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "DIE")
            Exit Function
        End If
        If parv(0) = DiePass Then
            Dim I As Long   'close all connection properly -Dill
            For I = 1 To UBound(Users)
                If Not Users(I) Is Nothing Then
                    SendWsock I, "NOTICE " & Users(I).Nick, SPrefix & " is quiting on the request of: " & cptr.Nick
                    Sockets.CloseIt I
                    m_error Users(I), "Closing Link: (" & ServerName & " is quitting)"
                End If
            Next I
            Terminate
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
        End If
    Else
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    End Function
#End If

'/*
'** check_link (added 97/12 to prevent abuse)
'**  routine which tries to find out how healthy a link is.
'**  useful to know if more strain may be imposed on the link or not.
'**
'**  returns 0 if link load is light, -1 otherwise.
'*/
'Public Function check_link(cptr As clsClient) As Long
'
'End Function

'/* used to return internal ircd's hash statistics */ -Dill
Public Function m_hash(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- HASH called! (" & cptr.Nick & ")"
#End If
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
SendWsock cptr.index, RPL_HASH & " " & cptr.Nick, ":Current array bounds [User: " & UBound(Users) & "]"
SendWsock cptr.index, RPL_HASH & " " & cptr.Nick, ":Local connections: " & LocalConn
SendWsock cptr.index, RPL_HASH & " " & cptr.Nick, ":Sent and Recieved bytes: " & ServerTraffic
SendWsock cptr.index, RPL_HASH & " " & cptr.Nick, ":Messages recieved: " & RecvMsg
SendWsock cptr.index, RPL_HASH & " " & cptr.Nick, ":Messages sent: " & SentMsg
SendWsock cptr.index, RPL_ENDOFHASH & " " & cptr.Nick, ":End of /HASH"
End Function

'/* used to close "half-open" connections (unknown connections that havent registered) */ -Dill
Public Function m_close(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- CLOSE called! (" & cptr.Nick & ")"
#End If
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
Dim I As Long, x&   'close all connections properly -Dill
If UBound(Users) = 0 Then Exit Function

For I = 1 To UBound(Users)
    If Not Users(I) Is Nothing Then
        'the onchannels.count thing is stupid but needed
        'apparently some users prefer to be recognized as unregistered but they are in channels
        'the IP thing is to skip over records that are null
        'oh, and IsKilled is to not send an error twice or whatever
        If Users(I).HasRegistered = False And Users(I).IsKilled = False And Users(I).Hops = 0 And Users(I).OnChannels.Count = 0 And Len(Users(I).IP) > 0 Then
            m_error Users(I), "Closing Link: (Closing Unknown Connections)"
            Users(I).IsKilled = True
            KillStruct Users(I).Nick, , False, Users(I).IP
            x = x + 1
            Set Users(I) = Nothing
        End If
    End If
Next I
SendSvrMsg "*** Notice -- " & x & " unregistered connections closed on the request of " & cptr.Nick
IrcStat.UnknownConnections = 0
End Function

'*/ shows how the network is currently laid out /* -Dill
Public Function m_map(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- MAP called! (" & cptr.Nick & ")"
#End If
'TODO: /MAP

'Dim i&, Links() As clsClient
'Links = Servers.Values
'If Not Links(0) Is Nothing Then
'    For i = 0 To UBound(Links)
'        SendWsock cptr.Index, RPL_MAP & cptr.Nick & " "
'    Next i
'End If
'SendWsock cptr.Index, RPL_ENDOFLINKS & " " & cptr.Nick, ":End of /LINKS list"
End Function
Public Function m_wallops(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
  SendSvrMsg "*** Notice -- WALLOPS called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
    SendWallOp parv(0), sptr.Nick, False
    SendToServer_ButOne "WALLOPS :" & parv(0), cptr.ServerName, sptr.Nick
Else
    If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    If Not (cptr.CanWallop Or cptr.IsNetAdmin) Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    SendWallOp parv(0), cptr.Nick & "!" & cptr.User & "@" & cptr.Host
End If
End Function
Public Function m_gnotice(cptr As clsClient, sptr As clsClient, parv$()) As Long
If cptr.AccessLevel = 4 Then
    SendSvrMsg parv(0), , sptr.Nick
    SendToServer_ButOne "GNOTICE :" & parv(0), cptr.ServerName, sptr.Nick
Else
    If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    SendSvrMsg parv(0), True, cptr.Nick
End If
End Function

Public Function m_kline(cptr As clsClient, sptr As clsClient, parv$()) As Long
On Error GoTo KLineError
Dim e As String
e = "Start"
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- KLINE called! (" & cptr.Nick & ")"
#End If
Dim I&, z&, Mask$, KUser$, KHost$, KMask$, tmp$
e = "check privledges"
If Not (cptr.CanKline Or cptr.CanUnkline) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
e = "check parameters"
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KLINE")
    Exit Function
End If
e = "check parameters - 2"
If UBound(parv) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KLINE")
    Exit Function
End If
e = "get mask"
Mask = ":" & CreateMask(parv(0))
e = "begin killing active"
For I = LBound(Users) To UBound(Users)
    If Not Users(I) Is Nothing Then
        If UCase$(Users(I).Prefix) Like UCase$(Mask) Then
            m_error Users(I), "Closing Link: (AutoKilled: " & parv(1) & ")"
            For z = 1 To Users(I).OnChannels.Count
                SendToChan Users(I).OnChannels.Item(z), Users(I).Prefix & " QUIT :AutoKilled: " & parv(1), vbNullString
            Next z
            Sockets.TerminateSocket Users(I).SockHandle
            KillStruct Users(I).Nick
        End If
    End If
Next I
e = "get killmask"
KMask = CreateMask(parv(0))
#If Debugging = 1 Then
  SendSvrMsg "*** KLine Debug: KMask='" & KMask & "'"
#End If
'KHost = Mid$(Mask, InStr(1, Mask, "@") + 1)
'Mask = Replace(Mask, "@" & KHost, vbNullString, , 1)
'KUser = Mid$(Mask, InStr(1, Mask, "!") + 1)
e = "get tmp"
tmp = Split(KMask, "!")(1)
e = "get user"
KUser = Split(tmp, "@")(0)
e = "get host"
KHost = Split(tmp, "@")(1)
e = "check method"
'we now see if nick is set, but everything else is *
'this implies they went /kline something reason -- we
'don't want to ban *@* because they went /kline something
If KHost = "*" And KUser = "*" Then
  'don't k-line if they /kline *'ed
  If Split(KMask, "!")(0) <> "*" Then
    KHost = Split(KMask, "!")(0)
  End If
End If
e = "print debug"
#If Debugging = 1 Then
  SendSvrMsg "*** KLine Debug: KUser='" & KUser & "' KHost='" & KHost & "'"
#End If
e = "add kline"
AddKLine KHost, parv(1), KUser
e = "done"
Exit Function

KLineError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_kline' at " & e
End Function

Public Function m_unkline(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- UNKLINE called! (" & cptr.Nick & ")"
#End If
If Not (cptr.CanUnkline) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "UNKLINE")
    Exit Function
End If
Dim I&
For I = 1 To UBound(KLine)
    If Len(KLine(I).Host) > 0 Then
        If KLine(I).User & "@" & KLine(I).Host Like parv(0) Then
            KLine(I).Host = vbNullString
            KLine(I).User = vbNullString
            KLine(I).Reason = vbNullString
        End If
    End If
Next I
End Function
Public Function GenerateEvent(EventType As String, EventName As String, Mask As String, Args As String)
'this function is called by all things that generate events
'If Event_LastEventTime = UnixTime And Event_LastEventType = EventType And Event_LastEventName = EventName And Event_LastEventArgs = Args Then Exit Function
#If Debugging = 1 Then
SendSvrMsg "*** GENERATEEVENT Called! (" & EventType & "." & EventName & ") (" & Mask & ") (" & Args & ") (" & UnixTime & ")"
#End If
If (UCase$(Event_LastEventType) = UCase$(EventType)) And (UCase$(Event_LastEventName) = UCase$(EventName)) And (UCase$(Event_LastEventArgs) = UCase$(Args)) Then Exit Function
#If Debugging = 1 Then
SendSvrMsg "proceeding with event sending.."
#End If
Event_LastEventType = EventType
Event_LastEventName = EventName
Event_LastEventArgs = Args
Event_LastEventTime = UnixTime
On Error Resume Next
Dim I As Long, Recv() As clsClient
Dim A As Long
Dim LastEventEsc As String
If Opers.Count = 0 Then Exit Function
Recv() = Opers.Values
If Recv(0) Is Nothing Then Exit Function
For I = LBound(Recv) To UBound(Recv)
  #If Debugging = 1 Then
    SendSvrMsg "[" & I & "] " & Recv(I).Nick
  #End If
  LastEventEsc = ""
  If Recv(I).Events.Count > 0 Then
    For A = 1 To Recv(I).Events.Count
      #If Debugging = 1 Then
        SendSvrMsg "[" & I & "] (" & A & ") " & Recv(I).Events.Item(A).EventType & "." & Recv(I).Events.Item(A).EventName & " " & Recv(I).Events.Item(A).Mask
      #End If
      If (Recv(I).Events(A).Mask Like Mask) And (UCase$(Recv(I).Events(A).EventType) = UCase$(EventType)) And (UCase$(Recv(I).Events(A).EventName) = UCase$(EventName)) Then
        'can get this event
        'here we make sure that the user wildcarded it
        'or if the user is asking for a specific name
        'If Len(Recv(I).Events.Item(A).EventName) = 0 Then
        '  'no event name at all -- assume wildcard
        '  SendEvent Recv(I).index, EventType, EventName, Args
        '  GoTo nextItem
        
        'lasteventesc basically contains the last event sent + mask
        'so you can't send the stupid thing twice in a row
        If LastEventEsc = Recv(I).Events.Item(A).EventType & "." & Recv(I).Events.Item(A).EventName & "::" & Recv(I).Events.Item(A).Mask Then GoTo nextItem
        LastEventEsc = Recv(I).Events.Item(A).EventType & "." & Recv(I).Events.Item(A).EventName & "::" & Recv(I).Events.Item(A).Mask
        
        'I'm thinking this is redundant, but I can't be bothered to check
        'you never know, VB might be stupid and try to execute this twice.
        If (EventType = Recv(I).Events.Item(A).EventType) And (EventName = Recv(I).Events.Item(A).EventName) Then
          'event name specified, and user did too
          #If Debugging = 1 Then
            SendSvrMsg "Sending event " & EventType & "." & EventName & " to " & Recv(I).Nick
          #End If
          SendEvent Recv(I).index, EventType, EventName, Args
          'GoTo nextItem
        End If
      End If
nextItem:
    Next A
  End If
Next I
End Function
Public Function m_event(cptr As clsClient, sptr As clsClient, parv$()) As Long
On Error GoTo EventError
Dim tL As String
tL = "entry"
#If Debugging = 1 Then
  SendSvrMsg "*** Notice -- EVENT called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
'Todo
Else
    tL = "determine oper perms"
    If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
    End If
    tL = "need more params"
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "EVENT")
        Exit Function
    End If
    'Syntax 1: EVENT [ADD | DELETE] <event> [<mask>]
    'Syntax 2: EVENT LIST [<event>]
    
    'determine information ahead of time
    'to simplify error trapping
    tL = "define vars"
    Dim Mask As String
    Dim EventType As String
    Dim EventName As String
    Dim tmpFullEvent As String
    
    tL = "proccess params"
    If UBound(parv) >= 2 Then
      tL = "determine event type"
      'ADD SOMETHING MASK
      If InStr(1, parv(1), ".") Then
        tmpFullEvent = parv(1)
        tL = "set event type"
        EventType = Split(tmpFullEvent, ".")(0)
        tL = "set event name"
        EventName = Split(tmpFullEvent, ".")(1)
      Else
        EventType = parv(1)
        EventName = vbNullString
      End If
      tL = "set mask"
      If UCase$(EventType) <> "CHANNEL" Then
        Mask = CreateMask(parv(2))
      Else
        Mask = parv(2)
      End If
    ElseIf UBound(parv) = 1 And UCase$(parv(0)) <> "LIST" Then
      'ADD SOMETHING (assume mask is *!*@*)
      tL = "determine event type (2 params not list)"
      If InStr(1, parv(1), ".") Then
        tmpFullEvent = parv(1)
        tL = "set event type"
        EventType = Split(tmpFullEvent, ".")(0)
        tL = "set event name"
        EventName = Split(tmpFullEvent, ".")(1)
      Else
        EventType = parv(1)
        EventName = ""
      End If
      tL = "set mask"
      If UCase$(EventType) <> "CHANNEL" Then
        Mask = "*!*@*"
      Else
        Mask = "#*"
      End If
    ElseIf UBound(parv) = 1 And UCase$(parv(0)) = "LIST" Then
      tL = "determine event type (2 params, list)"
      If InStr(1, parv(1), ".") Then
        tmpFullEvent = parv(1)
        tL = "set event type"
        EventType = Split(tmpFullEvent, ".")(0)
        tL = "set event name"
        EventName = Split(tmpFullEvent, ".")(1)
      Else
        EventType = parv(1)
        EventName = ""
      End If
      tL = "set mask"
      Mask = "*!*@*"
    Else
      'has to be list
      'if not, throw error
      If UCase$(parv(0)) <> "LIST" Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "EVENT")
        Exit Function
      End If
    End If
    tL = "determine action"
    Dim A As Long
    Select Case UCase$(parv(0))
      Case "ADD":
        tL = "add event"
        'detect if said event already exists
        If cptr.Events.Count > 0 Then
          For A = 1 To cptr.Events.Count
            'the following conditions must be met to be considered a dupe:
            '1) EventName = event trying to be added OR user specified a wildcard event, -and-
            '2) EventType = event type trying to be added
            '3) Mask = the same
            'if all 3 are met, event is a dupe
            If ((cptr.Events.Item(A).EventName = EventName) Or (Len(cptr.Events.Item(A).EventName) = 0)) And cptr.Events.Item(A).EventType = EventType And cptr.Events.Item(A).Mask = Mask Then
              SendWsock cptr.index, "918 " & cptr.Nick, TranslateCode(IRCERR_EVENTDUP, EventType, Mask)
            End If
          Next A
        End If
        If UCase$(EventType) = "SOCKET" Then
          tL = "add event socket"
          If Len(EventName) = 0 Then
            'note: mask does not apply here
            tL = "add event socket->all events"
            cptr.Events.Add "SOCKET", "*!*@*", "ACCEPT"
            cptr.Events.Add "SOCKET", "*!*@*", "CLOSE"
            tL = "send event socket->all events"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), "*!*@*")
          ElseIf UCase$(EventName) = "ACCEPT" Then
            'SOCKET.OPEN
            tL = "add event socket->accept"
            cptr.Events.Add "SOCKET", "*!*@*", "ACCEPT"
            tL = "sent event socket->accept"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), "*!*@*")
          ElseIf UCase$(EventName) = "CLOSE" Then
            'SOCKET.CLOSE
            tL = "add event socket->close"
            cptr.Events.Add "SOCKET", "*!*@*", "CLOSE"
            tL = "send event socket->close"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), "*!*@*")
          Else
            'send error
            tL = "invalid event name"
            SendWsock cptr.index, "902 " & cptr.Nick, TranslateCode(IRCERR_BADFUNCTION, UCase$(parv(1)))
          End If
        ElseIf UCase$(EventType) = "CHANNEL" Then
          If Len(EventName) = 0 Then
            tL = "add event channel->all"
            cptr.Events.Add "CHANNEL", Mask, "CREATE"
            cptr.Events.Add "CHANNEL", Mask, "TOPIC"
            cptr.Events.Add "CHANNEL", Mask, "MODE"
            cptr.Events.Add "CHANNEL", Mask, "KEYWORD"
            cptr.Events.Add "CHANNEL", Mask, "LIMIT"
            cptr.Events.Add "CHANNEL", Mask, "DESTROY"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "CREATE" Then
            tL = "add event channel->create"
            cptr.Events.Add "CHANNEL", Mask, "CREATE"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "TOPIC" Then
            tL = "add event channel->topicchange"
            cptr.Events.Add "CHANNEL", Mask, "TOPIC"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "MODE" Then
            tL = "add event channel->modechange"
            cptr.Events.Add "CHANNEL", Mask, "MODE"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "DESTROY" Then
            tL = "add event channel->close"
            cptr.Events.Add "CHANNEL", Mask, "DESTROY"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "KEYWORD" Then
            cptr.Events.Add "CHANNEL", Mask, "KEYWORD"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "LIMIT" Then
            cptr.Events.Add "CHANNEL", Mask, "LIMIT"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          Else
            'send error
            tL = "CHANNEL -> invalid event name"
            SendWsock cptr.index, "902 " & cptr.Nick, TranslateCode(IRCERR_BADFUNCTION, UCase$(parv(1)))
          End If
        ElseIf UCase$(EventType) = "MEMBER" Then
          If Len(EventName) = 0 Then
            tL = "add event member->all"
            cptr.Events.Add "MEMBER", Mask, "JOIN"
            cptr.Events.Add "MEMBER", Mask, "PART"
            cptr.Events.Add "MEMBER", Mask, "KICK"
            cptr.Events.Add "MEMBER", Mask, "MODE"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "JOIN" Then
            cptr.Events.Add "MEMBER", Mask, "JOIN"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "PART" Then
            cptr.Events.Add "MEMBER", Mask, "PART"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "KICK" Then
            cptr.Events.Add "MEMBER", Mask, "KICK"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "MODE" Then
            cptr.Events.Add "MEMBER", Mask, "MODE"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          Else
            SendWsock cptr.index, "902 " & cptr.Nick, TranslateCode(IRCERR_BADFUNCTION, UCase$(parv(1)))
          End If
        ElseIf UCase$(EventType) = "USER" Then
          If Len(EventName) = 0 Then
            tL = "add event user->all"
            cptr.Events.Add "USER", Mask, "LOGON"
            cptr.Events.Add "USER", Mask, "LOGOFF"
            cptr.Events.Add "USER", Mask, "MODE"
            cptr.Events.Add "USER", Mask, "NICK"
            cptr.Events.Add "USER", Mask, "KILL"
            cptr.Events.Add "USER", Mask, "QUIT"
            cptr.Events.Add "USER", Mask, "TIMEOUT"
            tL = "send event user->all"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "LOGON" Then
            'USER.LOGON
            tL = "add event user->logon"
            cptr.Events.Add "USER", Mask, "LOGON"
            tL = "send event user->logon"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "LOGOFF" Then
            'USER.LOGOFF
            tL = "add event user->logoff"
            cptr.Events.Add "USER", Mask, "LOGOFF"
            tL = "send event user->logoff"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "MODE" Then
            'USER.MODE
            tL = "add event user->modechange"
            cptr.Events.Add "USER", Mask, "MODE"
            tL = "send event user->modechange"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "NICK" Then
            'USER.NICK
            tL = "add event user->nickchange"
            cptr.Events.Add "USER", Mask, "NICK"
            tL = "send event user->nickchange"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "TIMEOUT" Then
            cptr.Events.Add "USER", Mask, "TIMEOUT"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "QUIT" Then
            cptr.Events.Add "USER", Mask, "QUIT"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          ElseIf UCase$(EventName) = "KILL" Then
            cptr.Events.Add "USER", Mask, "KILL"
            SendWsock cptr.index, "806", TranslateCode(IRCRPL_EVENTADD, cptr.Nick, UCase$(parv(1)), Mask)
          Else
            'send error
            tL = "USER -> invalid event name"
            SendWsock cptr.index, "902 " & cptr.Nick, TranslateCode(IRCERR_BADFUNCTION, UCase$(parv(1)))
          End If
        End If
        tL = "end add"
      Case "DELETE":
        If cptr.Events.Count > 0 Then
          For A = 1 To cptr.Events.Count
            'if it exists, process and exit
            If ((cptr.Events.Item(A).EventName = EventName) Or (Len(EventName) = 0)) And UCase$(cptr.Events.Item(A).EventType) = UCase$(EventType) And (cptr.Events.Item(A).Mask Like Mask) Then
              'it does exist
              cptr.Events.Remove A
              SendWsock cptr.index, "807", TranslateCode(IRCRPL_EVENTDEL, cptr.Nick, UCase$(parv(1)), Mask)
              Exit Function
            End If
            'didn't exist in this slot
          Next A
          'it can't exist
          SendWsock cptr.index, "919 " & cptr.Nick, TranslateCode(IRCERR_EVENTMIS, EventType, Mask)
        End If
      Case "LIST":
        SendWsock cptr.index, "808 " & cptr.Nick, TranslateCode(IRCRPL_EVENTSTART)
        If cptr.Events.Count > 0 Then
          For A = 1 To cptr.Events.Count
            If Len(EventType) <> 0 Then
              If Len(EventName) <> 0 Then
                'if there's an event name (there will be), and eventtype and such was specified
                If (UCase$(EventType) = UCase$(cptr.Events.Item(A).EventType)) And (UCase$(EventName) = UCase$(cptr.Events.Item(A).EventName)) Then
                  SendWsock cptr.index, "809 " & cptr.Nick, UCase$(cptr.Events.Item(A).EventType) & "." & UCase$(cptr.Events.Item(A).EventName) & " " & cptr.Events.Item(A).Mask
                End If
              Else
                'listing all events for a specific type
                If UCase$(EventType) = UCase$(cptr.Events.Item(A).EventType) Then
                  SendWsock cptr.index, "809 " & cptr.Nick, UCase$(cptr.Events.Item(A).EventType) & "." & UCase$(cptr.Events.Item(A).EventName) & " " & cptr.Events.Item(A).Mask
                End If
              End If
            Else
              'no event type specified at all, assuming EVENT LIST (sending all events)
              SendWsock cptr.index, "809 " & cptr.Nick, UCase$(cptr.Events.Item(A).EventType) & "." & UCase$(cptr.Events.Item(A).EventName) & " " & cptr.Events.Item(A).Mask
            End If
          Next A
        End If
        SendWsock cptr.index, "810 " & cptr.Nick, TranslateCode(IRCRPL_EVENTEND)
    End Select
End If
Exit Function

EventError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_event' at " & tL
End Function
