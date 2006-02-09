Attribute VB_Name = "mod_main"
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
' $Id: mod_main.bas,v 1.31 2004/08/08 21:14:32 ziggythehamster Exp $
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
Public Declare Function SetTimer Lib "user32" (ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
Public Declare Function KillTimer Lib "user32" (ByVal hWnd As Long, ByVal nIDEvent As Long) As Long
Public Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Public Declare Function Send Lib "wsock32.dll" Alias "send" (ByVal s As Long, buf As Any, ByVal buflen As Long, ByVal flags As Long) As Long
Public Declare Function GetTickCount& Lib "kernel32" ()
Private Declare Function CoCreateGuid Lib "ole32" (ID As Any) As Long
Private Bye As Boolean
#Const Debugging = 0 'enabling debugging here also turns on ircx.log
#Const CanDie = 1
#Const CanRestart = 1
#Const EnableNonstandard = 0

Public Function CreateGUID() As String
#If Debugging = 1 Then
    SendSvrMsg "CREATEGUID called!"
#End If
    Dim ID(0 To 15) As Byte, Cnt As Long
    Call CoCreateGuid(ID(0))
    For Cnt = 0 To 15
        CreateGUID = CreateGUID & Hex$(ID(Cnt))
    Next Cnt
End Function

Public Sub Main()
Dim F As Long
F = FreeFile
If App.PrevInstance = True And AllowMultiple = False Then
'you can't display msgbox'es in an unattended app...
'perhaps we need to puke it to a logfile or something?
'MsgBox "FATAL ERROR IN MODULE ""IGNITIONSERVER"": You can not start multiple instances of ignitionServer - see X:ALLOWMULTIPLE to change this setting"
ErrorMsg "ignitionServer was attempted to be started more than one time. ignitionServer can only be run once unless X:ALLOWMULTIPLE is enabled to allow this."
End
End If
AppVersion = App.Major & "." & App.Minor & "." & App.Revision
AppComments = "ignitionServer " & AppVersion & " (http://www.ignition-project.com/)"
StartUpDate = Now
Error_Connect
InitUnixTime
InitList
hTmrUnixTime = SetTimer(0&, 0&, 1000&, AddressOf uT)
hTmrDestroyWhoWas = SetTimer(0&, 0&, 300000, AddressOf DestroyWhoWas)
IrcStat.GlobServers = 1
Set Channels = New clsChanHashTable
Set Servers = New clsServerHashTable
Set GlobUsers = New clsUserHashTable
Set Opers = New clsUserHashTable
Set IPHash = New clsIPHashTable
Set ServerMsg = New clsUserHashTable
Set WallOps = New clsUserHashTable
modWhoWasHashTable.SetSize 128, 128, 64
ReDim Users(0): Channels.SetSize 512, 256, 128
StartUp = GetTickCount
StartUpUt = UnixTime
Channels.IgnoreCase = True
GlobUsers.IgnoreCase = True
Servers.IgnoreCase = True
Opers.IgnoreCase = True
ServerMsg.IgnoreCase = True
WallOps.IgnoreCase = True

Set Sockets = New clsSox
Rehash vbNullString
If ErrorLog = True Then
  Open App.Path & "\errorlog.txt" For Append As F
  Print #F, "(" & Now & ") ignitionServer " & AppVersion & " loaded and ready to go."
  Close #F
End If
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
Erase ILine: Erase YLine: Erase ZLine: Erase KLine: Erase QLine: Erase OLine: Erase LLine ': Erase CLine - Coming Soon
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
Dim F As Long
If ErrorLog = True Then
  Open App.Path & "\errorlog.txt" For Append As F
  Print #F, "(" & Now & ") ignitionServer " & AppVersion & " shut down."
  Close #F
End If
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
Public Sub KillNoPongs(ClassID As Long)
'this sub kills people who have not pong'ed yet (and are required to)
On Error GoTo KNPErr
Dim tmpU() As clsClient
Dim tmpN As Long
Dim x As Long
On Error Resume Next
If GlobUsers.Count = 0 Then Exit Sub
tmpU() = GlobUsers.Values
On Error GoTo KNPErr
For tmpN = LBound(tmpU) To UBound(tmpU)
  'only get mad about the pong if idle for 30+ seconds and not ponged
  'obviously, if you're not idle, and didn't respond to a pong, you
  'aren't dead... oh, and don't care about servers
  If (tmpU(tmpN).WaitingForPong = True) And (tmpU(tmpN).AccessLevel < 4) And (tmpU(tmpN).Class = ClassID) Then
    For x = 1 To tmpU(tmpN).OnChannels.Count
      If tmpU(tmpN).OnChannels.Item(x).IsAuditorium Then
          If ((tmpU(tmpN).OnChannels.Item(x).Member.Item(tmpU(tmpN).Nick).IsOp) Or (tmpU(tmpN).OnChannels.Item(x).Member.Item(tmpU(tmpN).Nick).IsOwner)) Then
            SendToChan tmpU(tmpN).OnChannels.Item(x), tmpU(tmpN).Prefix & " QUIT :Ping Timeout", vbNullString
          Else
            'the person wasn't a host/owner, so only the hosts/owners know about him/her
            SendToChanOps tmpU(tmpN).OnChannels.Item(x), tmpU(tmpN).Prefix & " QUIT :Ping Timeout", vbNullString
          End If
      Else
          SendToChan tmpU(tmpN).OnChannels.Item(x), tmpU(tmpN).Prefix & " QUIT :Ping Timeout", vbNullString
      End If
          
      'SendToChan tmpU(tmpN).OnChannels.Item(x), tmpU(tmpN).Prefix & " QUIT :Ping Timeout", vbNullString
    Next x
    If tmpU(tmpN).Hops = 0 Then
      SendToServer "QUIT :Ping Timeout", tmpU(tmpN).Nick
      GenerateEvent "USER", "TIMEOUT", Replace(tmpU(tmpN).Prefix, ":", ""), Replace(tmpU(tmpN).Prefix, ":", "")
      m_error tmpU(tmpN), "Closing Link: (Ping Timeout)"
    End If
    Sockets.TerminateSocket tmpU(tmpN).SockHandle
    KillStruct tmpU(tmpN).Nick
    'tmpU(tmpN).WaitingForPong = False 'incase socks get out of order or something -zg
    'tmpU(tmpN).IsKilled = True 'signfies sock is no longer usable -zg
  End If
Next tmpN
Exit Sub
KNPErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'KillNoPongs'"
End Sub
Public Sub SetNotWaiting(ClassID As Long)
On Error Resume Next
Dim allusers() As clsClient
allusers = GlobUsers.Values
Dim A As Long
For A = LBound(allusers) To UBound(allusers)
  If allusers(A).Class = ClassID Then allusers(A).WaitingForPong = False
Next A
End Sub
Public Sub DoPings()
On Error GoTo PingError
  'check if it's time to ping -zg
  'this may need to be adjusted later to compensate for links -zg
  Dim tmpY As Long
  Dim tmpY2 As Long
  Dim tmpU() As clsClient
  
  'If UBound(YLine) <= 1 Then Exit Sub 'possible error fix
  If GlobUsers.Count = 0 Then Exit Sub 'another error fix
  
  For tmpY = 2 To UBound(YLine)
    'math:
    'If UnixTime - PingFreq >= PingCounter
     'should work because:
    'PingCounter + PingFreq should equal UnixTime or be more
    If UnixTime - YLine(tmpY).PingFreq >= YLine(tmpY).PingCounter Then
      KillNoPongs YLine(tmpY).index
      SetNotWaiting YLine(tmpY).index
      #If Debugging = 1 Then
        SendSvrMsg "*** Pinging... (Class: " & YLine(tmpY).ID & " YClass: " & YLine(tmpY).index & ")"
      #End If
      On Error Resume Next
      tmpU() = GlobUsers.Values
      On Error GoTo PingError
      For tmpY2 = LBound(tmpU) To UBound(tmpU)
        #If Debugging = 1 Then
          SendSvrMsg "*** Will Ping: " & tmpU(tmpY2).Nick & " (YClass: " & tmpU(tmpY2).Class & ")"
        #End If
        If (tmpU(tmpY2).Class = YLine(tmpY).index) And (tmpU(tmpY2).AccessLevel < 4) Then 'don't care about servers
          'if their last action occured longer than PingFreq seconds ago, ping them
          If UnixTime - tmpU(tmpY2).LastAction >= YLine(tmpY).PingFreq Then
            #If Debugging = 1 Then
              SendSvrMsg "*** Pinging: " & tmpU(tmpY2).Nick & " (YClass: " & tmpU(tmpY2).Class & ")"
            #End If
            SendDirectRaw tmpU(tmpY2), "PING " & SPrefix & vbCrLf
            tmpU(tmpY2).WaitingForPong = True
          Else
            #If Debugging = 1 Then
              SendSvrMsg "*** Did not ping " & tmpU(tmpY2).Nick & ", active client (YClass: " & tmpU(tmpY2).Class & ")"
            #End If
            tmpU(tmpY2).WaitingForPong = False 'in case it got set
          End If
        End If
      Next tmpY2
      YLine(tmpY).PingCounter = UnixTime
    End If
  Next tmpY
Exit Sub
PingError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'DoPings'"
End Sub
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
    DoPings
    DoEvents
  Loop
    DoPings
    x = x + 1
    'Retrieve an item of the RecvQ -Dill
    With RecvQ.Item(1)
        Set cptr = .FromLink
        CurCmd = .Message
    End With
#If Debugging = 1 Then
    CreateObject("Scripting.FileSystemObject").OpenTextFile(App.Path & "\ircx.log", 8, True).WriteLine CurCmd
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
                SendSvrMsg "*** Notice -- SQUIT sent for unknown server prefix: " & Prefix, True
                GoTo nextmsg
            End If
        Else
            Set sptr = GlobUsers(Prefix)
            'this looks like it'll fix her up like a beaut -z
            'thanks nigel :P (how come i didn't think of this, lmao?)
            If sptr Is Nothing Then
                If cptr.ServerName = ServerName Then
                    SendSvrMsg "***Notice -- KILL sent for unknown prefix: " & Prefix, True
                    SendWsock cptr.index, "KILL " & Prefix, ":" & Prefix & " <-- ? Unknown client"
                End If
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
    cptr.LastAction = UnixTime
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
        Case "WHISPER": Cmds.Whisper = Cmds.Whisper + 1: Cmds.WhisperBW = Cmds.WhisperBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_whisper(cptr, sptr, arglist)
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
            If UCase$(arglist(0)) = "ISIRCX" Then
              Call m_isircx(cptr, sptr, arglist)
              GoTo nextmsg
            End If
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_mode(cptr, sptr, arglist)
        Case "CHANPASS": Cmds.ChanPass = Cmds.ChanPass + 1: Cmds.ChanPassBW = Cmds.ChanPassBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_chanpass(cptr, sptr, arglist)
        Case "KNOCK": 'no, we do NOT want to count this, because it's server-server only atm
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_knock(cptr, sptr, arglist)
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
            'if they're on the server already, PASS becomes useless
            If cptr.HasRegistered Then
              SendWsock cptr.index, ERR_ALREADYREGISTRED & " " & cptr.Nick, TranslateCode(ERR_ALREADYREGISTRED)
              GoTo nextmsg
            End If
            
            If m_pass(cptr, sptr, arglist) = -1 Then
                m_error cptr, "Closing Link: (Bad Password)"
                KillStruct cptr.Nick, , False
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
        Case "CREATE": Cmds.Create = Cmds.Create + 1: Cmds.CreateBW = Cmds.CreateBW + cmdLen
          With cptr
            If .HasRegistered = False Then
              SendWsock .index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_create(cptr, sptr, arglist)
          End With
        Case "PONG": Cmds.Pong = Cmds.Pong + 1: Cmds.PongBW = Cmds.PongBW + cmdLen
          With cptr
            If .WaitingForPong = True Then .WaitingForPong = False 'they responded to our ping, do not kill
            If .Timeout = 2 Then
                If Len(.User) > 0 Then
                  If Len(.Nick) > 0 Then
                    .RealHost = .Host
                    If MaskDNS = True Then
                        If MaskDNSMD5 = True Then
                            .Host = UCase$(modMD5.oMD5.MD5(.RealHost))
                        ElseIf MaskDNSHOST = True Then
                            If Not HostMask = vbNullString Then
                                .Host = .Nick & "." & HostMask
                            Else
                                'HostMask is unset so we'll swap to MD5 cos the Admin does want some form of masking...
                                MaskDNSHOST = False
                                MaskDNSMD5 = True
                                .Host = UCase$(modMD5.oMD5.MD5(.RealHost))
                            End If
                        End If
                    End If
                    'generate User Logon event
                    GenerateEvent "USER", "LOGON", .Nick & "!" & .User & "@" & .RealHost, .Nick & "!" & .User & "@" & .RealHost & " " & .IP & ":" & .RemotePort & " " & ServerLocalAddr & ":" & .LocalPort & " +"
                    SendWsock .index, SPrefix & " 001 " & .Nick & " :Welcome to the " & IRCNet & " IRC Network, " & .Nick & "!" & .User & "@" & .RealHost, vbNullString, , True
                    SendWsock .index, SPrefix & " 002 " & .Nick & " :Your host is " & ServerName & ", running version ignitionServer-" & AppVersion, vbNullString, , True
                    If Len(ServerLocation) <> 0 Then
                      SendWsock .index, SPrefix & " 003 " & .Nick & " :This server was (re)started " & StartUpDate & " and is in " & ServerLocation, vbNullString, , True
                    Else
                      SendWsock .index, SPrefix & " 003 " & .Nick & " :This server was (re)started " & StartUpDate, vbNullString, , True
                    End If
                    SendWsock .index, SPrefix & " 004 " & .Nick & " " & ServerName & " ignitionServer-" & AppVersion & " " & UserModes & " " & ChanModes, vbNullString, , True
                    If MaxChannelsPerUser > 0 Then
                      SendWsock .index, SPrefix & " 005 " & .Nick & " IRCX CHANTYPES=# CHANLIMIT=#:" & MaxChannelsPerUser & " NICKLEN=" & NickLen & " PREFIX=(qov).@+ CHANMODES=" & ChanModesX & " NETWORK=" & Replace(IRCNet, " ", "_") & " CASEMAPPING=ascii CHARSET=ascii MAXTARGETS=5 MAXCLONES=" & MaxConnectionsPerIP & " :are supported by this server", vbNullString, , True
                    Else
                      SendWsock .index, SPrefix & " 005 " & .Nick & " IRCX CHANTYPES=# NICKLEN=" & NickLen & " PREFIX=(qov).@+ CHANMODES=" & ChanModesX & " NETWORK=" & Replace(IRCNet, " ", "_") & " CASEMAPPING=ascii CHARSET=ascii MAXTARGETS=5 MAXCLONES=" & MaxConnectionsPerIP & " :are supported by this server", vbNullString, , True
                    End If
                    IrcStat.GlobUsers = IrcStat.GlobUsers + 1: IrcStat.LocUsers = IrcStat.LocUsers + 1
                    If IrcStat.MaxGlobUsers < IrcStat.GlobUsers Then IrcStat.MaxGlobUsers = IrcStat.MaxGlobUsers + 1
                    If IrcStat.MaxLocUsers < IrcStat.LocUsers Then IrcStat.MaxLocUsers = IrcStat.MaxLocUsers + 1
                    SendWsock .index, GetLusers(.Nick), vbNullString, , True
                    SendWsock .index, ReadMotd(.Nick), vbNullString, , True
                    .HasRegistered = True
                    If .IsIRCX Then SendWsock .index, SPrefix & " MODE " & .Nick & " +x", vbNullString, , True
                    'after careful consideration,
                    'i've decided that RealHost should be sent to links
                    'if the link supports MD5 encrpytion, then use it
                    'otherwise one server will have the real hostname and the other will have MD5 encrypted ones
                    '(this is so the server actually knows what the bloody hell your real ident is)
                    SendToServer "NICK " & .Nick & " 1 " & .SignOn & _
                    " " & .User & " " & .RealHost & " " & ServerName & " :" & .Name
                    .Prefix = ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host
                    .UpLink = ServerName
                  End If
                End If
            End If
            .Timeout = 0
          End With
        Case "ISIRCX": Cmds.Ircx = Cmds.Ircx + 1: Cmds.IrcxBW = Cmds.IrcxBW + cmdLen
          Call m_isircx(cptr, sptr, arglist)
        Case "IRCX": Cmds.Ircx = Cmds.Ircx + 1: Cmds.IrcxBW = Cmds.IrcxBW + cmdLen
          Call m_ircx(cptr, sptr, arglist)
        Case "DATA": Cmds.Data = Cmds.Data + 1: Cmds.DataBW = Cmds.DataBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_ircx_data(cptr, sptr, arglist, 0)
        Case "REQUEST": Cmds.Request = Cmds.Request + 1: Cmds.RequestBW = Cmds.RequestBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_ircx_data(cptr, sptr, arglist, 1)
        Case "REPLY": Cmds.Reply = Cmds.Reply + 1: Cmds.ReplyBW = Cmds.ReplyBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_ircx_data(cptr, sptr, arglist, 2)
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
        Case "INFO": Cmds.Info = Cmds.Info + 1: Cmds.InfoBW = Cmds.InfoBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_info(cptr, sptr, arglist)
        Case "TIME": Cmds.Time = Cmds.Time + 1: Cmds.TimeBW = Cmds.TimeBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_time(cptr, sptr, arglist)
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
        Case "PASSCRYPT"
          Call m_passcrypt(cptr, sptr, arglist)
