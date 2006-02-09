Attribute VB_Name = "m_nonstandard"
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
' $Id: m_nonstandard.bas,v 1.2 2004/06/04 02:09:26 ziggythehamster Exp $
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
'Set the following to 1 if you want to compile ignitionServer with nonstandard commands
'You'll also need to set it to 1 in mod_main
#Const EnableNonstandard = 0

#If EnableNonstandard = 1 Then
'/****************************\
'* begin nonstandard commands *
'\****************************/

Public Function m_umode(cptr As clsClient, sptr As clsClient, parv$()) As Long
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "UMODE")
    Exit Function
End If
If UBound(parv) < 1 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "UMODE")
    Exit Function
End If
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
Dim User As clsClient, NewModes$
Set User = GlobUsers(parv(0))
If User Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHNICK & " " & cptr.Nick, TranslateCode(ERR_NOSUCHNICK, , parv(0))
    Exit Function
End If
Dim FiltModes As String
'oOsixkreRDCcKBbAEZ

'this bit is to prevent malicious use
'of this command -- nobody should
'be able to set these modes on themselves!
FiltModes = parv(1)
FiltModes = Replace(FiltModes, "R", "") 'disallow restart
FiltModes = Replace(FiltModes, "D", "") 'disallow die
FiltModes = Replace(FiltModes, "O", "") 'disallow globop
FiltModes = Replace(FiltModes, "o", "") 'disallow locop
FiltModes = Replace(FiltModes, "k", "") 'disallow lockills
FiltModes = Replace(FiltModes, "K", "") 'disallow globkills
FiltModes = Replace(FiltModes, "e", "") 'disallow rehash
FiltModes = Replace(FiltModes, "C", "") 'disallow globconnects
FiltModes = Replace(FiltModes, "c", "") 'disallow locconnects
FiltModes = Replace(FiltModes, "B", "") 'disallow /unkline
FiltModes = Replace(FiltModes, "b", "") 'disallow /kline
FiltModes = Replace(FiltModes, "N", "") 'disallow netadmin
FiltModes = Replace(FiltModes, "E", "") 'disallow /add
FiltModes = Replace(FiltModes, "Z", "") 'disallow remadm
FiltModes = Replace(FiltModes, "S", "") 'disallow service
FiltModes = Replace(FiltModes, "P", "") 'disallow protect
FiltModes = Replace(FiltModes, "p", "") 'disallow lower protect

NewModes = add_umodes(User, FiltModes)
'nobody, anyone, ever should be allowed
'to give themselves or anyone else any
'oper flag

If Len(NewModes) = 0 Then Exit Function
Select Case User.Hops
    Case Is > 0
        GenerateEvent "USER", "MODECHANGE", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "") & " +" & NewModes
        SendWsock User.FromLink.index, "MODE " & User.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
    Case Else
        GenerateEvent "USER", "MODECHANGE", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "") & " +" & NewModes
        SendWsock User.index, "MODE " & User.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
End Select
End Function
Public Function m_samode(cptr As clsClient, sptr As clsClient, parv$()) As Long
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "SAMODE")
    Exit Function
End If
If UBound(parv) < 1 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "SAMODE")
    Exit Function
End If
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
Dim I&, ops$, Inc&, SetMode As Boolean, Chan As clsChannel, CurMode&, ChM As clsChanMember
Dim NewModes$, Param$
Set Chan = Channels(parv(0))
If Chan Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
    Exit Function
