Attribute VB_Name = "modConf"
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
' $Id: modConf.bas,v 1.35 2004/12/31 06:30:29 ziggythehamster Exp $
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
Option Base 1

Public AutoJoinChannels() As String
Public BLine() As BLines
Public ILine() As ILines
Public YLine() As YLines
Public ZLine() As ZLines
Public KLine() As KLines
Public QLine() As QLines
Public PLine() As PLines
Public OLine() As OLines
Public CLine() As CLines
Public NLine() As NLines
Public VLine() As VLines
#Const Debugging = 0

Public Function Macros(x As String, Optional MLine As Boolean = False) As String
Dim m As String
m = Replace(x, "<$COLON$>", ":")
If MLine = False Then m = Replace(m, "<$NET$>", IRCNet) 'this would be "invalid" in the M: line
Macros = m
End Function
Public Sub Rehash(Flag As String, Optional OnStartup As Boolean = False)
Dim Line() As String, Char As String, Temp As String, FF As Long: FF = FreeFile
Dim tmpY() As YLines
Dim A As Long
Select Case UCase$(Flag)
    Case vbNullString
        'Restore to Default
        'there's a bunch of stuff here, in case someone removes a line or two
        'I realize that this also permits a blank ircx.conf, but who will be
        'that stupid?
        If Not OnStartup Then
          For A = 1 To UBound(YLine)
            ReDim tmpY(UBound(YLine))
            tmpY(A).ConnectFreq = YLine(A).ConnectFreq
            tmpY(A).CurClients = YLine(A).CurClients
            tmpY(A).ID = YLine(A).ID
            tmpY(A).index = YLine(A).index
            tmpY(A).MaxClients = YLine(A).MaxClients
            tmpY(A).MaxSendQ = YLine(A).MaxSendQ
            tmpY(A).PingCounter = YLine(A).PingCounter
            tmpY(A).PingFreq = YLine(A).PingFreq
          Next A
        End If
        ReDim ILine(1)
        ReDim YLine(1)
        ReDim ZLine(1)
        ReDim KLine(1)
        ReDim QLine(1)
        ReDim OLine(1)
        ReDim CLine(1)
        ReDim NLine(1)
        ReDim VLine(1)
        ReDim PLine(1)
        ReDim BLine(1)
        If OnStartup = True Then ReDim AutoJoinChannels(1)
        
        'clear server M: line crap, and stuff that basically describes the server
        ServerName = ""
        IRCNet = ""
        ServerDescription = ""
        Admin = ""
        AdminLocation = ""
        AdminEmail = ""
        DiePass = ""
        RestartPass = ""
        ServerLocation = ""
        'registered channel mode
        RegChanMode_Always = True
        RegChanMode_Never = False
        RegChanMode_ModeR = False
        HostMask = ""
        'dns masking
        MaskDNS = False
        MaskDNSMD5 = False
        MaskDNSHOST = False
        'die/offline
        Die = True
        OfflineMode = False
        OfflineMessage = ""
        'encryption
        Crypt = False
        MD5Crypt = False
        'highprot
        HighProtAsq = False
        HighProtAso = False
        HighProtAsv = False
        HighProtAsn = True
        'lowprot
        LowProtAsq = False
        LowProtAso = False
        LowProtAsv = False
        LowProtAsn = True
        'allow multiple
        AllowMultiple = False
        'ircx stuff
        ShowGag = False
        BounceGagMsg = True
        IRCXM_Trans = True
        IRCXM_Both = False
        IRCXM_Strict = False
        'create mode
        CreateMode = 0
        MonitorIP = "127.0.0.1"
        'error log
        ErrorLog = True
        
        'and the grand finale...
        'process ircx.conf
        If Dir(App.Path & "\ircx.conf") <> vbNullString Then
          Open App.Path & "\ircx.conf" For Input As FF
          Do While Not EOF(FF)
            Line Input #FF, Temp
            Char = Left$(Temp, 1)
            Temp = Mid$(Temp, 3)
            Select Case Char
              Case "#"    'a comment, must be ignored -Dill
              Case "M"    'Servername, server description, main server port, main server ip -Dill
                Line = Split(Replace(Temp, "*", vbNullString), ":")
                ServerName = Macros(Line(0), True)
                IRCNet = Macros(Line(1), True)
                Dim tmpListen As String
                tmpListen = Line(3)
                If tmpListen = "*" Then tmpListen = ""
                Sockets.Listen tmpListen, CInt(Line(4))
                ServerDescription = Macros(Line(2), True)
                Ports = Ports + 1
                If Len(tmpListen) > 0 Then
                  ServerLocalAddr = tmpListen
                Else
                  ServerLocalAddr = "127.0.0.1"
                End If
                ServerLocalPort = Line(4)
              Case "A"    'Admin info -Dill
                Line = Split(Temp, ":")
                AdminLocation = Macros(Line(0))
                Admin = Macros(Line(1))
                AdminEmail = Macros(Line(2))
              Case "B"
                Line = Split(Temp, ":")
                ReDim Preserve BLine(UBound(BLine) + 1)
                With BLine(UBound(BLine))
                  .HostMask = Line(0)
                  .Message = Macros(Line(1))
                  .ServerName = Line(2)
                  .Port = CLng(Line(3))
                End With
              Case "Y"    'Connection classes -Dill
                Line = Split(Temp, ":")
                ReDim Preserve YLine(UBound(YLine) + 1)
                With YLine(UBound(YLine))
                    .ID = CLng(Line(0))
                    .index = UBound(YLine)
                    .PingFreq = CLng(Line(1))
                    .ConnectFreq = CLng(Line(2))
                    .MaxClients = CLng(Line(3))
                    .MaxSendQ = CLng(Line(4))
                    .PingCounter = UnixTime 'set initial timebomb -zg
                End With
                
                If Not OnStartup Then
                  For A = 1 To UBound(tmpY)
                    If tmpY(A).ID = Line(0) Then
                      'if the old Y: line's ID matches this one
                      'we know the current upper bound Y: line
                      'needs to have its CurClients set
                      YLine(UBound(YLine)).CurClients = tmpY(A).CurClients
                    End If
                  Next A
                End If
              Case "I"    'Client Authorization classes -Dill
                Line = Split(Temp, ":")
                ReDim Preserve ILine(UBound(ILine) + 1)
                With ILine(UBound(ILine))
                    .IP = Line(0)
                    .Pass = Line(1)
                    .Host = Line(2)
                    .ConnectionClass = CLng(Line(4))
                End With
              Case "O"    'Operator lines -Dill
                '# O:hostname (ident "@" permitted):password:NickName:AccessFlags:class -Dill
                Line = Split(Temp, ":")
                ReDim Preserve OLine(UBound(OLine) + 1)
                With OLine(UBound(OLine))
                    .Host = Line(0)
                    .Pass = Line(1)
                    .Name = Line(2)
                    .AccessFlag = Line(3)
                    .ConnectionClass = CLng(Line(4))
                End With
              Case "C"    'Networked -Dill
                ' "Host Mask" is unsupport right now,
                'i have no idea what the hell it is used for. -Dill
                Line = Split(Temp, ":")
                ReDim Preserve CLine(UBound(CLine) + 1)
                With CLine(UBound(CLine))
                    .Host = Line(0)
                    .Pass = Line(1)
                    .Server = Line(2)
                    If Not Len(Line(3)) = 0 Then .Port = CInt(Line(3))
                    .ConnectionClass = Line(4)
                End With
              Case "N"    'Networked -Dill
                Line = Split(Temp, ":")
                ReDim Preserve NLine(UBound(NLine) + 1)
                With NLine(UBound(NLine))
                    If Not IsIP(Line(0)) Then
                      'if it's not an IP, resolve it!
                      .Host = NameToAddress(Line(0))
                      #If Debugging = 1 Then
                        SendSvrMsg "*** N: line does not contain an IP, resolved " & Line(0) & " to " & .Host
                      #End If
                    Else
                      .Host = Line(0)
                    End If
                    .Pass = Line(1)
                    .Server = Line(2)
                    .ConnectionClass = Line(4)
                End With
              Case "K"    'Local bans -Dill
                Line = Split(Temp, ":")
                ReDim Preserve KLine(UBound(KLine) + 1)
                With KLine(UBound(KLine))
                    .Host = Line(0)
                    .Reason = Macros(Line(1))
                    .User = Line(2)
                End With
              Case "Q"    'Nickname quarantines -Dill
                Line = Split(Temp, ":")
                ReDim Preserve QLine(UBound(QLine) + 1)
                With QLine(UBound(QLine))
                    .Reason = Macros(Line(1))
                    .Nick = Line(2)
                End With
              Case "Z"    'Connection filters -Dill
                Line = Split(Temp, ":")
                ReDim Preserve ZLine(UBound(ZLine) + 1)
                With ZLine(UBound(ZLine))
                    .IP = Line(0)
                    .Reason = Macros(Line(1))
                End With
              Case "P"    'Additional listening ports -Dill
                Line = Split(Replace(Temp, "*", vbNullString), ":")
                ReDim Preserve PLine(UBound(PLine) + 1)
                With PLine(UBound(PLine))
                    .IP = Line(1)
                    .PortOption = Line(3)
                    .Port = (4)
                End With
                Sockets.Listen Line(1), CInt(Line(4))
                Ports = Ports + 1
              Case "V"
                Line = Split(Temp, ":")
                ReDim Preserve VLine(UBound(VLine) + 1)
                With VLine(UBound(VLine))
                    .Vhost = Line(0)
                    .Name = Line(1)
                    .Pass = Line(2)
                    .Host = Line(3)
                End With
