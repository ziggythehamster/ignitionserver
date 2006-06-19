Attribute VB_Name = "m_channel_remote"
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
' $Id: m_channel_remote.bas,v 1.1 2005/06/14 04:00:07 ziggythehamster Exp $
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

Public Function m_access_remote(cptr As clsClient, sptr As clsClient, parv$()) As Long
  ':Nick ACCESS #Channel ADD|DELETE DENY|GRANT|VOICE|HOST|OWNER [Mask] [Duration] [Reason]
  '                0           1               2                  3         4        5
  'Last two parameters don't exist in DELETE
  
  '** Initialize Variables
  Dim Chan As clsChannel
  Dim tmpLevel As Boolean
  
  '** Code
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then Exit Function
  tmpLevel = Chan.Member.Item(sptr.Nick).IsOwner
  
  Select Case UCase$(parv(1))
    Case "ADD"
      'some basic info
      Select Case UCase$(parv(2))
        Case "DENY"
          'shouldn't these be find exact?
          If Not FindAccessEntry(Chan, parv(3), aDeny) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Bans.AddX parv(3), sptr.Nick, tmpLevel, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " DENY " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD DENY " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "GRANT"
          If Not FindAccessEntry(Chan, parv(3), aGrant) Then
            'don't send it if the grant already exists, just silently ignore it
            Chan.Grants.AddX parv(3), sptr.Nick, tmpLevel, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " GRANT " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD GRANT " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "VOICE"
          If Not FindAccessEntry(Chan, parv(3), aVoice) Then
            'don't send it if the voice already exists, just silently ignore it
            Chan.Voices.AddX parv(3), sptr.Nick, tmpLevel, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " VOICE " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD VOICE " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "HOST"
          If Not FindAccessEntry(Chan, parv(3), aHost) Then
            'don't send it if the host already exists, just silently ignore it
            Chan.Hosts.AddX parv(3), sptr.Nick, tmpLevel, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " HOST " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD HOST " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "OWNER"
          If Not FindAccessEntry(Chan, parv(3), aHost) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Owners.AddX parv(3), sptr.Nick, tmpLevel, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " OWNER " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD OWNER " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
      End Select '</type>
    Case "DELETE"
      Select Case UCase$(parv(2))
        Case "DENY"
          If Chan.Bans.Count > 0 Then
            If FindAccessEntry(Chan, parv(3), aDeny) Then
              'only remove deny if it doesn't exist
              Chan.Bans.Remove parv(3)
              SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & parv(3), 0
            End If
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE DENY " & parv(3), cptr.ServerName, sptr.Nick
        Case "GRANT"
          If Chan.Grants.Count > 0 Then
            If FindAccessEntry(Chan, parv(3), aGrant) Then
              Chan.Grants.Remove parv(3)
              SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & parv(3), 0
            End If
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE GRANT " & parv(3), cptr.ServerName, sptr.Nick
        Case "VOICE"
          If Chan.Voices.Count > 0 Then
            If FindAccessEntry(Chan, parv(3), aVoice) Then
              Chan.Voices.Remove parv(3)
              SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & parv(3), 0
            End If
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE VOICE " & parv(3), cptr.ServerName, sptr.Nick
        Case "HOST"
          If Chan.Hosts.Count > 0 Then
            If FindAccessEntry(Chan, parv(3), aHost) Then
              Chan.Hosts.Remove parv(3)
              SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & parv(3), 0
            End If
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE HOST " & parv(3), cptr.ServerName, sptr.Nick
        Case "OWNER"
          If Chan.Owners.Count > 0 Then
            If FindAccessEntry(Chan, parv(3), aOwner) Then
              Chan.Owners.Remove parv(3)
              SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & parv(3), 0
            End If
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE OWNER " & parv(3), cptr.ServerName, sptr.Nick
      End Select '</type>
    Case "CLEAR"
      If UBound(parv) = 2 Then
        Select Case UCase$(parv(2))
          Case "DENY"
            ClearAccessEntries Chan, aDeny, Chan.Member.Item(sptr.Nick).IsOwner
            SendToServer_ButOne "ACCESS " & Chan.Name & " CLEAR DENY", cptr.ServerName, sptr.Nick
          Case "GRANT"
            ClearAccessEntries Chan, aGrant, Chan.Member.Item(sptr.Nick).IsOwner
            SendToServer_ButOne "ACCESS " & Chan.Name & " CLEAR GRANT", cptr.ServerName, sptr.Nick
          Case "HOST"
            ClearAccessEntries Chan, aHost, Chan.Member.Item(sptr.Nick).IsOwner
            SendToServer_ButOne "ACCESS " & Chan.Name & " CLEAR HOST", cptr.ServerName, sptr.Nick
          Case "OWNER"
            ClearAccessEntries Chan, aOwner, Chan.Member.Item(sptr.Nick).IsOwner
            SendToServer_ButOne "ACCESS " & Chan.Name & " CLEAR OWNER", cptr.ServerName, sptr.Nick
          Case "VOICE"
            ClearAccessEntries Chan, aVoice, Chan.Member.Item(sptr.Nick).IsOwner
            SendToServer_ButOne "ACCESS " & Chan.Name & " CLEAR VOICE", cptr.ServerName, sptr.Nick
        End Select
      Else
        'clear all access
        'FIXME: cptr might be sending this access clear on behalf of a server
        'and servers are > owners. but they aren't an owner in the channel,
        'so the .IsOwner will return false.
        ClearAccessEntries Chan, aDeny, Chan.Member.Item(sptr.Nick).IsOwner
        ClearAccessEntries Chan, aGrant, Chan.Member.Item(sptr.Nick).IsOwner
        ClearAccessEntries Chan, aHost, Chan.Member.Item(sptr.Nick).IsOwner
        ClearAccessEntries Chan, aOwner, Chan.Member.Item(sptr.Nick).IsOwner
        ClearAccessEntries Chan, aVoice, Chan.Member.Item(sptr.Nick).IsOwner
        SendToServer_ButOne "ACCESS " & Chan.Name & " CLEAR", cptr.ServerName, sptr.Nick
      End If
  End Select '</all>

End Function
