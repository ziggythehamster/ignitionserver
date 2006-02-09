Attribute VB_Name = "mod_NativeFunctions"
'ignitionServer is (C)  Keith Gable, Nigel Jones and Reid Burke.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>
'                     Reid Burke  (AirWalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: mod_NativeFunctions.bas,v 1.10 2004/06/06 02:45:43 ziggythehamster Exp $
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

Option Explicit

#Const Debugging = 0

'Changed to this on 28/02/2003 for WAY faster and bugfree execution -Dill
Public Function Duration(ByVal InSeconds As Long) As String
Dim Seconds As Long, mins As Long, Hours As Long, Days As Long
Seconds = InSeconds Mod 60
mins = (InSeconds \ 60) Mod 60
Hours = ((InSeconds \ 60) \ 60) Mod 24
Days = ((InSeconds \ 60) \ 60) \ 24
Duration = Abs(Days) & " days " & Format$(Abs(Hours), "00") & ":" & Format$(Abs(mins), "00") & ":" & Format$(Abs(Seconds), "00")
End Function

'This is Bahamut style LUSERS instead of unreal style which sends a notice for "highest user count" -Dill
Public Function GetLusers(Nick As String) As String
#If Debugging = 1 Then
    SendSvrMsg "GETLUSERS called! (" & Nick & ")"
#End If
'Chancount/LocServer count are off sometimes
GetLusers = SPrefix & " 251 " & Nick & " :There are " & GlobUsers.Count & " user(s) on " & Servers.Count & " server(s)" & vbCrLf
If Opers.Count > 0 Then GetLusers = GetLusers & SPrefix & " 252 " & Nick & " " & Opers.Count & " :IRC Operator(s) Online" & vbCrLf
If IrcStat.UnknownConnections > 0 Then GetLusers = GetLusers & SPrefix & " 253 " & Nick & " " & IrcStat.UnknownConnections & " :Unknown Connection(s)" & vbCrLf
If IrcStat.Channels > 0 Then GetLusers = GetLusers & SPrefix & " 254 " & Nick & " " & Channels.Count & " :channel(s) formed" & vbCrLf
GetLusers = GetLusers & SPrefix & " 255 " & Nick & " :I have " & GlobUsers.m_LocCount & " client(s) and " & IrcStat.LocServers & " server(s)" & vbCrLf
GetLusers = GetLusers & SPrefix & " 265 " & Nick & " :Current Local Users: " & GlobUsers.m_LocCount & " Max Local Users: " & IrcStat.MaxLocUsers & vbCrLf
GetLusers = GetLusers & SPrefix & " 266 " & Nick & " :Current Global Users: " & GlobUsers.Count & " Max Global Users: " & IrcStat.MaxGlobUsers
End Function

Public Function GetAdmin(Nick As String) As String
#If Debugging = 1 Then
    SendSvrMsg "GETADMIN called! (" & Nick & ")"
#End If
GetAdmin = SPrefix & " 256 " & Nick & " :Administrative information about " & ServerName & vbCrLf
GetAdmin = GetAdmin & SPrefix & " 257 " & Nick & " :Server Location: " & mod_list.AdminLocation & vbCrLf
GetAdmin = GetAdmin & SPrefix & " 258 " & Nick & " :Contact Name: " & mod_list.Admin & vbCrLf
GetAdmin = GetAdmin & SPrefix & " 259 " & Nick & " :Contact E-Mail: " & mod_list.AdminEmail
End Function

'it's a pretty bulky bunch of code but it works fine -Dill
'Massive cleanup, 1st mar 03 -Dill
Public Function GetStats(Nick As String, AccessLvl As Integer, Flag As String, Optional Param As String) As String
#If Debugging = 1 Then
    SendSvrMsg "GETSTATS called! (" & Flag & ")"
