Attribute VB_Name = "mod_serv"
'ignitionServer is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@silentsoft.net>
'                     Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
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

Option Explicit

Public Function ProcNumeric&(cptr As clsClient, sptr As clsClient, parv$(), Num&)
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- PROCNUMERIC called! (" & cptr.Nick & ")"
#End If
Dim Args$, i&
For i = 1 To UBound(parv)
    If UBound(parv) > i Then
        Args = Args & parv(i) & " "
    Else
        Args = Args & ":" & parv(i)
    End If
Next i
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
        SendWsock cptr.index, RPL_VERSION & " " & sptr.Nick & " " & AppVersion & "." & BuildDate & " ignitionServer", ":" & AppComments
    Else
        SendWsock Target.FromLink.index, "VERSION", ":" & Target.ServerName, ":" & sptr.Nick
    End If
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_VERSION & " " & cptr.Nick & " " & AppVersion & "." & BuildDate & " ignitionServer", ":" & AppComments
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
Dim Target As clsClient, User() As clsClient, i&, z&
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
            For i = LBound(User) To UBound(User)
                If User(i).FromLink Is Target Then
                    For z = 1 To User(i).OnChannels.Count
                        SendToChan User(i).OnChannels.Item(z), User(i).Prefix & " QUIT :" & ServerName & " " & Target.ServerName, vbNullString
                    Next z
                    KillStruct User(i).Nick
                    SendToServer "QUIT :" & ServerName & " " & Target.ServerName, User(i).Nick
                    '#If Debugging = 1 Then
                        SendSvrMsg "*** Notice -- User " & User(i).Nick & " lost during netsplit"
                    '#End If
                    Set User(i) = Nothing
                End If
            Next i
            User = Servers.Values
            For i = LBound(User) To UBound(User)
                If User(i).FromLink Is cptr Then
                    Servers.Remove User(i).ServerName
                    SendToServer "SQUIT :" & User(i).ServerName, ServerName
                    Set User(i).FromLink = Nothing
                    '#If Debugging = 1 Then
                        SendSvrMsg "*** Notice -- Server " & User(i).ServerName & " lost during netsplit"
                    '#End If
                    Set User(i) = Nothing
                End If
            Next i
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
Dim NewSptr As clsClient, User As clsClient, SendAuth As CLines, Outgoing$, SendInfo As Boolean
If Not cptr.HasRegistered Then
    If cptr.AccessLevel = 4 Then
        SendInfo = False
    Else
        SendInfo = True
    End If
    If Not cptr.Nlined Then
        If DoNLine(cptr) Then
            Exit Function
        End If
        cptr.Nlined = True
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
    Servers.Add cptr.ServerName, cptr
    cptr.UpLink = ServerName
    With cptr
        .Nick = parv(0)
        .ServerDescription = parv(2)
        Set .FromLink = cptr
        .HasRegistered = True
        SendAuth = GetCLine(.ServerName)
        If Len(SendAuth.Server) = 0 Then
            Servers.Remove cptr.ServerName
            m_error cptr, "Unauthorized connection"
            Exit Function
        End If
        SendSvrMsg "*** Notice -- Link with " & .ServerName & " accepted."
        If SendInfo Then
            SendWsock .index, "PASS " & SendAuth.Pass, vbNullString, vbNullString, True
            SendWsock .index, "SERVER " & ServerName & " 1 :" & ServerDescription, vbNullString, vbNullString, True
        End If
        Dim i As Long, Val() As clsClient, x As Long, chans() As clsChannel, Membrs$, ChM() As clsChanMember, y&
        Dim c&, s&, u&
        Val = Servers.Values
        If Not Val(0) Is Nothing Then
            For i = 0 To UBound(Val)
                If Val(i).Hops > 0 Then
                    SendWsock .index, "SERVER" & " " & Val(i).ServerName & " " & Val(i).Hops + 1, ":" & Val(i).ServerDescription, ":" & Val(i).UpLink
                    s = s + 1
                End If
            Next i
        End If
        Val = GlobUsers.Values
        If Not Val(0) Is Nothing Then
            For i = 0 To UBound(Val)
                SendWsock .index, "NICK" & " " & Val(i).Nick & " " & Val(i).Hops + 1 & " " & Val(i).SignOn & _
                " " & Val(i).User & " " & Val(i).Host & " " & Val(i).FromLink.ServerName, ":" & Val(i).Name
                u = u + 1
            Next i
        End If
        chans = Channels.Values
        If Not chans(0) Is Nothing Then
            For i = 0 To UBound(chans)
                ChM = chans(i).Member.Values
                For y = 0 To UBound(ChM)
                    'add another record to the njoin buffer
                    x = x + 1
                    c = c + 1
                    If ChM(y).IsOwner Then 'I think Ziggy Missed this bit...DAM - DG
                        Membrs = Membrs & "." & ChM(y).Member.Nick & " "
                    ElseIf ChM(y).IsOp Then
                        Membrs = Membrs & "@" & ChM(y).Member.Nick & " "
                    ElseIf ChM(y).IsHOp Then
                        Membrs = Membrs & "%" & ChM(y).Member.Nick & " "
                    ElseIf ChM(y).IsVoice Then
                        Membrs = Membrs & "+" & ChM(y).Member.Nick & " "
                    Else
                        Membrs = Membrs & ChM(y).Member.Nick & " "
                    End If
                    If x = 11 Or y = UBound(ChM) Then
                        'flush
                        SendWsock .index, "NJOIN " & chans(i).Name, ":" & Trim$(Membrs)
                        Membrs = vbNullString
                        x = 0
                    End If
                Next y
            Next i
        End If
        SendSvrMsg "*** Notice -- " & s & " Severs, " & u & " users and " & c & " channel structures sent to " & .ServerName
        SendSvrMsg "*** Notice -- Link with " & .ServerName & " established."
        SendToServer_ButOne "SERVER " & .ServerName & " " & .Hops + 1 & " :" & .ServerDescription, .ServerName, ServerName
    End With