'S:MaxConn:MaxClones:MaxChans:NickLen:TopicLen:KickLen:PartLen:KeyLen:QuitLen:MaxWhoLen:MaxListLen
'Security Line - Added 22nd Feb 2003 by dilligent
              Case "S"
                Line = Split(Temp, ":")
                MaxConnections = Line(0)
                MaxConnectionsPerIP = Line(1)
                MaxChannelsPerUser = Line(2)
                NickLen = Line(3)
                TopicLen = Line(4)
                KickLen = Line(5)
                PartLen = Line(6)
                KeyLen = Line(7)
                QuitLen = Line(8)
                MaxWhoLen = Line(9)
                MaxListLen = Line(10)
                MaxMsgsInQueue = Line(11)
              Case "X"
                'X:section:parameters
                Dim Section As String
                Line = Split(Temp, ":")
                Section = Line(0)
                If UCase$(Section) = "DIEPASS" Then
                  DiePass = Line(1)
                ElseIf UCase$(Section) = "RESTARTPASS" Then
                  RestartPass = Line(1)
                ElseIf UCase$(Section) = "DIE" Then
                  If Line(1) = "0" Then
                    Die = False
                  ElseIf Line(1) = "1" Then
                    'LAZY ADMIN ALERT
                    'Lets set Auto Kill to 1
                    'Shows that it pays to read README's Huh? - DG
                    Die = True
                  Else
                    Die = False
                  End If
                ElseIf UCase$(Section) = "OFFLINEMODE" Then
                    If Line(1) = "0" Or UCase$(Line(1)) = "OFF" Then
                        OfflineMode = False
                    ElseIf Line(1) = "1" Or UCase$(Line(1)) = "OFF" Then
                        OfflineMode = True
                    Else
                        OfflineMode = False
                    End If
                ElseIf UCase$(Section) = "OFFLINEMESSAGE" Then
                    OfflineMessage = Macros(Line(1))
                ElseIf UCase$(Section) = "CNOTICE" Then
                    CustomNotice = Macros(Line(1))
                ElseIf UCase$(Section) = "MASKDNS" Then
                    If Line(1) = "0" Then
                      MaskDNS = False
                      MaskDNSMD5 = False
                      MaskDNSHOST = False
                    ElseIf Line(1) = "1" Then
                      MaskDNS = True
                      MaskDNSMD5 = True
                      MaskDNSHOST = False
                    ElseIf Line(1) = "2" Then
                      MaskDNS = True
                      MaskDNSMD5 = False
                      MaskDNSHOST = True
                    Else
                      MaskDNS = False
                      MaskDNSMD5 = False
                      MaskDNSHOST = False
                    End If
                ElseIf UCase$(Section) = "HOSTMASK" Then
                    HostMask = Line(1)
                ElseIf UCase$(Section) = "SERVERLOCATION" Then
                    ServerLocation = Macros(Line(1))
                ElseIf UCase$(Section) = "CRYPT" Then
                    If Line(1) = "0" Or UCase$(Line(1)) = "OFF" Then
                        Crypt = False
                        MD5Crypt = False
                    ElseIf UCase$(Line(1)) = "MD5" Then
                        Crypt = True
                        MD5Crypt = True
                    End If
                ElseIf UCase$(Section) = "HIGHPROT" Then
                    If Line(1) = "0" Or UCase$(Line(1)) = "NORM" Then
                        HighProtAsq = False
                        HighProtAso = False
                        HighProtAsv = False
                        HighProtAsn = True
                    ElseIf UCase$(Line(1)) = "V" Then
                        HighProtAsq = False
                        HighProtAso = False
                        HighProtAsv = True
                        HighProtAsn = False
                    ElseIf UCase$(Line(1)) = "O" Then
                        HighProtAsq = False
                        HighProtAso = True
                        HighProtAsv = False
                        HighProtAsn = False
                    ElseIf UCase$(Line(1)) = "Q" Then
                        HighProtAsq = True
                        HighProtAso = False
                        HighProtAsv = False
                        HighProtAsn = False
                    End If
                ElseIf UCase$(Section) = "LOWPROT" Then
                    If Line(1) = "0" Or UCase$(Line(1)) = "NORM" Then
                        LowProtAsq = False
                        LowProtAso = False
                        LowProtAsv = False
                        LowProtAsn = True
                    ElseIf UCase$(Line(1)) = "V" Then
                        LowProtAsq = False
                        LowProtAso = False
                        LowProtAsv = True
                        LowProtAsn = False
                    ElseIf UCase$(Line(1)) = "O" Then
                        LowProtAsq = False
                        LowProtAso = True
                        LowProtAsv = False
                        LowProtAsn = False
                    ElseIf UCase$(Line(1)) = "Q" Then
                        LowProtAsq = True
                        LowProtAso = False
                        LowProtAsv = False
                        LowProtAsn = False
                    End If
                ElseIf UCase$(Section) = "ALLOWMULTIPLE" Then
                  If Line(1) = "0" Or UCase$(Line(1)) = "OFF" Then
                    AllowMultiple = False
                  ElseIf Line(1) = "1" Or UCase$(Line(1)) = "ON" Then
                    AllowMultiple = True
                  Else
                    AllowMultiple = False
                  End If
                ElseIf UCase$(Section) = "GAGMODE" Then
                  If Line(1) = "0" Then
                    ShowGag = False
                    BounceGagMsg = True
                  ElseIf Line(1) = "1" Then
                    ShowGag = True
                    BounceGagMsg = True
                  ElseIf Line(1) = "2" Then
                    ShowGag = False
                    BounceGagMsg = False
                  Else
                    'if not valid, pick default
                    ShowGag = False
                    BounceGagMsg = True
                  End If
                ElseIf UCase$(Section) = "IRCXMETHOD" Then
                  If Line(1) = "0" Then
                    IRCXM_Trans = True
                    IRCXM_Strict = False
                    IRCXM_Both = False
                  ElseIf Line(1) = "1" Then
                    IRCXM_Strict = True
                    IRCXM_Trans = False
                    IRCXM_Both = False
                  ElseIf Line(1) = "2" Then
                    IRCXM_Both = True
                    IRCXM_Trans = False
                    IRCXM_Strict = False
                  Else
                    IRCXM_Trans = True
                    IRCXM_Both = False
                    IRCXM_Strict = False
                  End If
                ElseIf UCase$(Section) = "REGCHANMODE" Then
                  If Line(1) = "0" Then
                    'always open
                    RegChanMode_Always = True
                    RegChanMode_Never = False
                    RegChanMode_ModeR = False
                  ElseIf Line(1) = "1" Then
                    'never open
                    RegChanMode_Always = False
                    RegChanMode_Never = True
                    RegChanMode_ModeR = False
                  ElseIf Line(1) = "2" Then
                    'only if +R
                    RegChanMode_Always = False
                    RegChanMode_Never = False
                    RegChanMode_ModeR = True
                  Else
                    'unknown
                    RegChanMode_Always = True
                    RegChanMode_Never = False
                    RegChanMode_ModeR = False
                  End If
                ElseIf UCase$(Section) = "REMOTEPASS" Then
                  RemotePass = Line(1)
                ElseIf UCase$(Section) = "ERRORLOG" Then
                  If Line(1) = "0" Then
                    ErrorLog = False
                  ElseIf Line(1) = "1" Then
                    ErrorLog = True
                  ElseIf UCase$(Line(1)) = "OFF" Then
                    ErrorLog = False
                  ElseIf UCase$(Line(1)) = "ON" Then
                    ErrorLog = True
                  Else
                    ErrorLog = True
                  End If
                ElseIf UCase$(Section) = "AUTOVHOST" Then
                  If Line(1) = "0" Then
                    AVHost = False
                  ElseIf Line(1) = "1" Then
                    AVHost = True
                  ElseIf UCase$(Line(1)) = "OFF" Then
                    AVHost = False
                  ElseIf UCase$(Line(1)) = "ON" Then
                    AVHost = True
                  Else
                    AVHost = False
                  End If
                ElseIf UCase$(Section) = "CREATEMODE" Then
                  If Line(1) = "0" Then
                    CreateMode = 0
                  ElseIf Line(1) = "1" Then
                    CreateMode = 1
                  ElseIf Line(1) = "2" Then
                    CreateMode = 2
                  Else
                    CreateMode = 1
                  End If
                ElseIf UCase$(Section) = "MONITORIP" Then
                  MonitorIP = Line(1)
                ElseIf UCase$(Section) = "STATICCHAN" Then
                  If OnStartup = True Then
                    Dim Chan As clsChannel
                    Set Chan = Channels.Add(CStr(Line(1)), New clsChannel)
                    Chan.Name = CStr(Line(1))
                    Chan.Prop_Name = CStr(Line(1))
                    Chan.IsTopicOps = True
                    Chan.IsNoExternalMsgs = True
                    Chan.IsStatic = True
                    #If Debugging = 1 Then
                      SendSvrMsg "parsed static channel n=" & Line(1) & " rn=" & Chan.Name
                    #End If
                    If MakeNumber(CStr(Line(2))) = 1 Then
                      #If Debugging = 1 Then
                        SendSvrMsg "added autojoin channel id=" & UBound(AutoJoinChannels) + 1
                      #End If
                      ReDim Preserve AutoJoinChannels(UBound(AutoJoinChannels) + 1)
                      AutoJoinChannels(UBound(AutoJoinChannels)) = CStr(Line(1))
                    End If
                  End If
                ElseIf UCase$(Section) = "LOGGING" Then
                  If Line(1) = "0" Then
                    LogChannels = False
                    LogChannelWhispers = False
                    LogUsers = False
                  ElseIf Line(1) = "1" Then
                    LogChannels = True
                    LogChannelWhispers = False
                    LogUsers = False
                  ElseIf Line(1) = "2" Then
                    LogChannels = True
                    LogChannelWhispers = True
                    LogUsers = False
                  ElseIf Line(1) = "3" Then
                    LogChannels = True
                    LogChannelWhispers = True
                    LogUsers = True
                  Else
                    LogChannels = False
                    LogChannelWhispers = False
                    LogUsers = False
                  End If
                ElseIf UCase$(Section) = "SVSNICK" Then
                    If UCase$(Line(1)) = "NICKSERV" Then
                        SVSN_NickServ = Line(2)
                    ElseIf UCase$(Line(1)) = "CHANSERV" Then
                        SVSN_ChanServ = Line(2)
                    End If
                End If
              'Everything else is ignored -Dill
            End Select
          Loop
        Else
          ErrorMsg "ircx.conf is missing. The server will now shut down."
          Terminate
        End If
        Close FF
    Case "-MOTD"
        GetMotD
    Case "-GC"
        Dim tmp As Long, x&
        For tmp = LBound(Users) To UBound(Users)
            If Not Users(tmp) Is Nothing Then
                If Len(Users(tmp).Prefix) = 1 Then
                    Set Users(tmp) = Nothing
                    x = x + 1
                    #If Debugging = 1 Then
                      SendSvrMsg "Garbage Collect: " & x
                    #End If
                    'Debug.Print x
                End If
            End If
        Next tmp
        Do While Users(UBound(Users)) Is Nothing
            ReDim Preserve Users(UBound(Users) - 1)
        Loop
