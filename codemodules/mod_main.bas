Attribute VB_Name = "mod_main"
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


Option Explicit
Public Declare Function SetTimer Lib "user32" (ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
Public Declare Function KillTimer Lib "user32" (ByVal hWnd As Long, ByVal nIDEvent As Long) As Long
Public Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Public Declare Function Send Lib "wsock32.dll" Alias "send" (ByVal s As Long, buf As Any, ByVal buflen As Long, ByVal flags As Long) As Long
Public Declare Function GetTickCount& Lib "kernel32" ()
Private Declare Function CoCreateGuid Lib "ole32" (id As Any) As Long
Private Bye As Boolean
#Const Debugging = 0
#Const CanDie = 1
#Const CanRestart = 1

Public Function CreateGUID() As String
#If Debugging = 1 Then
    SendSvrMsg "CREATEGUID called!"
#End If
    Dim id(0 To 15) As Byte, Cnt As Long
    Call CoCreateGuid(id(0))
    For Cnt = 0 To 15
        CreateGUID = CreateGUID & Hex$(id(Cnt))
    Next Cnt
End Function

Public Sub Main()

If App.PrevInstance = True Then
MsgBox "FATAL ERROR IN MODULE ""IGNITIONSERVER"": This product is already running!"
End
End If
AppVersion = App.Major & "." & App.Minor & "." & App.Revision
AppComments = "ignitionServer " & AppVersion & " (http://www.ignition-project.com/)"
StartUpDate = Now
Error_Connect
InitUnixTime
InitList
SaveSetting "ignitionServer", "Settings", "Path", App.Path
hTmrUnixTime = SetTimer(0&, 0&, 1000&, AddressOf uT)
hTmrDestroyWhoWas = SetTimer(0&, 0&, 300000, AddressOf DestroyWhoWas)
IrcStat.GlobServers = 1
Set Channels = New clsChanHashTable
Set Servers = New clsServerHashTable
Set GlobUsers = New clsUserHashTable
Set Opers = New clsUserHashTable
Set IPHash = New clsIPHashTable
Set ServerMsg = New clsUserHashTable
modWhoWasHashTable.SetSize 128, 128, 64
ReDim Users(0): Channels.SetSize 512, 256, 128
StartUp = GetTickCount
StartUpUt = UnixTime
Channels.IgnoreCase = True
GlobUsers.IgnoreCase = True
Servers.IgnoreCase = True
Opers.IgnoreCase = True
ServerMsg.IgnoreCase = True
Set Sockets = New clsSox
Rehash vbNullString
SPrefix = ":" & ServerName
Dim NewCptr As clsClient
Set NewCptr = New clsClient
With NewCptr
    .AccessLevel = 4
    .HasRegistered = True
    .ServerDescription = ServerDescription
    .ServerName = ServerName
    .UpLink = ServerName
End With
Servers.Add ServerName, NewCptr
GetMotD
SetHelp
IRCxCore
Terminate
End Sub

Public Sub Terminate(Optional Quit As Boolean = True)
#If Debugging = 1 Then
    SendSvrMsg "TERMINATE called!"
#End If
On Error Resume Next
'Release memory used by Channel and User/Server classes -Dill
Erase Users: Channels.RemoveAll: GlobUsers.RemoveAll: Opers.RemoveAll
'Realease Memory used by Configuration Types -Dill
Erase ILine: Erase YLine: Erase ZLine: Erase KLine: Erase QLine: Erase OLine: Erase CLine: Erase NLine
'reset ircd stats -Dill
With IrcStat
    .Channels = 0
    .Connections = 0
    .GlobServers = 0
    .GlobUsers = 0
    .Invisible = 0
    .LocServers = 0
    .LocUsers = 0
    .MaxGlobUsers = 0
    .MaxLocUsers = 0
    .Operators = 0
    .UnknownConnections = 0
End With
RecvQ.RemoveAll
'Release the hook for the winsock window -Dill
Sockets.Unhook
'Destroy the core classes -Dill
Set Sockets = Nothing
Set Channels = Nothing
Set Servers = Nothing
Set GlobUsers = Nothing
Set Opers = Nothing
'Set LocOps = Nothing
'Set GlobOps = Nothing
Set IPHash = Nothing
'Set KillMsg = Nothing
Set ServerMsg = Nothing
'Destroy the Unixtime incrementing Timer -Dill
KillTimer 0&, hTmrUnixTime
KillTimer 0&, hTmrDestroyWhoWas
'Unhook Excpetion filters -Dill
Error_Disconnect
'Unless Quit is set to false we end our program here -Dill
If Quit Then End
End Sub

'Gets executed by a timer on 1000ms interval
Public Function uT(ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
UnixTime = UnixTime + 1
On Error Resume Next
If (ServerTraffic / (UnixTime - StartUpUt)) >= MaxTrafficRate Then
    htm = True
Else
    htm = False
End If
End Function

'The RecvQ processer, main part of the IRC Server -Dill
Public Sub IRCxCore()
On Error Resume Next
Dim CurCmd$, cptr As clsClient, sptr As clsClient, ArgLine$
Dim Prefix$, cmd$, arglist$(), ClearRecvQ&, cmdLen&, cmdHash$, x&
'Infinite loop to keep the server up, it doesnt use up 100% of cpu unless it cant take load -Dill
Do
  Do While (RecvQ.Count = 0 Or x = 200)
    x = 0
    Sleep 10
    DoSend
    DoEvents
  Loop
    x = x + 1
    'Retrieve an item of the RecvQ -Dill
    With RecvQ.Item(1)
        Set cptr = .FromLink
        CurCmd = .Message
    End With
#If Debugging = 1 Then
    CreateObject("Scripting.FileSystemObject").OpenTextFile(App.Path & "\ircd.log", 8, True).WriteLine CurCmd
#End If
    If Len(CurCmd) = 0 Then GoTo nextmsg
    #If Debugging = 1 Then
        cmdHash = cmd
    #End If
            cmdLen = Len(CurCmd)
    If MaxMsgsInQueue > 0 Then cptr.MsgsInQueue = cptr.MsgsInQueue - 1
    'check if we have a prefix -Dill
    If AscW(CurCmd) = 58 Then
        'If so, retrieve it and erase the part we retrieved from the cmdline
        'if its a client sending us the prefix, silently drop the message. -Dill
        If cptr.AccessLevel < 4 Then GoTo nextmsg
        Prefix = Mid$(CurCmd, 2, InStr(1, CurCmd, " ") - 2)
        CurCmd = Mid$(CurCmd, Len(Prefix) + 3)
        If InStr(1, Prefix, "!") <> 0 Then Prefix = Left$(Prefix, InStr(1, Prefix, "!") - 1)
        If InStr(1, Prefix, ".") <> 0 Then
            Set sptr = Servers(Prefix)
            If sptr Is Nothing Then
                SendWsock cptr.index, "SQUIT " & Prefix, ":" & Prefix & " <-- ? Unknown Server"
                SendSvrMsg "*** Notice -- Squit sent for unknown server prefix: " & Prefix, True
                GoTo nextmsg
            End If
        Else
            Set sptr = GlobUsers(Prefix)
            If sptr Is Nothing Then
                SendSvrMsg "***Notice -- KILL sent for unknown prefix: " & Prefix, True
                SendWsock cptr.index, "KILL " & Prefix, ":" & Prefix & " <-- ? Unknown client"
                GoTo nextmsg
            End If
        End If
    Else
        Set sptr = cptr
    End If
    'Get the actual command of the cmdline -Dill
    If InStr(1, CurCmd, " ") <> 0 Then
      cmd = Mid$(CurCmd, 1, InStr(1, CurCmd, " ") - 1)
      '...and erase it from the cmdline -Dill
      CurCmd = Mid$(CurCmd, Len(cmd) + 2)
      'check if we have additional arguments -Dill
      If Not AscW(CurCmd) = 58 Then
        If StrComp(CurCmd, " ") = 1 Then
          If InStr(1, CurCmd, " :") <> 0 Then
            ArgLine = Left$(CurCmd, InStr(1, CurCmd, " :") - 1) 'Get the part infront of the : -Dill
            CurCmd = Replace(CurCmd, ArgLine & " :", vbNullString, , 1)   'Set Curcmd to be the part behind the : -Dill
            ArgLine = Trim$(ArgLine)
            arglist = Split(ArgLine, " ")                       'Array the content of Argline into arglist -Dill
            ReDim Preserve arglist(UBound(arglist) + 1)         'Add the content of curcmd to arglist -Dill
            arglist(UBound(arglist)) = CurCmd
          Else
            arglist = Split(Trim$(CurCmd), " ")
          End If
        End If
      Else
        ReDim arglist(0)          'Add the content of curcmd to arglist -Dill
        arglist(0) = Mid$(CurCmd, 2)
      End If
    Else
      ReDim arglist(0)
      cmd = UCase$(CurCmd)
    End If
    cmd = UCase$(cmd)
    Select Case cmd 'Process the command -Dill
        Case "PRIVMSG": Cmds.Privmsg = Cmds.Privmsg + 1: Cmds.PrivmsgBW = Cmds.PrivmsgBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_message(cptr, sptr, arglist, False)
        Case 100 To 999
            If cptr.AccessLevel = 4 Then Call ProcNumeric(cptr, sptr, arglist, CLng(cmd))
        Case "NOTICE": Cmds.Notice = Cmds.Notice + 1: Cmds.NoticeBW = Cmds.NoticeBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_message(cptr, sptr, arglist, True)
        Case "NICK": Cmds.Nick = Cmds.Nick + 1: Cmds.NickBW = Cmds.NickBW + cmdLen
          Call m_nick(cptr, sptr, arglist)
        Case "JOIN": Cmds.Join = Cmds.Join + 1: Cmds.JoinBW = Cmds.JoinBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_join(cptr, sptr, arglist)
        Case "PART": Cmds.Part = Cmds.Part + 1: Cmds.PartBW = Cmds.PartBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_part(cptr, sptr, arglist)
        Case "MODE": Cmds.Mode = Cmds.Mode + 1: Cmds.ModeBW = Cmds.ModeBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          If UCase(arglist(0)) = "ISIRCX" Then
            SendWsock cptr.index, SPrefix & " 800 * 1 0 " & AuthPackages & " 512 " & Capabilities, vbNullString, , True
            cptr.IsIRCX = True
            SendDirect cptr.index, cptr.Prefix & " MODE " & cptr.Nick & " +x" & vbCrLf
            GoTo nextmsg
          End If
          Call m_mode(cptr, sptr, arglist)
        Case "PROP": Cmds.Prop = Cmds.Prop + 1: Cmds.PropBW = Cmds.PropBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_prop(cptr, sptr, arglist)
        Case "KICK": Cmds.Kick = Cmds.Kick + 1: Cmds.KickBw = Cmds.KickBw + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_kick(cptr, sptr, arglist)
        Case "ISON": Cmds.Ison = Cmds.Ison + 1: Cmds.IsonBW = Cmds.IsonBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_ison(cptr, sptr, arglist)
        Case "USERHOST": Cmds.UserHost = Cmds.UserHost + 1: Cmds.UserHostBW = Cmds.UserHostBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_userhost(cptr, sptr, arglist)
        Case "LUSERS": Cmds.Lusers = Cmds.Lusers + 1: Cmds.LusersBW = Cmds.LusersBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_lusers(cptr, sptr, arglist)
        Case "PASS": Cmds.Pass = Cmds.Pass + 1: Cmds.PassBW = Cmds.PassBW + cmdLen
            If m_pass(cptr, sptr, arglist) = -1 Then
                m_error cptr, "Closing Link: (Bad Password)"
            End If
        Case "AUTH": Cmds.Auth = Cmds.Auth + 1: Cmds.AuthBW = Cmds.AuthBW + cmdLen
          With cptr
            If .HasRegistered = True Then
              SendWsock .index, IRCERR_ALREADYAUTHENTICATED, TranslateCode(IRCERR_ALREADYAUTHENTICATED)
            Else
              'we would send auth here, and stuff...
              'for now we ignore this
            End If
          End With
        Case "ACCESS": Cmds.Access = Cmds.Access + 1: Cmds.AccessBW = Cmds.AccessBW + cmdLen
          With cptr
            If .HasRegistered = False Then
              SendWsock .index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_access(cptr, sptr, arglist)
          End With
        Case "PONG": Cmds.Pong = Cmds.Pong + 1: Cmds.PongBW = Cmds.PongBW + cmdLen
          With cptr
            If .Timeout = 2 Then
                If Len(.User) > 0 Then
                  If Len(.Nick) > 0 Then
                    .RealHost = .Host
                    SendWsock .index, SPrefix & " 001 " & .Nick & " :Welcome to the " & IRCNet & " IRC Network " & .Nick & "!" & .User & "@" & .RealHost, vbNullString, , True
                    SendWsock .index, SPrefix & " 002 " & .Nick & " :Your host is " & ServerName & ", running version ignitionServer-" & AppVersion, vbNullString, , True
                    SendWsock .index, SPrefix & " 003 " & .Nick & " :This server was created " & StartUpDate, vbNullString, , True
                    SendWsock .index, SPrefix & " 004 " & .Nick & " " & ServerName & " ignitionServer " & UserModes & " " & ChanModes, vbNullString, , True
                    SendWsock .index, SPrefix & " 005 " & .Nick & " IRCX CHANTYPES=# PREFIX=(qov).@+ CHANMODES=" & ChanModes & " NETWORK=" & Replace(IRCNet, " ", "_") & " :are supported by this server", vbNullString, , True
                    IrcStat.GlobUsers = IrcStat.GlobUsers + 1: IrcStat.LocUsers = IrcStat.LocUsers + 1
                    If IrcStat.MaxGlobUsers < IrcStat.GlobUsers Then IrcStat.MaxGlobUsers = IrcStat.MaxGlobUsers + 1
                    If IrcStat.MaxLocUsers < IrcStat.LocUsers Then IrcStat.MaxLocUsers = IrcStat.MaxLocUsers + 1
                    SendWsock .index, GetLusers(.Nick), vbNullString, , True
                    SendWsock .index, ReadMotd(.Nick), vbNullString, , True
                    .HasRegistered = True
                    SendToServer "NICK" & " " & .Nick & " 1 " & .SignOn & _
                    " " & .User & " " & .Host & " " & ServerName & " :" & .Name
                    .Prefix = ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host
                    .UpLink = ServerName
                  End If
                End If
            End If
            .Timeout = 0
          End With
        Case "ISIRCX": Cmds.Ircx = Cmds.Ircx + 1: Cmds.IrcxBW = Cmds.IrcxBW + cmdLen
          SendWsock cptr.index, SPrefix & " 800 * 1 0 " & AuthPackages & " 512 " & Capabilities, vbNullString, , True
          cptr.IsIRCX = True
          SendDirect cptr.index, cptr.Prefix & " MODE " & cptr.Nick & " +x" & vbCrLf
        Case "IRCX": Cmds.Ircx = Cmds.Ircx + 1: Cmds.IrcxBW = Cmds.IrcxBW + cmdLen
          SendWsock cptr.index, SPrefix & " 800 * 1 0 " & AuthPackages & " 512 " & Capabilities, vbNullString, , True
          cptr.IsIRCX = True
          SendDirect cptr.index, cptr.Prefix & " MODE " & cptr.Nick & " +x" & vbCrLf
        Case "QUIT": Cmds.Quit = Cmds.Quit + 1: Cmds.QuitBW = Cmds.QuitBW + cmdLen
          Call m_quit(cptr, sptr, arglist)
        Case "VHOST"
            Call m_vhost(cptr, sptr, arglist)
        Case "USER": Cmds.User = Cmds.User + 1: Cmds.UserBW = Cmds.UserBW + cmdLen
          m_user cptr, sptr, arglist
        Case "TOPIC": Cmds.Topic = Cmds.Topic + 1: Cmds.TopicBW = Cmds.TopicBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_topic(cptr, sptr, arglist)
        Case "INVITE": Cmds.Invite = Cmds.Invite + 1: Cmds.InviteBW = Cmds.InviteBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_invite(cptr, sptr, arglist)
        Case "SAMODE": Cmds.SAMode = Cmds.SAMode + 1: Cmds.SAModeBW = Cmds.SAModeBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_samode(cptr, sptr, arglist)
        Case "UMODE": Cmds.UMode = Cmds.UMode + 1: Cmds.UModeBW = Cmds.UModeBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_umode(cptr, sptr, arglist)
        Case "NAMES": Cmds.Names = Cmds.Names + 1: Cmds.NamesBW = Cmds.NamesBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_names(cptr, sptr, arglist)
        Case "LIST": Cmds.List = Cmds.List + 1: Cmds.ListBW = Cmds.ListBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_list(cptr, sptr, arglist)
        'IRCX - Ziggy
        Case "LISTX": Cmds.ListX = Cmds.ListX + 1: Cmds.ListXBW = Cmds.ListXBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_listx(cptr, sptr, arglist)
        Case "PING": Cmds.Ping = Cmds.Ping + 1: Cmds.PingBW = Cmds.PingBW + cmdLen
          m_ping cptr, sptr, arglist
        Case "WHOIS": Cmds.Whois = Cmds.Whois + 1: Cmds.WhoisBW = Cmds.WhoisBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_whois(cptr, sptr, arglist)
        Case "WHOWAS": Cmds.WhoWas = Cmds.WhoWas + 1: Cmds.WhoWasBW = Cmds.WhoWasBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_whowas(cptr, sptr, arglist)
        Case "AWAY": Cmds.Away = Cmds.Away + 1: Cmds.AwayBW = Cmds.AwayBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_away(cptr, sptr, arglist)
        Case "MOTD": Cmds.MotD = Cmds.MotD + 1: Cmds.MotDBW = Cmds.MotDBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_motd(cptr, sptr, arglist)
        Case "VERSION": Cmds.Version = Cmds.Version + 1: Cmds.VersionBW = Cmds.VersionBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_version(cptr, sptr, arglist)
        Case "TIME": Cmds.Time = Cmds.Time + 1: Cmds.TimeBW = Cmds.TimeBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_time(cptr, sptr, arglist)
'        Case "INFO": Cmds.Info = Cmds.Info + 1
'          m_info cptr, sptr, arglist
        Case "STATS": Cmds.Stats = Cmds.Stats + 1: Cmds.StatsBW = Cmds.StatsBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_stats(cptr, sptr, arglist)
        Case "LINKS": Cmds.Links = Cmds.Links + 1: Cmds.LinksBW = Cmds.LinksBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_links(cptr, sptr, arglist)
'        Case "MAP"
'          m_map cptr, sptr, arglist
        Case "ADMIN": Cmds.Admin = Cmds.Admin + 1: Cmds.AdminBW = Cmds.AdminBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_admin(cptr, sptr, arglist)
        Case "WHO": Cmds.Who = Cmds.Who + 1: Cmds.WhoBW = Cmds.WhoBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_who(cptr, sptr, arglist)
        Case "SERVER": Cmds.Server = Cmds.Server + 1: Cmds.ServerBW = Cmds.ServerBW + cmdLen
          Call m_server(cptr, sptr, arglist)
        Case "NJOIN"
          Call m_njoin(cptr, sptr, arglist)
        Case "HELP": Cmds.Help = Cmds.Help + 1: Cmds.HelpBW = Cmds.HelpBW + cmdLen
          Call m_help(cptr, sptr, arglist(0))
        Case "IRCDHELP": Cmds.Help = Cmds.Help + 1: Cmds.HelpBW = Cmds.HelpBW + cmdLen
          Call m_help(cptr, sptr, arglist(0))
        Case "IRCXHELP": Cmds.Help = Cmds.Help + 1: Cmds.HelpBW = Cmds.HelpBW + cmdLen
          Call m_help(cptr, sptr, arglist(0))
'*****************************
'|      Operator Queries    ||
'*****************************
'I'm going to add a CHGHost soon but am not Ready To Put it in Fully *Yet* Planning on it in near Future
'Task #90351 - DG
'        Case "CHGHOST": Cmds.Chghost = Cmds.Chghost + 1: Cmds.ChghostBW = Cmds.ChghostBW + cmdLen
'          If Not cptr.HasRegistered Then
'            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
'            GoTo nextmsg
'          End If
'            Call m_chghost(cptr, sptr, arglist)
        Case "OPER": Cmds.Oper = Cmds.Oper + 1: Cmds.OperBW = Cmds.OperBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_oper(cptr, sptr, arglist)
        'Case "WALL"
'        Case "WALLOPS"
'          m_wallops cptr, sptr, arglist
        'Case "LOCOPS"
        'Case "GLOBOPS"
        Case "HASH": Cmds.Hash = Cmds.Hash + 1: Cmds.HashBW = Cmds.HashBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_hash(cptr, sptr, arglist)
        Case "CLOSE": Cmds.Close = Cmds.Close + 1: Cmds.CloseBW = Cmds.CloseBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_close(cptr, sptr, arglist)
        #If CanRestart = 1 Then
            Case "RESTART": Cmds.Restart = Cmds.Restart + 1: Cmds.RestartBW = Cmds.RestartBW + cmdLen
                If Not cptr.HasRegistered Then
                  SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
                  GoTo nextmsg
                End If
                Call m_restart(cptr, sptr, arglist)
        #End If
        #If CanDie = 1 Then
            Case "DIE": Cmds.Die = Cmds.Die + 1: Cmds.DieBW = Cmds.DieBW + cmdLen
                If Not cptr.HasRegistered Then
                  SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
                  GoTo nextmsg
                End If
                Call m_die(cptr, sptr, arglist)
        #End If
        
        Case "KLINE": Cmds.KLine = Cmds.KLine + 1: Cmds.KlineBW = Cmds.KlineBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_kline(cptr, sptr, arglist)
            
        Case "UNKLINE": Cmds.UnKLine = Cmds.UnKLine + 1: Cmds.UnKlineBW = Cmds.UnKlineBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_unkline(cptr, sptr, arglist)
            
        Case "KILL": Cmds.Kill = Cmds.Kill + 1: Cmds.KillBW = Cmds.KillBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_kill(cptr, sptr, arglist)
'        Case "AKILL"
'            m_akill cptr, sptr, arglist
        Case "REHASH": Cmds.Rehash = Cmds.Rehash + 1: Cmds.RehashBW = Cmds.RehashBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_rehash(cptr, sptr, arglist)
        Case "SUMMON"
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_summon(cptr, sptr, arglist)
        Case "USERS"
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_users(cptr, sptr, arglist)
        'Case "CLEARWHOWAS"
        Case "CONNECT": Cmds.Connect = Cmds.Connect + 1: Cmds.ConnectBW = Cmds.ConnectBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_connect(cptr, sptr, arglist)
        Case "SQUIT": Cmds.Squit = Cmds.Squit + 1: Cmds.Squit = Cmds.Squit + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_squit(cptr, sptr, arglist)
        Case "ERROR"
            If cptr.AccessLevel = 4 Then
                If Not cptr.HasRegistered Then
                  SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
                  GoTo nextmsg
                End If
                Call m_error(cptr, arglist(0))
            Else
                SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNCOMMAND, , , cmd)
            End If
        Case "GNOTICE"
            Call m_gnotice(cptr, sptr, arglist)
'*****************************
'|     Service Commands  ||     'Better be added later, after this all has been completed -Dill
'******************************
        Case "NS": Cmds.NickServ = Cmds.NickServ + 1: Cmds.NickServBW = Cmds.NickServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_nickserv(cptr, sptr, arglist)
        Case "NICKSERV": Cmds.NickServ = Cmds.NickServ + 1: Cmds.NickServBW = Cmds.NickServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_nickserv(cptr, sptr, arglist)
        Case "MS": Cmds.MemoServ = Cmds.MemoServ + 1: Cmds.MemoServBW = Cmds.MemoServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_memoserv(cptr, sptr, arglist)
        Case "MEMOSERV": Cmds.MemoServ = Cmds.MemoServ + 1: Cmds.MemoServBW = Cmds.MemoServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_memoserv(cptr, sptr, arglist)
        Case "CS": Cmds.ChanServ = Cmds.ChanServ + 1: Cmds.ChanServBW = Cmds.ChanServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_chanserv(cptr, sptr, arglist)
        Case "CHANSERV": Cmds.ChanServ = Cmds.ChanServ + 1: Cmds.ChanServBW = Cmds.ChanServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_chanserv(cptr, sptr, arglist)
        Case "OS": Cmds.OperServ = Cmds.OperServ + 1: Cmds.OperServBW = Cmds.OperServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_operserv(cptr, sptr, arglist)
        Case "OPERSERV": Cmds.OperServ = Cmds.OperServ + 1: Cmds.OperServBW = Cmds.OperServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_operserv(cptr, sptr, arglist)
        Case Else
            SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNCOMMAND, , , cmd)
    End Select
