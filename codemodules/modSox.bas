Attribute VB_Name = "modSox"
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
' $Id: modSox.bas,v 1.23 2005/04/17 03:29:37 ziggythehamster Exp $
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

Public Function WindowProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
    Let WindowProc = Sockets.WndProc(hWnd, uMsg, wParam, lParam)
End Function

Public Sub Sox_Close(insox As Long) 'Notification of a close -Dill
On Error Resume Next
Dim cptr As clsClient, QMsg$, Msg$, y&, x() As clsChanMember, z&
#If Debugging = 1 Then
    SendSvrMsg "Sox_Close called " & insox
#End If
If insox = -1 Then Exit Sub
Set cptr = Users(insox)
If cptr Is Nothing Then Exit Sub

If MaxConnectionsPerIP > 0 Then
    IPHash(cptr.IP) = IPHash(cptr.IP) - 1
    If IPHash(cptr.IP) = 0 Then
        IPHash.Remove cptr.IP
    End If
End If

If cptr.AccessLevel < 4 Then
    'Client connection closed -Dill
    If Len(cptr.Nick) > 0 And Len(cptr.User) > 0 And Len(cptr.RealHost) > 0 Then GenerateEvent "USER", "QUIT", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :Client Exited"
    If Len(cptr.Nick) > 0 And Len(cptr.User) > 0 And Len(cptr.RealHost) > 0 Then GenerateEvent "USER", "LOGOFF", cptr.Nick & "!" & cptr.User & "@" & cptr.RealHost, cptr.Nick & "!" & cptr.User & "@" & cptr.RealHost
    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
    If cptr.SentQuit Then Exit Sub
    With cptr
        Msg = .Prefix & " QUIT :Client Exited"
        If cptr.OnChannels.Count > 0 Then
          For y = 1 To cptr.OnChannels.Count
              x = cptr.OnChannels.Item(y).Member.Values
              
              'if the channel is auditorium, only send the quit to everyone
              'if everyone saw this person to begin with
              If cptr.OnChannels.Item(y).IsAuditorium Then
                  If ((cptr.OnChannels.Item(y).Member.Item(cptr.Nick).IsOp) Or (cptr.OnChannels.Item(y).Member.Item(cptr.Nick).IsOwner)) Then
                    SendToChan cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all channelmembers -Dill
                  Else
                    'the person wasn't a host/owner, so only the hosts/owners know about him/her
                    SendToChanOps cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all ops
                  End If
              Else
                  SendToChan cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all channelmembers -Dill
              End If
              
              cptr.OnChannels.Item(y).Member.Remove cptr.Nick
          Next
        End If
        SendToServer "QUIT :Client Exited", .Nick
        KillStruct .Nick
        .IsKilled = True
    End With
    Set cptr = Nothing
    Set Users(insox) = Nothing
Else
    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
    'Server connection closed -Dill
    Dim i&, User() As clsClient, s&, c&
    User = GlobUsers.Values
    'remove all users (behind and/or directly from) this link -Dill
    For i = LBound(User) To UBound(User)
        If User(i).FromLink Is cptr Then
            For z = 1 To User(i).OnChannels.Count
            
              'account for auditorium
              If User(i).OnChannels.Item(z).IsAuditorium Then
                  If ((User(i).OnChannels.Item(z).Member.Item(User(i).Nick).IsOp) Or (User(i).OnChannels.Item(z).Member.Item(User(i).Nick).IsOwner)) Then
                    SendToChan User(i).OnChannels.Item(z), User(i).Prefix & " QUIT :" & ServerName & " " & cptr.ServerName, vbNullString
                  Else
                    'the person wasn't a host/owner, so only the hosts/owners know about him/her
                    SendToChanOps User(i).OnChannels.Item(z), User(i).Prefix & " QUIT :" & ServerName & " " & cptr.ServerName, vbNullString
                  End If
              Else
                  SendToChan User(i).OnChannels.Item(z), User(i).Prefix & " QUIT :" & ServerName & " " & cptr.ServerName, vbNullString
              End If
              'SendToChan User(I).OnChannels.Item(z), User(I).Prefix & " QUIT :" & ServerName & " " & cptr.ServerName, vbNullString
            Next z
            KillStruct User(i).Nick
            SendToServer "QUIT :" & ServerName & " " & cptr.ServerName, User(i).Nick
            Set User(i) = Nothing
            c = c + 1
        End If
    Next i
    'remove all servers behind this link -Dill
    User = Servers.Values
    For i = LBound(User) To UBound(User)
        If User(i).FromLink Is cptr Then
            Servers.Remove User(i).ServerName
            SendToServer "SQUIT :" & User(i).ServerName, ServerName
            Set User(i).FromLink = Nothing
            Set User(i) = Nothing
            s = s + 1
        End If
    Next i
    SendToServer "SQUIT :" & cptr.ServerName, cptr.ServerName
    Servers.Remove cptr.ServerName
    Set Users(insox) = Nothing
    Set cptr.FromLink = Nothing
    SendSvrMsg "Connection lost to: " & cptr.ServerName & " " & c & " client(s) and " & s & " server(s) lost during netsplit."
    cptr.IsKilled = True
    Set cptr = Nothing
