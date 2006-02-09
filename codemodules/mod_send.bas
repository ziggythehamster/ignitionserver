Attribute VB_Name = "mod_send"
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
' $Id: mod_send.bas,v 1.2 2004/05/28 20:20:54 ziggythehamster Exp $
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
        Else
          .SendQ = .SendQ & SPrefix & " EVENT " & UnixTime & " " & EventType & " " & EventName & vbCrLf
        End If
        On Local Error Resume Next
        ColOutClientMsg.Add .index, CStr(index)
    End If
End With
End Sub
Public Sub SendWsock(index As Long, cmd, arg$, Optional Prefix As String, Optional CustomMsg As Boolean = False)
On Error Resume Next
Dim I&, x&, Res$
If Users(index) Is Nothing Then Exit Sub
If Users(index).IsKilled Then Exit Sub
If Len(Prefix) = 0 Then Prefix = SPrefix
If CustomMsg = True Then
  Res = cmd & vbCrLf
Else
  I = 1
  Res = Space$(512)
  x = Len(Prefix)
  Mid$(Res, I, x) = Prefix
  I = I + x
  Mid$(Res, I, 1) = " "
  I = I + 1
  x = Len(CStr(cmd))
  Mid$(Res, I, x) = CStr(cmd)
  I = I + x
  Mid$(Res, I, 1) = " "
  I = I + 1
  x = Len(arg)
  Mid$(Res, I, x) = arg
  I = I + x
  Mid$(Res, I, 2) = vbCrLf
  I = I + 2
End If
Res = Trim$(Res)
With Users(index)
    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
        .SendQ = .SendQ & Res
        On Local Error Resume Next
        ColOutClientMsg.Add .index, CStr(index)
    End If
End With
End Sub

