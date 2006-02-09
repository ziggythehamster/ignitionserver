Attribute VB_Name = "modConf"
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
Option Base 1

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

Public Sub Rehash(Flag As String)
Dim Line() As String, Char As String, Temp As String, ff As Integer: ff = FreeFile
Select Case Flag
    Case vbNullString
        ReDim ILine(1): ReDim YLine(1)
        ReDim ZLine(1): ReDim KLine(1)
        ReDim QLine(1): ReDim OLine(1)
        ReDim NLine(1): ReDim CLine(1)
        ReDim VLine(1): ReDim PLine(1)
        If Dir(App.Path & "\ircx.conf") <> vbNullString Then
          Open App.Path & "\ircx.conf" For Input As ff
          Do While Not EOF(ff)
            Line Input #ff, Temp
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
                    .Host = Line(0)
                    .Pass = Line(1)
                    .Server = Line(2)
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
                    If Line(1) = "0" Or Line(1) = "off" Then
                        OfflineMode = False
                    ElseIf Line(1) = "1" Or Line(1) = "on" Then
                        OfflineMode = True
                    Else
                        OfflineMode = False
                    End If
                ElseIf UCase(Section) = "OFFLINEMESSAGE" Then
                    OfflineMessage = Line(1)
                ElseIf UCase(Section) = "CNOTICE" Then
                    CustomNotice = Line(1)
                End If
              'Everything else is ignored -Dill
            End Select
          Loop
        Else
          SendSvrMsg "ircx.conf file is missing - quitting"
          Terminate
        End If
        Close ff
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
Dim i As Long
For i = 1 To UBound(KLine)
    If (cptr.IP Like KLine(i).Host) Or (cptr.Host Like KLine(i).Host) Then
        If (cptr.User Like KLine(i).User) Then
            m_error cptr, "Closing Link: K: line active (" & KLine(i).Reason & ")"
            KillStruct (cptr.Nick)
            DoKLine = True
            Exit Function
        End If
    End If
Next i
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
            Else
                cptr.PassOK = True
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
            Else
                cptr.PassOK = True
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
        buf = StrConv("ERROR :Closing Link: 'Z: Lined' " & ZLine(i).Reason & vbCrLf, vbFromUnicode)
        Call Send(Sockets.SocketHandle(index), buf(0), UBound(buf) + 1, 0&)
        DoZLine = True
        Exit Function
    End If
Next i
End Function

Public Function GetYLine(Class As Long) As YLines
Dim i As Long
For i = 2 To UBound(YLine)
    If YLine(i).id = Class Then
        GetYLine = YLine(i)
        Exit Function
    End If
Next i
End Function

Public Function GetMotD()
Dim ff As Integer, Temp As String
ff = FreeFile
If Dir(App.Path & "\ircx.motd") <> vbNullString Then
  Open App.Path & "\ircx.motd" For Input As ff
  MotD = SPrefix & " 375 " & vbNullChar & " :- " & ServerName & " Message of the Day -" & vbCrLf
  Do While Not EOF(ff)
    Line Input #ff, Temp
    MotD = MotD & SPrefix & " 372 " & vbNullChar & " :- " & Temp & vbCrLf
  Loop
  MotD = MotD & SPrefix & " 376 " & vbNullChar & " :End of /MOTD command."
Else
  MotD = SPrefix & " 422 " & vbNullChar & " :MOTD File is missing"
End If
Close ff
End Function

Public Function GetQLine(Nick As String, AccessLevel As Long) As Long
Dim i As Long
For i = 2 To UBound(QLine)
    If UCase(Nick) Like UCase(QLine(i).Nick) And AccessLevel <> 3 Then
        GetQLine = i
        Exit Function
    End If
Next i
End Function

Public Function DoOLine(cptr As clsClient, Pass As String, OperName As String) As Boolean
Dim i As Long, x As Long
For i = 2 To UBound(OLine)
    If StrComp(UCase(OperName), UCase(OLine(i).Name)) = 0 Then
        If InStr(1, OLine(i).Host, "@") Then
            If UCase(cptr.User) & "@" & UCase(cptr.RealHost) Like UCase(OLine(i).Host) Then
                If StrComp(Pass, OLine(i).Pass) = 0 Then
                    cptr.AccessLevel = 3
                    Opers.Add cptr.GUID, cptr
                    SendWsock cptr.index, "MODE " & cptr.Nick, "+" & add_umodes(cptr, OLine(i).AccessFlag), ":" & cptr.Nick
                    SendWsock cptr.index, RPL_YOUREOPER, ":You are now an IRC operator"
                    cptr.Class = GetYLine(OLine(i).ConnectionClass).index
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
            If UCase(cptr.RealHost) Like UCase(OLine(i).Host) Then
                If StrComp(Pass, OLine(i).Pass) = 0 Then
                    cptr.AccessLevel = 3
                    Opers.Add cptr.GUID, cptr
                    SendWsock cptr.index, "MODE " & cptr.Nick, "+" & add_umodes(cptr, OLine(i).AccessFlag), ":" & cptr.Nick
                    SendWsock cptr.index, RPL_YOUREOPER, ":You are now an IRC operator"
                    cptr.Class = GetYLine(OLine(i).ConnectionClass).index
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
Next i
SendWsock cptr.index, ERR_NOOPERHOST, TranslateCode(ERR_NOOPERHOST)
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

Public Sub DoVLine(cptr As clsClient, Login$, Pass$)
Dim i&
For i = 2 To UBound(VLine)
    With VLine(i)
        If StrComp(UCase(.Name), UCase(Login)) = 0 Then
            If UCase(cptr.User) & "@" & UCase(cptr.Host) Like UCase(.Host) Then
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
Next i
SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Invalid login name"
End Sub

Public Function DoNLine(cptr As clsClient) As Boolean
Dim i&
For i = 2 To UBound(NLine)
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
        cptr.AccessLevel = 4
        Exit Function
    End If
Next i
End Function

