Attribute VB_Name = "mod_Oper"
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
' $Id: mod_Oper.bas,v 1.2 2004/05/28 20:35:05 ziggythehamster Exp $
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

Public Function m_add(cptr As clsClient, sptr As clsClient, parv$()) As Long
If cptr.CanAdd Then
If Dir(App.Path & "\ircx.conf") <> vbNullString Then
    
    If UCase(parv(0)) = "OPER" Then
    
    'Parv 1 - Oper Nick
    'Parv 2 - Oper Pass
    'Parv 3 - User Host
    'Parv 4 - Oper Flags
    'Parv 5 - Oper Class
        Open App.Path & "\ircx.conf" For Append As #1
        Print #1, "#OPER(" & parv(1) & ") ADDED BY " & cptr.Nick & "(" & cptr.RealHost & ")"
        Print #1, "O:" & parv(3) & ":" & parv(2) & ":" & parv(1) & ":" & parv(4) & ":" & CLng(parv(5))
        Close #1
        Call Rehash(vbNullString)
    ElseIf UCase(parv(0)) = "SERVER" Then
    
    'Parv 1 - Server Name
    'Parv 2 - Server Pass
    'Parv 3 - Server IP
    'Parv 4 - Server Port
    'Parv 5 - Server Class
        Open App.Path & "\ircx.conf" For Append As #1
        Print #1, "#Server(" & parv(1) & ") ADDED BY " & cptr.Nick & "(" & cptr.RealHost & ")"
        Print #1, "L:" & parv(3) & ":" & parv(2) & ":" & parv(1) & ":" & parv(4) & ":" & CLng(parv(5))
        Close #1
        Call Rehash(vbNullString)
    ElseIf UCase(parv(0)) = "VHOST" Then
    
    'Parv 1 - VHost Nick
    'Parv 2 - VHost Pass
    'Parv 3 - VHost
    'Parv 4 - VHost UserHost
        Open App.Path & "\ircx.conf" For Append As #1
        Print #1, "#VHOST(" & parv(3) & ") ADDED BY " & cptr.Nick & "(" & cptr.RealHost & ")"
        Print #1, "V:" & parv(3) & ":" & parv(1) & ":" & parv(2) & ":" & parv(4)
        Close #1
        Call Rehash(vbNullString)
    ElseIf UCase(parv(0)) = "HELP" Then
        SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Oper: SYNTAX: /add oper [NickName] [Password] [UserHost] [OperFlags] [ServerClass]", SPrefix
        SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Server: SYNTAX: /add server [ServerName] [Password] [IP] [ServerPort] [ServerClass]", SPrefix
        SendWsock cptr.index, "NOTICE " & cptr.Nick, ":VHost: SYNTAX: /add vhost [UserName] [Password] [VHost] [UserHost]", SPrefix
        If MD5Crypt = True Then
            SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Oper/VHost: NOTE: Oper & VHost Passwords must be a MD5 hash generated by ignitionServer PassCrypt or /passcrypt", SPrefix
        End If
    End If
Else
    SendSvrMsg "ircx.conf file is missing - quitting"
    Terminate
End If
Else

    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
End If
End Function

Public Function m_remoteadm(cptr As clsClient, sptr As clsClient, parv$()) As Long
Dim x&
If UCase(parv(0)) = "LOGIN" Then
Dim NewModes$
    If Crypt = True Then
        If MD5Crypt = True Then
            If modMD5.oMD5.MD5(parv(1)) = RemotePass Then
                NewModes = add_umodes(cptr, "Z")
                If NewModes = "" Then Exit Function
                Select Case cptr.Hops
                    Case Is > 0
                        GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & NewModes
                        SendWsock cptr.FromLink.index, "MODE " & cptr.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
                    Case Else
                        GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & NewModes
                        SendWsock cptr.index, "MODE " & cptr.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
                End Select
            Else
                SendWsock cptr.index, ERR_PASSWDMISMATCH, TranslateCode(ERR_PASSWDMISMATCH)
                Exit Function
            End If
        End If
    Else
        If parv(1) = RemotePass Then
            NewModes = add_umodes(cptr, "Z")
            If NewModes = "" Then Exit Function
            Select Case cptr.Hops
                Case Is > 0
                    GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & NewModes
                    SendWsock cptr.FromLink.index, "MODE " & cptr.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
                Case Else
                    GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " +" & NewModes
                    SendWsock cptr.index, "MODE " & cptr.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
            End Select
        Else
            SendWsock cptr.index, ERR_PASSWDMISMATCH, TranslateCode(ERR_PASSWDMISMATCH)
            Exit Function
        End If
    End If
ElseIf UCase(parv(0)) = "SEND" Then
    If cptr.IsRemoteAdmClient Then
        If UCase(parv(1)) = "OPER" Then
            For x = 2 To UBound(OLine)
                SendWsock cptr.index, "REMOTEADM :SEND OPER " & OLine(x).Name & " " & OLine(x).Pass & " " & OLine(x).Host & " " & OLine(x).AccessFlag & " " & OLine(x).ConnectionClass, vbNullString, , True
            Next x
        ElseIf UCase(parv(1)) = "SERVER" Then
            For x = 2 To UBound(LLine)
                SendWsock cptr.index, "REMOTEADM :SEND SERVER " & LLine(x).Server & " " & LLine(x).Pass & " " & LLine(x).Host & " " & LLine(x).Port & " " & LLine(x).ConnectionClass, vbNullString, , True
            Next x
        End If
    Else
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    End If
End If
End Function