#End If
Dim CurUT&, I&, x&
Dim TempIsGlobOper As Boolean
Select Case Flag
    'list all oline hosts and ids -Dill
    Case "o"
        If AccessLvl >= 3 Then
            For x = 2 To UBound(OLine)
                TempIsGlobOper = False
                Dim y&, CurMode$
                For y = 1 To Len(OLine(x).AccessFlag)
                    CurMode = Mid$(OLine(x).AccessFlag, y, 1)
                    Select Case AscW(CurMode)
                        Case umGlobOper
                            TempIsGlobOper = True
                    End Select
                Next y
                If TempIsGlobOper = True Then
                    GetStats = GetStats & SPrefix & " " & RPL_STATSOLINE & " " & Nick & " :O " & OLine(x).Host & " * " & OLine(x).Name & vbCrLf
                Else
                    GetStats = GetStats & SPrefix & " " & RPL_STATSOLINE & " " & Nick & " :o " & OLine(x).Host & " * " & OLine(x).Name & vbCrLf
                End If
            Next x
        Else
            GetStats = GetStats & SPrefix & " " & ERR_NOPRIVILEGES & " " & Nick & " " & TranslateCode(ERR_NOPRIVILEGES) & vbCrLf
        End If
    'List traffic statistics
    Case "?"
    'list y-line info
    Case "y"
'RPL_STATSYLINE
    'list all K/Z line information -Dill
    Case "k"
        If AccessLvl >= 3 Then
        For x = 1 To UBound(KLine)
            If Len(KLine(x).Host) > 0 Then
                GetStats = GetStats & SPrefix & " " & RPL_STATSKLINE & " " & Nick & " :K " & KLine(x).User & "@" & KLine(x).Host & " :" & KLine(x).Reason & vbCrLf
            End If
        Next x
        For x = 1 To UBound(ZLine)
            If Len(ZLine(x).IP) > 0 Then
                GetStats = GetStats & SPrefix & " " & RPL_STATSKLINE & " " & Nick & " :Z " & ZLine(x).IP & " :" & ZLine(x).Reason & vbCrLf
            End If
        Next x
        End If
    'list memory/hashtable statistics
    Case "z"
    'list c/n pairs
    Case "c", "n"