Else
    Set NewSptr = Servers(parv(0))
    If Not NewSptr Is Nothing Then
        If Not NewSptr.ServerName = ServerName Then
            If Not parv(0) = cptr.ServerName Then
                If Not cptr.ServerName = parv(0) Then
                    SendSvrMsg "Server " & parv(0) & " already exists from " & NewSptr.FromLink.ServerName, True
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
End If
IrcStat.GlobServers = IrcStat.GlobServers + 1
End Function

'/*
'** m_info
'**  parv$()[0] = sender prefix
'**  parv$()[1] = servername
'*/
'Public Function m_info(cptr As clsClient, sptr As clsClient, parv$()) As Long
'
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
Dim i&, Links() As clsClient
Links = Servers.Values
If Not Links(0) Is Nothing Then
    For i = 0 To UBound(Links)
        SendWsock cptr.index, RPL_LINKS & " " & cptr.Nick & " " & Links(i).ServerName & " " & Links(i).UpLink, ":" & Links(i).Hops & " " & Links(i).ServerDescription
    Next i
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
    SendWsock cptr.index, GetStats(cptr.Nick, cptr.AccessLevel, parv(0)), vbNullString, , True
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
Dim Target As clsClient, ConnAuth As CLines
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
            ConnAuth = GetCLine(parv(0))
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
            ConnAuth = GetCLine(parv(0))
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
        SendWsock cptr.index, RPL_TIME & " " & sptr.Nick, ":" & Date & " -- " & Time$ & " -0100"
    Else
        SendWsock Target.FromLink.index, "TIME", Target.ServerName, ":" & sptr.Nick
    End If