nextmsg:
    Set sptr = Nothing
    ReDim arglist(-1)
Loop
End Sub

Public Function GetRand() As Long
#If Debugging = 1 Then
    SendSvrMsg "GETRAND called!"
#End If
Randomize
Dim MyValue As Long, i As Long, r As Long
For i = 1 To 4
    MyValue = Int((9 * Rnd) + 0)
    r = CLng(CStr(r) & CStr(MyValue))
Next i
GetRand = r
End Function

Public Sub KillDupes(ByRef srcArray&())
#If Debugging = 1 Then
    SendSvrMsg "KILLDUPES called!"
#End If
    Dim x&, y&, Arr2&(), z&
    Arr2 = srcArray
    For x = LBound(srcArray) To UBound(srcArray)
        For y = LBound(Arr2) To UBound(Arr2)
            If srcArray(x) = Arr2(y) Then
                z = z + 1
                If z = 2 Then
                    srcArray(x) = 0
                    z = 0
                End If
            End If
        Next y
        z = 0
    Next x
End Sub

'This proc is used to make sure an object is unloaded
Public Sub KillStruct(Name$, Optional InType As enmType = enmTypeClient)
#If Debugging = 1 Then
    SendSvrMsg "KILLSTRUCT called! (" & Name & ")"
#End If
On Error Resume Next
Dim cptr As clsClient, Chan As clsChannel, i&, User() As clsClient
If InType = enmTypeClient Then
    Set cptr = GlobUsers(Name)
    If Not cptr Is Nothing Then
        With cptr
            Do While (.OnChannels.Count > 0)
                Set Chan = cptr.OnChannels.Item(1)
                Chan.Member.Remove cptr.Nick
                cptr.OnChannels.Remove Chan.Name
                If Chan.Member.Count = 0 Then Channels.Remove Chan.Name
                Set Chan = Nothing
            Loop
            Set .FromLink = Nothing
        End With
        If cptr.Hops = 0 Then Set Users(cptr.index) = Nothing
        If cptr.IsServerMsg Then
            ServerMsg.Remove cptr.GUID
        End If
        If cptr.IsLocOperator Or cptr.IsGlobOperator Then
            Opers.Remove cptr.GUID
        End If
        GlobUsers.Remove cptr.Nick
        Set cptr = Nothing
    End If