End Select
End Sub

Public Function DoKLine(cptr As clsClient) As Boolean
Dim i As Long
For i = 1 To UBound(KLine)
    If (cptr.IP Like KLine(i).Host) Or (cptr.Host Like KLine(i).Host) Then
        If (cptr.User Like KLine(i).User) Then
            m_error cptr, "Closing Link: (AutoKilled: " & KLine(i).Reason & ")"
            KillStruct cptr.Nick
            DoKLine = True
            Exit Function
        End If
    End If
Next i
End Function
Public Function AddKLine(KHost As String, KReason As String, KUser As String) As Boolean
'this has to be here because of the Option Base 1
On Error GoTo AKLError
ReDim Preserve KLine(UBound(KLine) + 1)
With KLine(UBound(KLine))
  .Host = KHost
  .Reason = KReason
  .User = KUser
End With
AddKLine = True
Exit Function
AKLError:
AddKLine = False
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'AddKLine'"
End Function

Public Function DoILine(cptr As clsClient) As Boolean
Dim i As Long
For i = 2 To UBound(ILine)
    If StrComp(ILine(i).IP, "NOMATCH") = 0 Then
        If (cptr.Host Like ILine(i).Host) Then
            cptr.Class = GetYLine(ILine(i).ConnectionClass).index
            cptr.IIndex = i
            If YLine(cptr.Class).MaxClients = YLine(cptr.Class).CurClients Then
                cptr.Class = 0
                m_error cptr, "Closing Link: No more connections from your class allowed"
                DoILine = True
                Exit Function
            Else
                YLine(cptr.Class).CurClients = YLine(cptr.Class).CurClients + 1
            End If
            If Len(ILine(i).Pass) <> 0 Then
                cptr.PassOK = False
            'Else
            '    cptr.PassOK = True
            End If
            Exit Function
        End If
    Else
        If (cptr.IP Like ILine(i).IP) Then
            cptr.Class = GetYLine(ILine(i).ConnectionClass).index
            cptr.IIndex = i
            If YLine(cptr.Class).MaxClients = YLine(cptr.Class).CurClients Then
                cptr.Class = 0
                m_error cptr, "Closing Link: No more connections from your class allowed"
                DoILine = True
                Exit Function
            Else
                YLine(cptr.Class).CurClients = YLine(cptr.Class).CurClients + 1
            End If
            If Len(ILine(i).Pass) <> 0 Then
                cptr.PassOK = False
            'Else
            '    cptr.PassOK = True
            End If
            Exit Function
        End If
    End If
