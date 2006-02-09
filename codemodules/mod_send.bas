Attribute VB_Name = "mod_send"
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
' $Id: mod_send.bas,v 1.18 2004/09/08 03:48:58 ziggythehamster Exp $
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

Public Sub SendDirect(index As Long, cmd$)
On Error Resume Next
ServerTraffic = ServerTraffic + Len(cmd)
With Users(index)
    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
        .SendQ = .SendQ & cmd
        On Local Error Resume Next
        ColOutClientMsg.Add .index, CStr(index)
    End If
End With
End Sub
Public Sub SendEvent(index As Long, EventType As String, EventName As String, Args As String)
On Error Resume Next
With Users(index)
    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
        'after much thinking i decided that EVENT really does need the server prefix specified
        'it's harder to code for events if the prefix isn't specified.. this makes more logical sense
        'too...
        If Len(Args) > 0 Then
          .SendQ = .SendQ & SPrefix & " EVENT " & UnixTime & " " & EventType & " " & EventName & " " & Args & vbCrLf
          ServerTraffic = ServerTraffic + Len(SPrefix & " EVENT " & UnixTime & " " & EventType & " " & EventName & " " & Args & vbCrLf)
        Else
          .SendQ = .SendQ & SPrefix & " EVENT " & UnixTime & " " & EventType & " " & EventName & vbCrLf
          ServerTraffic = ServerTraffic + Len(SPrefix & " EVENT " & UnixTime & " " & EventType & " " & EventName & vbCrLf)
        End If
        On Local Error Resume Next
        ColOutClientMsg.Add .index, CStr(index)
    End If
End With
End Sub
Public Sub SendWsock(index As Long, cmd, arg$, Optional Prefix As String, Optional CustomMsg As Boolean = False)
On Error Resume Next
Dim i&, x&, Res$
If Users(index) Is Nothing Then Exit Sub
If Users(index).IsKilled Then Exit Sub
If Len(Prefix) = 0 Then Prefix = SPrefix
If CustomMsg = True Then
  Res = cmd & vbCrLf
Else
  i = 1
  Res = Space$(512)
  x = Len(Prefix)
  Mid$(Res, i, x) = Prefix
  i = i + x
  Mid$(Res, i, 1) = " "
  i = i + 1
  x = Len(CStr(cmd))
  Mid$(Res, i, x) = CStr(cmd)
  i = i + x
  Mid$(Res, i, 1) = " "
  i = i + 1
  x = Len(arg)
  Mid$(Res, i, x) = arg
  i = i + x
  Mid$(Res, i, 2) = vbCrLf
  i = i + 2
End If
Res = Trim$(Res)
With Users(index)
    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
        .SendQ = .SendQ & Res
        ServerTraffic = ServerTraffic + Len(Res)
        On Local Error Resume Next
        ColOutClientMsg.Add .index, CStr(index)
    End If
End With
End Sub

