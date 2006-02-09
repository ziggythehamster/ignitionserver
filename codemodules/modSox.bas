Attribute VB_Name = "modSox"
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
' $Id: modSox.bas,v 1.4 2004/05/28 21:27:37 ziggythehamster Exp $
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
    GenerateEvent "USER", "LOGOFF", cptr.Nick & "!" & cptr.User & "@" & cptr.RealHost, cptr.Nick & "!" & cptr.User & "@" & cptr.RealHost
    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP
    If cptr.SentQuit Then Exit Sub
    With cptr
        Msg = .Prefix & " QUIT :Client Exited"
        For y = 1 To .OnChannels.Count
            x = .OnChannels.Item(y).Member.Values
            For z = LBound(x) To UBound(x)
                With x(z).Member
                    If .Hops = 0 Then
                        .SendQ = .SendQ & Msg & vbCrLf
                        ColOutClientMsg.Add .index
                    End If
                End With
            Next z
            .OnChannels.Item(y).Member.Remove .Nick
        Next y
        SendToServer "QUIT :Client Exited", .Nick
        KillStruct .Nick
        .IsKilled = True
    End With
    Set cptr = Nothing
Else
    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP
    'Server connection closed -Dill
    Dim I&, User() As clsClient, s&, c&
    User = GlobUsers.Values
    'remove all users (behind and/or directly from) this link -Dill
    For I = LBound(User) To UBound(User)
        If User(I).FromLink Is cptr Then
            For z = 1 To User(I).OnChannels.Count
                SendToChan User(I).OnChannels.Item(z), User(I).Prefix & " QUIT :" & ServerName & " " & cptr.ServerName, vbNullString
            Next z
            KillStruct User(I).Nick
            SendToServer "QUIT :" & ServerName & " " & cptr.ServerName, User(I).Nick
            Set User(I) = Nothing
            c = c + 1
        End If
    Next I
    'remove all servers behind this link -Dill
    User = Servers.Values
    For I = LBound(User) To UBound(User)
        If User(I).FromLink Is cptr Then
            Servers.Remove User(I).ServerName
            SendToServer "SQUIT :" & User(I).ServerName, ServerName
            Set User(I).FromLink = Nothing
            Set User(I) = Nothing
            s = s + 1
        End If
    Next I
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
            bArr = StrConv("ERROR :Closing Link: Server is full" & vbCrLf, vbFromUnicode)
            Call Send(Sockets.SocketHandle(insox), bArr(0), UBound(bArr) + 1, 0)
            Sockets.TerminateSocket Sockets.SocketHandle(insox)
            Set Users(insox) = Nothing
            Exit Sub
        End If
    End If
    NC.IP = Sockets.Address(insox)
    GenerateEvent "SOCKET", "OPEN", "*!*@*", NC.IP
    If MaxConnectionsPerIP > 0 Then
        IPHash(NC.IP) = IPHash(NC.IP) + 1
        If IPHash(NC.IP) > MaxConnectionsPerIP Then
            bArr = StrConv("ERROR :Closing Link: Session limit exceeded, no more connections allowed from your host" & vbCrLf, vbFromUnicode)
            Call Send(Sockets.SocketHandle(insox), bArr(0), UBound(bArr) + 1, 0)
            Sockets.TerminateSocket Sockets.SocketHandle(insox)
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
    NC.Host = AddressToName(NC.IP)
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
    Dim SendAuth As LLines
    Set NC = GetFreeSlot(insox)
    NC.SockHandle = Sockets.SocketHandle(insox)
    NC.IP = Sockets.Address(insox)
    GenerateEvent "SOCKET", "OPEN", "*!*@*", NC.IP
    NC.AccessLevel = 4
    NC.ServerName = ServerName
    NC.ServerDescription = ServerDescription
    NC.Host = AddressToName(NC.IP)
    Set NC.FromLink = Servers(ServerName)
    If DoILine(NC) Then Exit Sub
    NC.Idle = UnixTime
    NC.SignOn = UnixTime
    NC.Timeout = 2
    IrcStat.UnknownConnections = IrcStat.UnknownConnections + 1
    SendAuth = GetLLineN(NC.IP)
    If Len(SendAuth.Server) = 0 Then
        m_error NC, "Closing Link: (No Access)"
        Set NC = Nothing
        Set Users(insox) = Nothing
        Exit Sub
    End If
    SendWsock insox, "PASS " & SendAuth.Pass, vbNullString, vbNullString, True
    SendWsock insox, "SERVER " & ServerName & " 1 :" & ServerDescription, vbNullString, vbNullString, True
End If
End Sub

Public Sub Sox_DataArrival(insox As Long, StrMsg As String)
#If Debugging = 1 Then
    SendSvrMsg "Sox_DataArrival called!"
#End If
Dim cptr As clsClient, StrArray$(), I&, x&
Set cptr = Users(insox)
If cptr Is Nothing Then
    Sockets.CloseIt insox
    Exit Sub
End If
If cptr.IsKilled Then
    Sockets.CloseIt insox
    Exit Sub
End If
If Len(StrMsg) = 0 Then Exit Sub
StrMsg = Replace(StrMsg, vbCrLf, vbLf)
If InStr(1, StrMsg, vbLf) = 0 Then
    cptr.tmpused = True
    cptr.tmp = cptr.tmp & StrMsg
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
'Due to the nature of a Stack (Last one to push on is the first one that will get pulled off)
'we will have to push incoming messages in reversed order. -Dill
For I = 0 To UBound(StrArray)
    If Len(StrArray(I)) > 3 Then
    
        If MaxMsgsInQueue > 0 Then
            If cptr.AccessLevel < 4 Then
                If cptr.MsgsInQueue >= MaxMsgsInQueue Then
                    cptr.IsKilled = True
                    'a client flooding us
                    For x = 1 To cptr.OnChannels.Count
                        SendToChan cptr.OnChannels.Item(x), cptr.Prefix & " QUIT :Max RecvQ length exceeded", vbNullString
                    Next x
                    SendToServer "QUIT :Max RecvQ length exceeded", cptr.Nick
                    KillStruct cptr.Nick, enmTypeClient
                    m_error cptr, "Closing Link: Max RecvQ length exceeded"
                    Sockets.TerminateSocket cptr.SockHandle
                    Exit Sub
                Else
                     cptr.MsgsInQueue = cptr.MsgsInQueue + 1
                End If
            End If
        End If

        RecvMsg = RecvMsg + 1
        RecvQ.Add cptr, StrArray(I)
        If Left$(StrArray(I), 5) = "QUIT " Then cptr.SentQuit = True
    End If
Next I
End Sub

Public Sub Sox_Error(insox As Long, inerror As Long, inDescription As String, inSource As String, inSnipet As String)
#If Debugging = 1 Then
    SendSvrMsg "Sox_Error called! " & inDescription
#End If
Debug.Print inDescription
Dim cptr As clsClient, QMsg$, Msg$, y&, x() As clsChanMember, z&
Set cptr = Users(insox)
If cptr Is Nothing Then Exit Sub
With cptr
    Msg = .Prefix & " QUIT :socket error: " & inDescription
    For y = 1 To .OnChannels.Count
        x = .OnChannels.Item(y).Member.Values
        For z = LBound(x) To UBound(x)
            With x(z).Member
                If .Hops = 0 Then
                    .SendQ = .SendQ & Msg & vbCrLf
                    ColOutClientMsg.Add .index
                End If
            End With
        Next z
        .OnChannels.Item(y).Member.Remove .Nick
    Next y
    SendToServer "QUIT :socket error: " & inDescription, .Nick
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
