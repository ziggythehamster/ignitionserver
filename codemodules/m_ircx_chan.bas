Attribute VB_Name = "m_ircx_chan"
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
' $Id: m_ircx_chan.bas,v 1.28 2004/12/05 04:00:38 ziggythehamster Exp $
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


'/*
' * This module contains the IRCX-specific channel functions (CLONE, CREATE, *
' * etc.). This module does not contain IRCX extensions to channels (PROP,   *
' * ACCESS, etc.). Just clarifying :)                                        *
' *                                                                          */

Option Explicit
#Const Debugging = 0

Public Function m_create(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = #Channel
'parv[1] = modes
'parv[2] = mode argument 1
'parv[3] = mode argument 2
Dim Chan As clsChannel
Dim CurrentInfo As String
If cptr.AccessLevel = 4 Then
'TODO: Accept CREATE from server
Else
  If cptr.IsIRCX = False Then
    'IRC clients should not be allowed to use this command
    SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNCOMMAND, , , "CREATE")
    Exit Function
  End If
  If Len(parv(0)) = 0 Then    'need more params
    CurrentInfo = "need more parameters"
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CREATE")
    Exit Function
  End If
  'TODO: there should be something besides "no such channel", surely there's a better raw >_<
  If Len(parv(0)) < 2 Then 'cant have a "blank" room name -Airwalk
    CurrentInfo = "channel name null"
    SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , parv(0))
    Exit Function
  End If
  If AscW(parv(0)) <> 35 Then
    CurrentInfo = "channel name does not begin with #"
    SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
    Exit Function
  End If
  If InStr(1, parv(0), "*") > 0 Then
      CurrentInfo = "illegal channel name"
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , parv(0))
      Exit Function
  End If
  If InStr(1, parv(0), "?") > 0 Then
      CurrentInfo = "illegal channel name"
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , parv(0))
      Exit Function
  End If
  If InStr(1, parv(0), Chr(7)) > 0 Then
      CurrentInfo = "illegal channel name"
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , parv(0))
      Exit Function
  End If
  If InStr(1, parv(0), ",") > 0 Then
      CurrentInfo = "illegal channel name"
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , parv(0))
      Exit Function
  End If
  If cptr.IsOnChan(parv(0)) Then 'already on the channel, complain -zg
      CurrentInfo = "already on channel"
      SendWsock cptr.index, IRCERR_ALREADYONCHANNEL & " " & cptr.Nick, TranslateCode(IRCERR_ALREADYONCHANNEL, , cptr.OnChannels.Item(parv(0)).Name)
      Exit Function
  End If
  If MaxChannelsPerUser > 0 Then
    If cptr.OnChannels.Count >= MaxChannelsPerUser Then
        'this could be turned into its own S: line thing
        'you're not really joining a chan, nor are you designated
        'owner
        CurrentInfo = "too many channels"
        SendWsock cptr.index, ERR_TOOMANYCHANNELS & " " & cptr.Nick, TranslateCode(ERR_TOOMANYCHANNELS, , parv(0))
        Exit Function
    End If
  End If
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then
    CurrentInfo = "channel does not exist"
    'channel does not exist
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
    Set Chan = Channels.Add(parv(0), New clsChannel)
    Chan.Name = parv(0)
    Chan.Prop_Creation = UnixTime
    Chan.Prop_Name = parv(0)
    
    'parse the modes
    If UBound(parv) = 3 Then
      Call ParseModes(parv(1) & " " & parv(2) & " " & parv(3), Chan)
    ElseIf UBound(parv) = 2 Then
      Call ParseModes(parv(1) & " " & parv(2), Chan)
    ElseIf UBound(parv) = 1 Then
      Call ParseModes(parv(1), Chan)
    End If
    If LogChannels = True Then Chan.IsMonitored = True
    
    'send CREATE message
    SendWsock cptr.index, "CREATE " & parv(0) & " 0", vbNullString
    Chan.Member.Add ChanOwner, cptr
    cptr.OnChannels.Add Chan, Chan.Name
    SendWsock cptr.index, cptr.Prefix & " JOIN " & parv(0), vbNullString, , True
    SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & parv(0), ":." & cptr.Nick
    SendWsock cptr.index, SPrefix & " " & RPL_ENDOFNAMES & " " & cptr.Nick & " " & Chan.Name & " :End of /NAMES list.", vbNullString, , True
    SendToServer "JOIN " & Chan.Name, cptr.Nick
    
    GenerateEvent "CHANNEL", "CREATE", Chan.Name, Chan.Name & " +" & Split(GetModes(Chan), " ")(0) & " " & Replace(cptr.Prefix, ":", "")
    GenerateEvent "MEMBER", "JOIN", Replace(cptr.Prefix, ":", ""), Chan.Name & " " & Replace(cptr.Prefix, ":", "") & " +q"
  Else
    CurrentInfo = "channel exists"
    'they're trying to use CREATE to JOIN
    'because they're on crack or something
    If UBound(parv) > 0 Then
      If InStr(1, parv(1), "c") <> 0 Then
        '+c flag was passed, which is quite unfortunate, because the channel already exists.
        SendWsock cptr.index, IRCERR_CHANNELEXIST & " " & cptr.Nick, TranslateCode(IRCERR_CHANNELEXIST, , parv(0))
        Exit Function
      End If
    End If
    'now, we'll want to check to see if the user can join
    'instead of repeating a buttload of code, we'll just
    '"fake" a call to m_join, just as soon as we check to
    'see if the command contains k and a password
    Dim tmpChan As clsChannel
    Dim tmpParv() As String
    
    Set tmpChan = New clsChannel
    
    If UBound(parv) = 3 Then
      Call ParseModes(parv(1) & " " & parv(2) & " " & parv(3), tmpChan)
    ElseIf UBound(parv) = 2 Then
      Call ParseModes(parv(1) & " " & parv(2), tmpChan)
    ElseIf UBound(parv) = 1 Then
      Call ParseModes(parv(1), tmpChan)
    End If
    
    If Len(tmpChan.Key) > 0 Then
      ReDim tmpParv(1)
      tmpParv(0) = parv(0)
      tmpParv(1) = tmpChan.Key
    Else
      ReDim tmpParv(0)
      tmpParv(0) = parv(0)
    End If
    
    m_join cptr, sptr, tmpParv
  End If
