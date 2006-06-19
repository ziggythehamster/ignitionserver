Attribute VB_Name = "mod_channel"
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
' $Id: mod_channel.bas,v 1.100 2005/07/20 00:10:34 ziggythehamster Exp $
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

'ACCESS #Channel <ADD|DELETE|CLEAR> <OWNER|HOST|VOICE|GRANT|DENY> Nick!ID@Host 0 :Reason
'parv:    0             1                        2                     3       4    5

'*** How Access Durations Will Be Handled ***
'(This is here for my future reference, since I'm going to end up forgetting how I thought
'of a way to make it work)
'--
'Whenever an entry is made, the AddX method will be called. AddX allows the Duration to be specified.
'Whenever someone views the accesslist, the entries with a duration (non-zero) will be computed. The
'following formula should work:
'If ((UnixTime/60) - (SetOn/60)) > Duration Then Remove_From_Access
'Basically, if the current time (mins) minus the time it was set on (mins) are greater than the duration, it's expired.
'Proof:
'UnixTime = 500m
'TimeSet = 300m
'Duration = 20m
'500-300=200
'200 minutes have elapsed since the entry was set. This is obiously longer than the duration so it will be discarded.
'Any joins will also trigger this proccessing
'If it isn't expired (<= Duration), it would look like this
'UT = 500m
'TS = 450m
'D = 100m
'500-450=50
'100-50=50 remaining
'Again, ignore these formulas for now. I only typed them so I know what to do when I feel like getting to it.

Public Function m_access(cptr As clsClient, sptr As clsClient, parv$()) As Long
On Error GoTo errtrap
  
#If Debugging = 1 Then
  SendSvrMsg "ACCESS called! (" & cptr.Nick & ")"
#End If

If Len(parv(0)) = 0 Then  'if no channel given, complain
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "ACCESS")
    Exit Function
End If

If cptr.AccessLevel = 4 Then
  Call m_access_remote(cptr, sptr, parv)
Else
  Call m_access_local(cptr, sptr, parv)
End If
Exit Function
errtrap:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_access'"
End Function
'Option Base 1
'/*
' * m_mode
' * parv$()[0] - sender
' * parv$()[1] - target; channels and/or user
' * parv$()[2] - optional modes
' * parv$()[n] - optional parameters
' */
Public Function m_mode(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "MODE called! (" & cptr.Nick & ")"
#End If

Dim Chan As clsChannel
Dim i As Long
Dim x As Long
Dim Target As clsClient
Dim op As String
Dim NewOp As Boolean
Dim SendModes As Boolean
Dim Mask As String
Dim Ban As clsBan
Dim parc As Long
Dim chans() As String
Dim y As Long
Dim Inc As Long
Dim op_nohost As String

Dim MSwitch           As Boolean
Dim CurMode           As Long
Dim UserPrivs         As Long
Dim A                 As Long
Dim NumParams         As Long
Dim CurParam          As Long
Dim NewModes          As String 'Generic new mode output
Dim NewModesExtra     As String 'For modes with extra parameters (+kvoq)
Dim FirstOp           As String 'records the first operation
Dim TargetUser        As clsClient
Dim SendPrivateRemove As Boolean
Dim SendSecretRemove  As Boolean
Dim SendHiddenRemove  As Boolean
Dim WasPrivate        As Boolean 'was a private room
Dim WasSecret         As Boolean 'was a secret room
Dim WasHidden         As Boolean 'was a hidden room
Dim UnsetPrivate      As Boolean 'unset +p
Dim UnsetSecret       As Boolean 'unset +s
Dim UnsetHidden       As Boolean 'unset +h
Dim ShowAudStuff      As Boolean 'to fix a stupid VB bug :\
Dim ShowAudStuffClnt  As clsClient
Dim HideAudStuff      As Boolean 'again, fixing a VB bug :\
Dim HideAudStuffClnt  As clsClient
Dim ModeSwitchSent    As Boolean 'don't process modes until a switch is sent (bug 23)

Set ShowAudStuffClnt = New clsClient
Set HideAudStuffClnt = New clsClient

parc = UBound(parv)
Dim TargetClient As clsClient
Dim tmpIsOwner As Boolean

'// begin code for servers
If cptr.AccessLevel = 4 Then
    Dim NM$, MU$, ChanMember As clsChanMember

    
    If AscW(parv(0)) = 35 Then
        'chan
        Set Chan = Channels(parv(0))
        If Chan Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , parv(0))
          Exit Function
        End If
        'CycleAccess Chan -- not working for some reason
        If Len(sptr.Nick) = 0 Then
            If Len(sptr.ServerName) > 0 Then op = cptr.ServerName
        Else
            op = sptr.Nick & "!" & sptr.User & "@" & sptr.Host
            op_nohost = sptr.Nick
        End If
        If UBound(parv) > 1 Then Inc = 1
        For i = 1 To Len(parv(1))
            Mask = Mid$(parv(1), i, 1)
            Select Case AscW(Mask)
                Case modeAdd
                    MSwitch = True
                    NM = NM & "+"
                Case modeRemove
                    MSwitch = False
                    NM = NM & "-"
                'Ok well I rewrote this bit because well otherwise servers wouldn't be able to give +q(so it seems) - DG
                Case cmOwner 'IRCX - Zg
                    Inc = Inc + 1
                    If MSwitch Then
                        With Chan.Member.Item(parv(Inc))
                            If Not .IsOwner Then
                                Set TargetClient = GlobUsers.Item(parv(Inc))
                                'the following line notifies the clients in an auditorium that this person exists
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOps Chan, TargetClient.Prefix & " JOIN :" & Chan.Name, 0
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOps1459 Chan, TargetClient.Prefix & " MODE " & Chan.Name & " +o " & TargetClient.Nick, 0
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOpsIRCX Chan, TargetClient.Prefix & " MODE " & Chan.Name & " +q " & TargetClient.Nick, 0
                                
                                .IsOwner = True
                                If Not TargetClient Is Nothing Then GenerateEvent "MEMBER", "MODE", Replace(TargetClient.Prefix, ":", ""), Chan.Name & " " & Replace(TargetClient.Prefix, ":", "") & " +q " & Replace(sptr.Prefix, ":", "")
                                Set TargetClient = Nothing
                            End If
                        End With
                    Else
                        With Chan.Member.Item(parv(Inc))
                            If .IsOwner Then
                                .IsOwner = False
                                Set TargetClient = GlobUsers.Item(parv(Inc))
                                'the following line notifies the clients in an auditorium that this person exists
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOps Chan, TargetClient.Prefix & " PART " & Chan.Name, 0
                                If Not TargetClient Is Nothing Then GenerateEvent "MEMBER", "MODE", Replace(TargetClient.Prefix, ":", ""), Chan.Name & " " & Replace(TargetClient.Prefix, ":", "") & " -q " & Replace(sptr.Prefix, ":", "")
                                Set TargetClient = Nothing
                            End If
                        End With
                    End If
                    MU = MU & " " & parv(Inc)
                    NM = NM & "q"
                Case cmOp
                    Inc = Inc + 1
                    If MSwitch Then
                        With Chan.Member.Item(parv(Inc))
                            If Not .IsOp Then
                                Set TargetClient = GlobUsers.Item(parv(Inc))
                                'the following line notifies the clients in an auditorium that this person exists
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOps Chan, TargetClient.Prefix & " JOIN :" & Chan.Name, 0
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOps Chan, TargetClient.Prefix & " MODE " & Chan.Name & " +o " & TargetClient.Nick, 0
                                
                                .IsOp = True
                                If Not TargetClient Is Nothing Then GenerateEvent "MEMBER", "MODE", Replace(TargetClient.Prefix, ":", ""), Chan.Name & " " & Replace(TargetClient.Prefix, ":", "") & " +o " & Replace(sptr.Prefix, ":", "")
                                Set TargetClient = Nothing
                            End If
                        End With
                    Else
                        With Chan.Member.Item(parv(Inc))
                            If .IsOp Then
                                .IsOp = False
                                Set TargetClient = GlobUsers.Item(parv(Inc))
                                'the following line notifies the clients in an auditorium that this person exists
                                If Chan.IsAuditorium And Not ((.IsOwner) Or (.IsOp)) Then SendToChanNotOps Chan, TargetClient.Prefix & " PART " & Chan.Name, 0
                                If Not TargetClient Is Nothing Then GenerateEvent "MEMBER", "MODE", Replace(TargetClient.Prefix, ":", ""), Chan.Name & " " & Replace(TargetClient.Prefix, ":", "") & " -q " & Replace(sptr.Prefix, ":", "")
                                Set TargetClient = Nothing
                            End If
                        End With
                    End If
                    MU = MU & " " & parv(Inc)
                    NM = NM & "o"
                Case cmVoice
                    Inc = Inc + 1
                    If MSwitch Then
                        With Chan.Member.Item(parv(Inc))
                            If Not .IsVoice Then
                                .IsVoice = True
                                Set TargetClient = GlobUsers.Item(parv(Inc))
                                If Not TargetClient Is Nothing Then GenerateEvent "MEMBER", "MODE", Replace(TargetClient.Prefix, ":", ""), Chan.Name & " " & Replace(TargetClient.Prefix, ":", "") & " +v " & Replace(sptr.Prefix, ":", "")
                                Set TargetClient = Nothing
                            End If
                        End With
                    Else
                        With Chan.Member.Item(parv(Inc))
                            If .IsVoice Then
                                .IsVoice = False
                                Set TargetClient = GlobUsers.Item(parv(Inc))
                                If Not TargetClient Is Nothing Then GenerateEvent "MEMBER", "MODE", Replace(TargetClient.Prefix, ":", ""), Chan.Name & " " & Replace(TargetClient.Prefix, ":", "") & " -v " & Replace(sptr.Prefix, ":", "")
                                Set TargetClient = Nothing
                            End If
                        End With
                    End If
                    MU = MU & " " & parv(Inc)
                    NM = NM & "v"
                Case cmBan
                    Inc = Inc + 1
                    If MSwitch Then
                        'store what level the user was that added the entry (for access lists)
                        If sptr.IsOnChan(Chan.Name) Then
                          'will return false if it's a server
                          tmpIsOwner = Chan.Member.Item(sptr.Nick).IsOwner
                        End If
                        Chan.Bans.Add parv(i + Inc), op, tmpIsOwner, UnixTime, parv(Inc)
                    Else
                        Chan.Bans.Remove parv(i + Inc)
                    End If
                    MU = MU & " " & parv(Inc)
                    NM = NM & "b"
                Case cmModerated
                    Chan.IsModerated = MSwitch
                    NM = NM & "m"
                Case cmNoExternalMsg
                    Chan.IsNoExternalMsgs = MSwitch
                    NM = NM & "n"
                Case cmSecret
                    If MSwitch Then
                        If Chan.IsPrivate Then
                            Chan.IsPrivate = False
                            Chan.IsSecret = True
                            Chan.IsHidden = False
                            NM = NM & "-p+s"
                        ElseIf Chan.IsHidden Then
                            Chan.IsPrivate = False
                            Chan.IsSecret = True
                            Chan.IsHidden = False
                            NM = NM & "-h+s"
                        Else
                            Chan.IsSecret = True
                            NM = NM & "s"
                        End If
                    Else
                        NM = NM & "s"
                    End If
                Case cmPrivate
                    If MSwitch Then
                        If Chan.IsSecret Then
                            Chan.IsSecret = False
                            Chan.IsPrivate = True
                            Chan.IsHidden = False
                            NM = NM & "-s+p"
                        ElseIf Chan.IsHidden Then
                            Chan.IsPrivate = True
                            Chan.IsSecret = False
                            Chan.IsHidden = False
                            NM = NM & "-h+p"
                        Else
                            Chan.IsPrivate = True
                            NM = NM & "p"
                        End If
                    Else
                        NM = NM & "p"
                    End If
                Case cmHidden
                    If MSwitch Then
                        If Chan.IsSecret Then
                            Chan.IsSecret = False
                            Chan.IsPrivate = False
                            Chan.IsHidden = True
                            NM = NM & "-s+h"
                        ElseIf Chan.IsPrivate Then
                            Chan.IsPrivate = False
                            Chan.IsSecret = False
                            Chan.IsHidden = True
                            NM = NM & "-p+h"
                        Else
                            Chan.IsHidden = True
                            NM = NM & "h"
                        End If
                    Else
                        NM = NM & "h"
                    End If
                Case cmInviteOnly
                    Chan.IsInviteOnly = MSwitch
                    NM = NM & "i"
                Case cmOpTopic
                    Chan.IsTopicOps = MSwitch
                    NM = NM & "t"
                Case cmLimit
                    If MSwitch Then
                        Inc = Inc + 1
                        Chan.Limit = parv(Inc)
                        MU = MU & " " & parv(Inc)
                    Else
                        Chan.Limit = 0
                    End If
                    GenerateEvent "CHANNEL", "LIMIT", Chan.Name, Chan.Name & " " & Replace(sptr.Prefix, ":", "") & " :" & Chan.Limit
                    NM = NM & "l"
                Case cmKey
                    Inc = Inc + 1
                    If MSwitch Then
                        Chan.Key = parv(Inc)
                        MU = MU & " " & parv(Inc)
                    Else
                        Chan.Key = vbNullString
                    End If
                    GenerateEvent "CHANNEL", "KEYWORD", Chan.Name, Chan.Name & " " & Replace(sptr.Prefix, ":", "") & " :" & Chan.Key
                    NM = NM & "k"
                Case cmRegistered
                    Chan.IsRegistered = MSwitch
                    NM = NM & "r"
                Case cmOperOnly
                    Chan.IsOperOnly = MSwitch
                    NM = NM & "O"
                Case cmPersistant
                    If RegChanMode_ModeR Then
                      Chan.IsPersistant = MSwitch
                      NM = NM & "R"
                    End If
                Case cmKnock
                    Chan.IsKnock = MSwitch
                    NM = NM & "u"
                Case cmAuditorium
                    Chan.IsAuditorium = MSwitch
                    NM = NM & "x"
                Case cmClone
                    Chan.IsClone = MSwitch
                    NM = NM & "e"
                Case cmCloneable
                    Chan.IsCloneable = MSwitch
                    NM = NM & "d"
            End Select
        Next i
        MU = LTrim$(MU)
        If Chan.IsAuditorium Then
          'the users in the channel need not know about this :)
          SendToChanOpsIRCX Chan, ":" & op & " MODE " & Chan.Name & " " & NM & " " & MU, vbNullString
          SendToChanOps1459 Chan, ":" & op & " MODE " & Chan.Name & " " & Replace(NM, "q", "o") & " " & MU, vbNullString
        Else
          SendToChanIRCX Chan, ":" & op & " MODE " & Chan.Name & " " & NM & " " & MU, vbNullString
          SendToChan1459 Chan, ":" & op & " MODE " & Chan.Name & " " & Replace(NM, "q", "o") & " " & MU, vbNullString
        End If
        SendToServer_ButOne "MODE " & Chan.Name & " " & NM & " " & MU, cptr.ServerName, op_nohost
        GenerateEvent "CHANNEL", "MODE", Chan.Name, Chan.Name & " " & NM & " " & op
    Else
        'user
        Set Target = GlobUsers(parv(0))
        For i = 1 To Len(parv(1))
            Mask = Mid$(parv(1), i, 1)
            Select Case AscW(Mask)
                Case modeAdd
                    MSwitch = True
                    NM = NM & "+"
                Case modeRemove
                    MSwitch = False
                    NM = NM & "-"
                Case umGlobOper
                    Target.IsGlobOperator = MSwitch
                    Target.IsLocOperator = MSwitch
                    NM = NM & "Oo"
                Case umInvisible
                    Target.IsInvisible = MSwitch
                    NM = NM & "i"
                Case umHostCloak
                    Target.IsCloaked = MSwitch
                    NM = NM & "d"
                Case umRegistered
                    Target.IsRegistered = MSwitch
                    NM = NM & "r"
                Case umWallOps
                    Target.GetsWallops = MSwitch
                    NM = NM & "w"
                'Start changes by SG_01 2004-06-21
                Case umService
                    Target.IsService = MSwitch
                    NM = NM & "S"
                Case umGagged
                    Target.IsGagged = MSwitch
                    NM = NM & "z"
                Case umLProtected
                    Target.IsLProtected = MSwitch
                    NM = NM & "p"
                Case umProtected
                    Target.IsProtected = MSwitch
                    NM = NM & "P"
                'End changes by SG_01
            End Select
        Next i
        GenerateEvent "USER", "MODE", Replace(Target.Prefix, ":", ""), Replace(Target.Prefix, ":", "") & " " & NM
        SendToServer_ButOne "MODE " & Target.Nick & " " & NM, cptr.ServerName, sptr.Nick
        If Target.Hops = 0 Then SendWsock Target.index, sptr.Prefix & " MODE " & Target.Nick & " " & NM, vbNullString, , True
    End If