'RPL_STATSCLINE
'RPL_STATSNLINE
    'list current ServerLink/Unknown connection info -Dill
    Case "l"
        GetStats = GetStats & SPrefix & " " & RPL_STATSLINKINFO & " " & Nick & " Name SendQ" & vbCrLf
        Dim Links() As clsClient
        Links = Servers.Values
        If Not Links(0) Is Nothing Then
          For I = 0 To UBound(Links)
            GetStats = GetStats & SPrefix & " " & RPL_STATSLINKINFO & " " & Nick & " " & Links(I).ServerName & " " & Len(Links(I).SendQ) & vbCrLf
          Next I
        End If
    'Send current uptime -Dill
    Case "u"
        GetStats = GetStats & SPrefix & " " & RPL_STATSUPTIME & " " & Nick & " :" & Duration(Abs(UnixTime - StartUpUt)) & vbCrLf
        GetStats = GetStats & SPrefix & " " & RPL_STATSCONN & " " & Nick & " :Connection count since last (re)start: " & IrcStat.Connections & vbCrLf
    'send command inbound bandwidth and usage -Dill
    Case "m"
        If Cmds.Access > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :ACCESS " & Cmds.Access & " " & Cmds.AccessBW & vbCrLf
        If Cmds.Add > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :ADD " & Cmds.Add & " " & Cmds.AddBW & vbCrLf
        If Cmds.Admin > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :ADMIN " & Cmds.Admin & vbCrLf
        If Cmds.Akill > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :AKILL " & Cmds.Akill & " " & Cmds.AkillBW & vbCrLf
        If Cmds.Auth > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :AUTH " & Cmds.Auth & " " & Cmds.AuthBW & vbCrLf
        If Cmds.Away > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :AWAY " & Cmds.Away & " " & Cmds.AwayBW & vbCrLf
        If Cmds.ChanPass > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CHANPASS " & Cmds.ChanPass & " " & Cmds.ChanPassBW & vbCrLf
        If Cmds.ChanServ > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CHANSERV " & Cmds.ChanServ & " " & Cmds.ChanServBW & vbCrLf
        If Cmds.Chghost > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CHGHOST " & Cmds.Chghost & " " & Cmds.ChghostBW & vbCrLf
        If Cmds.ChgNick > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CHGNICK " & Cmds.ChgNick & " " & Cmds.ChgNickBW & vbCrLf
        If Cmds.Close > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CLOSE " & Cmds.Close & " " & Cmds.CloseBW & vbCrLf
        If Cmds.Connect > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CONNECT " & Cmds.Connect & " " & Cmds.ConnectBW & vbCrLf
        If Cmds.Create > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :CREATE " & Cmds.Create & " " & Cmds.CreateBW & vbCrLf
        If Cmds.Die > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :DIE " & Cmds.Die & " " & Cmds.DieBW & vbCrLf
        If Cmds.Hash > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :HASH " & Cmds.Hash & " " & Cmds.HashBW & vbCrLf
        If Cmds.Info > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :INFO " & Cmds.Info & " " & Cmds.InfoBW & vbCrLf
        If Cmds.Invite > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :INVITE " & Cmds.Invite & " " & Cmds.InviteBW & vbCrLf
        If Cmds.Help > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :IRCXHELP " & Cmds.Help & " " & Cmds.HelpBW & vbCrLf
        If Cmds.Ircx > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :IRCX " & Cmds.Ircx & " " & Cmds.IrcxBW & vbCrLf
        If Cmds.Ison > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :ISON " & Cmds.Ison & " " & Cmds.IsonBW & vbCrLf
        If Cmds.Join > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :JOIN " & Cmds.Join & " " & Cmds.JoinBW & vbCrLf
        If Cmds.Kick > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :KICK " & Cmds.Kick & " " & Cmds.KickBw & vbCrLf
        If Cmds.Kill > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :KILL " & Cmds.Kill & " " & Cmds.KillBW & vbCrLf
        If Cmds.KLine > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :KLINE " & Cmds.KLine & " " & Cmds.KlineBW & vbCrLf
        If Cmds.Links > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :LINKS " & Cmds.Links & " " & Cmds.LinksBW & vbCrLf
        If Cmds.List > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :LIST " & Cmds.List & " " & Cmds.ListBW & vbCrLf
        If Cmds.ListX > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :LISTX " & Cmds.ListX & " " & Cmds.ListXBW & vbCrLf
        If Cmds.Lusers > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :LUSERS " & Cmds.Lusers & " " & Cmds.LusersBW & vbCrLf
        If Cmds.Map > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :MAP " & Cmds.Map & " " & Cmds.MapBW & vbCrLf
        If Cmds.MemoServ > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :MEMOSERV " & Cmds.MemoServ & " " & Cmds.MemoServBW & vbCrLf
        If Cmds.Mode > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :MODE " & Cmds.Mode & " " & Cmds.ModeBW & vbCrLf
        If Cmds.MotD > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :MOTD " & Cmds.MotD & " " & Cmds.MotDBW & vbCrLf
        If Cmds.Names > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :NAMES " & Cmds.Names & " " & Cmds.NamesBW & vbCrLf
        If Cmds.Nick > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :NICK " & Cmds.Nick & " " & Cmds.NickBW & vbCrLf
        If Cmds.NickServ > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :NICKSERV " & Cmds.NickServ & " " & Cmds.NickServBW & vbCrLf
        If Cmds.Notice > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :NOTICE " & Cmds.Notice & " " & Cmds.NoticeBW & vbCrLf
        If Cmds.Oper > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :OPER " & Cmds.Oper & " " & Cmds.OperBW & vbCrLf
        If Cmds.OperServ > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :OPERSERV " & Cmds.OperServ & " " & Cmds.OperServBW & vbCrLf
        If Cmds.Part > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PART " & Cmds.Part & " " & Cmds.PartBW & vbCrLf
        If Cmds.Pass > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PASS " & Cmds.Pass & " " & Cmds.PassBW & vbCrLf
        If Cmds.PassCrypt > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PASSCRYPT " & Cmds.PassCrypt & " " & Cmds.PassCryptBW & vbCrLf
        If Cmds.Ping > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PING " & Cmds.Ping & " " & Cmds.PingBW & vbCrLf
        If Cmds.Pong > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PONG " & Cmds.Pong & " " & Cmds.PongBW & vbCrLf
        If Cmds.Privmsg > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PRIVMSG " & Cmds.Privmsg & " " & Cmds.PrivmsgBW & vbCrLf
        If Cmds.Prop > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :PROP " & Cmds.Prop & " " & Cmds.PropBW & vbCrLf
        If Cmds.Quit > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :QUIT " & Cmds.Quit & " " & Cmds.QuitBW & vbCrLf
        If Cmds.Rehash > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :REHASH " & Cmds.Rehash & " " & Cmds.RehashBW & vbCrLf
        If Cmds.Restart > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :RESTART " & Cmds.Restart & " " & Cmds.RestartBW & vbCrLf
        If Cmds.SAMode > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :SAMODE " & Cmds.SAMode & " " & Cmds.SAModeBW & vbCrLf
        If Cmds.Server > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :SERVER " & Cmds.Server & " " & Cmds.ServerBW & vbCrLf
        If Cmds.Squit > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :SQUIT " & Cmds.Squit & " " & Cmds.SquitBW & vbCrLf
        If Cmds.Stats > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :STATS " & Cmds.Stats & " " & Cmds.StatsBW & vbCrLf
        If Cmds.Time > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :TIME " & Cmds.Time & " " & Cmds.TimeBW & vbCrLf
        If Cmds.Topic > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :TOPIC " & Cmds.Topic & " " & Cmds.TopicBW & vbCrLf
        If Cmds.UMode > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :UMODE " & Cmds.UMode & " " & Cmds.UModeBW & vbCrLf
        If Cmds.UnKLine > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :UNKLINE " & Cmds.UnKLine & " " & Cmds.UnKlineBW & vbCrLf
        If Cmds.User > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :USER " & Cmds.User & " " & Cmds.UserBW & vbCrLf
        If Cmds.UserHost > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :USERHOST " & Cmds.UserHost & " " & Cmds.UserHostBW & vbCrLf
        If Cmds.Version > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :VERSION " & Cmds.Version & " " & Cmds.VersionBW & vbCrLf
        If Cmds.Who > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :WHO " & Cmds.Who & " " & Cmds.WhoBW & vbCrLf
        If Cmds.Whois > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :WHOIS " & Cmds.Whois & " " & Cmds.WhoisBW & vbCrLf
        If Cmds.WhoWas > 0 Then GetStats = GetStats & SPrefix & " 212 " & Nick & " :WHOWAS " & Cmds.WhoWas & " " & Cmds.WhoWasBW & vbCrLf