End If
End Function

Public Sub ParseModes(ModeString As String, Chan As clsChannel)
Dim ModesArray() As String
Dim CurParam As Long
Dim A As Long
CurParam = 1 '1 would default to the first mode parameter
ModesArray = Split(ModeString, " ")
For A = 1 To Len(ModesArray(0))
  If Chr(cmModerated) = Mid$(ModesArray(0), A, 1) Then Chan.IsModerated = True
  If Chr(cmNoExternalMsg) = Mid$(ModesArray(0), A, 1) Then Chan.IsNoExternalMsgs = True
  If Chr(cmOpTopic) = Mid$(ModesArray(0), A, 1) Then Chan.IsTopicOps = True
  If Chr(cmAuditorium) = Mid$(ModesArray(0), A, 1) Then Chan.IsAuditorium = True
  If Chr(cmHidden) = Mid$(ModesArray(0), A, 1) Then
    Chan.IsHidden = True
    Chan.IsSecret = False
    Chan.IsPrivate = False
  End If
  If Chr(cmInviteOnly) = Mid$(ModesArray(0), A, 1) Then Chan.IsInviteOnly = True
  If Chr(cmOperOnly) = Mid$(ModesArray(0), A, 1) Then Chan.IsOperOnly = True
  If Chr(cmPersistant) = Mid$(ModesArray(0), A, 1) And RegChanMode_ModeR Then Chan.IsPersistant = True
  If Chr(cmSecret) = Mid$(ModesArray(0), A, 1) Then
    Chan.IsSecret = True
    Chan.IsHidden = False
    Chan.IsPrivate = False
  End If
  If Chr(cmPrivate) = Mid$(ModesArray(0), A, 1) Then
    Chan.IsSecret = False
    Chan.IsHidden = False
    Chan.IsPrivate = True
  End If
  If Chr(cmLimit) = Mid$(ModesArray(0), A, 1) Then
    If UBound(ModesArray) > 0 And UBound(ModesArray) >= CurParam Then
      'make sure we aren't going out of bounds
      'also adds protection against this kind of malformed create:
      '+mplntl 50
      'the last "l" would be ignored because CurParam would be greater than
      'the greatest modesarray
      Chan.Limit = CLng(ModesArray(CurParam))
      CurParam = CurParam + 1
    End If
  End If
  If Chr(cmKey) = Mid$(ModesArray(0), A, 1) Then
    If UBound(ModesArray) > 0 And UBound(ModesArray) >= CurParam Then
      Chan.Key = CStr(ModesArray(CurParam))
      Chan.Prop_Memberkey = UTF8_Unescape(CStr(ModesArray(CurParam)))
      CurParam = CurParam + 1
     End If
  End If
  'todo: allow opers to make a chan +r