Else
    'maybe a different format would be better, this should be correct too though -Dill
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_TIME & " " & cptr.Nick, ":" & Date & " -- " & Time$ & " -0100"
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
    '"ERR_NOADMININFO" should be sent if there is no info available here -Dill
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
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, RPL_REHASHING & " " & cptr.Nick, "ircx.conf :Rehashing"
    End If
    Rehash parv(0)
    SendSvrMsg "*** Notice -- " & ServerName & " has rehashed on the request of: " & cptr.Nick
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
            Dim i As Long   'close all connections properly -Dill
            For i = 1 To UBound(Users)
                If Not Users(i) Is Nothing Then
                    m_error Users(i), "Closing Link: (" & ServerName & " is restarting on the request of " & cptr.Nick & ")"
                End If
            Next i
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
''not sure how to do this -Dill
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
            Dim i As Long   'close all connection properly -Dill
            For i = 1 To UBound(Users)
                If Not Users(i) Is Nothing Then
                    SendWsock i, "NOTICE " & Users(i).Nick, SPrefix & " is quiting on the request of: " & cptr.Nick
                    Sockets.CloseIt i
                    m_error Users(i), "Closing Link: (" & ServerName & " is quitting)"
                End If
            Next i
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
Dim i As Long, x&   'close all connections properly -Dill
For i = 1 To UBound(Users)
    If Not Users(i) Is Nothing Then
        If Users(i).HasRegistered = False Then
            m_error Users(i), "Closing Link: (Closing half-open connections)"
            x = x + 1
            Set Users(i) = Nothing
        End If
    End If
Next i
SendWsock cptr.index, "NOTICE " & cptr.Nick, ":*** Notice -- " & x & " unregistered connections closed"
IrcStat.UnknownConnections = 0
End Function

'*/ shows how the network is currently laid out /* -Dill
Public Function m_map(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- MAP called! (" & cptr.Nick & ")"
#End If
'Dim i&, Links() As clsClient
'Links = Servers.Values
'If Not Links(0) Is Nothing Then
'    For i = 0 To UBound(Links)
'        SendWsock cptr.Index, RPL_MAP & cptr.Nick & " "
'    Next i
'End If
'SendWsock cptr.Index, RPL_ENDOFLINKS & " " & cptr.Nick, ":End of /LINKS list"
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
On Error Resume Next
#If Debugging = 1 Then
    SendSvrMsg "*** Notice -- KLINE called! (" & cptr.Nick & ")"
#End If
Dim i&, z&, Mask$, NewKline As KLines, KUser$, KHost$
If Not (cptr.CanKline Or cptr.CanUnkline) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KLINE")
    Exit Function
End If
If UBound(parv) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KLINE")
    Exit Function
End If
Mask = ":" & CreateMask(parv(0))
For i = LBound(Users) To UBound(Users)
    If Not Users(i) Is Nothing Then
        If Users(i).Prefix Like Mask Then
            m_error Users(i), "Closing Link: K-Line active from: " & cptr.Nick & " (" & parv(1) & ")"
            For z = 1 To Users(i).OnChannels.Count
                SendToChan Users(i).OnChannels.Item(z), Users(i).Prefix & " QUIT :Kline active (" & parv(1) & ")", vbNullString
            Next z
            Sockets.TerminateSocket Users(i).SockHandle
            KillStruct Users(i).Nick
        End If
    End If
Next i
Mask = Mid$(Mask, 2)
KHost = Mid$(Mask, InStr(1, Mask, "@") + 1)
Mask = Replace(Mask, "@" & KHost, vbNullString, , 1)
KUser = Mid$(Mask, InStr(1, Mask, "!") + 1)
ReDim Preserve KLine(UBound(KLine) + 1)
With KLine(UBound(KLine))
    .Host = KHost
    .reason = parv(1)
    .User = KUser
End With
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
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KLINE")
    Exit Function
End If
Dim i&
For i = 1 To UBound(KLine)
    If Len(KLine(i).Host) > 0 Then
        If KLine(i).User & "@" & KLine(i).Host Like parv(0) Then
            KLine(i).Host = vbNullString
            KLine(i).User = vbNullString
            KLine(i).reason = vbNullString
        End If
    End If
Next i
End Function