Next i
End Function

Public Function DoZLine(index As Long, IP As String) As Boolean
Dim i As Long, buf() As Byte
For i = 2 To UBound(ZLine)
    If IP Like ZLine(i).IP Then
        buf = StrConv("ERROR :Closing Link: Z: Lined" & ZLine(i).Reason & vbCrLf, vbFromUnicode)
        Call Send(Sockets.SocketHandle(index), buf(0), UBound(buf) + 1, 0&)
        DoZLine = True
        Exit Function
    End If
Next i
End Function

Public Function GetYLine(Class As Long) As YLines
Dim i As Long
For i = 2 To UBound(YLine)
    If YLine(i).ID = Class Then
        GetYLine = YLine(i)
        Exit Function
    End If
Next i
End Function

Public Function GetBLine(HostMask As String) As BLines
Dim i As Long
For i = 2 To UBound(BLine)
  If UCase$(HostMask) Like UCase$(BLine(i).HostMask) Then
    GetBLine = BLine(i)
    Exit Function
  End If
Next i
GetBLine.HostMask = ""
End Function
Public Function DoBLine(HostMask As String) As String
'this function returns a comma delimited list of
'all the servers/ports that HostMask matches
'a message will also be appended to the end
Dim i As Long
Dim B As Long
Dim tmpStr As String
Dim tmpMsg As String
Dim tmpUMsg As Boolean
'Dim UsedServerStrings(1) As String
ReDim UsedServerStrings(1) As String