'*****************************
'|      Operator Queries    ||
'*****************************
'I'm going to add a CHGHost soon but am not Ready To Put it in Fully *Yet* Planning on it in near Future
'Task #90351 - DG
'-completed by ziggy-
        Case "CHGHOST": Cmds.Chghost = Cmds.Chghost + 1: Cmds.ChghostBW = Cmds.ChghostBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_chghost(cptr, sptr, arglist)
        Case "FHOST": Cmds.Chghost = Cmds.Chghost + 1: Cmds.ChghostBW = Cmds.ChghostBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_chghost(cptr, sptr, arglist)
        Case "FNICK": Cmds.ChgNick = Cmds.ChgNick + 1: Cmds.ChgNickBW = Cmds.ChgNickBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_chgnick(cptr, sptr, arglist)
        Case "GLINE": Cmds.ChgNick = Cmds.ChgNick + 1: Cmds.ChgNickBW = Cmds.ChgNickBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_chgnick(cptr, sptr, arglist)
        Case "CHGNICK": Cmds.ChgNick = Cmds.ChgNick + 1: Cmds.ChgNickBW = Cmds.ChgNickBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_chgnick(cptr, sptr, arglist)
        Case "EVENT":
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_event(cptr, sptr, arglist)
        Case "OPER": Cmds.Oper = Cmds.Oper + 1: Cmds.OperBW = Cmds.OperBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_oper(cptr, sptr, arglist)
        Case "REMOTEADM"
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
            Call m_remoteadm(cptr, sptr, arglist)
        'Case "WALL"
        'Case "LOCOPS"
        'Case "GLOBOPS"
        Case "HASH": Cmds.Hash = Cmds.Hash + 1: Cmds.HashBW = Cmds.HashBW + cmdLen
          If Not cptr.HasRegistered Then
            SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
            GoTo nextmsg
          End If
          Call m_hash(cptr, sptr, arglist)
        Case "ADD": Cmds.Add = Cmds.Add + 1: Cmds.AddBW = Cmds.AddBW + cmdLen
          Call m_add(cptr, sptr, arglist)
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
        Case "LINK": Cmds.Connect = Cmds.Connect + 1: Cmds.ConnectBW = Cmds.ConnectBW + cmdLen
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
        Case "MDIE"
          Call m_mdie(cptr, sptr, arglist)
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
        Case "WALLOPS"
            Call m_wallops(cptr, sptr, arglist)
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
            Call m_nickserv(cptr, sptr, "NickServ", arglist)
        Case "NICKSERV": Cmds.NickServ = Cmds.NickServ + 1: Cmds.NickServBW = Cmds.NickServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_nickserv(cptr, sptr, "NickServ", arglist)
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
            Call m_chanserv(cptr, sptr, "ChanServ", arglist)
        Case "CHANSERV": Cmds.ChanServ = Cmds.ChanServ + 1: Cmds.ChanServBW = Cmds.ChanServBW + cmdLen
            If Not cptr.HasRegistered Then
              SendWsock cptr.index, ERR_NOTREGISTERED, TranslateCode(ERR_NOTREGISTERED)
              GoTo nextmsg
            End If
            Call m_chanserv(cptr, sptr, "ChanServ", arglist)
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
'*** NONSTANDARD COMMANDS
        #If EnableNonstandard = 1 Then
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
        #End If