End Select
GetStats = GetStats & SPrefix & " 219 " & Nick & " " & Flag & " :End of /STATS report"
End Function

'An array of +s/opers should be used for this instead of looping
'through all users and check for these modes! -Dill
Public Sub SendSvrMsg(Msg As String, Optional Glob As Boolean = False, Optional Origin As String)
#If Debugging = 1 Then
    CreateObject("Scripting.FileSystemObject").OpenTextFile(App.Path & "\ircx.log", 8, True).WriteLine Msg
#End If
If ServerMsg.Count = 0 Then Exit Sub
If Len(Origin) = 0 Then Origin = ServerName
On Error Resume Next
Dim I As Long, Recv() As clsClient
Recv = ServerMsg.Values
If Recv(0) Is Nothing Then Exit Sub
For I = LBound(Recv) To UBound(Recv)
    SendWsock Recv(I).index, "NOTICE " & Recv(I).Nick, ":" & Msg, ":" & Origin
Next I
If Glob Then SendToServer "GNOTICE :" & Msg, Origin
End Sub
Public Sub ErrorMsg(Msg As String, Optional Glob As Boolean = False, Optional Origin As String)
If ErrorLog = False Then Exit Sub

Dim F As Long
F = FreeFile
Open App.Path & "\errorlog.txt" For Append As F
Print #1, "[" & Now & "] " & Msg
Close #F

If ServerMsg.Count = 0 Then Exit Sub
If Len(Origin) = 0 Then Origin = ServerName
On Error Resume Next
Dim I As Long, Recv() As clsClient
Recv = ServerMsg.Values
If Recv(0) Is Nothing Then Exit Sub
For I = LBound(Recv) To UBound(Recv)
    SendWsock Recv(I).index, "NOTICE " & Recv(I).Nick, ":" & Msg, ":" & Origin
Next I
If Glob Then SendToServer "GNOTICE :" & Msg, Origin
End Sub

'simply substituting chr$(0) with the users nick because the motd is cached -Dill
Public Function ReadMotd(Nick As String) As String
#If Debugging = 1 Then
    SendSvrMsg "READMOTD called! (" & Nick & ")"
#End If
ReadMotd = Replace(MotD, vbNullChar, Nick)
End Function

Public Function GetServer(Mask$) As clsClient
#If Debugging = 1 Then
    SendSvrMsg "GETSERVER called! (" & Mask & ")"
#End If
Dim I&, Val() As clsClient
Val = Servers.Values
For I = LBound(Val) To UBound(Val)
    If Not Val(I).Hops = 0 Then
        If Val(I).ServerName Like Mask Then
            Set GetServer = Val(I)
            Exit Function
        End If
    End If
Next I
End Function