Next A
End Sub
Public Function m_whisper(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHISPER called! (" & cptr.Nick & ")"
#End If
'/*****************************************************
'* I know, this is basically a copy of m_message -_-  *
'******************************************************/
Dim cmd$, RecList$(), i, x&, Chan As clsChannel, Recp As clsClient, RecvServer() As clsClient, ChM As clsChanMember
If cptr.AccessLevel = 4 Then
    Set Chan = Channels(parv(0))
    If Chan Is Nothing Then Exit Function
    
    RecList = Split(parv(1), ",")
    For Each i In RecList
        If AscW(CStr(i)) = 35 Then
            'you can't whisper to a channel...
            GoTo NextCmd
        Else
            Set Recp = GlobUsers(CStr(i))
            If Recp Is Nothing Then
                GoTo NextCmd
            End If
            If Recp.Hops > 0 Then
                'The user is an remote user
                SendWsock Recp.FromLink.index, "WHISPER " & Chan.Name & " " & Recp.Nick, ":" & parv(2), ":" & sptr.Nick
            Else
                'the user is an local user
                SendWsock Recp.index, "WHISPER " & Chan.Name & " " & Recp.Nick, ":" & parv(2), sptr.Prefix
            End If
            If LogChannelWhispers Then LogChannel Chan.Name, "[" & sptr.Nick & " whispers to " & Recp.Nick & "] " & parv(2)
        End If
NextCmd:
    Next
Else
    If Len(parv(0)) = 0 Then 'if no recipient is given, return an error -Dill
      SendWsock cptr.index, ERR_NORECIPIENT & " " & cptr.Nick, TranslateCode(ERR_NORECIPIENT, "WHISPER")
      Exit Function
    End If
    If UBound(parv) = 1 Then 'if cptr didnt tell us what to send, complain -Dill
      SendWsock cptr.index, ERR_NOTEXTTOSEND & " " & cptr.Nick, TranslateCode(ERR_NOTEXTTOSEND)
      Exit Function
    End If
    If Len(parv(2)) = 0 Then
      SendWsock cptr.index, ERR_NOTEXTTOSEND & " " & cptr.Nick, TranslateCode(ERR_NOTEXTTOSEND)
      Exit Function
    End If
    If cptr.IsGagged Then 'if they're gagged, they can't speak
      If BounceGagMsg Then SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
      Exit Function
    End If
    'does the channel exist?
    Set Chan = Channels(parv(0))
    If Chan Is Nothing Then
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
      Exit Function
    End If
    
    'allow them to whisper if the channel is -n
    If Chan.Member.Item(cptr.Nick) Is Nothing And Chan.IsNoExternalMsgs Then
      SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOTONCHANNEL, , Chan.Name)
      Exit Function
    End If
    
    RecList = Split(parv(1), ",")
    For Each i In RecList
      If Len(i) = 0 Then GoTo nextmsg
      If AscW(CStr(i)) = 35 Then
        SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(i))
        GoTo nextmsg
      Else
        'user message -Dill
        If InStr(1, i, "*") <> 0 Then
          If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then 'Can't send to wildcarded recipient list if not an oper -Dill
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
          Else
            'WILDCARD recievelist -Dill
            Dim Umask$, Target() As clsClient
            Umask = ":" & CreateMask(CStr(i))
            Target = GlobUsers.Values
            For x = LBound(Target) To UBound(Target)
                If Target(x).Prefix Like Umask Then
                    If Target(x).Hops = 0 Then
                        SendWsock Target(x).index, "WHISPER " & Chan.Name & " " & Target(x).Nick, ":" & parv(2), cptr.Prefix
                    Else
                        SendWsock Target(x).FromLink.index, "WHISPER " & Chan.Name & " " & Target(x).Nick, ":" & parv(2), ":" & cptr.Nick
                    End If
                End If
            Next x
            GoTo nextmsg
          End If
        End If
        
        'not wildcarded
        On Local Error Resume Next
        'to avoid possible confusion
        'we're using sptr in order to not waste memory with initializing another client class
        Set sptr = GlobUsers(CStr(i))
        If sptr Is Nothing Then 'in case user does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(i))
          GoTo nextmsg
        End If
        Dim tmpChan As clsChannel
        
        'don't deliver the whisper if they're not on the channel specified
        Set tmpChan = sptr.OnChannels.Item(Chan.Name)
        If tmpChan Is Nothing Then
          SendWsock cptr.index, ERR_USERNOTINCHANNEL, cptr.Nick & " " & TranslateCode(ERR_USERNOTINCHANNEL, sptr.Nick, Chan.Name)
          GoTo nextmsg
        End If
        
        'deliver the message -Dill
        If sptr.Hops = 0 Then
            SendWsock sptr.index, "WHISPER " & Chan.Name & " " & sptr.Nick, ":" & parv(2), cptr.Prefix
        Else
            SendWsock sptr.FromLink.index, "WHISPER " & Chan.Name & " " & sptr.Nick, ":" & parv(2), ":" & cptr.Nick
        End If
        If Len(sptr.AwayMsg) > 0 Then
            SendWsock cptr.index, RPL_AWAY & " " & cptr.Nick & " " & sptr.Nick, ":" & sptr.AwayMsg
        End If
        'reset idle time
        If LogChannelWhispers Then LogChannel Chan.Name, "[" & cptr.Nick & " whispers to " & sptr.Nick & "] " & parv(2)
        cptr.Idle = UnixTime
      End If
