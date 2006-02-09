Attribute VB_Name = "modConf"
'ignitionServer is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: modConf.bas,v 1.3 2004/05/28 20:20:54 ziggythehamster Exp $
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

Public ILine() As ILines
Public YLine() As YLines
Public ZLine() As ZLines
Public KLine() As KLines
Public QLine() As QLines
Public PLine() As PLines
Public OLine() As OLines
Public LLine() As LLines
'Public CLine() as CLines - Coming Soon! - DG
Public VLine() As VLines

Public Sub Rehash(Flag As String)
Dim Line() As String, Char As String, Temp As String, FF As Integer: FF = FreeFile
Select Case Flag
    Case vbNullString
        ReDim ILine(1): ReDim YLine(1)
        ReDim ZLine(1): ReDim KLine(1)
        ReDim QLine(1): ReDim OLine(1)
        ReDim LLine(1) ': ReDim CLine(1) - This is coming soon! -DG
        ReDim VLine(1): ReDim PLine(1)
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
                ServerName = Line(0)
                IRCNet = Line(1)
                Sockets.Listen "", CInt(Line(3))
                ServerDescription = Line(2)
                Ports = Ports + 1
              Case "A"    'Admin info -Dill
                Line = Split(Temp, ":")
                AdminLocation = Line(0)
                Admin = Line(1)
                AdminEmail = Line(2)
              Case "Y"    'Connection classes -Dill
                Line = Split(Temp, ":")
                ReDim Preserve YLine(UBound(YLine) + 1)
                With YLine(UBound(YLine))
                    .id = CLng(Line(0))
                    .index = UBound(YLine)
                    .PingFreq = CLng(Line(1))
                    .ConnectFreq = CLng(Line(2))
                    .MaxClients = CLng(Line(3))
                    .MaxSendQ = CLng(Line(4))
                End With
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
              Case "L"  'Link Line -ZG
                        'Ziggy: With this line we don't need C/N lines so lets do away with them! - DG
                Line = Split(Temp, ":")
                ReDim Preserve LLine(UBound(LLine) + 1)
                With LLine(UBound(LLine))
                    .Host = Line(0)
                    .Pass = Line(1)
                    .Server = Line(2)
                    If Not Len(Line(3)) = 0 Then .Port = CInt(Line(3))
                    .ConnectionClass = Line(4)
                End With
              Case "K"    'Local bans -Dill
                Line = Split(Temp, ":")
                ReDim Preserve KLine(UBound(KLine) + 1)
                With KLine(UBound(KLine))
                    .Host = Line(0)
                    .Reason = Line(1)
                    .User = Line(2)
                End With
              Case "Q"    'Nickname quarantines -Dill
                Line = Split(Temp, ":")
                ReDim Preserve QLine(UBound(QLine) + 1)
                With QLine(UBound(QLine))
                    .Reason = Line(1)
                    .Nick = Line(2)
                End With
              Case "Z"    'Connection filters -Dill
                Line = Split(Temp, ":")
                ReDim Preserve ZLine(UBound(ZLine) + 1)
                With ZLine(UBound(ZLine))
                    .IP = Line(0)
                    .Reason = Line(1)
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
                If UCase(Section) = "DIEPASS" Then
                  DiePass = Line(1)
                ElseIf UCase(Section) = "RESTARTPASS" Then
                  RestartPass = Line(1)
                ElseIf UCase(Section) = "DIE" Then
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
                ElseIf UCase(Section) = "OFFLINEMODE" Then
                    If Line(1) = "0" Or UCase(Line(1)) = "OFF" Then
                        OfflineMode = False
                    ElseIf Line(1) = "1" Or UCase(Line(1)) = "OFF" Then
                        OfflineMode = True
                    Else
                        OfflineMode = False
                    End If
                ElseIf UCase(Section) = "OFFLINEMESSAGE" Then
                    OfflineMessage = Line(1)
                ElseIf UCase(Section) = "CNOTICE" Then
                    CustomNotice = Line(1)
                ElseIf UCase(Section) = "MASKDNS" Then
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
                    End If
                ElseIf UCase(Section) = "HOSTMASK" Then
                    HostMask = Line(1)
                ElseIf UCase(Section) = "SERVERLOCATION" Then
                    ServerLocation = Line(1)
                ElseIf UCase(Section) = "CRYPT" Then
                    If Line(1) = "0" Or UCase(Line(1)) = "OFF" Then
                        Crypt = False
                        MD5Crypt = False
                    ElseIf UCase(Line(1)) = "MD5" Then
                        Crypt = True
                        MD5Crypt = True
                    End If
                ElseIf UCase(Section) = "ALLOWMULTIPLE" Then
                  If Line(1) = "0" Or UCase(Line(1)) = "OFF" Then
                    AllowMultiple = False
                  ElseIf Line(1) = "1" Or UCase(Line(1)) = "ON" Then
                    AllowMultiple = True
                  Else
                    AllowMultiple = False
                  End If
                ElseIf UCase(Section) = "REMOTEPASS" Then
                  RemotePass = Line(1)
                ElseIf UCase(Section) = "SVSNICK" Then
                    If UCase(Line(1)) = "NICKSERV" Then
                        SVSN_NickServ = Line(2)
                    ElseIf UCase(Line(1)) = "CHANSERV" Then
                        SVSN_ChanServ = Line(2)
                    End If
                End If
              'Everything else is ignored -Dill
            End Select
          Loop
        Else
          SendSvrMsg "ircx.conf file is missing - quitting"
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
                    Debug.Print x
                End If
            End If
        Next tmp
        Do While Users(UBound(Users)) Is Nothing
            ReDim Preserve Users(UBound(Users) - 1)
        Loop