Public Function SendToChan(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim I As Long, Val() As clsChanMember
Msg = Msg & vbCrLf
ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
Val = Chan.Member.Values
If Len(From) > 0 Then
    For I = LBound(Val) To UBound(Val)
        If Not StrComp(From, Val(I).Member.Nick) = 0 Then
            If Val(I).Member.Hops = 0 Then
                With Val(I).Member
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
    Next I
Else
    For I = LBound(Val) To UBound(Val)
        If Val(I).Member.Hops = 0 Then
            With Val(I).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    .SendQ = .SendQ & Msg
                    On Local Error Resume Next
                    ColOutClientMsg.Add .index, CStr(.index)
                End If
            End With
        Else
            SendToChan = True
        End If
    Next I
End If
End Function
Public Function SendRawToChanOps(Chan As clsChannel, Raw As Long, Msg As String, From As String) As Boolean
On Error Resume Next
Dim I As Long, Val() As clsChanMember
Msg = Msg & vbCrLf
ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
Val = Chan.Member.Values
If Len(From) > 0 Then
    For I = LBound(Val) To UBound(Val)
        If Not StrComp(From, Val(I).Member.Nick) = 0 Then
            If Val(I).Member.Hops = 0 Then
                With Val(I).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        If Chan.Member.Item(.Nick).IsOp Or Chan.Member.Item(.Nick).IsOwner Then
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
    Next I
Else
    For I = LBound(Val) To UBound(Val)
        If Val(I).Member.Hops = 0 Then
            With Val(I).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    If Chan.Member.Item(.Nick).IsOp Or Chan.Member.Item(.Nick).IsOwner Then
                      .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                      On Local Error Resume Next
                      ColOutClientMsg.Add .index, CStr(.index)
                    End If
                End If
            End With
        Else
            SendRawToChanOps = True
        End If
    Next I
End If
End Function
Public Function SendRawToChan(Chan As clsChannel, Raw As Long, Msg As String, From As String) As Boolean
On Error Resume Next
Dim I As Long, Val() As clsChanMember
Msg = Msg & vbCrLf
ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
Val = Chan.Member.Values
If Len(From) > 0 Then
    For I = LBound(Val) To UBound(Val)
        If Not StrComp(From, Val(I).Member.Nick) = 0 Then
            If Val(I).Member.Hops = 0 Then
                With Val(I).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                        On Local Error Resume Next
                        ColOutClientMsg.Add .index, CStr(.index)
                    End If
                End With
            Else
                SendRawToChan = True
            End If
        End If
    Next I
Else
    For I = LBound(Val) To UBound(Val)
        If Val(I).Member.Hops = 0 Then
            With Val(I).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    .SendQ = .SendQ & SPrefix & " " & Raw & " " & .Nick & " " & Msg
                    On Local Error Resume Next
                    ColOutClientMsg.Add .index, CStr(.index)
                End If
            End With
        Else
            SendRawToChan = True
        End If
    Next I
End If
End Function
Public Sub SendToServer(Msg As String, Optional Prefix As String)
Dim I&, Val() As clsClient
If Len(Prefix) = 0 Then Prefix = ServerName
Val = Servers.Values
For I = LBound(Val) To UBound(Val)
    If Val(I).Hops = 1 Then
        SendWsock Val(I).index, ":" & Prefix & " " & Msg, vbNullString, vbNullString, True
    End If
Next I
End Sub

Public Sub SendToServer_ButOne(Msg As String, Except$, Optional Prefix As String)
Dim I&, Val() As clsClient
If Len(Prefix) = 0 Then Prefix = ServerName
Val = Servers.Values
For I = LBound(Val) To UBound(Val)
    If Val(I).Hops = 1 Then
        If Not StrComp(Val(I).ServerName, Except, vbTextCompare) = 0 Then
            SendWsock Val(I).index, ":" & Prefix & " " & Msg, vbNullString, vbNullString, True
        End If
    End If
Next I
End Sub

Public Sub SendToOps(index As Long, Msg As String, Optional Prefix As String)
Dim I As Long, Message() As Byte
If IsMissing(Prefix) Then Prefix = SPrefix
If AscW(Msg) = 58 Then
    Message = StrConv(Msg & vbCrLf, vbFromUnicode)
Else
    Message = StrConv(Prefix & " " & Msg & vbCrLf, vbFromUnicode)
End If
End Sub

Public Function SendToChanOwners(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim I As Long, Val() As clsChanMember
Msg = Msg & vbCrLf
ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
Val = Chan.Member.Values
If Len(From) > 0 Then
    For I = LBound(Val) To UBound(Val)
        If Not StrComp(From, Val(I).Member.Nick) = 0 Then
            If Val(I).Member.Hops = 0 Then
                With Val(I).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Then
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                    End If
                End With
            Else
                SendToChanOwners = True
            End If
        End If
    Next I
Else
    For I = LBound(Val) To UBound(Val)
        If Val(I).Member.Hops = 0 Then
            With Val(I).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Then
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                End If
            End With
        Else
            SendToChanOwners = True
        End If
    Next I
End If
End Function
Public Function SendToChanOps(Chan As clsChannel, Msg As String, From As String) As Boolean
On Error Resume Next
Dim I As Long, Val() As clsChanMember
Msg = Msg & vbCrLf
ServerTraffic = ServerTraffic + (Chan.Member.Count * Len(Msg))
'The first checks everytime if the target is the sender, so it executes a *BIT* slower than the other -Dill
Val = Chan.Member.Values
If Len(From) > 0 Then
    For I = LBound(Val) To UBound(Val)
        If Not StrComp(From, Val(I).Member.Nick) = 0 Then
            If Val(I).Member.Hops = 0 Then
                With Val(I).Member
                    If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                        On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Or Chan.Member.Item(.Nick).IsOp Then
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                    End If
                End With
            Else
                SendToChanOps = True
            End If
        End If
    Next I
Else
    For I = LBound(Val) To UBound(Val)
        If Val(I).Member.Hops = 0 Then
            With Val(I).Member
                If Not (Len(.SendQ) > YLine(.Class).MaxSendQ And .HasRegistered) Then
                    On Local Error Resume Next
                        If Chan.Member.Item(.Nick).IsOwner Or Chan.Member.Item(.Nick).IsOp Then
                          .SendQ = .SendQ & Msg
                          ColOutClientMsg.Add .index, CStr(.index)
                        End If
                End If
            End With
        Else
            SendToChanOps = True
        End If
    Next I
End If
End Function