Else
'// begin code for clients

  If Len(parv(0)) = 0 Then    'oops, client forgot to tell us which channel it wanted to mode -Dill
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
    GoTo NextChan
  End If
  
  If AscW(parv(0)) = 35 Then
    Set Chan = Channels(parv(0))
    'see if the channel even exists
    If Chan Is Nothing Then
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , chans(y))
      Exit Function
    End If
    'cycle the access list
    Call CycleAccess(Chan)
    
    If UBound(parv) = 0 Then
      'we're hiding the key from people who aren't welcome to see it (i.e. they're not on the channel)
      If cptr.OnChannels.Item(Chan.Name) Is Nothing Then
        SendWsock cptr.index, SPrefix & " " & RPL_CHANNELMODEIS & " " & cptr.Nick & " " & Chan.Name & " +" & GetModes(Chan, True), vbNullString, , True
      Else
        SendWsock cptr.index, SPrefix & " " & RPL_CHANNELMODEIS & " " & cptr.Nick & " " & Chan.Name & " +" & GetModes(Chan), vbNullString, , True
      End If
      Exit Function
    Else
      'and now the mode code!
      'It's a lot easier to match numbers than it is to keep going into Chan
      
      '                                     [NQOV]
      'Normal = 0                           [0000]
      'Normal + Voice = 1                   [0001]
      'Normal + Host = 2                    [0010]
      'Normal + Host + Voice = 3            [0011]
      'Normal + Owner = 4                   [0100]
      'Normal + Owner + Voice = 5           [0101]
      'Normal + Owner + Host = 6            [0110]
      'Normal + Owner + Host + Voice = 7    [0111]
      
      If Chan.Member.Item(cptr.Nick).IsVoice Then UserPrivs = UserPrivs + 1
      If Chan.Member.Item(cptr.Nick).IsOp Then UserPrivs = UserPrivs + 2
      If Chan.Member.Item(cptr.Nick).IsOwner Then UserPrivs = UserPrivs + 4
      
      'Chr(43) = +
      'Chr(45) = -
      
      NumParams = UBound(parv) 'This is to simplify further checking :)
      If NumParams > 1 Then
        CurParam = 2
      Else
        CurParam = NumParams
      End If
      FirstOp = Left(parv(1), 1)
      
      WasPrivate = Chan.IsPrivate
      WasSecret = Chan.IsSecret
      WasHidden = Chan.IsHidden
      
      For A = 1 To Len(parv(1))
        CurMode = Asc(Mid$(parv(1), A, 1))
        
CheckParam:
        'this does some basic checking, so you don't
        'set a null ban or something because you sent
        'extra spaces
        If CurParam <= NumParams And CurParam > 1 Then
          If Len(parv(CurParam)) = 0 Then
            CurParam = CurParam + 1
            GoTo CheckParam
          ElseIf StrComp(parv(CurParam), Chr(32)) = 0 Then
            CurParam = CurParam + 1
            GoTo CheckParam
          End If
        End If
        
        'Don't process modes until someone sends + or -
        'An awful hack brought to you from HackCo.
        '(blame Microsoft for making VB so crappy)
        If CurMode = modeAdd Then ModeSwitchSent = True
        If CurMode = modeRemove Then ModeSwitchSent = True
        If ModeSwitchSent = False Then GoTo NextMode
        
        Select Case CurMode
          Case modeAdd
            MSwitch = True
            NewModes = NewModes & "+"
          Case modeRemove
            MSwitch = False
            NewModes = NewModes & "-"
          Case cmVoice
            If UserPrivs > 1 Then
              If CurParam <= NumParams Then
                'We don't want to continue processing if the current param is
                'greater than the number of params
                If CurParam > 1 Then
                  'You can't set +v without specifying a target
                  Set TargetUser = GlobUsers(parv(CurParam))
                  'So we get the right casing for the nickname :)
                  If TargetUser Is Nothing Then
                    SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(CurParam), Chan.Name)
                    GoTo NextMode
                  End If
                  If TargetUser.IsLProtected Then
                    If Not (cptr.IsLProtected Or cptr.IsProtected Or cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  If TargetUser.IsProtected Then
                    If Not (cptr.IsProtected Or cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  If TargetUser.IsNetAdmin Then
                    If Not (cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  '// now that we've disallowed the de-opping if the user lacks sufficient privileges, go on
                  Select Case MSwitch
                    Case True
                      GenerateEvent "MEMBER", "MODE", Replace(TargetUser.Prefix, ":", ""), Chan.Name & " " & Replace(TargetUser.Prefix, ":", "") & " +v " & Replace(cptr.Prefix, ":", "")
                      If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendWsock TargetUser.index, "MODE", Chan.Name & " +v " & TargetUser.Nick, cptr.Prefix
                    Case False
                      GenerateEvent "MEMBER", "MODE", Replace(TargetUser.Prefix, ":", ""), Chan.Name & " " & Replace(TargetUser.Prefix, ":", "") & " -v " & Replace(cptr.Prefix, ":", "")
                      If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendWsock TargetUser.index, "MODE", Chan.Name & " -v " & TargetUser.Nick, cptr.Prefix
                  End Select
                  Chan.Member.Item(TargetUser.Nick).IsVoice = MSwitch
                  NewModes = NewModes & "v"
                  If Len(NewModesExtra) > 0 Then
                    NewModesExtra = NewModesExtra & " " & TargetUser.Nick
                  Else
                    NewModesExtra = TargetUser.Nick
                  End If
                  CurParam = CurParam + 1
                End If
              End If
            Else
              SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
            End If
          Case cmOp
            If UserPrivs > 1 Then
              If CurParam <= NumParams Then
                If CurParam > 1 Then
                  Set TargetUser = GlobUsers(parv(CurParam))
                  If TargetUser Is Nothing Then
                    SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(CurParam), Chan.Name)
                    GoTo NextMode
                  End If
                  If TargetUser.IsLProtected Then
                    If Not (cptr.IsLProtected Or cptr.IsProtected Or cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  If TargetUser.IsProtected Then
                    If Not (cptr.IsProtected Or cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  If TargetUser.IsNetAdmin Then
                    If Not (cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  Select Case MSwitch
                    Case True
                      GenerateEvent "MEMBER", "MODE", Replace(TargetUser.Prefix, ":", ""), Chan.Name & " " & Replace(TargetUser.Prefix, ":", "") & " +o " & Replace(cptr.Prefix, ":", "")
                      'the following line notifies the clients in an auditorium that this person exists
                      If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendToChanNotOps Chan, TargetUser.Prefix & " JOIN :" & Chan.Name, TargetUser.Nick
                      If Chan.IsAuditorium And Not (Chan.Member.Item(TargetUser.Nick).IsOp) Then
                        If Not (Chan.Member.Item(TargetUser.Nick).IsOwner) Then
                          'don't tell the TargetUser about it if they're not an owner
                          'they'll get told later
                          SendToChanNotOps Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & TargetUser.Nick, TargetUser.Nick
                          ShowAudStuff = True
                          Set ShowAudStuffClnt = TargetUser
                        Else
                          SendToChanNotOps Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & TargetUser.Nick, 0
                        End If
                      End If
                    Case False
                      GenerateEvent "MEMBER", "MODE", Replace(TargetUser.Prefix, ":", ""), Chan.Name & " " & Replace(TargetUser.Prefix, ":", "") & " -o " & Replace(cptr.Prefix, ":", "")
                      'in an auditorium, if the user is no longer +q/+o, they "leave"
                      'tell the people the person was just -o'ed
                      If Chan.IsAuditorium And (Chan.Member.Item(TargetUser.Nick).IsOp) Then SendToChanNotOps Chan, cptr.Prefix & " MODE " & Chan.Name & " -o " & TargetUser.Nick, 0
                  End Select
                  Chan.Member.Item(TargetUser.Nick).IsOp = MSwitch
                  NewModes = NewModes & "o"
                  
                  'the following line is used to tell the person they've been deopped
                  'in case they won't see the message
                  If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendWsock TargetUser.index, "MODE", Chan.Name & " -o " & TargetUser.Nick, cptr.Prefix
                  'tell the user the gig is up!
                  If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendToChanNotOps Chan, TargetUser.Prefix & " PART " & Chan.Name, TargetUser.Nick
                  
                  'hide the clients
                  If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then
                    HideAudStuff = True
                    Set HideAudStuffClnt = TargetUser
                  End If
                  
                  If Len(NewModesExtra) > 0 Then
                    NewModesExtra = NewModesExtra & " " & TargetUser.Nick
                  Else
                    NewModesExtra = TargetUser.Nick
                  End If
                  CurParam = CurParam + 1
                End If
              End If
            Else
              SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
            End If
          Case cmOwner
            If UserPrivs > 3 Then
              If CurParam <= NumParams Then
                If CurParam > 1 Then
                  Set TargetUser = GlobUsers(parv(CurParam))
                  If TargetUser Is Nothing Then
                    SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(CurParam), Chan.Name)
                    GoTo NextMode
                  End If
                  If TargetUser.IsLProtected Then
                    If Not (cptr.IsLProtected Or cptr.IsProtected Or cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  If TargetUser.IsProtected Then
                    If Not (cptr.IsProtected Or cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  If TargetUser.IsNetAdmin Then
                    If Not (cptr.IsNetAdmin) Then
                      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                      GoTo NextMode
                    End If
                  End If
                  'continue...
                  #If Debugging = 1 Then
                    SendSvrMsg "m_mode -> owner -> processing"
                  #End If
                  Select Case MSwitch
                    Case True
                      #If Debugging = 1 Then
                        SendSvrMsg "m_mode -> owner -> +q, sending event"
                      #End If
                      GenerateEvent "MEMBER", "MODE", Replace(TargetUser.Prefix, ":", ""), Chan.Name & " " & Replace(TargetUser.Prefix, ":", "") & " +q " & Replace(cptr.Prefix, ":", "")
                      #If Debugging = 1 Then
                        SendSvrMsg "m_mode -> owner -> +q, auditorium, sending join"
                      #End If
                      If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendToChanNotOps Chan, TargetUser.Prefix & " JOIN :" & Chan.Name, TargetUser.Nick
                      #If Debugging = 1 Then
                        SendSvrMsg "m_mode -> owner -> +q, auditorium, choosing +o/+q"
                      #End If
                      If Chan.IsAuditorium And Not (Chan.Member.Item(TargetUser.Nick).IsOwner) Then
                        If Not (Chan.Member.Item(TargetUser.Nick).IsOp) Then
                          'don't tell the TargetUser about it if they're not a host
                          'they'll get told later
                          #If Debugging = 1 Then
                            SendSvrMsg "m_mode -> owner -> +q, auditorium, sending +o/+q excl. user"
                          #End If
                          SendToChanNotOps1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & TargetUser.Nick, TargetUser.Nick
                          SendToChanNotOpsIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & TargetUser.Nick, TargetUser.Nick
                          #If Debugging = 1 Then
                            SendSvrMsg "m_mode -> owner -> +q, auditorium, sent excl. user"
                          #End If
                          ShowAudStuff = True
                          #If Debugging = 1 Then
                            SendSvrMsg "m_mode -> owner -> +q, auditorium, assigned ShowAudStuff"
                          #End If
                          Set ShowAudStuffClnt = TargetUser
                          #If Debugging = 1 Then
                            SendSvrMsg "m_mode -> owner -> +q, auditorium, assigned ShowAudStuffClnt"
                          #End If
                        Else
                          #If Debugging = 1 Then
                            SendSvrMsg "m_mode -> owner -> +q, auditorium, choosing +o/+q incl. user"
                          #End If
                          SendToChanNotOps1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & TargetUser.Nick, 0
                          SendToChanNotOpsIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & TargetUser.Nick, 0
                        End If
                      End If
                    Case False
                      #If Debugging = 1 Then
                        SendSvrMsg "m_mode -> owner -> -q, sending event"
                      #End If
                      GenerateEvent "MEMBER", "MODE", Replace(TargetUser.Prefix, ":", ""), Chan.Name & " " & Replace(TargetUser.Prefix, ":", "") & " -q " & Replace(cptr.Prefix, ":", "")
                      If Chan.IsAuditorium And (Chan.Member.Item(TargetUser.Nick).IsOp) Then SendToChanNotOps Chan, cptr.Prefix & " MODE " & Chan.Name & " -q " & TargetUser.Nick, 0
                  End Select
                  #If Debugging = 1 Then
                    SendSvrMsg "m_mode -> owner -> setting MSwitch"
                  #End If
                  Chan.Member.Item(TargetUser.Nick).IsOwner = MSwitch
                  NewModes = NewModes & "q"
                  
                  'the following line is used to tell the person they've been deopped
                  'in case they won't see the message
                  If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendWsock TargetUser.index, "MODE", Chan.Name & " -q " & TargetUser.Nick, cptr.Prefix
                  'tell the user the gig is up!
                  If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then SendToChanNotOps Chan, TargetUser.Prefix & " PART " & Chan.Name, TargetUser.Nick
                  
                  'hide the clients
                  If Chan.IsAuditorium And Not ((Chan.Member.Item(TargetUser.Nick).IsOwner) Or (Chan.Member.Item(TargetUser.Nick).IsOp)) Then
                    HideAudStuff = True
                    Set HideAudStuffClnt = TargetUser
                  End If
                  
                  If Len(NewModesExtra) > 0 Then
                    NewModesExtra = NewModesExtra & " " & TargetUser.Nick
                  Else
                    NewModesExtra = TargetUser.Nick
                  End If
                  CurParam = CurParam + 1
                End If
              End If
            Else
              SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmLimit
               If UserPrivs > 1 Then
                  Select Case MSwitch
                     Case True
                        If CurParam <= NumParams Then
                           If CurParam > 1 Then
                              Chan.Limit = CLng(MakeNumber(parv(CurParam)))
                              If Chan.Limit > 0 Then
                                NewModes = NewModes & "l"
                                If Len(NewModesExtra) > 0 Then
                                  NewModesExtra = NewModesExtra & " " & Chan.Limit
                                Else
                                  NewModesExtra = Chan.Limit
                                End If
                                GenerateEvent "CHANNEL", "LIMIT", Chan.Name, Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " :" & Chan.Limit
                                CurParam = CurParam + 1
                              End If
                           End If
                        End If
                     Case False
                        Chan.Limit = 0
                        GenerateEvent "CHANNEL", "LIMIT", Chan.Name, Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " :" & Chan.Limit
                        NewModes = NewModes & "l"
                  End Select
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmKey
               If UserPrivs > 1 Then
                  If CurParam <= NumParams Then
                     If CurParam > 1 Then
                        Select Case MSwitch
                           Case True
                              Chan.Key = UTF8_Unescape(parv(CurParam))
                              Chan.Prop_Memberkey = UTF8_Unescape(parv(CurParam))
                              NewModes = NewModes & "k"
                              If Len(NewModesExtra) > 0 Then
                                 NewModesExtra = NewModesExtra & " " & parv(CurParam)
                              Else
                                 NewModesExtra = parv(CurParam)
                              End If
                              GenerateEvent "CHANNEL", "KEYWORD", Chan.Name, Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " :" & Chan.Key
                              CurParam = CurParam + 1
                           Case False
                              If StrComp(Chan.Key, parv(CurParam)) = 0 Then
                                 Chan.Key = vbNullString
                                 Chan.Prop_Memberkey = vbNullString
                                 NewModes = NewModes & "k"
                                 If Len(NewModesExtra) > 0 Then
                                    NewModesExtra = NewModesExtra & " " & parv(CurParam)
                                 Else
                                    NewModesExtra = parv(CurParam)
                                 End If
                                 GenerateEvent "CHANNEL", "KEYWORD", Chan.Name, Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " :" & Chan.Key
                                 CurParam = CurParam + 1
                              End If
                        End Select
                     End If
                  End If
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmBan
               If UserPrivs > 1 Then
                  If CurParam <= NumParams Then
                     If CurParam > 1 Then
                        Select Case MSwitch
                           Case True
                              Mask = CreateMask(parv(CurParam))
                              'store if the user was an owner when he/she adds the entry
                              If Not FindAccessEntry(Chan, Mask, aDeny) Then
                                Set Ban = Nothing
                                If UserPrivs > 3 Then
                                  Chan.Bans.AddX Mask, cptr.Nick, True, UnixTime, 0, vbNullString, Mask
                                Else
                                  Chan.Bans.AddX Mask, cptr.Nick, False, UnixTime, 0, vbNullString, Mask
                                End If
                              End If
                              NewModes = NewModes & "b"
                              If Len(NewModesExtra) > 0 Then
                                NewModesExtra = NewModesExtra & " " & Mask
                              Else
                                NewModesExtra = Mask
                              End If
                              CurParam = CurParam + 1
                           Case False
                              Mask = CreateMask(parv(CurParam))
                              
                              If FindAccessEntry(Chan, Mask, aDeny) Then
                                If UserPrivs > 3 Then
                                  If RemoveAccessEntry(Chan, Mask, aDeny, True) Then
                                    NewModes = NewModes & "b"
                                    If Len(NewModesExtra) > 0 Then
                                      NewModesExtra = NewModesExtra & " " & Mask
                                    Else
                                      NewModesExtra = Mask
                                    End If
                                  End If
                                Else
                                  'if you're not an owner, pass false to this function
                                  If RemoveAccessEntry(Chan, Mask, aDeny, False) Then
                                    NewModes = NewModes & "b"
                                    If Len(NewModesExtra) > 0 Then
                                      NewModesExtra = NewModesExtra & " " & Mask
                                    Else
                                      NewModesExtra = Mask
                                    End If
                                  End If
                                End If
                              End If
                              'increase this even if we ignored this +b
                              CurParam = CurParam + 1
                        End Select
                     Else
                        'get bans (CurParam = 1, therefore there was only one param)
                        For x = 1 To Chan.Bans.Count
                          SendWsock cptr.index, SPrefix & " " & RPL_BANLIST & " " & cptr.Nick & " " & Chan.Name & " " & Chan.Bans(x).Mask & " " & Chan.Bans(x).SetBy & " " & Chan.Bans(x).SetOn, vbNullString, , True
                        Next x
                        SendWsock cptr.index, SPrefix & " " & RPL_ENDOFBANLIST & " " & cptr.Nick & " " & Chan.Name & " :End of Channel Ban List", vbNullString, , True
                     End If
                  End If
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmSecret
               If UserPrivs > 1 Then
                  If Chan.IsHidden Then
                    If WasHidden Then SendHiddenRemove = True
                    If WasPrivate Then SendPrivateRemove = True
                  End If
                  If Chan.IsPrivate Then
                    If WasPrivate Then SendPrivateRemove = True
                    If WasHidden Then SendHiddenRemove = True
                  End If
                  SendSecretRemove = False
                  Chan.IsSecret = MSwitch
                  If MSwitch = False Then UnsetSecret = True
                  Chan.IsHidden = False
                  Chan.IsPrivate = False
                  NewModes = NewModes & " s "
               Else
                SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmPrivate
               If UserPrivs > 1 Then
                  If Chan.IsHidden Then
                    If WasHidden Then SendHiddenRemove = True
                    If WasSecret Then SendSecretRemove = True
                  End If
                  If Chan.IsSecret Then
                    If WasSecret Then SendSecretRemove = True
                    If WasHidden Then SendHiddenRemove = True
                  End If
                  SendPrivateRemove = False
                  Chan.IsPrivate = MSwitch
                  If MSwitch = False Then UnsetPrivate = True
                  Chan.IsHidden = False
                  Chan.IsSecret = False
                  NewModes = NewModes & " p "
               Else
                SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmHidden
               If UserPrivs > 1 Then
                  If Chan.IsPrivate Then
                    If WasPrivate Then SendPrivateRemove = True
                    If WasSecret Then SendSecretRemove = True
                  End If
                  If Chan.IsSecret Then
                    If WasSecret Then SendSecretRemove = True
                    If WasPrivate Then SendPrivateRemove = True
                  End If
                  SendHiddenRemove = False
                  Chan.IsHidden = MSwitch
                  If MSwitch = False Then UnsetHidden = True
                  Chan.IsPrivate = False
                  Chan.IsSecret = False
                  NewModes = NewModes & " h "
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmInviteOnly
               If UserPrivs > 1 Then
                  Chan.IsInviteOnly = MSwitch
                  NewModes = NewModes & "i"
               Else
                SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmModerated
               If UserPrivs > 1 Then
                  Chan.IsModerated = MSwitch
                  NewModes = NewModes & "m"
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmKnock
               If UserPrivs > 1 Then
                  Chan.IsKnock = MSwitch
                  NewModes = NewModes & "u"
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmNoExternalMsg
               If UserPrivs > 1 Then
                  Chan.IsNoExternalMsgs = MSwitch
                  NewModes = NewModes & "n"
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmOpTopic
               If UserPrivs > 1 Then
                  Chan.IsTopicOps = MSwitch
                  NewModes = NewModes & "t"
               Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
               End If
            Case cmOperOnly
               If cptr.IsNetAdmin Or cptr.IsGlobOperator Then
                  Chan.IsOperOnly = MSwitch
                  NewModes = NewModes & "O"
               Else
                  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
               End If
            Case cmCloneable
              If cptr.IsNetAdmin Or cptr.IsGlobOperator Then
                  If Not Chan.IsClone Then
                    'not a clone, proceed
                    Chan.IsCloneable = MSwitch
                    NewModes = NewModes & "d"
                  Else
                    'already a clone, fail
                    SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, "+d", Chan.Name)
                  End If
              Else
                  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
              End If
            Case cmPersistant
               If RegChanMode_ModeR Then
                  If cptr.IsNetAdmin Or cptr.IsGlobOperator Then
                     Chan.IsPersistant = MSwitch
                     NewModes = NewModes & "R"
                  Else
                     SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                  End If
               Else
                  Select Case MSwitch
                     Case True
                        SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, "+R", Chan.Name)
                     Case False
                        SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, "-R", Chan.Name)
                  End Select
               End If
            Case Else
               Select Case MSwitch
                  Case True
                     SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, "+" & Chr(CurMode), Chan.Name)
                  Case False
                     SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, "-" & Chr(CurMode), Chan.Name)
               End Select
        End Select
NextMode:
      Next A
    End If
NextChan:
    GoTo Flush
  Else
    'not a channel
    'so we change user modes!
    Dim NModes As String
    Set Target = GlobUsers(parv(0))
    If Target Is Nothing Then
        SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
        Exit Function
    End If
    'allow opers to change other people's modes
    If Not (cptr Is Target) And Not ((cptr.IsLocOperator) Or (cptr.IsGlobOperator)) Then
        SendWsock cptr.index, ERR_USERSDONTMATCH, cptr.Nick & " " & TranslateCode(ERR_USERSDONTMATCH)
        Exit Function
    End If
    'okay not change ALL of them...
    'let them get them at least
    If UBound(parv) = 0 Then
        If cptr Is Target Then
          SendWsock cptr.index, SPrefix & " 221 " & cptr.Nick & " +" & cptr.GetModes, vbNullString, , True
        Else
          SendWsock cptr.index, SPrefix & " 221 " & Target.Nick & " +" & Target.GetModes, vbNullString, , True
        End If
        Exit Function
    End If
    
    'ah hell with it.. just let them set gag! (unless it's their own nick)
    'TODO: Make the <> crap be StrComp's
    
    If Not (cptr Is Target) And (cptr.IsLocOperator Or cptr.IsGlobOperator) And ((parv(1) <> "+z") And (parv(1) <> "-z")) Then
        SendWsock cptr.index, ERR_USERSDONTMATCH, cptr.Nick & " " & TranslateCode(ERR_USERSDONTMATCH)
        Exit Function
    End If

    'now to decide if the first char is + or -
    m_mode = AscW(Left(parv(1), 1))
    
    If m_mode <> modeAdd Then
        If m_mode <> modeRemove Then
            Exit Function
        End If
    End If
    
    op = vbNullString
    
    For i = 1 To Len(parv(1))
        Mask = Mid$(parv(1), i, 1)
        Select Case AscW(Mask)
            Case modeAdd
                MSwitch = True
                op = op & Mask
            Case modeRemove
                MSwitch = False
                op = op & Mask
            Case umInvisible
                If Not cptr.IsInvisible = MSwitch Then
                    cptr.IsInvisible = MSwitch
                    op = op & Mask
                End If
            Case umLocOper
                If MSwitch = False Then
                    If cptr.IsLocOperator Or cptr.IsGlobOperator Then
                        Dim WasGlob As Boolean
                        WasGlob = cptr.IsGlobOperator
                        cptr.IsLocOperator = False
                        cptr.IsGlobOperator = False
                        Opers.Remove cptr.GUID
                        cptr.AccessLevel = 1
                        op = op & Mask & IIf(WasGlob, "O", "")
                    End If
                End If
            Case umGlobOper
                If MSwitch = False And cptr.IsGlobOperator Then
                    cptr.IsGlobOperator = False
                    op = op & Mask
                End If
            Case umGagged
                If (cptr.IsLocOperator Or cptr.IsGlobOperator) And (Not cptr Is Target) Then
                  Target.IsGagged = MSwitch
                  op = op & Mask
                End If
            Case umLProtected
                If cptr.IsNetAdmin Or (cptr.IsLProtected And MSwitch = False) Then
                  cptr.IsLProtected = MSwitch
                  op = op & Mask
                End If
            Case umProtected
                If cptr.IsNetAdmin Or (cptr.IsProtected And MSwitch = False) Then
                  cptr.IsProtected = MSwitch
                  op = op & Mask
                End If
            Case umServerMsg
                If Not cptr.IsServerMsg = MSwitch Then
                    cptr.IsServerMsg = MSwitch
                    op = op & Mask
                    If MSwitch Then
                        ServerMsg.Add cptr.GUID, cptr
                    Else
                        ServerMsg.Remove cptr.GUID
                    End If
                End If
             Case umWallOps
                If Not cptr.GetsWallops = MSwitch Then
                    cptr.GetsWallops = MSwitch
                    op = op & Mask
                    If MSwitch Then
                        WallOps.Add cptr.GUID, cptr
                    Else
                        WallOps.Remove cptr.GUID
                    End If
                End If
            'contributed patch, modified because it's a little wrong
            Case umCanRehash
                If MSwitch = False And cptr.CanRehash = True Then
                    cptr.CanRehash = False
                    op = op & Mask
                End If
            Case umLocKills
                If MSwitch = False And cptr.CanLocKill = True Then
                    'TODO: decide whether or not to make removing local kill capabilities also kill global kills
                    op = op & Mask
                    cptr.CanLocKill = False
                End If
            Case umGlobKills
                If MSwitch = False And cptr.CanGlobKill = True Then
                    op = op & Mask
                    cptr.CanGlobKill = False
                End If
            Case umCanUnKline
                If MSwitch = False And cptr.CanUnkline = True Then
                    op = op & Mask
                    cptr.CanUnkline = False
                End If
            '</contributed-patch>
            '<in-addition-to-contributed-patch>
            Case umCanKline
                If MSwitch = False And cptr.CanKline = True Then
                    op = op & Mask
                    cptr.CanKline = False
                End If
            '</in-addition-to-contributed-patch>
        End Select
    Next i
    If Len(op) > 1 Then
        If InStr(1, op, "z") Then
          'obviously, we deny normal users from setting +z on themselves
          'and opers can't set +z on themselves (how stupid would that be)
          'this modechange was forced upon Target, not cptr!
          GenerateEvent "USER", "MODE", Replace(Target.Prefix, ":", ""), Replace(Target.Prefix, ":", "") & " " & op
          If ShowGag Then SendWsock Target.index, "MODE " & Target.Nick, op, cptr.Prefix 'notify the one being gagged
          SendWsock cptr.index, "MODE " & Target.Nick, op, cptr.Prefix  'notify the gagger
          SendToServer "MODE " & Target.Nick & " " & op, cptr.Nick
        Else
          GenerateEvent "USER", "MODE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & op
          SendWsock cptr.index, "MODE " & cptr.Nick, op, cptr.Prefix
          SendToServer "MODE " & cptr.Nick & " " & op, cptr.Nick
        End If
    End If
  End If