'*** END OF NONSTANDARD COMMANDS
        Case Else
            Dim tmpSN As String
            If Len(cptr.Nick) = 0 Then
              tmpSN = "Anonymous"
            Else
              tmpSN = cptr.Nick
            End If
            SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & tmpSN, TranslateCode(ERR_UNKNOWNCOMMAND, , , cmd)
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
Dim MyValue As Long, I As Long, r As Long
For I = 1 To 4
    MyValue = Int((9 * Rnd) + 0)
    r = CLng(CStr(r) & CStr(MyValue))
Next I
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
Public Sub KillStruct(Name$, Optional InType As enmType = enmTypeClient, Optional Registered As Boolean = True, Optional IPAddress As String)
#If Debugging = 1 Then
    SendSvrMsg "KILLSTRUCT called! (" & Name & ")"
#End If
On Error Resume Next
Dim cptr As clsClient, Chan As clsChannel, I&, User() As clsClient
If InType = enmTypeClient Then
    
'we send registered = false before cptr would be valid
    If Registered = False Then
      If MaxConnectionsPerIP > 0 Then
        IPHash(IPAddress) = IPHash(IPAddress) - 1
        If IPHash(IPAddress) <= 0 Then
          IPHash.Remove IPAddress
        End If
      End If
      Exit Sub
    End If
    
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
        'hopefully this'll fix the "max connections" problem
        If MaxConnectionsPerIP > 0 Then
          IPHash(cptr.IP) = IPHash(cptr.IP) - 1
          If IPHash(cptr.IP) = 0 Then
              IPHash.Remove cptr.IP
          End If
        End If
        GlobUsers.Remove cptr.Nick
        Set cptr = Nothing
    End If