End If
End Sub

Public Sub Sox_Connect(insox As Long, IsClient As Boolean) 'Notification of connection -Dill
#If Debugging = 1 Then
    SendSvrMsg "Sox_Connect called! " & IsClient
#End If
Call Sockets.SetOption(insox, soxSO_SNDBUF, 4096)
Call Sockets.SetOption(insox, soxSO_RCVBUF, 4096)
IrcStat.Connections = IrcStat.Connections + 1
If IsClient Then
    If DoZLine(insox, Sockets.Address(insox)) Then
        Sockets.TerminateSocket Sockets.Address(insox)
        Exit Sub
    End If
    Dim NC As clsClient, bArr() As Byte
    Set NC = GetFreeSlot(insox)
    If MaxConnections > 0 Then
        If LocalConn > MaxConnections Then
            Dim tmpSendOut As String
            If Len(DoBLine("")) > 0 Then
              Dim tmpRedirect As String
              tmpRedirect = DoBLine("")
              tmpRedirect = Trim$(tmpRedirect)
              If InStr(1, tmpRedirect, ",") = 0 Then tmpRedirect = tmpRedirect & ","
              tmpSendOut = tmpSendOut & SPrefix & " 010 Anonymous " & Trim$(Split(Split(tmpRedirect, ",")(0), ":")(0)) & " " & Trim$(Split(Split(tmpRedirect, ",")(0), ":")(1)) & " :" & DoBLineMsg("") & vbCrLf
              tmpSendOut = tmpSendOut & "ERROR :Closing Link: (""" & DoBLineMsg("") & """)" & vbCrLf
            End If
            If Len(tmpSendOut) = 0 Then tmpSendOut = "ERROR :Closing Link: (Server is full)" & vbCrLf
            bArr = StrConv(tmpSendOut, vbFromUnicode)
            Call Send(Sockets.SocketHandle(insox), bArr(0), UBound(bArr) + 1, 0)
            Sockets.TerminateSocket Sockets.SocketHandle(insox)
            Set Users(insox) = Nothing
            Exit Sub
        End If
    End If
    NC.IP = Sockets.Address(insox)
    On Error Resume Next
    NC.RemotePort = Sockets.Port(insox)
    NC.LocalPort = Sockets.LocalPort(Sockets.SocketHandle(insox))
    On Error GoTo 0
    GenerateEvent "SOCKET", "ACCEPT", "*!*@*", NC.IP & ":" & NC.RemotePort & " " & ServerLocalAddr & ":" & NC.LocalPort
    If MaxConnectionsPerIP > 0 Then
        IPHash(NC.IP) = IPHash(NC.IP) + 1
        If IPHash(NC.IP) > MaxConnectionsPerIP Then
            bArr = StrConv("ERROR :Closing Link: (Session limit exceeded, no more connections allowed from your host)" & vbCrLf, vbFromUnicode)
            Call Send(Sockets.SocketHandle(insox), bArr(0), UBound(bArr) + 1, 0)
            Sockets.TerminateSocket Sockets.SocketHandle(insox)
            GenerateEvent "SOCKET", "CLOSE", "*!*@*", NC.IP & ":" & NC.RemotePort & " " & ServerLocalAddr & ":" & NC.LocalPort
            IPHash(NC.IP) = IPHash(NC.IP) - 1
            Set Users(insox) = Nothing
            Exit Sub
        End If
    End If
    NC.SockHandle = Sockets.SocketHandle(insox)
    Sockets.SetOption insox, soxSO_KEEPALIVE, 1
    Sockets.SetOption insox, soxSO_TCP_NODELAY, 1
    Sockets.SetOption insox, soxSO_LINGER, 1
    NC.AccessLevel = 1
    NC.ServerName = ServerName
    NC.ServerDescription = ServerDescription
    NC.Host = AddressToName(NC.IP) 'perhaps we should have an option to disable name resolution?
    #If Debugging = 1 Then
      SendSvrMsg "Port: " & NC.RemotePort
    #End If
    Set NC.FromLink = Servers(ServerName)
    If DoILine(NC) Then Exit Sub
    NC.Idle = UnixTime
    NC.SignOn = UnixTime
    NC.Timeout = 2
    IrcStat.UnknownConnections = IrcStat.UnknownConnections + 1
Else
    Sockets.SetOption insox, soxSO_KEEPALIVE, 1
    Sockets.SetOption insox, soxSO_TCP_NODELAY, 1
    Sockets.SetOption insox, soxSO_LINGER, 0
    Dim SendAuth As NLines
    Set NC = GetFreeSlot(insox)
    NC.SockHandle = Sockets.SocketHandle(insox)
    NC.IP = Sockets.Address(insox)
    NC.AccessLevel = 4
    NC.ServerName = ServerName
    NC.ServerDescription = ServerDescription
    NC.Host = AddressToName(NC.IP)
    NC.RealHost = NC.Host
    On Error Resume Next
    NC.RemotePort = Sockets.Port(insox)
    NC.LocalPort = Sockets.LocalPort(Sockets.SocketHandle(insox))
    On Error GoTo 0
    GenerateEvent "SOCKET", "ACCEPT", "*!*@*", NC.IP & ":" & NC.RemotePort & " " & ServerLocalAddr & ":" & NC.LocalPort
    Set NC.FromLink = Servers(ServerName)
    If DoILine(NC) Then Exit Sub
    NC.Idle = UnixTime
    NC.SignOn = UnixTime
    NC.Timeout = 2
    IrcStat.UnknownConnections = IrcStat.UnknownConnections + 1
    SendAuth = GetNLine(NC.IP)
    If Len(SendAuth.Server) = 0 Then
        m_error NC, "Closing Link: (No Access)"
        #If Debugging = 1 Then
          SendSvrMsg "*** Closed link, N: line's server field is empty"
        #End If
        Set NC = Nothing
        Set Users(insox) = Nothing
        Exit Sub
    End If
    SendWsock insox, "PASS " & SendAuth.Pass, vbNullString, vbNullString, True
    SendWsock insox, "SERVER " & ServerName & " 1 :" & ServerDescription, vbNullString, vbNullString, True
End If
End Sub

Public Sub Sox_DataArrival(insox As Long, myStrMsg As String)
#If Debugging = 1 Then
    SendSvrMsg "Sox_DataArrival called!"
#End If
Dim cptr As clsClient, StrArray$(), i&, x&
Dim StrMsg As String
Set cptr = Users(insox)
If cptr Is Nothing Then
    Sockets.CloseIt insox
    Exit Sub
End If
If cptr.IsKilled Then
    Sockets.CloseIt insox
    Exit Sub
End If
If Len(myStrMsg) = 0 Then Exit Sub
If myStrMsg = vbNullChar Then Exit Sub 'ignore 0x00 (DoS)
StrMsg = myStrMsg 'it's a very bad idea to modify this variable directly, since it's the socket buffer and could allow overruns and all kinds of nasty business
StrMsg = Replace(StrMsg, vbNullChar, vbNullString) 'remove 0x00
StrMsg = Replace(StrMsg, vbCrLf, vbLf) 'filter this business
StrMsg = Replace(StrMsg, vbCr, vbLf) 'filter this too

If InStr(1, StrMsg, vbLf) = 0 Then
    cptr.tmpused = True
    #If Debugging = 1 Then
      SendSvrMsg "Telnet rightmost char: (ASCII " & Asc(Right(StrMsg, 1)) & ", Len " & Len(StrMsg) & ") '" & Right(StrMsg, 1) & "'"
    #End If
    If Asc(Right(StrMsg, 1)) = 0 Then
      #If Debugging = 1 Then
        SendSvrMsg "Found null as last char"
      #End If
      StrMsg = Left(StrMsg, Len(StrMsg) - 1)
    End If
    #If Debugging = 1 Then
      SendSvrMsg "Telnet rightmost char after trim: (ASCII " & Asc(Right(StrMsg, 1)) & ", Len " & Len(StrMsg) & ") '" & Right(StrMsg, 1) & "'"
    #End If
    
    'handle backspace
    If StrMsg = Chr(8) Then
      If Len(cptr.tmp) > 0 Then cptr.tmp = Left(cptr.tmp, Len(cptr.tmp) - 1)
      'don't add this to cptr.tmp, it's backspace ^_^
    Else
      cptr.tmp = cptr.tmp & Left(StrMsg, 512) 'no buffer overruns, mommy!
    End If
    Exit Sub
End If
If cptr.tmpused Then
    If Len(cptr.tmp) > 200 Then
        cptr.IsKilled = True
        'a client flooding us
        For x = 1 To cptr.OnChannels.Count
            SendToChan cptr.OnChannels.Item(x), cptr.Prefix & " QUIT :Max temp. RecvQ length exceeded", vbNullString
        Next x
        SendToServer "QUIT :Max temp. RecvQ length exceeded", cptr.Nick
        GenerateEvent "USER", "QUIT", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :Max temp. RecvQ length exceeded"
        GenerateEvent "USER", "LOGOFF", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "")
        GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
        KillStruct cptr.Nick, enmTypeClient
        m_error cptr, "Closing Link: Max temp. RecvQ length exceeded"
        Sockets.TerminateSocket cptr.SockHandle
        Exit Sub
    End If
    RecvQ.Add cptr, cptr.tmp
    cptr.tmp = vbNullString
    cptr.tmpused = False
    Exit Sub
End If
ServerTraffic = ServerTraffic + Len(StrMsg)
StrArray = Split(StrMsg, vbLf)

For i = 0 To UBound(StrArray)
    If Len(StrArray(i)) > 1024 Then
      'the line length is really 512, we're being nice.
      cptr.IsKilled = True
      If cptr.OnChannels.Count > 0 Then
        For x = 1 To cptr.OnChannels.Count
            SendToChan cptr.OnChannels.Item(x), cptr.Prefix & " QUIT :Line length too long", vbNullString
        Next x
      End If
      SendToServer "QUIT :Line length too long", cptr.Nick
      GenerateEvent "USER", "QUIT", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :Line length too long"
      GenerateEvent "USER", "LOGOFF", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "")
      GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
      KillStruct cptr.Nick, enmTypeClient
      m_error cptr, "Closing Link: (Line length too long)"
      Sockets.TerminateSocket cptr.SockHandle
      Exit Sub
    End If
    
    If Len(StrArray(i)) > 3 Then
    
        If MaxMsgsInQueue > 0 Then
            If cptr.AccessLevel < 4 Then
                If cptr.MsgsInQueue >= MaxMsgsInQueue Then
                    cptr.IsKilled = True
                    'a client flooding us
                    For x = 1 To cptr.OnChannels.Count
                        SendToChan cptr.OnChannels.Item(x), cptr.Prefix & " QUIT :Flooding", vbNullString
                    Next x
                    SendToServer "QUIT :Flooding", cptr.Nick
                    GenerateEvent "USER", "QUIT", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :Flooding"
                    GenerateEvent "USER", "LOGOFF", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "")
                    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
                    KillStruct cptr.Nick, enmTypeClient
                    m_error cptr, "Closing Link: (Flooding)"
                    Sockets.TerminateSocket cptr.SockHandle
                    Exit Sub
                Else
                     cptr.MsgsInQueue = cptr.MsgsInQueue + 1
                End If
            End If
        End If

        RecvMsg = RecvMsg + 1
        RecvQ.Add cptr, Left$(StrArray(i), 512)
        If Left$(StrArray(i), 5) = "QUIT " Then cptr.SentQuit = True
    End If
Next i
End Sub

Public Sub Sox_Error(insox As Long, inerror As Long, inDescription As String, inSource As String, inSnipet As String)
#If Debugging = 1 Then
    SendSvrMsg "Sox_Error called! " & inDescription
#End If
'Debug.Print inDescription
Dim cptr As clsClient, QMsg$, Msg$, y&, x() As clsChanMember, z&
Set cptr = Users(insox)
If cptr Is Nothing Then Exit Sub
With cptr
    Msg = .Prefix & " QUIT :Socket Error: " & inDescription
    If cptr.OnChannels.Count > 0 Then
      For y = 1 To cptr.OnChannels.Count
          x = cptr.OnChannels.Item(y).Member.Values
          
          'if the channel is auditorium, only send the quit to everyone
          'if everyone saw this person to begin with
          If cptr.OnChannels.Item(y).IsAuditorium Then
              If ((cptr.OnChannels.Item(y).Member.Item(cptr.Nick).IsOp) Or (cptr.OnChannels.Item(y).Member.Item(cptr.Nick).IsOwner)) Then
                SendToChan cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all channelmembers -Dill
              Else
                'the person wasn't a host/owner, so only the hosts/owners know about him/her
                SendToChanOps cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all ops
              End If
          Else
              SendToChan cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all channelmembers -Dill
          End If
          
          cptr.OnChannels.Item(y).Member.Remove cptr.Nick
      Next
    End If
    SendToServer "QUIT :Socket Error: " & inDescription, .Nick
    GenerateEvent "USER", "DISCONNECT", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :Socket Error: " & inDescription
    GenerateEvent "USER", "LOGOFF", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "")
    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
    KillStruct .Nick
    .IsKilled = True
End With
Set cptr = Nothing
End Sub

Public Function GetFreeSlot(UseIndex As Long) As clsClient
  ReDim Preserve Users(UseIndex)
  Set Users(UseIndex) = New clsClient
  Users(UseIndex).index = UseIndex
  Set GetFreeSlot = Users(UseIndex)
End Function