End If
Exit Function

Flush:
'finish the job :)

'basically, the if auditorium business makes sure that only the clients who can see everyone see the mode change
If SendHiddenRemove Then
  If Chan.IsAuditorium Then
    SendToChanOps Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " -h", 0
  Else
    SendToChan Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " -h", 0
  End If
  SendToServer "MODE " & Chan.Name & " -h", cptr.Nick
  GenerateEvent "CHANNEL", "MODE", Chan.Name, Chan.Name & " -h " & Replace(cptr.Prefix, ":", "")
End If
If SendSecretRemove Then
  If Chan.IsAuditorium Then
    SendToChanOps Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " -s", 0
  Else
    SendToChan Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " -s", 0
  End If
  SendToServer "MODE " & Chan.Name & " -s", cptr.Nick
  GenerateEvent "CHANNEL", "MODE", Chan.Name, Chan.Name & " -s " & Replace(cptr.Prefix, ":", "")
End If
If SendPrivateRemove Then
  If Chan.IsAuditorium Then
    SendToChanOps Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " -p", 0
  Else
    SendToChan Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " -p", 0
  End If
  SendToServer "MODE " & Chan.Name & " -p", cptr.Nick
  GenerateEvent "CHANNEL", "MODE", Chan.Name, Chan.Name & " -p " & Replace(cptr.Prefix, ":", "")
End If

'and now, the final round!
'ugly hack
'ignore it

If Chan.IsSecret Then
  NewModes = Replace(NewModes, " s ", "s")
Else
  If UnsetSecret Then
    NewModes = Replace(NewModes, " s ", "s")
  Else
    NewModes = Replace(NewModes, " s ", "")
  End If
End If

If Chan.IsHidden Then
  NewModes = Replace(NewModes, " h ", "h")
Else
  If UnsetHidden Then
    NewModes = Replace(NewModes, " h ", "h")
  Else
    NewModes = Replace(NewModes, " h ", "")
  End If
End If

If Chan.IsPrivate Then
  NewModes = Replace(NewModes, " p ", "p")
Else
  If UnsetPrivate Then
    NewModes = Replace(NewModes, " p ", "p")
  Else
    NewModes = Replace(NewModes, " p ", "")
  End If
End If

If Len(NewModes) > 1 Then
  
  x = 0
  'filter erroneous mode set/unset chars
  For A = Len(NewModes) To 2 Step -1
    If Mid$(NewModes, A, 1) = "+" Then
      x = x + 1
    ElseIf Mid$(NewModes, A, 1) = "-" Then
      x = x + 1
    Else
      Exit For
    End If
  Next A
  
  If x > 0 Then NewModes = Left(NewModes, Len(NewModes) - x)
  If Len(NewModesExtra) > 0 Then
    If Chan.IsAuditorium Then
      SendToChanOpsIRCX Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & NewModes & " " & NewModesExtra, 0
      SendToChanOps1459 Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & Replace(NewModes, "q", "o") & " " & NewModesExtra, 0
    Else
      SendToChanIRCX Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & NewModes & " " & NewModesExtra, 0
      SendToChan1459 Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & Replace(NewModes, "q", "o") & " " & NewModesExtra, 0
    End If
    SendToServer "MODE " & Chan.Name & " " & NewModes & " " & NewModesExtra, cptr.Nick
  Else
    If Chan.IsAuditorium Then
      SendToChanOpsIRCX Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & NewModes, 0
      SendToChanOps1459 Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & Replace(NewModes, "q", "o"), 0
    Else
      SendToChanIRCX Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & NewModes, 0
      SendToChan1459 Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & Replace(NewModes, "q", "o"), 0
    End If
    SendToServer "MODE " & Chan.Name & " " & NewModes, cptr.Nick
  End If
  GenerateEvent "CHANNEL", "MODE", Chan.Name, Chan.Name & " " & NewModes & " " & Replace(cptr.Prefix, ":", "")
End If

If ShowAudStuff = True Then
  If Not ShowAudStuffClnt Is Nothing Then
    AuditoriumShowClients Chan, ShowAudStuffClnt
  End If
End If
If HideAudStuff = True Then
  If Not HideAudStuffClnt Is Nothing Then
    AuditoriumHideClients Chan, HideAudStuffClnt
  End If