ElseIf InType = enmTypeChannel Then
ElseIf InType = enmTypeServer Then
    If Name = ServerName Then Exit Sub
    Set cptr = Servers(Name)
    User = GlobUsers.Values
    For I = LBound(User) To UBound(User)
        With User(I)
            If Not .FromLink Is Nothing Then
                If .FromLink.ServerName = Name Then
                    Set .FromLink = Nothing
                End If
            End If
        End With
    Next I
    User = Servers.Values
    For I = LBound(User) To UBound(User)
        With User(I)
            If Not .FromLink Is Nothing Then
                If .FromLink.ServerName = Name Then
                    Set .FromLink = Nothing
                    Servers.Remove .ServerName
                    Set User(I) = Nothing
                End If
            End If
        End With
    Next I
    Set cptr.FromLink = Nothing
    Servers.Remove Name
End If
End Sub

Public Function DestroyWhoWas(ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
modWhoWasHashTable.RemoveAll
End Function

Public Sub DoSend() '(ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
On Error Resume Next
Dim OutMsg() As Byte, cptr As clsClient, I&, x&
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
                For I = 1 To .OnChannels.Count
                    SendToChan .OnChannels.Item(I), .Prefix & " QUIT :Max SendQ length exceeded", vbNullString
                Next I
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
                For I = LBound(usr) To UBound(usr)
                    Set usr(I).FromLink = Nothing
                    KillStruct usr(I).Nick, enmTypeClient
                    usr(I).SendQ = vbNullString
                    For y = 1 To .OnChannels.Count
                        SendToChan .OnChannels.Item(y), .Prefix & " QUIT :Max SendQ length exceeded", vbNullString
                    Next y
                    Set usr(I) = Nothing
                    GoTo nextmsg
                Next I
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
    CreateObject("Scripting.FileSystemObject").OpenTextFile(App.Path & "\ircx.log", 8, True).WriteLine .SendQ
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