Public Function SendToChan(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        .SendQ = .SendQ & Msg
                        On Local Error Resume Next
                        ColOutClientMsg.Add .index, CStr(.index)
                    End If
                End With
            Else
                SendToChan = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    .SendQ = .SendQ & Msg
                    On Local Error Resume Next
                    ColOutClientMsg.Add .index, CStr(.index)
                End If
            End With
        Else
            SendToChan = True
        End If
    Next i
End If
End Function
Public Function SendToChanIRCX(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If .IsIRCX Then
                      If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                           ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          On Local Error Resume Next
                          ColOutClientMsg.Add .index, CStr(.index)
                      End If
                    End If
                End With
            Else
                SendToChanIRCX = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If .IsIRCX Then
                  If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                      ServerTraffic = ServerTraffic + Len(Msg)
                      .SendQ = .SendQ & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                  End If
                End If
            End With
        Else
            SendToChanIRCX = True
        End If
    Next i
End If
End Function

'/* 20-Jul-2004 - Removed DATA/REQUEST/REPLY stuff    */
'/* It appears official IRCX no longer implements it  */
'/* as this function did. More memory, please! :) -Zg */

Public Function SendToChanOpsIRCX(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If .IsIRCX Then
                      If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                          If ClientVal(i).IsOp Or ClientVal(i).IsOwner Then
                            ServerTraffic = ServerTraffic + Len(Msg)
                            .SendQ = .SendQ & Msg
                            On Local Error Resume Next
                            ColOutClientMsg.Add .index, CStr(.index)
                          End If
                      End If
                    End If
                End With
            Else
                SendToChanOpsIRCX = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If .IsIRCX Then
                  If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    If ClientVal(i).IsOp Or ClientVal(i).IsOwner Then
                      ServerTraffic = ServerTraffic + Len(Msg)
                      .SendQ = .SendQ & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                    End If
                  End If
                End If
            End With
        Else
            SendToChanOpsIRCX = True
        End If
    Next i
End If
End Function
Public Function SendToChanOps1459(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not .IsIRCX Then
                      If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                          If ClientVal(i).IsOp Or ClientVal(i).IsOwner Then
                            ServerTraffic = ServerTraffic + Len(Msg)
                            .SendQ = .SendQ & Msg
                            On Local Error Resume Next
                            ColOutClientMsg.Add .index, CStr(.index)
                          End If
                      End If
                    End If
                End With
            Else
                SendToChanOps1459 = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not .IsIRCX Then
                  If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    If ClientVal(i).IsOp Or ClientVal(i).IsOwner Then
                      ServerTraffic = ServerTraffic + Len(Msg)
                      .SendQ = .SendQ & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                    End If
                  End If
                End If
            End With
        Else
            SendToChanOps1459 = True
        End If
    Next i
End If
End Function
Public Function SendToChanNotOps1459(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
#If Debugging = 1 Then
  SendSvrMsg "SendToChanNotOps1459 (" & Chan.Name & ")"
#End If
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not .IsIRCX Then
                      If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                          If Not ((ClientVal(i).IsOp) Or (ClientVal(i).IsOwner)) Then
                            ServerTraffic = ServerTraffic + Len(Msg)
                            .SendQ = .SendQ & Msg
                            On Local Error Resume Next
                            ColOutClientMsg.Add .index, CStr(.index)
                          End If
                      End If
                    End If
                End With
            Else
                SendToChanNotOps1459 = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not .IsIRCX Then
                  If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    If Not ((ClientVal(i).IsOp) Or (ClientVal(i).IsOwner)) Then
                      ServerTraffic = ServerTraffic + Len(Msg)
                      .SendQ = .SendQ & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                    End If
                  End If
                End If
            End With
        Else
            SendToChanNotOps1459 = True
        End If
    Next i
End If
End Function
Public Function SendToChanNotOpsIRCX(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
#If Debugging = 1 Then
  SendSvrMsg "SendToChanNotOpsIRCX (" & Chan.Name & ")"
#End If
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If .IsIRCX Then
                      If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                          If Not ((ClientVal(i).IsOp) Or (ClientVal(i).IsOwner)) Then
                            ServerTraffic = ServerTraffic + Len(Msg)
                            .SendQ = .SendQ & Msg
                            On Local Error Resume Next
                            ColOutClientMsg.Add .index, CStr(.index)
                          End If
                      End If
                    End If
                End With
            Else
                SendToChanNotOpsIRCX = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If .IsIRCX Then
                  If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    If Not ((ClientVal(i).IsOp) Or (ClientVal(i).IsOwner)) Then
                      ServerTraffic = ServerTraffic + Len(Msg)
                      .SendQ = .SendQ & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                    End If
                  End If
                End If
            End With
        Else
            SendToChanNotOpsIRCX = True
        End If
    Next i
End If
End Function
Public Function SendToChan1459(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not .IsIRCX Then
                      If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          On Local Error Resume Next
                          ColOutClientMsg.Add .index, CStr(.index)
                      End If
                    End If
                End With
            Else
                SendToChan1459 = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not .IsIRCX Then
                  If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                      ServerTraffic = ServerTraffic + Len(Msg)
                      .SendQ = .SendQ & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                  End If
                End If
            End With
        Else
            SendToChan1459 = True
        End If
    Next i
End If
End Function
Public Function SendRawToChanOps(Chan As clsChannel, Raw As Long, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        If Chan.Member.Item(.Nick).IsOp Or Chan.Member.Item(.Nick).IsOwner Then
                          ServerTraffic = ServerTraffic + Len(SPrefix & " " & Raw & " " & .Nick & " " & Msg)
                          .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                          On Local Error Resume Next
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                    End If
                End With
            Else
                SendRawToChanOps = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    If Chan.Member.Item(.Nick).IsOp Or Chan.Member.Item(.Nick).IsOwner Then
                      ServerTraffic = ServerTraffic + Len(SPrefix & " " & Raw & " " & .Nick & " " & Msg)
                      .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                    End If
                End If
            End With
        Else
            SendRawToChanOps = True
        End If
    Next i
End If
End Function
Public Function SendRawToChan(Chan As clsChannel, Raw As Long, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        ServerTraffic = ServerTraffic + Len(SPrefix & " " & Raw & " " & .Nick & " " & Msg)
                        .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                        On Local Error Resume Next
                        ColOutClientMsg.Add .index, CStr(.index)
                    End If
                End With
            Else
                SendRawToChan = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    ServerTraffic = ServerTraffic + Len(SPrefix & " " & Raw & " " & .Nick & " " & Msg)
                    .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                    On Local Error Resume Next
                    ColOutClientMsg.Add .index, CStr(.index)
                End If
            End With
        Else
            SendRawToChan = True
        End If
    Next i
End If
End Function
Public Sub SendToServer(Msg As String, Optional Prefix As String)
#If Debugging = 1 Then
SendSvrMsg "*** SendToServer called!"
#End If
Dim i&, ClientVal() As clsClient
If Len(Prefix) = 0 Then Prefix = ServerName
ClientVal = Servers.Values
For i = LBound(ClientVal) To UBound(ClientVal)
    If ClientVal(i).Hops = 1 Then
        SendWsock ClientVal(i).index, ":" & Prefix & " " & Msg, vbNullString, vbNullString, True
    End If
Next i
End Sub

Public Sub SendToServer_ButOne(Msg As String, Except$, Optional Prefix As String)
#If Debugging = 1 Then
SendSvrMsg "*** SendToServer_ButOne called! (except " & Except & ")"
#End If
Dim i&, ClientVal() As clsClient
If Len(Prefix) = 0 Then Prefix = ServerName
ClientVal = Servers.Values
For i = LBound(ClientVal) To UBound(ClientVal)
    If ClientVal(i).Hops = 1 Then
        If Not StrComp(ClientVal(i).ServerName, Except, vbTextCompare) = 0 Then
            SendWsock ClientVal(i).index, ":" & Prefix & " " & Msg, vbNullString, vbNullString, True
        End If
    End If
Next i
End Sub

Public Sub SendToOps(index As Long, Msg As String, Optional Prefix As String)
Dim i As Long, Message() As Byte
If IsMissing(Prefix) Then Prefix = SPrefix
If AscW(Msg) = 58 Then
    Message = StrConv(Msg & vbCrLf, vbFromUnicode)
    ServerTraffic = ServerTraffic + Len(Msg & vbCrLf)
Else
    Message = StrConv(Prefix & " " & Msg & vbCrLf, vbFromUnicode)
    ServerTraffic = ServerTraffic + Len(Prefix & " " & Msg & vbCrLf)
End If
End Sub

Public Function SendToChanOwners(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                    End If
                End With
            Else
                SendToChanOwners = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                End If
            End With
        Else
            SendToChanOwners = True
        End If
    Next i
End If
End Function
Public Function SendToChanOps(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Or Chan.Member.Item(.Nick).IsOp Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                    End If
                End With
            Else
                SendToChanOps = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Or Chan.Member.Item(.Nick).IsOp Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                End If
            End With
        Else
            SendToChanOps = True
        End If
    Next i
End If
End Function
Public Function SendToChanNotOps(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim i As Long, ClientVal() As clsChanMember
#If Debugging = 1 Then
  SendSvrMsg "SendToChanNotOps (" & Chan.Name & ")"
#End If
Msg = Msg & vbCrLf
'ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
ClientVal = Chan.Member.Values
If Len(From) > 0 Then
    For i = LBound(ClientVal) To UBound(ClientVal)
        If Not StrComp(From, ClientVal(i).Member.Nick) = 0 Then
            If ClientVal(i).Member.Hops = 0 Then
                With ClientVal(i).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        On Local Error Resume Next
                        If Not (Chan.Member.Item(.Nick).IsOwner Or Chan.Member.Item(.Nick).IsOp) Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                    End If
                End With
            Else
                SendToChanNotOps = True
            End If
        End If
    Next i
Else
    For i = LBound(ClientVal) To UBound(ClientVal)
        If ClientVal(i).Member.Hops = 0 Then
            With ClientVal(i).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    On Local Error Resume Next
                        If Not (Chan.Member.Item(.Nick).IsOwner Or Chan.Member.Item(.Nick).IsOp) Then
                          ServerTraffic = ServerTraffic + Len(Msg)
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                End If
            End With
        Else
            SendToChanNotOps = True
        End If
    Next i
End If
End Function
Public Function SendDirectRaw(cptr As clsClient, Message As String)
On Error Resume Next
Dim bArr() As Byte
ServerTraffic = ServerTraffic + Len(Message)
bArr = StrConv(Message, vbFromUnicode)
Call Send(cptr.SockHandle, bArr(0), UBound(bArr) + 1, 0)
End Function