For i = 2 To UBound(BLine)
  If UCase$(HostMask) Like UCase$(BLine(i).HostMask) Then
    #If Debugging = 1 Then
      SendSvrMsg "HostMask Match"
    #End If
    For B = 2 To UBound(UsedServerStrings)
      If UsedServerStrings(B) = Trim$(BLine(i).ServerName) & ":" & Trim(BLine(i).Port) Then
        #If Debugging = 1 Then
          SendSvrMsg "Skipped Adding To REDIRECT"
        #End If
        GoTo SkipAdd
      End If
    Next B
    
    tmpStr = tmpStr & Trim$(BLine(i).ServerName) & ":" & Trim$(BLine(i).Port) & ","
    If tmpUMsg = False Then tmpMsg = BLine(i).Message
    ReDim Preserve UsedServerStrings(UBound(UsedServerStrings) + 1) As String
    UsedServerStrings(UBound(UsedServerStrings)) = Trim$(BLine(i).ServerName) & ":" & Trim(BLine(i).Port)
SkipAdd:
  End If
Next i

If Right$(tmpStr, 1) = "," Then tmpStr = Left$(tmpStr, Len(tmpStr) - 1)
If Len(tmpMsg) > 0 Then tmpStr = Trim$(tmpStr) & " :" & Trim$(tmpMsg)
DoBLine = tmpStr
End Function
Public Function DoBLineMsg(HostMask As String) As String
Dim i As Long
Dim tmpMsg As String