End If
If UBound(parv) > 1 Then Inc = 1
For I = 1 To Len(parv(1))
    CurMode = AscW(Mid$(parv(1), I, 1))
    Select Case CurMode
        Case modeAdd
            SetMode = True
            NewModes = NewModes & "+"
        Case modeRemove
            SetMode = False
            NewModes = NewModes & "-"
        Case cmOwner
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If Not ChM.IsOwner Then
                            NewModes = NewModes & "q"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOwner = True
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
                Case False
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If ChM.IsOwner Then
                            NewModes = NewModes & "q"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOwner = False
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
            End Select
        Case cmOp
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If Not ChM.IsOp Then
                            NewModes = NewModes & "o"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOp = True
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
                Case False
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If ChM.IsOp Then
                            NewModes = NewModes & "o"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOp = False
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
            End Select
        'Case cmHOp
        '    Inc = Inc + 1
        '    Select Case SetMode
        '        Case True
        '            Set ChM = Chan.Member.Item(parv(Inc))
        '            If Not ChM Is Nothing Then
        '                If Not ChM.IsHOp Then
        '                    NewModes = NewModes & "H"
        '                    Param = Param & parv(Inc) & " "
        '                    ChM.IsHOp = True
        '                End If
        '            Else
        '                SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
        '            End If
        '        Case False
        '            Set ChM = Chan.Member.Item(parv(Inc))
        '            If Not ChM Is Nothing Then
        '                If ChM.IsHOp Then
        '                    NewModes = NewModes & "H"
        '                    Param = Param & parv(Inc) & " "
        '                    ChM.IsHOp = False
        '                End If
        '            Else
        '                SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
        '            End If
        '    End Select
        Case cmVoice
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If Not ChM.IsVoice Then
                            NewModes = NewModes & "v"
                            Param = Param & parv(Inc) & " "
                            ChM.IsVoice = True
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
                Case False
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If ChM.IsVoice Then
                            NewModes = NewModes & "v"
                            Param = Param & parv(Inc) & " "
                            ChM.IsVoice = False
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
            End Select
        Case cmBan
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    NewModes = NewModes & "b"
                    Param = Param & parv(Inc) & " "
                    Chan.Bans.Add parv(Inc), cptr.Nick, UnixTime, parv(Inc)
                Case False
                    NewModes = NewModes & "b"
                    Param = Param & parv(Inc) & " "
                    Chan.Bans.Remove parv(Inc)
            End Select
        Case cmKey
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    If Len(Chan.Key) = 0 Then
                        NewModes = NewModes & "k"
                        Param = Param & parv(Inc) & " "
                        Chan.Key = parv(Inc)
                        Chan.Prop_Memberkey = parv(Inc)
                    Else
                        SendWsock cptr.index, ERR_KEYSET & " " & cptr.Nick, TranslateCode(ERR_KEYSET, , , Chan.Name)
                    End If
                Case False
                    If Len(Chan.Key) > 0 Then
                        If Chan.Key = parv(Inc) Then
                            NewModes = NewModes & "k"
                            Param = Param & parv(Inc) & " "
                            Chan.Key = vbNullString
                            Chan.Prop_Memberkey = vbNullString
                        End If
                    End If
            End Select
        Case cmLimit
            Select Case SetMode
                Case True
                    Inc = Inc + 1
                    Chan.Limit = parv(Inc)
                    NewModes = NewModes & "l"
                    Param = Param & parv(Inc) & " "
                Case False
                    Chan.Limit = 0
                    NewModes = NewModes & "l"
            End Select
        Case cmInviteOnly
            Select Case SetMode
                Case True
                    If Not Chan.IsInviteOnly Then
                        Chan.IsInviteOnly = True
                        NewModes = NewModes & "i"
                    End If
                Case False
                    If Chan.IsInviteOnly Then
                        Chan.IsInviteOnly = False
                        NewModes = NewModes & "i"
                    End If
            End Select
        Case cmOpTopic
            Select Case SetMode
                Case True
                    If Not Chan.IsTopicOps Then
                        Chan.IsTopicOps = True
                        NewModes = NewModes & "t"
                    End If
                Case False
                    If Chan.IsTopicOps Then
                        Chan.IsTopicOps = False
                        NewModes = NewModes & "t"
                    End If
            End Select
        Case cmModerated
            Select Case SetMode
                Case True
                    If Not Chan.IsModerated Then
                        Chan.IsModerated = True
                        NewModes = NewModes & "m"
                    End If
                Case False
                    If Chan.IsModerated Then
                        Chan.IsModerated = False
                        NewModes = NewModes & "m"
                    End If
            End Select
        Case cmNoExternalMsg
            Select Case SetMode
                Case True
                    If Not Chan.IsNoExternalMsgs Then
                        Chan.IsNoExternalMsgs = True
                        NewModes = NewModes & "n"
                    End If
                Case False
                    If Chan.IsNoExternalMsgs Then
                        Chan.IsNoExternalMsgs = False
                        NewModes = NewModes & "n"
                    End If
            End Select
        Case cmSecret
            Select Case SetMode
                Case True
                    If Not Chan.IsSecret Then
                        Chan.IsSecret = True
                        NewModes = NewModes & "s"
                    End If
                Case False
                    If Chan.IsSecret Then
                        Chan.IsSecret = False
                        NewModes = NewModes & "s"
                    End If
            End Select
        Case cmPrivate
            Select Case SetMode
                Case True
                    If Not Chan.IsPrivate Then
                        Chan.IsPrivate = True
                        NewModes = NewModes & "p"
                    End If
                Case False
                    If Chan.IsPrivate Then
                        Chan.IsPrivate = False
                        NewModes = NewModes & "p"
                    End If
            End Select
        Case cmOperOnly
        If cptr.IsGlobOperator Or cptr.IsNetAdmin Then
            Select Case SetMode
                Case True
                    If Not Chan.IsOperOnly Then
                        Chan.IsOperOnly = True
                        NewModes = NewModes & "O"
                    End If
                Case False
                    If Chan.IsOperOnly Then
                        Chan.IsOperOnly = False
                        NewModes = NewModes & "O"
                    End If
            End Select
        Else
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        End If
    End Select
Next I
If Len(NewModes) <= 1 Then Exit Function
Param = RTrim$(Param)
SendToChanIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " " & NewModes & " " & Param, vbNullString
SendToChan1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " " & Replace(NewModes, "q", "o") & " " & Param, vbNullString
SendToServer "MODE " & NewModes & " " & Param, cptr.Nick
End Function

'/******************************\
'* end of nonstandard commands  *
'\******************************/
#End If