End If
End Function
'/*
'** m_join
'**  parv$()[0] = sender prefix
'**  parv$()[1] = channel
'**  parv$()[2] = channel password (key)
'*/
Public Function m_join(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "JOIN called! (" & cptr.Nick & ")"
#End If

On Error GoTo err
Dim Chan As clsChannel, x&, y$(), A, Names$(0), OnJoinS$(), B&
Dim fake_param(1) As String

Dim CurrentInfo As String
CurrentInfo = "entry"
'x being the counter-var for notifying users someone joined -Dill
'y is an array of chan's to join -Dill
'a is used in the for...each loop -Dill
'p is an array which tell m_part what chan to part at a time in case 0 is 'joined' -Dill
If cptr.AccessLevel = 4 Then
  CurrentInfo = "server join"
  y = Split(parv(0), ",") 'just in case it wants to join several channels -Dill
  For Each A In y
    'if invalid channel name or user already on channel then bounce
    If AscW(CStr(A)) <> 35 Then
        SendWsock cptr.index, "PART", CStr(A), ":" & sptr.Nick
        GoTo NextChannel
    End If
    Set Chan = Channels(CStr(A))
    If Chan Is Nothing Then
      'the channel sptr wants to join doesn't exist, so we create it -Dill
      Set Chan = Channels.Add(CStr(A), New clsChannel)
      Chan.Name = A
      Chan.Prop_Name = A
      Chan.Member.Add ChanOwner, sptr
      cptr.OnChannels.Add Chan, Chan.Name
      Chan.IsNoExternalMsgs = True
      Chan.IsTopicOps = True
      If LogChannels = True Then Chan.IsMonitored = True
      GenerateEvent "CHANNEL", "CREATE", Chan.Name, Chan.Name & " +" & Split(GetModes(Chan), " ")(0) & " " & Replace(sptr.Prefix, ":", "")
      GenerateEvent "MEMBER", "JOIN", Replace(sptr.Prefix, ":", ""), Chan.Name & " " & Replace(sptr.Prefix, ":", "") & " +q"
      If LogChannels Then LogChannel Chan.Name, "*** " & sptr.Nick & " has created " & Chan.Name
    Else
      sptr.OnChannels.Add Chan, Chan.Name
      Chan.Member.Add ChanNormal, sptr
      GenerateEvent "MEMBER", "JOIN", Replace(sptr.Prefix, ":", ""), Chan.Name & " " & Replace(sptr.Prefix, ":", "") & " +"
      SendToChan Chan, sptr.Prefix & " JOIN :" & Chan.Name, 0
      SendToServer_ButOne "JOIN " & Chan.Name, cptr.ServerName, sptr.Nick
      If LogChannels Then LogChannel Chan.Name, "*** " & sptr.Nick & " has joined " & Chan.Name
    End If
NextChannel:
  Next
Else
  CurrentInfo = "client join"
  Dim StrCache$
  If Len(parv(0)) = 0 Then    'oops, client forgot to tell us which channel it wanted to join -Dill
    CurrentInfo = "need more parameters"
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "JOIN")
    Exit Function
  End If
  If MaxChannelsPerUser > 0 Then
    If cptr.OnChannels.Count >= MaxChannelsPerUser Then
        CurrentInfo = "too many channels"
        SendWsock cptr.index, ERR_TOOMANYCHANNELS & " " & cptr.Nick, TranslateCode(ERR_TOOMANYCHANNELS, , parv(0))
        Exit Function
    End If
  End If
  y = Split(parv(0), ",") 'just in case it wants to join several channels -Dill
  For Each A In y
    CurrentInfo = "multi join"
    StrCache = A
    
    'The following bit of code is a pain in the ass, - Ziggy
    If StrCache = "0" Then  '#0 means part all -Dill
                            'No, it doesn't (#0 is a perfectly legitimate chan name) - Ziggy
      fake_param(1) = "" 'this would be the part msg (leaving null -- should have an X: line for it or something) -Z
      Do While cptr.OnChannels.Count > 0
        fake_param(0) = cptr.OnChannels.Item(cptr.OnChannels.Count).Name
        m_part cptr, cptr, fake_param
        'cptr.OnChannels.Remove 1
        'doesn't m_part do this already?
      Loop
      GoTo NextChan
    End If
    
    If MaxChannelsPerUser > 0 Then
        If cptr.OnChannels.Count >= MaxChannelsPerUser Then
            CurrentInfo = "too many channels"
            SendWsock cptr.index, ERR_TOOMANYCHANNELS & " " & cptr.Nick, TranslateCode(ERR_TOOMANYCHANNELS, , StrCache)
            GoTo NextChan
        End If
    End If
    
    'If AscW(StrCache) <> 35 And AscW(StrCache) <> 48 Then 'note: % = 37, 0 = 48; add % soon - Ziggy
    If AscW(StrCache) <> 35 Then 'use this for now
        CurrentInfo = "no such channel"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , StrCache)
        GoTo NextChan
    End If
    'reordered this
    'TODO: better error message for this
    If Len(StrCache) < 2 Then 'cant have a "blank" room name -Airwalk
        CurrentInfo = "channel name null"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , StrCache)
        Exit Function
    End If
    If InStr(1, StrCache, "*") > 0 Then
        CurrentInfo = "illegal channel name"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , StrCache)
        Exit Function
    End If
    If InStr(1, StrCache, "?") > 0 Then
        CurrentInfo = "illegal channel name"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , StrCache)
        Exit Function
    End If
    If InStr(1, StrCache, Chr(7)) > 0 Then
        CurrentInfo = "illegal channel name"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , StrCache)
        Exit Function
    End If
    If InStr(1, StrCache, ",") > 0 Then
        CurrentInfo = "illegal channel name"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , StrCache)
        Exit Function
    End If
    CurrentInfo = "setting up chan (exist/nonexist?)"
    If cptr.IsOnChan(StrCache) Then GoTo NextChan
    CurrentInfo = "setting up chan (exist/nonexist?)1"
    Set Chan = Channels(StrCache)
    CurrentInfo = "setting up chan (exist/nonexist?)2"
    If Chan Is Nothing Then
      CurrentInfo = "channel does not exist"
      'the channel cptr wants to join doesn't exist, so we create it -Dill
      'but not if the server admin doesn't want them to -zg
      If CreateMode = 1 Then
        If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
          SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
          Exit Function
        End If
      ElseIf CreateMode = 2 Then
        If Not ((cptr.IsLocOperator Or cptr.IsGlobOperator) Or (cptr.IsRegistered)) Then
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          Exit Function
        End If
      End If
      Set Chan = Channels.Add(StrCache, New clsChannel)
      Chan.Name = StrCache
      Chan.Prop_Creation = UnixTime
      Chan.Prop_Name = StrCache
      Chan.Member.Add ChanOwner, cptr
      cptr.OnChannels.Add Chan, Chan.Name
      Chan.IsNoExternalMsgs = True
      Chan.IsTopicOps = True
      If LogChannels = True Then Chan.IsMonitored = True
      SendWsock cptr.index, cptr.Prefix & " JOIN :" & StrCache, vbNullString, , True
      If cptr.IsIRCX Then
        SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & StrCache, ":" & Level_Owner & cptr.Nick
      Else
        SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & StrCache, ":" & Level_Host & cptr.Nick
      End If
      SendWsock cptr.index, SPrefix & " " & RPL_ENDOFNAMES & " " & cptr.Nick & " " & Chan.Name & " :End of /NAMES list.", vbNullString, , True
      GenerateEvent "CHANNEL", "CREATE", Chan.Name, Chan.Name & " +" & Split(GetModes(Chan), " ")(0) & " " & Replace(cptr.Prefix, ":", "")
      GenerateEvent "MEMBER", "JOIN", Replace(cptr.Prefix, ":", ""), Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " +q"
      SendToServer "JOIN " & Chan.Name, cptr.Nick
      If LogChannels Then LogChannel Chan.Name, "*** " & cptr.Nick & " has created " & Chan.Name
    Else
      Call CycleAccess(Chan)
      CurrentInfo = "channel exists"
      'Is it Oper Only? - DG
      CurrentInfo = "channel exists - Oper Only Check"
      If Chan.IsOperOnly = True Then
        CurrentInfo = "Channel oper only checking user"
        If Not (cptr.IsGlobOperator Or cptr.IsLocOperator) Then
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            If Chan.IsKnock Then
              SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :Cannot join (not an IRC Operator)", 0
              SendToServer "KNOCK " & Chan.Name & " :Cannot join (not an IRC Operator)", cptr.Nick
            End If
            Exit Function
        End If
      End If
      'Is cptr banned? -Dill
      If IsBanned(Chan, cptr) And Not ((IsHosted(Chan, cptr) Or IsOwnered(Chan, cptr)) Or (cptr.IsProtected Or cptr.IsLProtected)) Then
          If UBound(parv) > 0 Then
            If UTF8_Unescape(parv(1)) = Chan.Prop_Ownerkey And Len(Chan.Prop_Ownerkey) > 0 Then
              CurrentInfo = "banned, ownerkey"
              GoTo pastban
            End If
            If UTF8_Unescape(parv(1)) = Chan.Prop_Hostkey And Len(Chan.Prop_Hostkey) > 0 And Chan.Member.Item(cptr.Nick).IsOwner = False Then
              CurrentInfo = "banned, hostkey"
              GoTo pastban
            End If
            If UTF8_Unescape(parv(1)) = Chan.Prop_Memberkey And Len(Chan.Prop_Memberkey) > 0 Then
              CurrentInfo = "banned, memberkey"
              GoTo pastban
            End If
          End If
          'no good keys specified, sorry :P
          CurrentInfo = "user banned"
          SendWsock cptr.index, ERR_BANNEDFROMCHAN & " " & cptr.Nick & " " & TranslateCode(ERR_BANNEDFROMCHAN, , Chan.Name), vbNullString, SPrefix
          If Chan.IsKnock Then
            SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :User is banned", 0
            SendToServer "KNOCK " & Chan.Name & " :User is banned", cptr.Nick
          End If
          Exit Function
      End If
pastban:
      'is the channel key'ed? -Dill
      If Len(Chan.Key) <> 0 And Not (cptr.IsProtected Or cptr.IsLProtected) Then
        CurrentInfo = "channel locked"
        'if they have the ownerkey, or hostkey, let them in
        If UBound(parv) > 0 Then
          If StrComp(UTF8_Unescape(parv(1)), Chan.Key) <> 0 And StrComp(UTF8_Unescape(parv(1)), Chan.Prop_Hostkey) <> 0 And StrComp(UTF8_Unescape(parv(1)), Chan.Prop_Ownerkey) <> 0 Then
            CurrentInfo = "invalid key"
            SendWsock cptr.index, ERR_BADCHANNELKEY & " " & cptr.Nick & " " & TranslateCode(ERR_BADCHANNELKEY, , Chan.Name), vbNullString, SPrefix
            If Chan.IsKnock Then
              SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :Invalid channel key", 0
              SendToServer "KNOCK " & Chan.Name & " :Invalid channel key", cptr.Nick
            End If
            Exit Function
          End If
        Else
          CurrentInfo = "invalid key"
          SendWsock cptr.index, ERR_BADCHANNELKEY & " " & cptr.Nick & " " & TranslateCode(ERR_BADCHANNELKEY, , Chan.Name), vbNullString, SPrefix
          If Chan.IsKnock Then
            SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :Channel is password-protected", 0
            SendToServer "KNOCK " & Chan.Name & " :Channel is password-protected", cptr.Nick
          End If
          Exit Function
        End If
      End If
      'is it invite-only? -Dill
      If Chan.IsInviteOnly And Not (cptr.IsProtected Or cptr.IsLProtected) Then
        CurrentInfo = "invite only"
        'is the user on the invite list? -Dill
        If Chan.IsInvited(cptr.Nick) = False Then
            CurrentInfo = "not invited"
            SendWsock cptr.index, ERR_INVITEONLYCHAN & " " & cptr.Nick & " " & TranslateCode(ERR_INVITEONLYCHAN, , Chan.Name), vbNullString, SPrefix
            If Chan.IsKnock Then
              SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :User is not invited to channel", 0
              SendToServer "KNOCK " & Chan.Name & " :User is not invited to channel", cptr.Nick
            End If
            Exit Function
        End If
      End If
      
      'for security, this is the last cannot join failure a user could encounter
      'if they have no access to the chan, they have no business knowing if it's full or not
      Dim HideSJoin As Boolean 'for clone
      HideSJoin = False
      
      If Chan.Limit > 0 And Not (cptr.IsLProtected Or cptr.IsProtected) Then
        If Chan.Member.Count >= Chan.Limit Then
          CurrentInfo = "channel full"
          
          'check if the channel is cloneable
          If Chan.IsCloneable Then
            'create a clone, exit function
            Dim CloneChan As clsChannel
            Dim CheckChan As clsChannel
            Dim c As Long
            
            'see which clone the user can validly join next
            For c = 1 To 99
              If Len(Chan.Prop_ParentName) = 0 Then
                'parent channels have no ParentName set
                'thusly, we have to base CheckChan on Chan.Name
                Set CheckChan = Channels(Chan.Name & c)
              Else
                'ParentName is filled in, we don't want to end up
                'with channel names like #TheLobby991 or whatever
                'this is of course a race condition, but just to be safe
                Set CheckChan = Channels(Chan.Prop_ParentName & c)
              End If
              If CheckChan Is Nothing Then
                'CheckChan doesn't exist, create it and join!
                Set CloneChan = Channels.Add(Chan.Name & c, New clsChannel)
                CloneChan.Name = Chan.Name & c
                CloneChan.Prop_Name = Chan.Name & c
                
                'sync the modes
                CloneChan.IsClone = True
                CloneChan.IsAuditorium = Chan.IsAuditorium
                CloneChan.IsHidden = Chan.IsHidden
                CloneChan.IsInviteOnly = Chan.IsInviteOnly
                CloneChan.IsKnock = Chan.IsKnock
                CloneChan.IsModerated = Chan.IsModerated
                CloneChan.IsNoExternalMsgs = Chan.IsNoExternalMsgs
                CloneChan.IsOperOnly = Chan.IsOperOnly
                CloneChan.IsPersistant = Chan.IsPersistant
                CloneChan.IsPrivate = Chan.IsPrivate
                CloneChan.IsRegistered = Chan.IsRegistered 'should this REALLY be synced too?
                CloneChan.IsSecret = Chan.IsSecret
                CloneChan.IsTopicOps = Chan.IsTopicOps
                CloneChan.Limit = Chan.Limit
                
                'sync the keys
                CloneChan.Key = Chan.Key
                CloneChan.Prop_Hostkey = Chan.Prop_Hostkey
                CloneChan.Prop_Memberkey = Chan.Prop_Memberkey
                CloneChan.Prop_Ownerkey = Chan.Prop_Ownerkey
                
                'sync the access lists
                CurrentInfo = "syncing access lists"
                Call CopyAccess(Chan, CloneChan)
                
                'sync properties
                CurrentInfo = "syncing properties"
                CloneChan.Topic = Chan.Topic
                CloneChan.TopcSetAt = Chan.TopcSetAt
                CloneChan.TopicSetBy = Chan.TopicSetBy
                CloneChan.Prop_Account = Chan.Prop_Account
                CloneChan.Prop_Client = Chan.Prop_Client
                CloneChan.Prop_ClientGUID = Chan.Prop_ClientGUID
                CloneChan.Prop_CloneNumber = c
                CloneChan.Prop_Creation = UnixTime 'sync to now
                CloneChan.Prop_Lag = Chan.Prop_Lag
                CloneChan.Prop_Language = Chan.Prop_Language
                CloneChan.Prop_OID = 0
                CloneChan.Prop_OnJoin = Chan.Prop_OnJoin
                CloneChan.Prop_OnPart = Chan.Prop_OnPart
                CloneChan.Prop_ParentName = Chan.Name
                CloneChan.Prop_PICS = Chan.Prop_PICS
                CloneChan.Prop_ServicePath = Chan.Prop_ServicePath
                CloneChan.Prop_Subject = Chan.Prop_Subject
                CloneChan.Prop_Topic = Chan.Prop_Topic
                
                'set the chan to clonechan and finish the function
                SendToChanOpsIRCX Chan, SPrefix & " CLONE " & CloneChan.Name & " 0", 0
                HideSJoin = True
                
                'TODO: send CLONE message to links, handle CLONE message, generate USER.CREATE event
                
                'this is so we don't have to send a -q later
                SendToServer "NJOIN " & CloneChan.Name & " :" & cptr.Nick, ServerName
                SendToServer "NPROP " & CloneChan.Name & " " & CloneChan.Prop_Creation & " " & CloneChan.Prop_OID & " " & _
                ":ACCOUNT=" & UTF8_Escape(CloneChan.Prop_Account, True) & " CLIENT=" & UTF8_Escape(CloneChan.Prop_Client, True) _
                & " HOSTKEY=" & UTF8_Escape(CloneChan.Prop_Hostkey, True) & " LANGUAGE=" & UTF8_Escape(CloneChan.Prop_Language, True) _
                & " MEMBERKEY=" & UTF8_Escape(CloneChan.Prop_Memberkey, True) & " ONJOIN=" & UTF8_Escape(CloneChan.Prop_OnJoin, True) _
                & " ONPART=" & UTF8_Escape(CloneChan.Prop_OnPart, True) & " OWNERKEY=" & UTF8_Escape(CloneChan.Prop_Ownerkey, True) _
                & " SUBJECT=" & UTF8_Escape(CloneChan.Prop_Subject, True) & " TOPIC=" & UTF8_Escape(CloneChan.Prop_Topic, True), ServerName
                SendToServer "MODE " & CloneChan.Name & " +" & GetModes(CloneChan), ServerName
                
                CurrentInfo = "setting chan"
                Set Chan = New clsChannel
                Set Chan = Channels(CloneChan.Name)
                GoTo afterclone
              Else
                'channel exists
                If CheckChan.Member.Count < CheckChan.Limit Then
                  If Not cptr.IsOnChan(CheckChan.Name) Then
                    'this user can safely join this clone
                    Set Chan = New clsChannel
                    Set Chan = Channels(CheckChan.Name)
                    GoTo afterclone
                  Else
                    'need to return error for you're already on channel
                    Exit Function
                  End If
                End If
              End If
            Next c
            'if the loop has completed and we still can't find a suitable channel,
            'it should fall through to the channel is full
          End If
          SendWsock cptr.index, ERR_CHANNELISFULL & " " & cptr.Nick & " " & TranslateCode(ERR_CHANNELISFULL, , Chan.Name), vbNullString, SPrefix
          If Chan.IsKnock Then
            SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :Channel is full (+l)", 0
            SendToServer "KNOCK " & Chan.Name & " :Channel is full (+l)", cptr.Nick
          End If
          Exit Function
        End If
      End If
afterclone:
'we use a goto to go here, because we've set chan to be clonechan
'and we'll process the rest of the crap as if they had joined the original
'channel, except with a different name

      Dim OnJoinFlags As Byte '[QOV]
      'n = 0
      'v = 1
      'o = 2
      'q = 4
      
      
      'the OnJoinModes thing is for the event reply mostly
      
      'cptr is allowed to join the channel, so we let it -Dill
      CurrentInfo = "allowed on channel"
      cptr.OnChannels.Add Chan, Chan.Name
      Chan.Member.Add ChanNormal, cptr
      'Notify all users about the new member -Dill
      If Chan.IsAuditorium Then
        SendToChanOps Chan, cptr.Prefix & " JOIN :" & Chan.Name, 0
        SendWsock cptr.index, "JOIN", ":" & Chan.Name, cptr.Prefix
      Else
        SendToChan Chan, cptr.Prefix & " JOIN :" & Chan.Name, 0
      End If
      
      'we hide this if we've already sent it
      If Not HideSJoin Then SendToServer "JOIN " & Chan.Name, cptr.Nick
      
      'tell cptr about all members of the channel -Dill
      CurrentInfo = "names"
      Names(0) = Chan.Name
      m_names cptr, cptr, Names, True
      If Len(Chan.Topic) > 0 Then 'if there's a topic, tell cptr about it -Dill
        CurrentInfo = "topic"
        SendWsock cptr.index, RPL_TOPIC & " " & cptr.Nick & " " & Chan.Name, ":" & Chan.Topic
        'who set that topic?
        If Chan.TopcSetAt > 0 Then SendWsock cptr.index, RPL_TOPICWHOTIME & " " & Chan.TopicSetBy & " " & Chan.Name & " " & Chan.TopicSetBy & " " & Chan.TopcSetAt, vbNullString
      End If
      'compare ownerkeys and the like
      '(just in case they joined with the key or something)
      CurrentInfo = "keys"
      If UBound(parv) > 0 Then
        If UTF8_Unescape(parv(1)) = Chan.Prop_Ownerkey And Len(Chan.Prop_Ownerkey) > 0 Then
          CurrentInfo = "ownerkey"
          Chan.Member.Item(cptr.Nick).IsOwner = True
          If Chan.IsAuditorium Then
            'if the channel is auditorium, the regular members didn't see this person
            'join the channel
            SendToChanNotOps Chan, cptr.Prefix & " JOIN :" & Chan.Name, 0
          End If
          SendToChanIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
          SendToChan1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
          SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
          OnJoinFlags = OnJoinFlags Or 4
        End If
        If UTF8_Unescape(parv(1)) = Chan.Prop_Hostkey And Len(Chan.Prop_Hostkey) > 0 And Chan.Member.Item(cptr.Nick).IsOwner = False Then
          CurrentInfo = "hostkey"
          Chan.Member.Item(cptr.Nick).IsOp = True
          If Chan.IsAuditorium Then
            'if the channel is auditorium, the regular members didn't see this person
            'join the channel
            SendToChanNotOps Chan, cptr.Prefix & " JOIN :" & Chan.Name, 0
          End If
          SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
          SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
          OnJoinFlags = OnJoinFlags Or 2
        End If
      End If
      CurrentInfo = "oper check - high protection"
      If ((cptr.IsGlobOperator) Or (cptr.IsLocOperator)) And (cptr.IsProtected) Then
        'Protected IRCOps should be auto-owner -Zg
        'They should? I got a better way to fix this... -DG
        'IRC Networks like freenode disagree with the keeping of chanops so we should at least give
        'People the option of what mode is given
        'I concur, but you have to realize that most of our users are pseudo-moronic MSN wannabes -Zg
        If HighProtAsq Then
            Chan.Member.Item(cptr.Nick).IsOwner = True
            OnJoinFlags = OnJoinFlags Or 4
        ElseIf HighProtAso Then
            Chan.Member.Item(cptr.Nick).IsOp = True
            OnJoinFlags = OnJoinFlags Or 2
        ElseIf HighProtAsv Then
            Chan.Member.Item(cptr.Nick).IsVoice = True
            OnJoinFlags = OnJoinFlags Or 1
        End If
      End If
      CurrentInfo = "oper check - low protection"
      If ((cptr.IsGlobOperator) Or (cptr.IsLocOperator)) And (cptr.IsLProtected) Then
        'Low Protection get a different defined level because some want to control other opers
        'Other than themselves differently (e.g. give them +o and admins +q)
        If LowProtAsq Then
            Chan.Member.Item(cptr.Nick).IsOwner = True
            OnJoinFlags = OnJoinFlags Or 4
        ElseIf LowProtAso Then
            Chan.Member.Item(cptr.Nick).IsOp = True
            OnJoinFlags = OnJoinFlags Or 2
        ElseIf LowProtAsv Then
            Chan.Member.Item(cptr.Nick).IsVoice = True
            OnJoinFlags = OnJoinFlags Or 1
        End If
      End If
      If IsOwnered(Chan, cptr) Then
        'is in owner access
        CurrentInfo = "user is ownered"
        Chan.Member.Item(cptr.Nick).IsOwner = True
        OnJoinFlags = OnJoinFlags Or 4
      End If
      If IsHosted(Chan, cptr) Then
        'is in host access
        CurrentInfo = "user is hosted"
        Chan.Member.Item(cptr.Nick).IsOp = True
        OnJoinFlags = OnJoinFlags Or 2
      End If
      If IsVoiced(Chan, cptr) Then
        'is in voice access
        CurrentInfo = "user is voiced"
        Chan.Member.Item(cptr.Nick).IsVoice = True
        OnJoinFlags = OnJoinFlags Or 1
      End If
      
      If Chan.IsAuditorium And (Chan.Member.Item(cptr.Nick).IsOwner Or Chan.Member.Item(cptr.Nick).IsOp) Then
        'if the channel is auditorium, the regular members didn't see this person
        'join the channel
        SendToChanNotOps Chan, cptr.Prefix & " JOIN :" & Chan.Name, 0
      End If
      
      'send +q/+o/+v onjoin
      If Chan.Member.Item(cptr.Nick).IsOwner Then
        SendToChanIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
        SendToChan1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
        SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick 'servers always support IRCX
      End If
      If Chan.Member.Item(cptr.Nick).IsOp Then
        'if they're owner, RFC1459 clients already saw a +o get sent.
        If Chan.Member.Item(cptr.Nick).IsOwner Then
          SendToChanIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
        Else
          SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
        End If
        SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
      End If
      If Chan.IsAuditorium And Chan.Member.Item(cptr.Nick).IsVoice Then
        SendToChanOps Chan, cptr.Prefix & " MODE " & Chan.Name & " +v " & cptr.Nick, 0
      ElseIf Not Chan.IsAuditorium And Chan.Member.Item(cptr.Nick).IsVoice Then
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +v " & cptr.Nick, 0
        SendToServer "MODE " & Chan.Name & " +v " & cptr.Nick, cptr.Nick
      End If
      CurrentInfo = ""
      Dim OnJoinModes As String
      If OnJoinFlags And 4 = 4 Then OnJoinModes = OnJoinModes & "q"
      If OnJoinFlags And 2 = 2 Then OnJoinModes = OnJoinModes & "o"
      If OnJoinFlags And 1 = 1 Then OnJoinModes = OnJoinModes & "v"
      GenerateEvent "MEMBER", "JOIN", Replace(cptr.Prefix, ":", ""), Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " +" & OnJoinModes
      
      CurrentInfo = "onjoin"
      If Len(Chan.Prop_OnJoin) > 0 Then
        OnJoinS() = Split(UTF8_Escape(Chan.Prop_OnJoin), "\n")
        For B = 0 To UBound(OnJoinS)
            SendWsock cptr.index, ":" & Chan.Name & " PRIVMSG " & Chan.Name & " :" & OnJoinS(B), vbNullString, , True
            'SendWsock cptr.index, ":" & Chan.Name & " PRIVMSG " & cptr.Nick & " :" & OnJoinS(b) & vbCrLf, vbNullString, , True
        Next B
      End If
      CurrentInfo = "log join"
      If LogChannels Then LogChannel Chan.Name, "*** " & cptr.Nick & " has joined " & Chan.Name
    End If
