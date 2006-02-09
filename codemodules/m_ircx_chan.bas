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
' $Id: m_ircx_chan.bas,v 1.9 2004/06/26 07:01:13 ziggythehamster Exp $
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
'Todo
Else
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
  If cptr.IsOnChan(parv(0)) Then Exit Function
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then
    CurrentInfo = "channel does not exist"
    'channel does not exist
    Set Chan = Channels.Add(parv(0), New clsChannel)
    Chan.Name = parv(0)
    Chan.Prop_Creation = UnixTime
    Chan.Prop_Name = parv(0)
    Chan.Member.Add ChanOwner, cptr
    cptr.OnChannels.Add Chan, Chan.Name
    
    If UBound(parv) = 3 Then
      Call ParseModes(parv(1) & " " & parv(2) & " " & parv(3), Chan)
    ElseIf UBound(parv) = 2 Then
      Call ParseModes(parv(1) & " " & parv(2), Chan)
    ElseIf UBound(parv) = 1 Then
      Call ParseModes(parv(1), Chan)
    End If
    SendWsock cptr.index, "CREATE " & parv(0) & " 0", vbNullString
    SendWsock cptr.index, cptr.Prefix & " JOIN " & parv(0), vbNullString, , True
    If cptr.IsIRCX Then
      SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & parv(0), ":." & cptr.Nick
    Else
      'why you'd be non-IRCX and send CREATE... i dunno
      SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & parv(0), ":@" & cptr.Nick
    End If
    SendWsock cptr.index, SPrefix & " " & RPL_ENDOFNAMES & " " & cptr.Nick & " " & Chan.Name & " :End of /NAMES list.", vbNullString, , True
    SendToServer "JOIN " & Chan.Name, cptr.Nick
    GenerateEvent "USER", "JOIN", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & Chan.Name
    GenerateEvent "CHANNEL", "CREATE", Chan.Name, Chan.Name & " " & cptr.Nick
    GenerateEvent "CHANNEL", "JOIN", Chan.Name, Chan.Name & " " & cptr.Nick
  Else
    CurrentInfo = "channel exists"
    SendWsock cptr.index, IRCERR_CHANNELEXIST & " " & cptr.Nick, TranslateCode(IRCERR_CHANNELEXIST, , parv(0))
  End If
End If
End Function

Public Sub ParseModes(ModeString As String, Chan As clsChannel)
Dim ModesArray() As String
Dim CurParam As Integer
Dim A As Integer
CurParam = 1 '1 would default to the first mode parameter
ModesArray = Split(ModeString, " ")
For A = 1 To Len(ModesArray(0))
  If Chr(cmModerated) = Mid$(ModesArray(0), A, 1) Then Chan.IsModerated = True
  If Chr(cmNoExternalMsg) = Mid$(ModesArray(0), A, 1) Then Chan.IsNoExternalMsgs = True
  If Chr(cmOpTopic) = Mid$(ModesArray(0), A, 1) Then Chan.IsTopicOps = True
  If Chr(cmHidden) = Mid$(ModesArray(0), A, 1) Then
    Chan.IsHidden = True
    Chan.IsSecret = False
    Chan.IsPrivate = False
  End If
  If Chr(cmInviteOnly) = Mid$(ModesArray(0), A, 1) Then Chan.IsInviteOnly = True
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
      Chan.Prop_Memberkey = CStr(ModesArray(CurParam))
      CurParam = CurParam + 1
     End If
  End If
  'todo: allow opers to make a chan +r
Next A
End Sub