End Select
End Sub

Public Function DoKLine(cptr As clsClient) As Boolean
Dim I As Long
For I = 1 To UBound(KLine)
    If (cptr.IP Like KLine(I).Host) Or (cptr.Host Like KLine(I).Host) Then
        If (cptr.User Like KLine(I).User) Then
            m_error cptr, "Closing Link: K: line active (" & KLine(I).Reason & ")"
            KillStruct (cptr.Nick)
            DoKLine = True
            Exit Function
        End If
    End If
Next I
End Function

Public Function DoILine(cptr As clsClient) As Boolean
Dim I As Long
For I = 2 To UBound(ILine)
    If StrComp(ILine(I).IP, "NOMATCH") = 0 Then
        If (cptr.Host Like ILine(I).Host) Then
            cptr.Class = GetYLine(ILine(I).ConnectionClass).index
            cptr.IIndex = I
            If YLine(cptr.Class).MaxClients = YLine(cptr.Class).CurClients Then
                cptr.Class = 0
                m_error cptr, "Closing Link: No more connections from your class allowed"
                DoILine = True
                Exit Function
            Else
                YLine(cptr.Class).CurClients = YLine(cptr.Class).CurClients + 1
            End If
            If Len(ILine(I).Pass) <> 0 Then
                cptr.PassOK = False
            Else
                cptr.PassOK = True
            End If
            Exit Function
        End If
    Else
        If (cptr.IP Like ILine(I).IP) Then
            cptr.Class = GetYLine(ILine(I).ConnectionClass).index
            cptr.IIndex = I
            If YLine(cptr.Class).MaxClients = YLine(cptr.Class).CurClients Then
                cptr.Class = 0
                m_error cptr, "Closing Link: No more connections from your class allowed"
                DoILine = True
                Exit Function
            Else
                YLine(cptr.Class).CurClients = YLine(cptr.Class).CurClients + 1
            End If
            If Len(ILine(I).Pass) <> 0 Then
                cptr.PassOK = False
            Else
                cptr.PassOK = True
            End If
            Exit Function
        End If
    End If
Next I
End Function

Public Function DoZLine(index As Long, IP As String) As Boolean
Dim I As Long, buf() As Byte
For I = 2 To UBound(ZLine)
    If IP Like ZLine(I).IP Then
        buf = StrConv("ERROR :Closing Link: 'Z: Lined' " & ZLine(I).Reason & vbCrLf, vbFromUnicode)
        Call Send(Sockets.SocketHandle(index), buf(0), UBound(buf) + 1, 0&)
        DoZLine = True
        Exit Function
    End If
Next I
End Function

Public Function GetYLine(Class As Long) As YLines
Dim I As Long
For I = 2 To UBound(YLine)
    If YLine(I).id = Class Then
        GetYLine = YLine(I)
        Exit Function
    End If
Next I
End Function

Public Function GetMotD()
Dim FF As Integer, Temp As String
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
Dim I As Long
For I = 2 To UBound(QLine)
    If UCase(Nick) Like UCase(QLine(I).Nick) And AccessLevel <> 3 Then
        GetQLine = I
        Exit Function
    End If
Next I
End Function

Public Function DoOLine(cptr As clsClient, Pass As String, OperName As String) As Boolean
Dim I As Long, x As Long, tmpPass As String
Dim tmpFlags As String
If Crypt = True Then
    'We have Pass Encryption Now to see what one
    If MD5Crypt = True Then
        'We have MD5 so lets encrypt the pass here and now...
        tmpPass = oMD5.MD5(Pass)
        Pass = tmpPass
    End If