For i = 2 To UBound(BLine)
  If UCase$(HostMask) Like UCase$(BLine(i).HostMask) Then
    tmpMsg = BLine(i).Message
    Exit For
  End If
Next i

DoBLineMsg = tmpMsg
End Function
Public Function GetMotD()
Dim FF As Long, Temp As String
FF = FreeFile
If Dir(App.Path & "\ircx.motd") <> vbNullString Then
  Open App.Path & "\ircx.motd" For Input As FF
  MotD = SPrefix & " 375 " & vbNullChar & " :- " & ServerName & " Message of the Day -" & vbCrLf
  Do While Not EOF(FF)
    Line Input #FF, Temp
    MotD = MotD & SPrefix & " 372 " & vbNullChar & " :- " & Temp & vbCrLf
  Loop
  MotD = MotD & SPrefix & " 376 " & vbNullChar & " :End of /MOTD command."
Else
  MotD = SPrefix & " 422 " & vbNullChar & " :MOTD File is missing"
End If
Close FF
End Function

Public Function GetQLine(Nick As String, AccessLevel As Long) As Long
Dim i As Long
For i = 2 To UBound(QLine)
    If UCase$(Nick) Like UCase$(QLine(i).Nick) And AccessLevel <> 3 Then
        GetQLine = i
        Exit Function
    End If