ElseIf InType = enmTypeChannel Then
ElseIf InType = enmTypeServer Then
    If Name = ServerName Then Exit Sub
    Set cptr = Servers(Name)
    User = GlobUsers.Values
    For i = LBound(User) To UBound(User)
        With User(i)
            If Not .FromLink Is Nothing Then
                If .FromLink.ServerName = Name Then
                    Set .FromLink = Nothing
                End If
            End If
        End With
    Next i
    User = Servers.Values
    For i = LBound(User) To UBound(User)
        With User(i)
            If Not .FromLink Is Nothing Then
                If .FromLink.ServerName = Name Then
                    Set .FromLink = Nothing
                    Servers.Remove .ServerName
                    Set User(i) = Nothing
                End If
            End If
        End With
    Next i
    Set cptr.FromLink = Nothing
    Servers.Remove Name
End If
End Sub

Public Function DestroyWhoWas(ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
modWhoWasHashTable.RemoveAll
End Function

Public Sub DoSend() '(ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
On Error Resume Next
Dim OutMsg() As Byte, cptr As clsClient, i&, x&
If ColOutClientMsg.Count = 0 Then Exit Sub
Do While ColOutClientMsg.Count > 0
    x = x + 1
    If x >= 200 Then
        DoEvents
        x = 0
    End If
    Set cptr = Users(ColOutClientMsg(1))
    If cptr Is Nothing Then
        ColOutClientMsg.Remove 1
        GoTo nextmsg
    End If
    With cptr
        If Len(.SendQ) < 3 Then
            ColOutClientMsg.Remove 1
            GoTo nextmsg
        ElseIf Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered Then
            If .AccessLevel < 4 Then
                If .IsKilled Then
                    ColOutClientMsg.Remove 1
                    GoTo nextmsg
                End If
                .IsKilled = True
                'a client flooding us
                For i = 1 To .OnChannels.Count
                    SendToChan .OnChannels.Item(i), .Prefix & " QUIT :Max SendQ length exceeded", vbNullString
                Next i
                SendToServer "QUIT :Max SendQ length exceeded", .Nick
                KillStruct cptr.Nick, enmTypeClient
                m_error cptr, "Closing Link: Max SendQ length exceeded"
                GoTo nextmsg
            Else
                'a server generating a huge flood
                If .IsKilled Then
                    ColOutClientMsg.Remove 1
                    GoTo nextmsg
                End If
                .IsKilled = True
                Dim usr() As clsClient, y&
                usr = GlobUsers.Values
                For i = LBound(usr) To UBound(usr)
                    Set usr(i).FromLink = Nothing
                    KillStruct usr(i).Nick, enmTypeClient
                    usr(i).SendQ = vbNullString
                    For y = 1 To .OnChannels.Count
                        SendToChan .OnChannels.Item(y), .Prefix & " QUIT :Max SendQ length exceeded", vbNullString
                    Next y
                    Set usr(i) = Nothing
                    GoTo nextmsg
                Next i
                m_error cptr, "Closing Link: Max SendQ length exceeded"
                SendToServer_ButOne "SQUIT :Max SendQ length exceeded", .ServerName, .ServerName
                SendSvrMsg "Closing link to " & .ServerName & " (Max SendQ length exceeded)"
                .SendQ = vbNullString
                Set .FromLink = Nothing
                Sockets.CloseIt .index
                Set Users(.index) = Nothing
                Set cptr = Nothing
                GoTo nextmsg
            End If
            m_error cptr, "Max SendQ exceeded"
            Set cptr = Nothing
            ColOutClientMsg.Remove 1
            GoTo nextmsg
        End If
        If .IsKilled Then
            ColOutClientMsg.Remove 1
            .SendQ = vbNullString
            GoTo nextmsg
        End If
#If Debugging = 1 Then
    CreateObject("Scripting.FileSystemObject").OpenTextFile(App.Path & "\ircd.log", 8, True).WriteLine .SendQ
#End If
        SentMsg = SentMsg + 1
        OutMsg = StrConv(.SendQ, vbFromUnicode)
        ColOutClientMsg.Remove 1
        Call Send(.SockHandle, OutMsg(0), UBound(OutMsg) + 1, 0)
        .SendQ = vbNullString
    End With
nextmsg:
Loop
End Sub