nextmsg:
    Next
End If
End Function

Public Function AuditoriumShowClients(Chan As clsChannel, cptr As clsClient)
'This function's purpose is to notify a client that just got opped in a channel
'that's auditorium about the other clients

Dim A As Long
Dim ChanUsers() As clsChanMember
If GlobUsers.Count = 0 Then Exit Function
If Chan.Member.Count = 0 Then Exit Function

ChanUsers = Chan.Member.Values

For A = 1 To Chan.Member.Count
  If Not ((ChanUsers(A).IsOp) Or (ChanUsers(A).IsOwner)) Then
    'they're on the same channel as us, and aren't owners or hosts
    If StrComp(ChanUsers(A).Member.GUID, cptr.GUID) <> 0 Then
      SendWsock cptr.index, "JOIN", ":" & Chan.Name, ChanUsers(A).Member.Prefix
    End If
  End If
Next A
Exit Function
End Function

Public Function AuditoriumHideClients(Chan As clsChannel, cptr As clsClient)
Dim A As Long
Dim ChanUsers() As clsChanMember
If GlobUsers.Count = 0 Then Exit Function
If Chan.Member.Count = 0 Then Exit Function

ChanUsers = Chan.Member.Values

For A = 1 To Chan.Member.Count
  If Not ((ChanUsers(A).IsOp) Or (ChanUsers(A).IsOwner)) Then
    'they're on the same channel as us, and aren't owners or hosts
    If StrComp(ChanUsers(A).Member.GUID, cptr.GUID) <> 0 Then
      SendWsock cptr.index, "PART", Chan.Name, ChanUsers(A).Member.Prefix
    End If
  End If
Next A
End Function