Next i
End Function

Public Function DoOLine(cptr As clsClient, Pass As String, OperName As String) As Boolean
Dim i As Long, x As Long, tmpPass As String
Dim tmpFlags As String
Dim OldPass As String
Dim tmpSendFlags As String
OldPass = Pass 'so MD5 doesn't throw us off ;)

If Crypt = True Then
    'We have Pass Encryption Now to see what one
    If MD5Crypt = True Then
        'We have MD5 so lets encrypt the pass here and now...
        tmpPass = oMD5.MD5(Pass)
        Pass = tmpPass
    End If
End If
For i = 2 To UBound(OLine)
    If StrComp(UCase$(OperName), UCase$(OLine(i).Name)) = 0 Then
        If InStr(1, OLine(i).Host, "@") Then
            If UCase$(cptr.User) & "@" & UCase$(cptr.RealHost) Like UCase$(OLine(i).Host) Then
                If StrComp(Pass, OLine(i).Pass) = 0 Then
                    'With the coming of modes like +Z we gotta make sure they aren't set via an oline...(Security)
                    tmpFlags = OLine(i).AccessFlag
                    '+r = Registered with NickServ (Just cos your an oper doesn't mean your registered)
                    tmpFlags = Replace(tmpFlags, "r", "")
                    '+Z = No oper should ever be a Remote Admin Client Automaticly
                    tmpFlags = Replace(tmpFlags, "Z", "")
                    '+S = Services can give themselves +S
                    tmpFlags = Replace(tmpFlags, "S", "")
                    
                    'put the modes in a buffer
                    'less clock cycles :)
                    tmpSendFlags = add_umodes(cptr, tmpFlags)
                    
                    'this event should be generated _before_ the user becomes an operator
                    '(no chance in getting his own mode flags thrown at him)
                    GenerateEvent "USER", "MODE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & tmpSendFlags
                    cptr.AccessLevel = 3
                    Opers.Add cptr.GUID, cptr
                    '// don't send the flags if there aren't any
                    If Len(tmpSendFlags) > 0 Then SendWsock cptr.index, "MODE " & cptr.Nick, "+" & tmpSendFlags, ":" & cptr.Nick
                    SendWsock cptr.index, RPL_YOUREOPER, cptr.Nick & " :You are now an IRC operator"
                    cptr.Class = GetYLine(OLine(i).ConnectionClass).index
                    If AVHost Then DoVLine cptr, OperName, OldPass, True
                    DoOLine = True
                    Exit Function
                Else
                    SendWsock cptr.index, ERR_PASSWDMISMATCH & " " & cptr.Nick, TranslateCode(ERR_PASSWDMISMATCH)
                    Exit Function
                End If
            Else
                SendWsock cptr.index, ERR_NOOPERHOST & " " & cptr.Nick, TranslateCode(ERR_NOOPERHOST)
                Exit Function
            End If
        Else
            If UCase$(cptr.RealHost) Like UCase$(OLine(i).Host) Then
                If StrComp(Pass, OLine(i).Pass) = 0 Then
                    'With the coming of modes like +Z we gotta make sure they aren't set via an oline...(Security)
                    tmpFlags = OLine(i).AccessFlag
                    '+r = Registered with NickServ (Just cos your an oper doesn't mean your registered)
                    tmpFlags = Replace(tmpFlags, "r", "")
                    '+Z = No oper should ever be a Remote Admin Client Automaticly
                    tmpFlags = Replace(tmpFlags, "Z", "")
                    '+S = Services can give themselves +S
                    tmpFlags = Replace(tmpFlags, "S", "")
                    
                    'put the modes in a buffer
                    'less clock cycles :)
                    tmpSendFlags = add_umodes(cptr, tmpFlags)
                    
                    'this event should be generated _before_ the user becomes an operator
                    '(no chance in getting his own mode flags thrown at him)
                    GenerateEvent "USER", "MODE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & tmpSendFlags
                    cptr.AccessLevel = 3
                    Opers.Add cptr.GUID, cptr
                    '// don't send the flags if there aren't any
                    If Len(tmpSendFlags) > 0 Then SendWsock cptr.index, "MODE " & cptr.Nick, "+" & tmpSendFlags, ":" & cptr.Nick
                    SendWsock cptr.index, RPL_YOUREOPER, cptr.Nick & " :You are now an IRC operator"
                    cptr.Class = GetYLine(OLine(i).ConnectionClass).index
                    DoOLine = True
                    If AVHost Then DoVLine cptr, OperName, OldPass, True
                    Exit Function
                Else
                    SendWsock cptr.index, ERR_PASSWDMISMATCH & " " & cptr.Nick, TranslateCode(ERR_PASSWDMISMATCH)
                    Exit Function
                End If
            Else
                SendWsock cptr.index, ERR_NOOPERHOST & " " & cptr.Nick, TranslateCode(ERR_NOOPERHOST)
                Exit Function
            End If
        End If
    End If