End If
For I = 2 To UBound(OLine)
    If StrComp(UCase(OperName), UCase(OLine(I).Name)) = 0 Then
        If InStr(1, OLine(I).Host, "@") Then
            If UCase(cptr.User) & "@" & UCase(cptr.RealHost) Like UCase(OLine(I).Host) Then
                If StrComp(Pass, OLine(I).Pass) = 0 Then
                    'With the coming of modes like +Z we gotta make sure they aren't set via an oline...(Security)
                    tmpFlags = OLine(I).AccessFlag
                    '+r = Registered with NickServ (Just cos your an oper doesn't mean your registered)
                    tmpFlags = Replace(tmpFlags, "r", "")
                    '+Z = No oper should ever be a Remote Admin Client Automaticly
                    tmpFlags = Replace(tmpFlags, "Z", "")
                    '+S = Services can give themselves +S
                    tmpFlags = Replace(tmpFlags, "S", "")

                    'this event should be generated _before_ the user becomes an operator
                    '(no chance in getting his own mode flags thrown at him)
                    GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & add_umodes(cptr, tmpFlags)
                    cptr.AccessLevel = 3
                    Opers.Add cptr.GUID, cptr
                    SendWsock cptr.index, "MODE " & cptr.Nick, "+" & add_umodes(cptr, tmpFlags), ":" & cptr.Nick
                    SendWsock cptr.index, RPL_YOUREOPER, ":You are now an IRC operator"
                    cptr.Class = GetYLine(OLine(I).ConnectionClass).index
                    DoOLine = True
                    Exit Function
                Else
                    SendWsock cptr.index, ERR_PASSWDMISMATCH, TranslateCode(ERR_PASSWDMISMATCH)
                    Exit Function
                End If
            Else
                SendWsock cptr.index, ERR_NOOPERHOST, TranslateCode(ERR_NOOPERHOST)
                Exit Function
            End If
        Else
            If UCase(cptr.RealHost) Like UCase(OLine(I).Host) Then
                If StrComp(Pass, OLine(I).Pass) = 0 Then
                    'this event should be generated _before_ the user becomes an operator
                    '(no chance in getting his own mode flags thrown at him)
                    GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & add_umodes(cptr, OLine(I).AccessFlag)
                    cptr.AccessLevel = 3
                    Opers.Add cptr.GUID, cptr
                    SendWsock cptr.index, "MODE " & cptr.Nick, "+" & add_umodes(cptr, OLine(I).AccessFlag), ":" & cptr.Nick
                    SendWsock cptr.index, RPL_YOUREOPER, ":You are now an IRC operator"
                    cptr.Class = GetYLine(OLine(I).ConnectionClass).index
                    DoOLine = True
                    Exit Function
                Else
                    SendWsock cptr.index, ERR_PASSWDMISMATCH, TranslateCode(ERR_PASSWDMISMATCH)
                    Exit Function
                End If
            Else
                SendWsock cptr.index, ERR_NOOPERHOST, TranslateCode(ERR_NOOPERHOST)
                Exit Function
            End If
        End If
    End If
Next I
SendWsock cptr.index, ERR_NOOPERHOST, TranslateCode(ERR_NOOPERHOST)
End Function

Public Function GetLLineC(Server As String) As LLines
Dim I As Long
For I = 2 To UBound(LLine)
    If LLine(I).Server Like Server Then
        GetLLineC = LLine(I)
        Exit Function
    End If
Next I
End Function

Public Function GetLLineN(IP As String) As LLines
Dim I As Long
For I = 2 To UBound(LLine)
    If LLine(I).Host = IP Then
        GetLLineN = LLine(I)
        Exit Function
    End If
Next I
End Function

Public Sub DoVLine(cptr As clsClient, Login$, Pass$)
Dim I&
If Crypt = True Then
    'We have Pass Encryption Now to see what one
    If MD5Crypt = True Then
        'We have MD5 so lets encrypt the pass here and now...
        Pass = oMD5.MD5(Pass)
    End If
End If
For I = 2 To UBound(VLine)
    With VLine(I)
        If StrComp(UCase(.Name), UCase(Login)) = 0 Then
            If UCase(cptr.User) & "@" & UCase(cptr.RealHost) Like UCase(.Host) Then
                If Pass = .Pass Then
                    cptr.Host = .Vhost
                    cptr.Prefix = ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host
                    SendWsock cptr.index, "NOTICE " & cptr.Nick, ":VHost applied for: " & .Vhost
                    Exit Sub
                Else
                    SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Invalid password"
                    Exit Sub
                End If
            Else
                SendWsock cptr.index, "NOTICE " & cptr.Nick, ":No virtual host for your hostname"
                Exit Sub
            End If
        End If
    End With
Next I
SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Invalid login name"
End Sub

Public Function DoLLine(cptr As clsClient) As Boolean
Dim I&
For I = 2 To UBound(LLine)
    If cptr.IP Like LLine(I).Host Then
        cptr.Class = GetYLine(LLine(I).ConnectionClass).index
        If cptr.Class < 2 Then
            m_error cptr, "Closing Link: No class specified for your host"
            DoLLine = True
            Exit Function
        End If
        cptr.IIndex = I
        If YLine(cptr.Class).MaxClients = YLine(cptr.Class).CurClients Then
            cptr.Class = 0
            cptr.IIndex = 0
            m_error cptr, "Closing Link: No more connections from your class allowed"
            DoLLine = True
            Exit Function
        Else
            YLine(cptr.Class).CurClients = YLine(cptr.Class).CurClients + 1
        End If
        If Len(LLine(I).Pass) <> 0 Then
            cptr.PassOK = False
        Else
            cptr.PassOK = True
        End If
        cptr.AccessLevel = 4
        Exit Function
    End If
Next I
End Function