NextChan:
  Next
End If
Exit Function
err:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_join' at " & CurrentInfo & " by " & cptr.Nick
End Function

'/*
'** m_njoin
'**  parv$()[0] = sender prefix
'**  parv$()[1] = channel
'**  parv$()[2] = channel members and modes
'*/
Public Function m_njoin(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "NJOIN called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
If cptr.AccessLevel = 4 Then
    Dim i&, Chan As clsChannel, User As clsClient, nUser$()
    Dim Modes$, nu$, cache$
    ReDim Normals(0)
    Set Chan = Channels(parv(0))
    If Chan Is Nothing Then
        Set Chan = New clsChannel
        Channels.Add parv(0), Chan
        Chan.Name = parv(0)
        Chan.Prop_Name = parv(0)
        Chan.Prop_OID = 0
    End If
    nUser = Split(parv(1), " ")
    For i = LBound(nUser) To UBound(nUser)
        Select Case Left$(nUser(i), 1)
            Case Level_Owner
                cache = Mid$(nUser(i), 2)
                Modes = Modes & "q"
                nu = nu & cache & " "
                Set User = GlobUsers(cache)
                If Not User Is Nothing Then Chan.Member.Add ChanOwner, User
            Case Level_Host
                cache = Mid$(nUser(i), 2)
                Modes = Modes & "o"
                nu = nu & cache & " "
                Set User = GlobUsers(cache)
                If Not User Is Nothing Then Chan.Member.Add ChanOp, User
            Case Level_Voice
                cache = Mid$(nUser(i), 2)
                Modes = Modes & "v"
                nu = nu & cache & " "
                If Not User Is Nothing Then Set User = GlobUsers(cache)
                Chan.Member.Add ChanVoice, User
            Case Else
                cache = nUser(i)
                If Not User Is Nothing Then Set User = GlobUsers(cache)
                Chan.Member.Add ChanNormal, User
        End Select
        If Not User Is Nothing Then User.OnChannels.Add Chan, Chan.Name
        SendToChan Chan, User.Prefix & " JOIN " & Chan.Name, ""
    Next i
    If Len(Modes) > 0 Then SendToChan Chan, ":" & sptr.ServerName & " MODE " & Chan.Name & " +" & Modes & " " & nu, ""
    SendToServer_ButOne "NJOIN " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.ServerName
Else
  Dim tmpSN As String
  If Len(cptr.Nick) = 0 Then
    tmpSN = "Anonymous"
  Else
    tmpSN = cptr.Nick
  End If
  SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & tmpSN, TranslateCode(ERR_UNKNOWNCOMMAND, , , "NJOIN")
  Exit Function
End If
End Function
Public Function m_nprop(cptr As clsClient, sptr As clsClient, parv$()) As Long
'NPROP
'#ChannelName CreationTime OID :Property1=PropertyValue Property2=PropertyValue Property3=PropertyValue
'      0           1        2        3
#If Debugging = 1 Then
  SendSvrMsg "NPROP called! (" & cptr.Nick & ")"
#End If
Dim Chan As clsChannel
Dim tmpCreation As Long
Dim A As Long
Dim tmpSplitProps() As String
Dim tmpPropName As String

If cptr.AccessLevel = 4 Then
  'server
  Set Chan = Channels(parv(0))
  If Not Chan Is Nothing Then
    'channel exists
    tmpCreation = CLng(parv(1))
    If Chan.Prop_Creation <= tmpCreation Then
      'if the channel was created before or at the same time
      'as the channel being introduced
      Chan.Prop_OID = CLng(parv(2))
      tmpSplitProps() = Split(parv(3), " ")
      For A = LBound(tmpSplitProps) To UBound(tmpSplitProps)
        tmpPropName = Split(tmpSplitProps(A), "=")(0)
        With Chan
          Select Case UCase$(tmpPropName)
            Case "ACCOUNT"
              If StrComp(.Prop_Account, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " ACCOUNT :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Account = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "CLIENT"
              If StrComp(.Prop_Client, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " CLIENT :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Client = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "CLIENTGUID"
              If StrComp(.Prop_ClientGUID, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " CLIENTGUID :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_ClientGUID = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "CLONENUMBER"
              If StrComp(.Prop_CloneNumber, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " CLONENUMBER :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_CloneNumber = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "HOSTKEY"
              If StrComp(.Prop_Hostkey, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " HOSTKEY :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Hostkey = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "LAG"
              If StrComp(.Prop_Lag, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " LAG :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Lag = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "LANGUAGE"
              If StrComp(.Prop_Language, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " LANGUAGE :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Language = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "MEMBERKEY"
              If StrComp(.Prop_Memberkey, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " MEMBERKEY :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Memberkey = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "ONJOIN"
              If StrComp(.Prop_OnJoin, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " ONJOIN :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_OnJoin = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "ONPART"
              If StrComp(.Prop_OnPart, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " ONPART :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_OnPart = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "OWNERKEY"
              If StrComp(.Prop_Ownerkey, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " OWNERKEY :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Ownerkey = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "PARENTNAME"
              If StrComp(.Prop_ParentName, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " PARENTNAME :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_ParentName = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "PICS"
              If StrComp(.Prop_PICS, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " PICS :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_PICS = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "SERVICEPATH"
              If StrComp(.Prop_ServicePath, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " SERVICEPATH :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_ServicePath = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "SUBJECT"
              If StrComp(.Prop_Subject, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " SUBJECT :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Subject = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
            Case "TOPIC"
              If StrComp(.Prop_Topic, UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)) <> 0 Then SendToChan Chan, "PROP " & Chan.Name & " TOPIC :" & UTF8_Escape(UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)), cptr.Prefix
              .Prop_Topic = UTF8_Unescape(CStr(Split(tmpSplitProps(A), "=")(1)), True)
          End Select
        End With
      Next A
    End If
  End If
Else
  Dim tmpSN As String
  If Len(cptr.Nick) = 0 Then
    tmpSN = "Anonymous"
  Else
    tmpSN = cptr.Nick
  End If
  SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & tmpSN, TranslateCode(ERR_UNKNOWNCOMMAND, , , "NPROP")
End If
End Function
'/*
'** m_part
'**  parv$()[0] = sender prefix
'**  parv$()[1] = channel
'*/
Public Function m_part(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "PART called! (" & cptr.Nick & ")"
#End If
On Error GoTo PartError
Dim at As String
Dim x&, cmd$, Chan As clsChannel, chans$(), i&, A&, B As Long, OnPartS() As String
If cptr.AccessLevel = 4 Then
  at = "server user part"
  chans = Split(parv(0), ",")
  With sptr
    For i = LBound(chans) To UBound(chans)  'Letting clients part multiple chans at one time -Dill
      Set Chan = .OnChannels.Item(chans(i))
      If Chan Is Nothing Then GoTo NextChannel
      If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
        cmd = .Prefix & " PART " & chans(i)
      Else
        cmd = .Prefix & " PART " & chans(i) & " :""" & parv(1) & """"
      End If
      
      If Chan.IsAuditorium Then
        If ((Chan.Member.Item(cptr.Nick).IsOp) Or (Chan.Member.Item(cptr.Nick).IsOwner)) Then
          SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
        Else
          'the person wasn't a host/owner, so only the hosts/owners know about him/her
          SendToChanOps Chan, cmd, 0   'Notify all ops
        End If
      Else
        SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
      End If
      
      SendToServer_ButOne "PART " & Chan.Name, cptr.ServerName, sptr.Nick
      Chan.Member.Remove .Nick
      .OnChannels.Remove chans(i)
      GenerateEvent "MEMBER", "PART", Replace(.Prefix, ":", ""), chans(i) & " " & Replace(.Prefix, ":", "")
      If LogChannels Then
        If UBound(parv) = 0 Then
          LogChannel Chan.Name, "*** " & sptr.Nick & " has left " & Chan.Name
        Else
          LogChannel Chan.Name, "*** " & sptr.Nick & " has left " & Chan.Name & " (""" & parv(1) & """)"
        End If
      End If
      If Chan.Member.Count = 0 Then
        'the channel only dies if it's not registered, or not persistant
        'and there's no people in it
        
        'don't even process this crap if the channel is static, since the channel will always stay
        If Not Chan.IsStatic Then
          If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
            Channels.Remove Chan.Name
            GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
            Set Chan = Nothing
          ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
            Channels.Remove Chan.Name
            GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
            Set Chan = Nothing
          ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
            Channels.Remove Chan.Name
            GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
            Set Chan = Nothing
          End If
        End If
      End If
NextChannel:
    Next i
  End With
Else
  at = "client start"
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PART")
    Exit Function
  End If
  at = "check mult chans"
  If InStr(1, parv(0), ",") > 0 Then
    at = "begin multiple channels"
    chans = Split(parv(0), ",")
    With cptr
      at = "begin checking this user's channels"
      For i = LBound(chans) To UBound(chans)  'Letting clients part multiple chans at one time -Dill
        If Not .IsOnChan(chans(i)) Then    'if client wasn't on this channel then complain -Dill / fixed error -Zg
          at = "throw error"
          SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOTONCHANNEL, , chans(i))
          GoTo NextChan
        End If
        Set Chan = Channels(chans(i))
        If Chan Is Nothing Then Exit Function
        'send partmsg!
        If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
          cmd = .Prefix & " PART " & Chan.Name
        ElseIf Len(parv(1)) = 0 Then 'PART #Channel : (no reason specified)
            cmd = cptr.Prefix & " PART " & Chan.Name
        Else
          If PartLen > 0 Then
            parv(1) = Mid$(parv(1), 1, PartLen)
          End If
          cmd = .Prefix & " PART " & Chan.Name & " :""" & parv(1) & """"
        End If
        
        If Chan.IsAuditorium Then
          If ((Chan.Member.Item(cptr.Nick).IsOp) Or (Chan.Member.Item(cptr.Nick).IsOwner)) Then
            SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
          Else
            'the person wasn't a host/owner, so only the hosts/owners know about him/her
            SendToChanOps Chan, cmd, 0   'Notify all ops
            SendWsock cptr.index, cmd, vbNullString, vbNullString, True 'notify the parting user
          End If
        Else
          SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
        End If
        If LogChannels Then
          If UBound(parv) = 0 Then
            LogChannel Chan.Name, "*** " & cptr.Nick & " has left " & Chan.Name
          Else
            LogChannel Chan.Name, "*** " & cptr.Nick & " has left " & Chan.Name & " (""" & parv(1) & """)"
          End If
        End If
        SendToServer "PART " & chans(i) & " :" & cptr.Nick, cptr.Nick
        If Len(Chan.Prop_OnPart) > 0 Then
          #If Debugging = 1 Then
            SendSvrMsg "Debug - OnPart Sending"
          #End If
          OnPartS() = Split(UTF8_Escape(Chan.Prop_OnPart), "\n")
          For B = 0 To UBound(OnPartS)
            #If Debugging = 1 Then
              SendSvrMsg "Debug - Sending OnPart Line: :" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(B)
            #End If
            'bloody hell.. this should, by all means, be working!
            'SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & Chan.Name & " :" & OnPartS(b) & vbCrLf
            SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(B) & vbCrLf
          Next B
        End If
        Chan.Member.Remove cptr.Nick
        .OnChannels.Remove chans(i)
        GenerateEvent "MEMBER", "PART", Replace(.Prefix, ":", ""), chans(i) & " " & Replace(.Prefix, ":", "")
        If Chan.Member.Count = 0 Then
          'the channel only dies if it's not registered, or not persistant
          'and there's no people in it
          If Not Chan.IsStatic Then
            If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
              Channels.Remove Chan.Name
              GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
              Set Chan = Nothing
            ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
              Channels.Remove Chan.Name
              GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
              Set Chan = Nothing
            ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
              Channels.Remove Chan.Name
              GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
              Set Chan = Nothing
            End If
          End If
        End If
        'Set Chan = Nothing 'wtf? -zg
NextChan:
      Next i
    End With
  Else 'only one channel
    at = "parting one channel"
    #If Debugging = 1 Then
        On Error GoTo 0
    #End If
    Set Chan = Nothing
    Set Chan = Channels.Item(parv(0))
    
    at = "check if chan exists"
    If Chan Is Nothing Then
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
        Exit Function
    End If
    at = "check if user is on channel"
    If Not cptr.IsOnChan(Chan.Name) Then
        SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOTONCHANNEL, , parv(0))
        Exit Function
    End If
    
    at = "prepare outbound part message"
    'now we get the part message formatted and stuff
    If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
        cmd = cptr.Prefix & " PART " & Chan.Name
    ElseIf Len(parv(1)) = 0 Then 'PART #Channel : (no reason specified)
        cmd = cptr.Prefix & " PART " & Chan.Name
    Else
      If PartLen > 0 Then
        parv(1) = Mid$(parv(1), 1, PartLen)
      End If
      cmd = cptr.Prefix & " PART " & Chan.Name & " :""" & parv(1) & """"
    End If
    If Chan.IsAuditorium Then
      If ((Chan.Member.Item(cptr.Nick).IsOp) Or (Chan.Member.Item(cptr.Nick).IsOwner)) Then
        SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
      Else
        'the person wasn't a host/owner, so only the hosts/owners know about him/her
        SendToChanOps Chan, cmd, 0   'notify ops
        SendWsock cptr.index, cmd, vbNullString, vbNullString, True 'notify the parting user
      End If
    Else
      SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
    End If
    If LogChannels Then
      If UBound(parv) = 0 Then
        LogChannel Chan.Name, "*** " & cptr.Nick & " has left " & Chan.Name
      Else
        LogChannel Chan.Name, "*** " & cptr.Nick & " has left " & Chan.Name & " (""" & parv(1) & """)"
      End If
    End If
    SendToServer "PART " & parv(0) & " :" & cptr.Nick, cptr.Nick
    #If Debugging = 1 Then
      SendSvrMsg "Debug - OnPart Len: " & Len(Chan.Prop_OnPart)
      SendSvrMsg "Debug - OnPart: " & UTF8_Escape(Chan.Prop_OnPart)
    #End If
    at = "send onpart"
    If Len(Chan.Prop_OnPart) > 0 Then
      #If Debugging = 1 Then
        SendSvrMsg "Debug - OnPart Sending"
      #End If
      OnPartS() = Split(UTF8_Escape(Chan.Prop_OnPart), "\n")
      For B = 0 To UBound(OnPartS)
        #If Debugging = 1 Then
          SendSvrMsg "Debug - Sending OnPart Line: :" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(B)
        #End If
        'SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & Chan.Name & " :" & OnPartS(b) & vbCrLf
        SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(B) & vbCrLf
      Next B
    End If
    at = "after onpart"
    Chan.Member.Remove cptr.Nick
    cptr.OnChannels.Remove parv(0)
    GenerateEvent "MEMBER", "PART", Replace(cptr.Prefix, ":", ""), Chan.Name & " " & Replace(cptr.Prefix, ":", "")
    
    If Chan.Member.Count = 0 Then
      'the channel only dies if it's not registered, or not persistant
      'and there's no people in it
      
      If Not Chan.IsStatic Then
        If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
          Channels.Remove Chan.Name
          GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
          Set Chan = Nothing
        ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
          Channels.Remove Chan.Name
          GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
          Set Chan = Nothing
        ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
          Channels.Remove Chan.Name
          GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
          Set Chan = Nothing
        End If
      End If
    End If
    'Set Chan = Nothing 'again, wtf? --zg
  End If
End If
Exit Function

PartError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_part' at " & at
End Function

'/*
'** m_kick
'**  parv$()[0] = sender prefix
'**  parv$()[1] = channel

'**  parv$()[2] = client to kick
'**  parv$()[3] = kick comment
'*/
Public Function m_kick(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "KICK called! (" & cptr.Nick & ")"
#End If
Dim Chan As clsChannel, i&, victim As clsClient, Reason$
If cptr.AccessLevel = 4 Then
  Reason = parv(2)
  SendToChan Chan, sptr.Prefix & " KICK " & parv(0) & " " & parv(1) & " :" & Reason, 0
  Chan.Member.Remove parv(1)
  GlobUsers(parv(1)).OnChannels.Remove Chan.Name
  If LogChannels Then LogChannel Chan.Name, "*** " & parv(1) & " has been kicked from " & Chan.Name & " by " & sptr.Nick & " (""" & Reason & """)"
  If Chan.Member.Count = 0 Then
    'the channel only dies if it's not registered, or not persistant
    'and there's no people in it
    If Not Chan.IsStatic Then
      If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
        Channels.Remove Chan.Name
        GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
        Set Chan = Nothing
      ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
        Channels.Remove Chan.Name
        GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
        Set Chan = Nothing
      ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
        Channels.Remove Chan.Name
        GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
        Set Chan = Nothing
      End If
    End If
  End If
  SendToServer_ButOne "KICK " & Chan.Name & " " & parv(1) & " :" & Reason, cptr.ServerName, sptr.Nick
  Set victim = GlobUsers.Item(parv(1))
  If Not victim Is Nothing Then GenerateEvent "MEMBER", "KICK", Replace(victim.Prefix, ":", ""), Chan.Name & " " & Replace(victim.Prefix, ":", "") & " " & sptr.Nick & " :" & Reason
Else
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KICK")
    Exit Function
  End If
  If Len(parv(1)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KICK")
    Exit Function
  End If
  Set victim = GlobUsers(parv(1))
  If victim Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(1))
    Exit Function
  End If
  
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
    Exit Function
  End If
  If Not (Chan.Member.Item(cptr.Nick).IsOp) And Not (Chan.Member.Item(cptr.Nick).IsOwner) Then
    SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
    Exit Function
  End If
  
  If Chan.Member.Item(victim.Nick).IsOwner Then
    If Not Chan.Member.Item(cptr.Nick).IsOwner Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
    End If
  End If
  
  If victim.IsProtected Or victim.IsLProtected Then
  'note: this only checks to see if a user is kicking an oper
  'opers can kick other opers
    If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
      Exit Function
    End If
    
    If victim.IsNetAdmin Then
      'what to do if the person being kicked is a network administrator
      If Not cptr.IsNetAdmin Then
        'the kicking user isn't even a netadmin
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
      End If
      If cptr.IsLProtected Then
        If victim.IsProtected Then
          '+P > +p
          SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
          Exit Function
        End If
      End If 'if they're not LProtected, they're Protected, and Protected opers can kill other opers
    Else 'not a net admin
      If cptr.IsLProtected Then
        '+P > +p
        If victim.IsProtected Then
          SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
          Exit Function
        End If
      End If
    End If
  'now get on with the show
  End If
  
  If UBound(parv) = 1 Then
    Reason = cptr.Nick
  Else
    If NickLen > 0 Then
      Reason = Mid$(parv(2), 1, KickLen)
    End If
  End If
  SendToChan Chan, cptr.Prefix & " KICK " & parv(0) & " " & parv(1) & " :" & Reason, 0
  SendToServer "KICK " & parv(0) & " " & parv(1) & " :" & Reason, cptr.Nick
  GenerateEvent "MEMBER", "KICK", Replace(victim.Prefix, ":", ""), Chan.Name & " " & Replace(victim.Prefix, ":", "") & " " & cptr.Nick & " :" & Reason
  If LogChannels Then LogChannel Chan.Name, "*** " & victim.Nick & " has been kicked from " & Chan.Name & " by " & cptr.Nick & " (""" & Reason & """)"
  
  Chan.Member.Remove victim.Nick
  If Chan.Member.Count = 0 Then
    'the channel only dies if it's not registered, or not persistant
    'and there's no people in it
    If Not Chan.IsStatic Then
      If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
        Channels.Remove Chan.Name
        GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
        Set Chan = Nothing
      ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
        Channels.Remove Chan.Name
        GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
        Set Chan = Nothing
      ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
        Channels.Remove Chan.Name
        GenerateEvent "CHANNEL", "DESTROY", Chan.Name, Chan.Name
        Set Chan = Nothing
      End If
    End If
  End If
  victim.OnChannels.Remove Chan.Name
End If
End Function


Public Function m_prop(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = target
'parv[1] = property
'parv[2] = value
'--ziggy

#If Debugging = 1 Then
  SendSvrMsg "PROP called! (" & cptr.Nick & ")"
#End If

Dim Chan As clsChannel, i&
Dim TargetUser As clsClient

'check if null (not enough params)
If Len(parv(0)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PROP")
  Exit Function
End If
If UBound(parv) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PROP")
  Exit Function
End If
If Len(parv(1)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PROP")
  Exit Function
End If

'cache the owner, host, and member statuses
Dim tmpGod As Boolean
Dim tmpOwner As Boolean
Dim tmpHost As Boolean
Dim tmpMember As Boolean
Dim tmpUser As Boolean 'outside the channel

Dim tmpSvrName As String 'because I'm lazy and don't want to write a server PROP section
Dim tmpAccessLvl As Long '    "    "
Dim PropList() As String 'to facilitate multiple prop list queries
Dim PL_Item As Variant
Dim ChanList() As String
Dim CL_Item As Variant

If (cptr.IsProtected) Then
  'high protected ircop
  If HighProtAsq Then tmpOwner = True
  If HighProtAso Then tmpHost = True
  If HighProtAsv Then tmpMember = True
  If HighProtAsn Then tmpMember = True
End If
If (cptr.IsLProtected) Then
  'low protected ircop
  If LowProtAsq Then tmpOwner = True
  If LowProtAso Then tmpHost = True
  If LowProtAsv Then tmpMember = True
  If LowProtAsn Then tmpMember = True
End If
If cptr.AccessLevel = 4 Then
 'server
 tmpOwner = True
 tmpGod = True
 'before messing up cptr, let's tell the other servers
 'about the dirty deed
 'how about not?
 
 'If Not Chan Is Nothing Then
 '  SendToServer_ButOne "PROP " & Chan.Name & " " & parv(1) & " :" & parv(2), cptr.ServerName, sptr.Nick
 'End If
 tmpSvrName = cptr.ServerName
 tmpAccessLvl = cptr.AccessLevel
 Set cptr = sptr
End If
#If Debugging = 1 Then
  SendSvrMsg "*** Processing properties..."
#End If
If UBound(parv) = 1 Then
  #If Debugging = 1 Then
    SendSvrMsg "*** Showing properties..."
  #End If
  'show properties
  ChanList = Split(parv(0), ",")
  For Each CL_Item In ChanList
    'setup Chan
    Set Chan = Channels.Item(CStr(CL_Item))
    If Chan Is Nothing Then
      tmpOwner = False
      tmpHost = False
      tmpMember = False
      tmpUser = False
    Else
      If Not Chan.GetUser(cptr.Nick) Is Nothing Then
        tmpOwner = Chan.Member.Item(cptr.Nick).IsOwner
        tmpHost = Chan.Member.Item(cptr.Nick).IsOp
        If Not (tmpOwner Or tmpHost) Then tmpMember = True
      End If
      
      'If not a member of the channel, there are some props we can't read
      If (Chan.GetUser(cptr.Nick) Is Nothing) And Not tmpGod Then
        #If Debugging = 1 Then
          SendSvrMsg "Is a user!"
        #End If
        tmpUser = True
        tmpGod = False
        tmpOwner = False
        tmpHost = False
        tmpMember = False
      End If
    End If
    If Asc(Left$(CStr(CL_Item), 1)) = 35 Then
      #If Debugging = 1 Then
        SendSvrMsg "*** Channel Prop"
      #End If
      If Chan Is Nothing Then
        'channel specified wasn't valid
        #If Debugging = 1 Then
          SendSvrMsg "*** Invalid Channel"
        #End If
        SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & CL_Item, TranslateCode(IRCRPL_PROPEND)
        GoTo NextChannelProp
      Else
        If Chan.IsSecret And (Chan.GetUser(cptr.Nick) Is Nothing) Then
          #If Debugging = 1 Then
            SendSvrMsg "*** Secret Channel"
          #End If
          SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCRPL_PROPEND)
          GoTo NextChannelProp
        End If
        PropList = Split(parv(1), ",")
        For Each PL_Item In PropList
          #If Debugging = 1 Then
            SendSvrMsg "*** Sending Props!"
          #End If
          With Chan
            If "ACCOUNT" Like UCase$(PL_Item) And ((Len(.Prop_Account) > 0) And (tmpOwner)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Account :" & UTF8_Escape(.Prop_Account)
            If "CLIENT" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Client) <> 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Client :" & UTF8_Escape(.Prop_Client)
            'If .Prop_ClientGUID <> vbNullString Then SendWsock cptr.Index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "ClientGUID :" & .Prop_ClientGUID
            If "CREATION" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate))) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Creation :" & UTF8_Escape(.Prop_Creation)
            If "GUID" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate))) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "GUID :" & UTF8_Escape(.GUID)
            '.Prop_Lag (future implementation)
            If "LANGUAGE" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Language) <> 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Language :" & UTF8_Escape(.Prop_Language)
            If "MEMBERKEY" Like UCase$(PL_Item) And (Len(.Prop_Memberkey) <> 0 And Not (tmpUser) And ((tmpMember) Or (tmpOwner) Or (tmpHost))) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "MemberKey :" & UTF8_Escape(.Prop_Memberkey)
            If "NAME" Like UCase$(PL_Item) And (Len(.Prop_Name) <> 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Name :" & UTF8_Escape(.Prop_Name)
            If "OID" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate))) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OID :" & UTF8_Escape(.Prop_OID)
            If "ONJOIN" Like UCase$(PL_Item) And (Len(.Prop_OnJoin) <> 0 And (tmpOwner Or tmpHost)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OnJoin :" & UTF8_Escape(.Prop_OnJoin)
            If "ONPART" Like UCase$(PL_Item) And (Len(.Prop_OnPart) <> 0 And (tmpOwner Or tmpHost)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OnPart :" & UTF8_Escape(.Prop_OnPart)
            '.Prop_PICS
            '.Prop_ServicePath
            If "SUBJECT" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Subject) <> 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Subject :" & UTF8_Escape(.Prop_Subject)
            If "TOPIC" Like UCase$(PL_Item) And (Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Topic) <> 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Topic :" & UTF8_Escape(.Prop_Topic)
            SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCRPL_PROPEND)
          End With
        Next
      End If
    Else
      'user properties go here
      'here's the ones I intend on supporting:
      'OID            -- the user's object identifier (0)
      'GUID           -- the user's GUID
      'Nick           -- the user's nickname
      'Identity       -- the user's ident
      
      'TODO: finish these props:
      'UserHostname   -- only viewable by opers? it won't make any sense to the client
      'UserServername -- only viewable by opers? it won't make any sense to the client
      
      'will probably never make it, but...
      'Language would be a good property to have, and it'd need to be settable.
      'It'd also need to be viewable by everybody...
      Set TargetUser = GlobUsers(CStr(CL_Item))
      If TargetUser Is Nothing Then 'if user doesn't exist...
        'SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(CL_Item))
        SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & CL_Item, TranslateCode(IRCRPL_PROPEND)
        GoTo NextChannelProp
      End If
      If Not TargetUser Is cptr Then 'if the TargetUser != user issuing command
        If Not (cptr.IsGlobOperator Or cptr.IsLocOperator) Then 'if not an oper (all opers can see user props)
          'SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & CL_Item, TranslateCode(IRCRPL_PROPEND)
          GoTo NextChannelProp
        End If
      End If
      'now, we list them some props
      'note: you can't set anything on a user
      PropList = Split(parv(1), ",")
      
      For Each PL_Item In PropList
        With TargetUser
          If "GUID" Like UCase$(PL_Item) And (Len(.GUID) > 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & .Nick, "GUID :" & UTF8_Escape(.GUID)
          If "IDENTITY" Like UCase$(PL_Item) And (Len(.User) > 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & .Nick, "Identity :" & UTF8_Escape(.User)
          If "NICK" Like UCase$(PL_Item) And (Len(.Nick) > 0) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & .Nick, "Nick :" & UTF8_Escape(.Nick)
          If "OID" Like UCase$(PL_Item) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & .Nick, "OID :" & UTF8_Escape(.OID)
          SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & .Nick, TranslateCode(IRCRPL_PROPEND)
        End With
      Next
    End If
NextChannelProp:
  Next 'chan list
Else
'ubound of parv > 1
  ChanList = Split(parv(0), ",")
  For Each CL_Item In ChanList
    'setup Chan
    Set Chan = Channels.Item(CStr(CL_Item))
    If Chan Is Nothing Then
      tmpOwner = False
      tmpHost = False
      tmpMember = False
      tmpUser = False
    Else
      If Not Chan.GetUser(cptr.Nick) Is Nothing Then
        tmpOwner = Chan.Member.Item(cptr.Nick).IsOwner
        tmpHost = Chan.Member.Item(cptr.Nick).IsOp
        If Not (tmpOwner Or tmpHost) Then tmpMember = True
      End If
      
      'If not a member of the channel, there are some props we can't read
      If (Chan.GetUser(cptr.Nick) Is Nothing) And Not tmpGod Then
        #If Debugging = 1 Then
          SendSvrMsg "Is a user!"
        #End If
        tmpUser = True
        tmpGod = False
        tmpOwner = False
        tmpHost = False
        tmpMember = False
      End If
    End If
    
    'does the channel exist?
    If Chan Is Nothing Then
      'channel specified wasn't valid
      SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & CL_Item, TranslateCode(IRCRPL_PROPEND)
      GoTo NextChannelPropValue
    End If
    
    Dim tmpVal As String
    'prop # something :value
    '     0    1        2
    With Chan
      'set prop, handle here
      Select Case UCase$(parv(1))
        Case "ACCOUNT":
          If tmpGod Then
            tmpVal = parv(2)
            .Prop_Account = UTF8_Unescape(tmpVal)
            SendToChanOwners Chan, cptr.Prefix & " PROP " & Chan.Name & " ACCOUNT :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " ACCOUNT :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " ACCOUNT :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        'parentname and clonenumber are "hidden" properties
        'no client should ever care about it
        Case "PARENTNAME":
          If tmpGod Then
            tmpVal = parv(2)
            .Prop_ParentName = UTF8_Unescape(tmpVal)
            SendToServer_ButOne "PROP " & Chan.Name & " PARENTNAME :" & tmpVal, tmpSvrName, cptr.Nick
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "CLONENUMBER":
          If tmpGod Then
            tmpVal = parv(2)
            .Prop_CloneNumber = CLng(UTF8_Unescape(tmpVal))
            SendToServer_ButOne "PROP " & Chan.Name & " CLONENUMBER :" & tmpVal, tmpSvrName, cptr.Nick
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "OWNERKEY":
          If tmpOwner Then
            tmpVal = parv(2)
            .Prop_Ownerkey = UTF8_Unescape(tmpVal)
            SendToChanOwners Chan, cptr.Prefix & " PROP " & Chan.Name & " OWNERKEY :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " OWNERKEY :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " OWNERKEY :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "HOSTKEY":
          If tmpOwner Or tmpHost Then
            tmpVal = parv(2)
            .Prop_Hostkey = UTF8_Unescape(tmpVal)
            SendToChanOps Chan, cptr.Prefix & " PROP " & Chan.Name & " HOSTKEY :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " HOSTKEY :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " HOSTKEY :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "MEMBERKEY":
          If tmpOwner Or tmpHost Then
            tmpVal = parv(2)
            .Prop_Memberkey = UTF8_Unescape(tmpVal)
            .Key = tmpVal
            If IRCXM_Trans = True Then
              SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +k " & tmpVal, 0
            ElseIf IRCXM_Strict = True Then
              SendToChanIRCX Chan, cptr.Prefix & " PROP " & Chan.Name & " MEMBERKEY :" & tmpVal, 0
              SendToChan1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +k " & tmpVal, 0
            ElseIf IRCXM_Both = True Then
              SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " MEMBERKEY :" & tmpVal, 0
              SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +k " & tmpVal, 0
            Else
              SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +k " & tmpVal, 0
            End If
            'send to server!
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " MEMBERKEY :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " MEMBERKEY :" & tmpVal, cptr.Nick
            End If
            GenerateEvent "CHANNEL", "KEYWORD", Chan.Name, Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " :" & Chan.Key
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "CLIENT":
          If (tmpOwner Or tmpHost) Then
            tmpVal = parv(2)
            .Prop_Client = UTF8_Unescape(tmpVal)
            SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " CLIENT :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " CLIENT :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " CLIENT :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "CREATION":
          If tmpGod Then
            tmpVal = parv(2)
            .Prop_Account = UTF8_Unescape(tmpVal)
            SendToChanOwners Chan, cptr.Prefix & " PROP " & Chan.Name & " CREATION :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " CREATION :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " CREATION :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "GUID": 'cannot set GUID
          SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
        Case "LANGUAGE":
          If (tmpOwner Or tmpHost) Then
            tmpVal = parv(2)
            .Prop_Language = UTF8_Unescape(tmpVal)
            SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " LANGUAGE :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " LANGUAGE :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " LANGUAGE :" & tmpVal, cptr.Nick
            End If
          Else 'no permissions
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "NAME": 'cannot set name
          SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
        Case "OID": 'cannot set OID
          SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
        Case "ONJOIN":
          If (tmpOwner Or tmpHost) Then
            tmpVal = parv(2)
            .Prop_OnJoin = UTF8_Unescape(tmpVal)
            SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " ONJOIN :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " ONJOIN :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " ONJOIN :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "ONPART":
          If (tmpOwner Or tmpHost) Then
            tmpVal = parv(2)
            .Prop_OnPart = UTF8_Unescape(tmpVal)
            SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " ONPART :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " ONPART :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " ONPART :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "SUBJECT":
          If (tmpOwner Or tmpHost) Then
            tmpVal = parv(2)
            .Prop_Subject = UTF8_Unescape(tmpVal)
            SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " SUBJECT :" & tmpVal, 0
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " SUBJECT :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " SUBJECT :" & tmpVal, cptr.Nick
            End If
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case "TOPIC":
          If (tmpOwner Or tmpHost) Or Chan.IsTopicOps Then
            tmpVal = parv(2)
            If TopicLen > 0 Then
              tmpVal = Left$(tmpVal, TopicLen)
            End If
            .Prop_Topic = UTF8_Unescape(tmpVal)
            .Topic = UTF8_Unescape(tmpVal)
            .TopicSetBy = cptr.Nick
            .TopcSetAt = UnixTime
            If IRCXM_Trans = True Then
              SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & tmpVal, 0
            ElseIf IRCXM_Strict = True Then
              SendToChanIRCX Chan, cptr.Prefix & " PROP " & Chan.Name & " TOPIC :" & tmpVal, 0
              SendToChan1459 Chan, cptr.Prefix & " TOPIC " & .Name & " :" & tmpVal, 0
            ElseIf IRCXM_Both = True Then
              SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " TOPIC :" & tmpVal, 0
              SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & tmpVal, 0
            Else
              SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & tmpVal, 0
            End If
            If tmpAccessLvl = 4 Then
              SendToServer_ButOne "PROP " & Chan.Name & " TOPIC :" & tmpVal, tmpSvrName, cptr.Nick
            Else
              SendToServer "PROP " & Chan.Name & " TOPIC :" & tmpVal, cptr.Nick
            End If
            GenerateEvent "CHANNEL", "TOPIC", Chan.Name, Chan.Name & " " & Replace(cptr.Nick, ":", "") & " :" & tmpVal
          Else
            SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
          End If
        Case Else:
          SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
      End Select
    End With
NextChannelPropValue:
  Next 'chan list
End If
End Function
Public Function m_knock(cptr As clsClient, sptr As clsClient, parv$()) As Long
'this function is mainly for server-server communication
'we probably could extend it to clients...
#If Debugging = 1 Then
  SendSvrMsg "KNOCK called! (" & cptr.Nick & ")"
#End If
Dim Chan As clsChannel
If cptr.AccessLevel = 4 Then
  ':Nick KNOCK #Channel :Reason
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then Exit Function
  SendToChanOpsIRCX Chan, "KNOCK " & Chan.Name & " :" & parv(1), sptr.Prefix
  SendToServer_ButOne "KNOCK " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.Nick
Else
  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, ":Permission Denied"
  Exit Function
End If
End Function

'/*
'** m_topic
'**  parv$()[0] = sender prefix
'**  parv$()[1] = topic text
'*/
Public Function m_topic(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "TOPIC called! (" & cptr.Nick & ")"
#End If
Dim Chan As clsChannel, i&
If cptr.AccessLevel = 4 Then
  Set Chan = Channels(parv(0))
  If UBound(parv) = 1 Then
    'added maxlen (ircx default 160) - ziggy
    SendToChan Chan, sptr.Prefix & " TOPIC " & Chan.Name & " :" & Left$(parv(1), TopicLen), 0
    With Chan
        .Topic = Left$(UTF8_Unescape(parv(1)), TopicLen)
        .Prop_Topic = Left$(UTF8_Unescape(parv(1)), TopicLen)
        .TopicSetBy = sptr.Nick
        .TopcSetAt = UnixTime
        SendToServer_ButOne "TOPIC " & .Name & " :" & .Topic, cptr.ServerName, sptr.Nick
        GenerateEvent "CHANNEL", "TOPIC", Chan.Name, Chan.Name & " " & Replace(sptr.Prefix, ":", "") & " :" & .Topic
    End With
  Else
    If StrComp(Chan.Topic, vbNullString) = 0 Then
      SendWsock cptr.index, RPL_NOTOPIC & " " & sptr.Nick & " " & Chan.Name, ":No topic is set"
    Else
      SendWsock cptr.index, RPL_TOPIC & " " & sptr.Nick & " " & Chan.Name, " :" & Chan.Topic
      SendWsock cptr.index, RPL_TOPICWHOTIME & " " & sptr.Nick & " " & Chan.TopicSetBy & " " & Chan.Name & " " & Chan.TopicSetBy & " " & Chan.TopcSetAt, vbNullString
    End If
  End If
  
Else
  If Len(parv(0)) = 0 Then
      SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "TOPIC")
      Exit Function
  End If
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
    Exit Function
  End If
  If UBound(parv) = 1 Then
    If TopicLen > 0 Then
      parv(1) = Left$(parv(1), TopicLen)
    End If
    If Chan.IsTopicOps Then
      If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsOwner Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
      End If
    End If
    With Chan
        If IRCXM_Trans = True And IRCXM_Strict = False And IRCXM_Both = False Then
          SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & parv(1), 0
        ElseIf IRCXM_Trans = False And IRCXM_Strict = True And IRCXM_Both = False Then
          SendToChanIRCX Chan, cptr.Prefix & " PROP " & Chan.Name & " TOPIC :" & parv(1), 0
          SendToChan1459 Chan, cptr.Prefix & " TOPIC " & .Name & " :" & parv(1), 0
        ElseIf IRCXM_Trans = False And IRCXM_Strict = False And IRCXM_Both = True Then
          SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " TOPIC :" & parv(1), 0
          SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & parv(1), 0
        Else
          SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & parv(1), 0
        End If
        SendToServer "TOPIC " & .Name & " :" & parv(1), cptr.Nick
        GenerateEvent "CHANNEL", "TOPIC", Chan.Name, Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " :" & parv(1)
        .Topic = UTF8_Unescape(parv(1))
        .Prop_Topic = UTF8_Unescape(parv(1))
        .TopicSetBy = cptr.Nick
        .TopcSetAt = UnixTime
    End With
  Else
    If Len(Chan.Topic) = 0 Then
      SendWsock cptr.index, RPL_NOTOPIC & " " & cptr.Nick & " " & Chan.Name, ":No topic is set"
    Else
      SendWsock cptr.index, RPL_TOPIC & " " & cptr.Nick & " " & Chan.Name, " :" & Chan.Topic
      SendWsock cptr.index, RPL_TOPICWHOTIME & " " & Chan.TopicSetBy & " " & Chan.Name & " " & Chan.TopicSetBy & " " & Chan.TopcSetAt, vbNullString
    End If
  End If
End If
End Function

'/*
'** m_invite
'**  parv$()[0] - sender prefix
'**  parv$()[1] - user to invite
'**  parv$()[2] - channel number
'*/
Public Function m_invite(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "INVITE called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "INVITE")
        Exit Function
    End If
    If UBound(parv) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "INVITE")
        Exit Function
    End If
    Dim Chan As clsChannel, User As clsClient
    Set User = GlobUsers(parv(0))
    If User Is Nothing Then
        SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
        Exit Function
    End If
    Set Chan = Channels(parv(1))
    If Chan Is Nothing Then
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & Chan.Name, TranslateCode(ERR_NOSUCHCHANNEL, , Chan.Name)
        Exit Function
    End If
    If Chan.GetUser(cptr.Nick) Is Nothing Then
        SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOTONCHANNEL, , Chan.Name)
        Exit Function
    End If
    If Chan.IsInviteOnly Then
        If Chan.Member(cptr.Nick).Priv < ChanOp Then
            SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
            Exit Function
        End If
    End If
    If Not Chan.GetUser(User.Nick) Is Nothing Then
        SendWsock cptr.index, ERR_USERONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERONCHANNEL, User.Nick, Chan.Name)
        Exit Function
    End If
    Chan.AddInvite User.Nick
    SendWsock cptr.index, RPL_INVITING & " " & cptr.Nick & " " & User.Nick & " " & Chan.Name, vbNullString
    SendWsock User.index, cptr.Prefix & " INVITE " & User.Nick & " " & Chan.Name, vbNullString, , True
End If
End Function
Public Function m_listx(cptr As clsClient, sptr As clsClient, parv$()) As Long
On Error Resume Next
#If Debugging = 1 Then
    SendSvrMsg "LISTX called! (" & cptr.Nick & ")"
#End If

'Table 3.2. Query terms for LIST command
'Query Term    Description
'===========================================================================
'<#            Select channels with less than # members.
'>#            Select channels with more than # members.
'C<#           Select channels created less than # minutes ago.
'C>#           Select channels created greater than # minutes ago.
'L=<mask>      Select channels with language property matching the mask string.
'N=<mask>      Select channels with name matching the mask string.
'R=0           Select unregistered channels.
'R=1           Select registered channels.
'S=<mask>      Select channels with subject matching the mask string.
'T<#           Select channels with a topic changed less than # minutes ago.
'T>#           Select channels with a topic changed greater than # minutes ago.
'T=<mask>      Select channels that topic matches the mask string.
'<query limit> Maximum number of channels to be returned.
'<mask>        Sequence of characters that is used to select a matching channel name or topic.
'              The character * and ? are used for wildcard searches.

If cptr.AccessLevel <> 4 Then
    Dim i As Long, Ucount As Long, chans() As clsChannel, ret&
    Dim A As Long, ShowChannel As Boolean, NewMask As String
    
    'query terms
    Dim QT_Limit_LT As Long, QT_Limit_GT As Long
    Dim QT_Creation_LT As Long, QT_Creation_GT As Long
    Dim QT_Language_Mask As String
    Dim QT_Name_Mask As String
    Dim QT_Registered As Long '0 = don't search, 1 = not, 2 = registered
    Dim QT_Subject_Mask As String
    Dim QT_Topic_LT As Long, QT_Topic_GT As Long
    Dim QT_Topic_Mask As String
    
    Dim ChanList As Variant, CL() As String
    Dim MaxCL As Long
    
    chans = Channels.Values
    SendWsock cptr.index, IRCRPL_LISTXSTART & " " & cptr.Nick, ":Start of ListX"
    
    If UBound(chans) = 0 And chans(0) Is Nothing Then
        SendWsock cptr.index, IRCRPL_LISTXEND & " " & cptr.Nick, ":End of /LISTX"
        Exit Function
    End If
    If UBound(parv) = 0 And Left$(parv(0), 1) = "#" Then
      #If Debugging = 1 Then
        SendSvrMsg "Processing channel list..."
      #End If
      CL() = Split(parv(0), ",")
      For Each ChanList In CL()
        For i = 0 To UBound(chans)
          If UCase$(chans(i).Name) = UCase$(CStr(ChanList)) Then
            SendWsock cptr.index, IRCRPL_LISTXLIST & " " & cptr.Nick & " " & chans(i).Name & " +" & Replace(GetModesX(chans(i)), "+", "") & " " & chans(i).Member.Count & " " & chans(i).Limit, ":" & chans(i).Topic
            If MaxListLen > 0 Then
              ret = ret + 1
              If ret = MaxListLen Then Exit For
            End If
          End If
        Next i
      Next
      SendWsock cptr.index, IRCRPL_LISTXEND & " " & cptr.Nick, ":End of /LISTX"
      Exit Function
    End If
    
    For i = 0 To UBound(chans)
        If Not (chans(i).IsSecret Or chans(i).IsHidden Or chans(i).IsPrivate) Then
          'query terms!
          #If Debugging = 1 Then
            SendSvrMsg "Preparing to process query terms..."
          #End If
          If Len(parv(0)) > 0 Then
            #If Debugging = 1 Then
              SendSvrMsg "Processing Query Terms..."
            #End If
            For A = 0 To UBound(parv)
              If Left$(parv(A), 1) = "<" Then
                #If Debugging = 1 Then
                  SendSvrMsg "Limit Less Than " & MakeNumber(Mid$(parv(A), 2))
                #End If
                QT_Limit_LT = CLng(MakeNumber(Mid$(parv(A), 2)))
              ElseIf Left$(parv(A), 1) = ">" Then
                #If Debugging = 1 Then
                  SendSvrMsg "Limit Greater Than " & MakeNumber(Mid$(parv(A), 2))
                #End If
                QT_Limit_GT = CLng(MakeNumber(Mid$(parv(A), 2)))
              ElseIf Left$(parv(A), 2) = "C<" Then
                QT_Creation_LT = CLng(MakeNumber(Mid$(parv(A), 3)))
              ElseIf Left$(parv(A), 2) = "C>" Then
                QT_Creation_GT = CLng(MakeNumber(Mid$(parv(A), 3)))
              ElseIf Left$(parv(A), 2) = "L=" Then
                QT_Language_Mask = Mid$(parv(A), 3)
              ElseIf Left$(parv(A), 2) = "N=" Then
                QT_Name_Mask = Mid$(parv(A), 3)
              ElseIf Left$(parv(A), 3) = "R=0" Then
                QT_Registered = 1
              ElseIf Left$(parv(A), 3) = "R=1" Then
                QT_Registered = 2
              ElseIf Left$(parv(A), 2) = "S=" Then
                QT_Subject_Mask = Mid$(parv(A), 3)
              ElseIf Left$(parv(A), 2) = "T<" Then
                QT_Topic_LT = CLng(MakeNumber(Mid$(parv(A), 3)))
              ElseIf Left$(parv(A), 2) = "T>" Then
                QT_Topic_GT = CLng(MakeNumber(Mid$(parv(A), 3)))
              ElseIf Left$(parv(A), 2) = "T=" Then
                QT_Topic_Mask = Mid$(parv(A), 3)
              End If
            Next A
          End If
          
          'filter the masks
          NewMask = Replace(QT_Language_Mask, "[", " [ ")
          NewMask = Replace(NewMask, "]", " ] ")
          NewMask = Replace(NewMask, "#", "[#]")
          NewMask = Replace(NewMask, " [ ", "[[]")
          NewMask = Replace(NewMask, " ] ", "[]]")
          NewMask = Replace(NewMask, "\*", "[*]")
          NewMask = Replace(NewMask, "\?", "[?]")
          NewMask = Replace(NewMask, "\b", " ")
          NewMask = Replace(NewMask, "\c", ",")
          NewMask = Replace(NewMask, "\\", "\")
          QT_Language_Mask = NewMask
          NewMask = Replace(QT_Name_Mask, "[", " [ ")
          NewMask = Replace(NewMask, "]", " ] ")
          NewMask = Replace(NewMask, "#", "[#]")
          NewMask = Replace(NewMask, " [ ", "[[]")
          NewMask = Replace(NewMask, " ] ", "[]]")
          NewMask = Replace(NewMask, "\*", "[*]")
          NewMask = Replace(NewMask, "\?", "[?]")
          NewMask = Replace(NewMask, "\b", " ")
          NewMask = Replace(NewMask, "\c", ",")
          NewMask = Replace(NewMask, "\\", "\")
          QT_Name_Mask = NewMask
          NewMask = Replace(QT_Subject_Mask, "[", " [ ")
          NewMask = Replace(NewMask, "]", " ] ")
          NewMask = Replace(NewMask, "#", "[#]")
          NewMask = Replace(NewMask, " [ ", "[[]")
          NewMask = Replace(NewMask, " ] ", "[]]")
          NewMask = Replace(NewMask, "\*", "[*]")
          NewMask = Replace(NewMask, "\?", "[?]")
          NewMask = Replace(NewMask, "\b", " ")
          NewMask = Replace(NewMask, "\c", ",")
          NewMask = Replace(NewMask, "\\", "\")
          QT_Subject_Mask = NewMask
          NewMask = Replace(QT_Topic_Mask, "[", " [ ")
          NewMask = Replace(NewMask, "]", " ] ")
          NewMask = Replace(NewMask, "#", "[#]")
          NewMask = Replace(NewMask, " [ ", "[[]")
          NewMask = Replace(NewMask, " ] ", "[]]")
          NewMask = Replace(NewMask, "\*", "[*]")
          NewMask = Replace(NewMask, "\?", "[?]")
          NewMask = Replace(NewMask, "\b", " ")
          NewMask = Replace(NewMask, "\c", ",")
          NewMask = Replace(NewMask, "\\", "\")
          QT_Topic_Mask = NewMask
          
          'now, test this channel with the query terms
          ShowChannel = True
          If ShowChannel And QT_Limit_LT > 0 Then
            If chans(i).Limit < QT_Limit_LT Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And QT_Limit_GT > 0 Then
            If chans(i).Limit > QT_Limit_GT Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And QT_Creation_LT > 0 Then
            If chans(i).Prop_Creation < (UnixTime - (QT_Creation_LT * 60)) Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And QT_Creation_GT > 0 Then
            If chans(i).Prop_Creation > (UnixTime - (QT_Creation_GT * 60)) Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And Len(QT_Language_Mask) > 0 Then
            If chans(i).Prop_Language Like QT_Language_Mask Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And Len(QT_Name_Mask) > 0 Then
            If chans(i).Name Like QT_Name_Mask Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And QT_Registered > 0 Then
            If chans(i).IsRegistered And QT_Registered = 1 Then
              ShowChannel = True
            ElseIf Not chans(i).IsRegistered And QT_Registered = 0 Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And Len(QT_Subject_Mask) > 0 Then
            If chans(i).Prop_Subject Like QT_Subject_Mask Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And QT_Topic_LT > 0 Then
            If chans(i).TopcSetAt < QT_Topic_LT Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And QT_Topic_GT > 0 Then
            If chans(i).TopcSetAt > QT_Topic_GT Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          If ShowChannel And Len(QT_Topic_Mask) > 0 Then
            If chans(i).Topic Like QT_Topic_Mask Then
              ShowChannel = True
            Else
              ShowChannel = False
            End If
          End If
          
          If IsNumeric(parv(UBound(parv))) Then
            'if the last parameter is numeric, that's the max
            'channel list thingy
            MaxCL = CLng(parv(UBound(parv)))
          End If
            
          If ShowChannel Then
            SendWsock cptr.index, IRCRPL_LISTXLIST & " " & cptr.Nick & " " & chans(i).Name & " +" & Replace(GetModesX(chans(i)), "+", "") & " " & chans(i).Member.Count & " " & chans(i).Limit, ":" & chans(i).Topic
            ret = ret + 1
            
            If MaxListLen > 0 Then
              If ret = MaxListLen Then Exit For
            End If
            If MaxCL > 0 Then If ret = MaxCL Then Exit For
          End If
        End If
    Next i
    SendWsock cptr.index, IRCRPL_LISTXEND & " " & cptr.Nick, ":End of /LISTX"
End If
End Function
'/*
'** m_list
'**      parv$()[0] = sender prefix
'**      parv$()[1] = channel
'*/
Public Function m_list(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "LIST called! (" & cptr.Nick & ")"
#End If
On Error GoTo ListError
Dim ListAt As String
ListAt = "entry"
If cptr.AccessLevel = 4 Then
'server listing?
'this is pretty useless... -_-
Else
    Dim i As Long, Ucount As Long, chans() As clsChannel, ret&
    Dim NewMask As String
    
    chans = Channels.Values
    ListAt = "check for no channels"
    
    If UBound(chans) = 0 And chans(0) Is Nothing Then
        ListAt = "no chans"
        SendWsock cptr.index, RPL_LISTEND & " " & cptr.Nick, ":End of /LIST"
        Exit Function
    End If
    
    'now, check the channels
    ListAt = "check parameters"
    Select Case parv(0)
        'no parameters - /list
        '// vbNullChar added, possibly a Winsock error could cause one to be returned -Zg
        Case vbNullString, vbNullChar
            ListAt = "no parameters"
            For i = 0 To UBound(chans)
                ListAt = "scan all channels"
                'the next bit makes sure that it shows only channels you're supposed to see
                'I probably need to handle private channels differently (so says CompNerd)
                If Not (chans(i).IsSecret Or chans(i).IsHidden Or chans(i).IsPrivate) Then
                    ListAt = "show all chans not +phs"
                    
                    SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(i).Name & " " & chans(i).Member.Count, ":[+" & GetModes(chans(i), True) & "] " & chans(i).Topic
                    
                    If MaxListLen > 0 Then
                        ret = ret + 1
                        If ret = MaxListLen Then Exit For
                    End If
                End If
            Next i
        'more users than - /list > 50
        'should /list >50 be allowed too?
        Case ">"
            ListAt = "more users than..."
            If UBound(parv) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "LIST")
                Exit Function
            End If
            'get the count...
            Ucount = CLng(MakeNumber(parv(1)))
            For i = LBound(chans) To UBound(chans)
                If chans(i).Member.Count > Ucount Then
                    'again, don't send +phs chans
                    If Not (chans(i).IsSecret Or chans(i).IsHidden Or chans(i).IsPrivate) Then
                        SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(i).Name & " " & chans(i).Member.Count, ":[+" & Replace(GetModes(chans(i), True), "+", "") & "] " & chans(i).Topic
                        If MaxListLen > 0 Then
                            ret = ret + 1
                            If ret = MaxListLen Then Exit For
                        End If
                    End If
                End If
            Next i
        'less users than - /list < 50
        'should /list <50 be allowed too?
        Case "<"
            ListAt = "less users than"
            If UBound(parv) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "LIST")
                Exit Function
            End If
            Ucount = CLng(MakeNumber(parv(1)))
            For i = LBound(chans) To UBound(chans)
                If chans(i).Member.Count < Ucount Then
                    If Not (chans(i).IsSecret Or chans(i).IsHidden Or chans(i).IsPrivate) Then
                        SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(i).Name & " " & chans(i).Member.Count, ":[+" & Replace(GetModes(chans(i), True), "+", "") & "] " & chans(i).Topic
                        If MaxListLen > 0 Then
                            ret = ret + 1
                            If ret = MaxListLen Then Exit For
                        End If
                    End If
                End If
            Next i
        'if it's other garbage
        Case Else
            ListAt = "case else"
            'if it contains wildcards (*)
            If InStr(1, parv(0), "*") > 0 Then
              ListAt = "contains wildcards"
              #If Debugging = 1 Then
                SendSvrMsg "contains wildcard"
              #End If
              'the following removes the # from the mask, if it begins with one
              'since Like considers # to be "any number". Placing it in brackets
              '([]) makes it work. Basically, VB makes you mask it with [ and ].
              NewMask = Replace(parv(0), "[", " [ ")
              NewMask = Replace(NewMask, "]", " ] ")
              NewMask = Replace(NewMask, "#", "[#]")
              NewMask = Replace(NewMask, " [ ", "[[]")
              NewMask = Replace(NewMask, " ] ", "[]]")
              
              'cycle through the channels
              For i = LBound(chans) To UBound(chans)
                  ListAt = "scanning channels"
                  #If Debugging = 1 Then
                    SendSvrMsg "chan: " & chans(i).Name & " mask: " & parv(0) & " escaped: " & NewMask
                  #End If
                  If UCase$(chans(i).Name) Like UCase$(NewMask) Then
                  'If UCase$(parv(0)) Like UCase$(chans(I).Name) Then
                      #If Debugging = 1 Then
                        SendSvrMsg "contains wildcard, matches"
                      #End If
                      ListAt = "matches wildcard"
                      If Not ((chans(i).IsSecret) Or (chans(i).IsHidden) Or (chans(i).IsPrivate)) Then
                          ListAt = "can be shown (w/c)"
                          SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(i).Name & " " & chans(i).Member.Count, ":[+" & Replace(GetModes(chans(i), True), "+", "") & "] " & chans(i).Topic
                          If MaxListLen > 0 Then
                              ret = ret + 1
                              If ret = MaxListLen Then Exit For
                          End If
                      End If
                  End If
              Next i
            End If
    End Select
    ListAt = "end of list"
    SendWsock cptr.index, 323 & " " & cptr.Nick, ":End of /LIST"
End If
Exit Function

ListError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_list' at " & ListAt
End Function


'/************************************************************************
' * m_names() - Added by Jto 27 Apr 1989
' ************************************************************************/
'
'/*
'** m_names
'**  parv$()[0] = sender prefix
'**  parv$()[1] = channel
'*/
Public Function m_names(cptr As clsClient, sptr As clsClient, parv$(), Optional ShowInvisible As Boolean = False) As Long
#If Debugging = 1 Then
    SendSvrMsg "NAMES called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
If cptr.AccessLevel = 4 Then
Else
  If Len(parv(0)) = 0 Then  'if no channels have been given, send need more params -Dill
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "NAMES")
    Exit Function
  End If
  Dim i&, Chan As clsChannel, RetVal$, x&, chans$(), Membrs() As clsChanMember, y&, z&
  Dim UserPrivs As Long
  
  chans = Split(parv(0), ",")
  For x = LBound(chans) To UBound(chans)
    Set Chan = Channels(chans(x))
    If Chan Is Nothing Then GoTo NextChan
    If Chan.IsSecret Or Chan.IsPrivate Then
        If Chan.GetUser(cptr.Nick) Is Nothing Then GoTo NextChan
    End If
    Membrs = Chan.Member.Values
    RetVal = Space$(500)
    y = 0
    
    '                                     [NQOV]
    'Normal = 0                           [0000]
    'Normal + Voice = 1                   [0001]
    'Normal + Host = 2                    [0010]
    'Normal + Host + Voice = 3            [0011]
    'Normal + Owner = 4                   [0100]
    'Normal + Owner + Voice = 5           [0101]
    'Normal + Owner + Host = 6            [0110]
    'Normal + Owner + Host + Voice = 7    [0111]
    
    If Chan.Member.Item(cptr.Nick).IsVoice Then UserPrivs = UserPrivs + 1
    If Chan.Member.Item(cptr.Nick).IsOp Then UserPrivs = UserPrivs + 2
    If Chan.Member.Item(cptr.Nick).IsOwner Then UserPrivs = UserPrivs + 4
    
    
    
    For i = LBound(Membrs) To UBound(Membrs) 'List all members of a chan -Dill
      With Membrs(i).Member
          y = y + 1
          If Membrs(i).IsOwner Then
            z = Len(.Nick)
            If cptr.IsIRCX Or cptr.AccessLevel = 4 Then
              'servers aren't supposed to send IRCX when they connect
              'so consider them to be IRCX anyways
              Mid$(RetVal, y, 1) = Level_Owner
            Else
              'older clients
              Mid$(RetVal, y, 1) = Level_Host
            End If
            y = y + 1
            Mid$(RetVal, y, z) = .Nick
            y = y + z
            
          ElseIf Membrs(i).IsOp Then
            z = Len(.Nick)
            Mid$(RetVal, y, 1) = Level_Host
            y = y + 1
            Mid$(RetVal, y, z) = .Nick
            y = y + z
          ElseIf Membrs(i).IsVoice Then
            If (Not Chan.IsAuditorium) Or (UserPrivs > 1) Then
              z = Len(.Nick)
              Mid$(RetVal, y, 1) = Level_Voice
              y = y + 1
              Mid$(RetVal, y, z) = .Nick
              y = y + z
            Else
              'if it's auditorium, still tell them about themselves
              If StrComp(UCase$(.Nick), UCase$(cptr.Nick)) = 0 Then
                z = Len(.Nick)
                Mid$(RetVal, y, 1) = Level_Voice
                y = y + 1
                Mid$(RetVal, y, z) = .Nick
                y = y + z
              End If
            End If
          Else
            If (Not Chan.IsAuditorium) Or (UserPrivs > 1) Then
              z = Len(.Nick)
              Mid$(RetVal, y, z) = .Nick
              y = y + z
            Else
              If StrComp(UCase$(.Nick), UCase$(cptr.Nick)) = 0 Then
                z = Len(.Nick)
                Mid$(RetVal, y, z) = .Nick
                y = y + z
              End If
            End If
          End If
          If y > 450 Then 'in case it exceeds 512 bytes, directly send names reply -Dill
            RetVal = Trim$(RetVal)
            'RetVal = Left$(RetVal, InStrRev(RetVal, " "))
            SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & Chan.Name, " :" & RetVal
            RetVal = Space$(500)
            i = i - 1
            y = 0
          End If
      End With
    Next i
    RetVal = Left$(RetVal, y - 1) 'remove leading/trailing spaces -Dill
    'if the buffer still contains char's, send em out -Dill
    Dim ChanStatus As String
    If Chan.IsPrivate Then
      ChanStatus = "*"
    ElseIf ((Chan.IsSecret) Or (Chan.IsHidden)) Then
      ChanStatus = "@"
    'possibly pick another char for hidden?
    Else
      ChanStatus = "="
    End If
    If Len(RetVal) > 0 Then SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " " & ChanStatus & " " & Chan.Name, ":" & RetVal
NextChan:
    SendWsock cptr.index, RPL_ENDOFNAMES & " " & cptr.Nick & " " & chans(x) & " :End of /NAMES list.", vbNullString
    RetVal = vbNullString
  Next x
End If
End Function

'/************************************************************************
' * Generic Channel functions
' ************************************************************************/


Public Function GetModes(Channel As clsChannel, Optional HideKey As Boolean = False) As String
#If Debugging = 1 Then
    SendSvrMsg "GETMODES called! (" & Channel.Name & ")"
#End If
Dim i&
GetModes = Space$(30)
i = 1
'TODO: Put these in alphabetical order, lowercase first (i.e. abcdABCD)
With Channel
    If .IsCloneable Then
        Mid$(GetModes, i, 1) = "d"
        i = i + 1
    End If
    If .IsClone Then
        Mid$(GetModes, i, 1) = "e"
        i = i + 1
    End If
    If .IsInviteOnly Then
        Mid$(GetModes, i, 1) = "i"
        i = i + 1
    End If
    If .IsModerated Then
        Mid$(GetModes, i, 1) = "m"
        i = i + 1
    End If
    If .IsNoExternalMsgs Then
        Mid$(GetModes, i, 1) = "n"
        i = i + 1
    End If
    If .IsPrivate Then
        Mid$(GetModes, i, 1) = "p"
        i = i + 1
    End If
    If .IsHidden Then
        Mid$(GetModes, i, 1) = "h"
        i = i + 1
    End If
    If .IsSecret Then
        Mid$(GetModes, i, 1) = "s"
        i = i + 1
    End If
    If .IsTopicOps Then
        Mid$(GetModes, i, 1) = "t"
        i = i + 1
    End If
    If .IsRegistered Then
        Mid$(GetModes, i, 1) = "r"
        i = i + 1
    End If
    If .IsAuditorium Then
        Mid$(GetModes, i, 1) = "x"
        i = i + 1
    End If
    If .IsMonitored Then
        Mid$(GetModes, i, 1) = "z"
        i = i + 1
    End If
    If .IsOperOnly Then
        Mid$(GetModes, i, 1) = "O"
        i = i + 1
    End If
    If .IsPersistant Then
        Mid$(GetModes, i, 1) = "R"
        i = i + 1
    End If
    If Len(.Key) > 0 And .Limit > 0 Then
        Mid$(GetModes, i, 3) = "lk "
        i = i + 3
        Mid$(GetModes, i, Len(CStr(.Limit))) = .Limit
        i = i + Len(CStr(.Limit))
        
        If Not HideKey Then
          Mid$(GetModes, i, Len(.Key)) = .Key
          i = i + Len(CStr(.Key))
        End If
    ElseIf Len(.Key) > 0 And .Limit = 0 Then
        If Not HideKey Then
          Mid$(GetModes, i, 1) = "k "
          i = i + 2
          Mid$(GetModes, i, Len(.Key)) = .Key
          i = i + Len(.Key)
        Else
          Mid$(GetModes, i, 1) = "k"
          i = i + 1
        End If
    ElseIf Len(.Key) = 0 And .Limit > 0 Then
        Mid$(GetModes, i, 3) = "l "
        i = i + 2
        Mid$(GetModes, i, Len(CStr(.Limit))) = .Limit
        i = i + Len(CStr(.Limit))
    End If
End With
GetModes = Left$(GetModes, i - 1)
End Function
Public Function GetModesX(Channel As clsChannel) As String
#If Debugging = 1 Then
    SendSvrMsg "GETMODESX called! (" & Channel.Name & ")"
#End If
Dim i&
GetModesX = Space$(30)
i = 1
'TODO: Put these in alphabetical order, lowercase first (i.e. abcdABCD)
With Channel
    If .IsInviteOnly Then
        Mid$(GetModesX, i, 1) = "i"
        i = i + 1
    End If
    If .IsModerated Then
        Mid$(GetModesX, i, 1) = "m"
        i = i + 1
    End If
    If .IsNoExternalMsgs Then
        Mid$(GetModesX, i, 1) = "n"
        i = i + 1
    End If
    If .IsPrivate Then
        Mid$(GetModesX, i, 1) = "p"
        i = i + 1
    End If
    If .IsHidden Then
        Mid$(GetModesX, i, 1) = "h"
        i = i + 1
    End If
    If .IsSecret Then
        Mid$(GetModesX, i, 1) = "s"
        i = i + 1
    End If
    If .IsTopicOps Then
        Mid$(GetModesX, i, 1) = "t"
        i = i + 1
    End If
    If .IsRegistered Then
        Mid$(GetModesX, i, 1) = "r"
        i = i + 1
    End If
    If .IsAuditorium Then
        Mid$(GetModesX, i, 1) = "x"
        i = i + 1
    End If
    If .IsMonitored Then
        Mid$(GetModesX, i, 1) = "z"
        i = i + 1
    End If
    If .IsOperOnly Then
        Mid$(GetModesX, i, 1) = "O"
        i = i + 1
    End If
    If .IsPersistant Then
        Mid$(GetModesX, i, 1) = "R"
        i = i + 1
    End If
End With
GetModesX = Left$(GetModesX, i - 1)
End Function
Public Function CreateMask$(InVar$)
#If Debugging = 1 Then
    SendSvrMsg "CREATEMASK called! (" & InVar & ")"
#End If
If (InVar Like "*!*?@*") Then
  CreateMask = InVar: Exit Function
ElseIf (InVar Like "*?!@?*") Then
  CreateMask = Replace(InVar, "!@", "!*@", , 1): Exit Function
ElseIf (InVar Like "*?!?*") Then
  CreateMask = InVar & "@*": Exit Function
ElseIf (InVar Like "*?@?*") Then
  CreateMask = "*!" & InVar: Exit Function
ElseIf (InVar Like "!?*") Then
  CreateMask = "*" & InVar & "@*": Exit Function
ElseIf (InVar Like "@?*") Then
  CreateMask = "*!*" & InVar: Exit Function
ElseIf (InVar Like "*?") Then
  CreateMask = InVar & "!*@*": Exit Function
End If
End Function