Next i
SendWsock cptr.index, ERR_NOOPERHOST & " " & cptr.Nick, TranslateCode(ERR_NOOPERHOST)
End Function
Public Sub DoVLine(cptr As clsClient, Login$, Pass$, Optional AutoVHost As Boolean = False)
Dim i&
'The AutoVHost parameter is so the oper doesn't get weird error messages
'duh :P
If Crypt = True Then
    'We have Pass Encryption Now to see what one
    If MD5Crypt = True Then
        'We have MD5 so lets encrypt the pass here and now...
        Pass = oMD5.MD5(Pass)
    End If
End If
For i = 2 To UBound(VLine)
    With VLine(i)
        If StrComp(UCase$(.Name), UCase$(Login)) = 0 Then
            If UCase$(cptr.User) & "@" & UCase$(cptr.RealHost) Like UCase$(.Host) Then
                If StrComp(Pass, .Pass) = 0 Then
                    cptr.Host = .Vhost
                    cptr.Prefix = ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host
                    If AutoVHost = False Then
                      SendWsock cptr.index, "NOTICE " & cptr.Nick, ":VHost applied for: " & .Vhost
                    Else
                      SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Automatic VHost of " & .Vhost & " applied."
                    End If
                    Exit Sub
                Else
                    If AutoVHost = False Then SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Invalid password"
                    Exit Sub
                End If
            Else
                If AutoVHost = False Then SendWsock cptr.index, "NOTICE " & cptr.Nick, ":No virtual host for your hostname"
                Exit Sub
            End If
        End If
    End With
Next i
If AutoVHost = False Then SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Invalid login name"
End Sub
Public Function DoNLine(cptr As clsClient) As Boolean
'Returns True if something is wrong
'Returns False if everything is okay.
Dim i&
#If Debugging = 1 Then
  SendSvrMsg "*** DoNLine called!"
#End If
For i = 2 To UBound(NLine)
    #If Debugging = 1 Then
      SendSvrMsg "*** DoNLine, cptr.IP is " & cptr.IP & ", NLine.Host is " & NLine(i).Host
    #End If
    'If (cptr.IP Like NLine(i).Host) Or (UCase$(cptr.RealHost) Like UCase$(NLine(i).Host)) Or (UCase$(cptr.Host) Like UCase$(NLine(i).Host)) Then
    If cptr.IP Like NLine(i).Host Then
        cptr.Class = GetYLine(NLine(i).ConnectionClass).index
        If cptr.Class < 2 Then
            m_error cptr, "Closing Link: No class specified for your host"
            DoNLine = True
            Exit Function
        End If
        cptr.IIndex = i
        If YLine(cptr.Class).MaxClients = YLine(cptr.Class).CurClients Then
            cptr.Class = 0
            cptr.IIndex = 0
            m_error cptr, "Closing Link: No more connections from your class allowed"
            DoNLine = True
            Exit Function
        Else
            YLine(cptr.Class).CurClients = YLine(cptr.Class).CurClients + 1
        End If
        If Len(NLine(i).Pass) <> 0 Then
            cptr.PassOK = False
        Else
            cptr.PassOK = True
        End If
        'cptr.AccessLevel = 4
        Exit Function
    End If
Next i
End Function
Public Function GetCLine(Server As String) As CLines
Dim i As Long
For i = 2 To UBound(CLine)
    If CLine(i).Server Like Server Then
        GetCLine = CLine(i)
        Exit Function
    End If
Next i
End Function

Public Function GetNLine(IP As String) As NLines
Dim i As Long
For i = 2 To UBound(NLine)
    If NLine(i).Host = IP Then
        GetNLine = NLine(i)
        Exit Function
    End If
Next i
End Function
