Attribute VB_Name = "m_channel_local"
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
' $Id: m_channel_local.bas,v 1.2 2005/07/09 00:15:15 ziggythehamster Exp $
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

Public Function m_access_local(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
  SendSvrMsg "ACCESS (local) called! (" & cptr.Nick & ")"
#End If
  
  On Error GoTo errtrap
  Dim A As Long
  Dim Chan As clsChannel
  Dim Mask As String
  Dim tmpLoc As String
  tmpLoc = "entry"
  
  Set Chan = Channels(parv(0))
  Dim r As Boolean
  Dim r_d As Boolean
  Dim r_g As Boolean
  Dim r_h As Boolean
  Dim r_o As Boolean
  Dim r_v As Boolean
  #If Debugging = 1 Then
    SendSvrMsg "Channel Ready"
  #End If
  
  If Chan Is Nothing Then
    tmpLoc = "channel does not exist"
    SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
    Exit Function
  Else
    tmpLoc = "Cycle Access"
    Call CycleAccess(Chan)
    tmpLoc = "channel exists"
    
    If Not cptr.IsOnChan(Chan.Name) Then
      SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , Chan.Name)
      Exit Function
    End If
    
    If UBound(parv) >= 1 Then
    tmpLoc = "specified a command"
    '#Channel (cmd)
    '0          1
    'we want ACCESS #Channel to be seperate - means "LIST"
      Select Case UCase$(parv(1))
        Case "CLEAR"
          tmpLoc = "clear access"
          If UBound(parv) = 1 Then
            tmpLoc = "clear all access place 1"
            r_d = ClearAccessEntries(Chan, aDeny, Chan.Member.Item(cptr.Nick).IsOwner)
            tmpLoc = "clear all access place 2"
            r_g = ClearAccessEntries(Chan, aGrant, Chan.Member.Item(cptr.Nick).IsOwner)
            tmpLoc = "clear all access place 3"
            r_h = ClearAccessEntries(Chan, aHost, Chan.Member.Item(cptr.Nick).IsOwner)
            tmpLoc = "clear all access place 4"
            r_o = ClearAccessEntries(Chan, aOwner, Chan.Member.Item(cptr.Nick).IsOwner)
            tmpLoc = "clear all access place 5"
            r_v = ClearAccessEntries(Chan, aVoice, Chan.Member.Item(cptr.Nick).IsOwner)
            SendToServer "ACCESS " & Chan.Name & " CLEAR", cptr.Nick
            tmpLoc = "clear all access place 6"
            'this won't run if these are all true, but if any of these are false, it'll run
            If Not (r_d And r_g And r_h And r_o And r_v) Then SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
          Else
            tmpLoc = "clear specific level"
            If UCase$(parv(2)) = "GRANT" Then
              tmpLoc = "clear grants"
              r = ClearAccessEntries(Chan, aGrant, Chan.Member.Item(cptr.Nick).IsOwner)
              If Not r Then SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
              SendToServer "ACCESS " & Chan.Name & " CLEAR GRANT", cptr.Nick
            ElseIf UCase$(parv(2)) = "DENY" Then
              tmpLoc = "clear denys"
              r = ClearAccessEntries(Chan, aDeny, Chan.Member.Item(cptr.Nick).IsOwner)
              If Not r Then SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
              SendToServer "ACCESS " & Chan.Name & " CLEAR DENY", cptr.Nick
            ElseIf UCase$(parv(2)) = "VOICE" Then
              tmpLoc = "clear voices"
              r = ClearAccessEntries(Chan, aVoice, Chan.Member.Item(cptr.Nick).IsOwner)
              If Not r Then SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
              SendToServer "ACCESS " & Chan.Name & " CLEAR VOICE", cptr.Nick
            ElseIf UCase$(parv(2)) = "HOST" Then
              tmpLoc = "clear hosts"
              r = ClearAccessEntries(Chan, aHost, Chan.Member.Item(cptr.Nick).IsOwner)
              If Not r Then SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
              SendToServer "ACCESS " & Chan.Name & " CLEAR HOST", cptr.Nick
            ElseIf UCase$(parv(2)) = "OWNER" Then
              tmpLoc = "clear owners"
              'can only remove access for owner if owner, else return no permissions to perform command
              If Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "clear owners (owner)"
                r = ClearAccessEntries(Chan, aOwner, Chan.Member.Item(cptr.Nick).IsOwner)
                If Not r Then SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
                SendToServer "ACCESS " & Chan.Name & " CLEAR OWNER", cptr.Nick
              Else
                tmpLoc = "clear owners (no access)"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            Else
              tmpLoc = "bad level"
              'not grant/deny/voice/host/owner
              SendWsock cptr.index, IRCERR_BADLEVEL & " " & cptr.Nick, TranslateCode(IRCERR_BADLEVEL)
            End If
          End If
        Case "ADD"
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ACCESS ADD
          '#Channel ADD <level> <mask> <time> :<reason>
          '  0       1     2      3       4      5
          tmpLoc = "add access"
          Dim AccessAdd_Duration As Long
          Dim AccessAdd_Reason As String
          
          If UBound(parv) = 3 Then
            AccessAdd_Duration = 0
            AccessAdd_Reason = vbNullString
          ElseIf UBound(parv) = 4 Then
            AccessAdd_Duration = MakeNumber(parv(4))
            AccessAdd_Reason = vbNullString
          ElseIf UBound(parv) = 5 Then
            AccessAdd_Duration = MakeNumber(parv(4))
            AccessAdd_Reason = parv(5)
          Else
            tmpLoc = "add needs more params"
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS)
            Exit Function
          End If
          tmpLoc = "add has params"
          If UCase$(parv(2)) = "GRANT" Then
            tmpLoc = "grant"
            If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "can set grant"
              Mask = CreateMask(parv(3))
              If Not FindAccessEntry(Chan, Mask, aGrant) Then
                tmpLoc = "grant does not exist"
                If Len(Mask) > 0 Then
                  Chan.Grants.AddX CStr(Mask), CStr(cptr.Nick), Chan.Member.Item(cptr.Nick).IsOwner, CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
                  SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " GRANT " & Mask & " " & AccessAdd_Duration & " " & cptr.Nick & " :" & AccessAdd_Reason, 0
                  SendToServer "ACCESS " & Chan.Name & " ADD GRANT " & Mask & " " & AccessAdd_Duration & " :" & AccessAdd_Reason, cptr.Nick
                End If
              Else
                tmpLoc = "grant exists"
                'access entry already exists
                SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
              End If
            Else
              tmpLoc = "cannot set grant"
              SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
            End If
          ElseIf UCase$(parv(2)) = "DENY" Then
            tmpLoc = "deny"
            If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "can set deny"
              Mask = CreateMask(parv(3))
              If Not FindAccessEntry(Chan, Mask, aDeny) Then
                tmpLoc = "deny does not exist"
                If Len(Mask) > 0 Then
                  Chan.Bans.AddX CStr(Mask), CStr(cptr.Nick), Chan.Member.Item(cptr.Nick).IsOwner, CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
                  SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " DENY " & Mask & " " & AccessAdd_Duration & " " & cptr.Nick & " :" & AccessAdd_Reason, 0
                  SendToServer "ACCESS " & Chan.Name & " ADD DENY " & Mask & " " & AccessAdd_Duration & " :" & AccessAdd_Reason, cptr.Nick
                End If
              Else
                tmpLoc = "deny exists"
                'access entry exists
                SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
              End If
            Else
              tmpLoc = "cannot set deny"
              SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
            End If
          ElseIf UCase$(parv(2)) = "VOICE" Then
            tmpLoc = "voice"
            If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "can set vouce"
              Mask = CreateMask(parv(3))
              If Not FindAccessEntry(Chan, Mask, aVoice) Then
                tmpLoc = "voice does not exist"
                If Len(Mask) > 0 Then
                  Chan.Voices.AddX CStr(Mask), CStr(cptr.Nick), Chan.Member.Item(cptr.Nick).IsOwner, CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
                  SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " VOICE " & Mask & " " & AccessAdd_Duration & " " & cptr.Nick & " :" & AccessAdd_Reason, 0
                  SendToServer "ACCESS " & Chan.Name & " ADD VOICE " & Mask & " " & AccessAdd_Duration & " :" & AccessAdd_Reason, cptr.Nick
                End If
              Else
                tmpLoc = "voice exists"
                SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
              End If
            Else
              tmpLoc = "cannot set voice"
              SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
            End If
          ElseIf UCase$(parv(2)) = "HOST" Then
            tmpLoc = "host"
            If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "can set host"
              Mask = CreateMask(parv(3))
              tmpLoc = "generated mask"
              If Not FindAccessEntry(Chan, Mask, aHost) Then
                tmpLoc = "host does not exist"
                If Len(Mask) > 0 Then
                  Chan.Hosts.AddX CStr(Mask), CStr(cptr.Nick), Chan.Member.Item(cptr.Nick).IsOwner, CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
                  SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " HOST " & Mask & " " & AccessAdd_Duration & " " & cptr.Nick & " :" & AccessAdd_Reason, 0
                  SendToServer "ACCESS " & Chan.Name & " ADD HOST " & Mask & " " & AccessAdd_Duration & " :" & AccessAdd_Reason, cptr.Nick
                End If
              Else
                tmpLoc = "host exists"
                SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
              End If
            Else
              tmpLoc = "cannot set host"
              SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
            End If
          ElseIf UCase$(parv(2)) = "OWNER" Then
            tmpLoc = "owner"
            If Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "can set owner"
              Mask = CreateMask(parv(3))
              If Not FindAccessEntry(Chan, Mask, aOwner) Then
                tmpLoc = "owner does not exist"
                If Len(Mask) > 0 Then
                  Chan.Owners.AddX CStr(Mask), CStr(cptr.Nick), Chan.Member.Item(cptr.Nick).IsOwner, CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
                  SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " OWNER " & Mask & " " & AccessAdd_Duration & " " & cptr.Nick & " :" & AccessAdd_Reason, 0
                  SendToServer "ACCESS " & Chan.Name & " ADD OWNER " & Mask & " " & AccessAdd_Duration & " :" & AccessAdd_Reason, cptr.Nick
                End If
              Else
                tmpLoc = "owner exists"
                SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
              End If
            Else
              tmpLoc = "cannot set owner"
              SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
            End If
          Else
            tmpLoc = "set bad level for add"
            SendWsock cptr.index, IRCERR_BADLEVEL & " " & cptr.Nick, TranslateCode(IRCERR_BADLEVEL)
          End If
        Case "DELETE"
  '%%%%%%%%%%%%%%%%%%%%%%%%% DELETE ACCESS
          If UBound(parv) < 3 Then
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS)
            Exit Function
          Else
            tmpLoc = "delete access start"
            If UCase$(parv(2)) = "GRANT" Then
              tmpLoc = "delete grant"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete grant"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindAccessEntry(Chan, Mask, aGrant) Then
                    tmpLoc = "cannot delete grant - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS, TranslateCode(IRCERR_MISACCESS, cptr.Nick)
                  Else
                    tmpLoc = "grant exists, deleting"
                    'the entry does exist, delete and return message
                    If RemoveAccessEntry(Chan, Mask, aGrant, Chan.Member.Item(cptr.Nick).IsOwner) Then
                      SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & Mask, 0
                      SendToServer "ACCESS " & Chan.Name & " DELETE GRANT " & Mask, cptr.Nick
                    Else
                      tmpLoc = "can't delete grant, created by owner"
                      SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                    End If
                  End If
                Else
                  tmpLoc = "can't delete grant"
                  SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                End If
              End If
            ElseIf UCase$(parv(2)) = "DENY" Then
              tmpLoc = "delete deny"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete deny"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindAccessEntry(Chan, Mask, aDeny) Then
                    tmpLoc = "cannot delete deny - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS, TranslateCode(IRCERR_MISACCESS, cptr.Nick)
                  Else
                    If RemoveAccessEntry(Chan, Mask, aDeny, Chan.Member.Item(cptr.Nick).IsOwner) Then
                      SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & Mask, 0
                      SendToServer "ACCESS " & Chan.Name & " DELETE DENY " & Mask, cptr.Nick
                    Else
                      tmpLoc = "can't delete deny, created by owner"
                      SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                    End If
                  End If
                End If
              Else
                tmpLoc = "can't delete deny"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase$(parv(2)) = "VOICE" Then
              tmpLoc = "delete voice"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete voice"

                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindAccessEntry(Chan, Mask, aVoice) Then
                    tmpLoc = "cannot delete voice - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS, TranslateCode(IRCERR_MISACCESS, cptr.Nick)
                  Else
                    If RemoveAccessEntry(Chan, Mask, aVoice, Chan.Member.Item(cptr.Nick).IsOwner) Then
                      SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & Mask, 0
                      SendToServer "ACCESS " & Chan.Name & " DELETE VOICE " & Mask, cptr.Nick
                    Else
                      tmpLoc = "can't delete voice, created by owner"
                      SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                    End If
                  End If
                End If
              Else
                tmpLoc = "cannot delete voice"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase$(parv(2)) = "HOST" Then
               tmpLoc = "delete host"
               If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete host"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindAccessEntry(Chan, Mask, aHost) Then
                    tmpLoc = "cannot delete host - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS, TranslateCode(IRCERR_MISACCESS, cptr.Nick)
                  Else
                    If RemoveAccessEntry(Chan, Mask, aHost, Chan.Member.Item(cptr.Nick).IsOwner) Then
                      SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & Mask, 0
                      SendToServer "ACCESS " & Chan.Name & " DELETE HOST " & Mask, cptr.Nick
                    Else
                      tmpLoc = "can't delete host, created by owner"
                      SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                    End If
                  End If
                End If
              Else
                tmpLoc = "cannot delete host"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase$(parv(2)) = "OWNER" Then
              tmpLoc = "delete owner"
              If Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete owner"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindAccessEntry(Chan, Mask, aOwner) Then
                    tmpLoc = "cannot delete owner - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS, TranslateCode(IRCERR_MISACCESS, cptr.Nick)
                  Else
                    If RemoveAccessEntry(Chan, Mask, aOwner, Chan.Member.Item(cptr.Nick).IsOwner) Then
                      SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & Mask, 0
                      SendToServer "ACCESS " & Chan.Name & " DELETE OWNER " & Mask, cptr.Nick
                    Else
                      tmpLoc = "can't delete owner, created by owner"
                      SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                    End If
                  End If
                End If
              Else
                tmpLoc = "cannot delete owner"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            Else
              tmpLoc = "cannot delete - bad level"
              SendWsock cptr.index, IRCERR_BADLEVEL & " " & cptr.Nick, TranslateCode(IRCERR_BADLEVEL)
            End If
          End If
        Case "LIST", "*":
  '%%%%%%%%%%%%%%%%%%%%%%%%% LIST ACCESS
          '# LIST
          '0 1
          'Mathematically speaking,
          'TimeRemaining = Duration - TimeSoFar
          'TimeSoFar = (CurrentTime - TimeSetAt) \ 60
          'rationale:
          'The current time is the current UNIX timestamp
          'Time set at is also a UNIX timestamp
          'Subtracting the two gets you the number of seconds that have elapsed
          'Divide by 60 to get the number of minutes (int divide saves an Int())
          tmpLoc = "list, compute stuff"
          Dim TimeRemaining As Long

          tmpLoc = "list"
          If UBound(parv) >= 1 Then
            If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
              SendWsock cptr.index, IRCRPL_ACCESSSTART & " " & cptr.Nick & " " & Chan.Name, ":Start of access entries"
              If CLng(Chan.Owners.Count) > 0 Then
                For A = 1 To Chan.Owners.Count
                  TimeRemaining = Chan.Owners.Item(A).Duration - ((UnixTime - Chan.Owners.Item(A).SetOn) \ 60)
                  If Chan.Owners.Item(A).Duration = 0 Then TimeRemaining = 0
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "OWNER " & Chan.Owners.Item(A).Mask & " " & TimeRemaining & " " & Chan.Owners.Item(A).SetBy & " :" & Chan.Owners.Item(A).Reason
                Next A
              End If
              If Chan.Hosts.Count > 0 Then
                For A = 1 To Chan.Hosts.Count
                  TimeRemaining = Chan.Hosts.Item(A).Duration - ((UnixTime - Chan.Hosts.Item(A).SetOn) \ 60)
                  If Chan.Hosts.Item(A).Duration = 0 Then TimeRemaining = 0
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "HOST " & Chan.Hosts.Item(A).Mask & " " & TimeRemaining & " " & Chan.Hosts.Item(A).SetBy & " :" & Chan.Hosts.Item(A).Reason
                Next A
              End If
              If Chan.Voices.Count > 0 Then
                For A = 1 To Chan.Voices.Count
                  TimeRemaining = Chan.Voices.Item(A).Duration - ((UnixTime - Chan.Voices.Item(A).SetOn) \ 60)
                  If Chan.Voices.Item(A).Duration = 0 Then TimeRemaining = 0
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "VOICE " & Chan.Voices.Item(A).Mask & " " & TimeRemaining & " " & Chan.Voices.Item(A).SetBy & " :" & Chan.Voices.Item(A).Reason
                Next A
              End If
              If Chan.Grants.Count > 0 Then
                For A = 1 To Chan.Grants.Count
                  TimeRemaining = Chan.Grants.Item(A).Duration - ((UnixTime - Chan.Grants.Item(A).SetOn) \ 60)
                  If Chan.Grants.Item(A).Duration = 0 Then TimeRemaining = 0
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "GRANT " & Chan.Grants.Item(A).Mask & " " & TimeRemaining & " " & Chan.Grants.Item(A).SetBy & " :" & Chan.Grants.Item(A).Reason
                Next A
              End If
              If Chan.Bans.Count > 0 Then
                For A = 1 To Chan.Bans.Count
                  TimeRemaining = Chan.Bans.Item(A).Duration - ((UnixTime - Chan.Bans.Item(A).SetOn) \ 60)
                  If Chan.Bans.Item(A).Duration = 0 Then TimeRemaining = 0
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "DENY " & Chan.Bans.Item(A).Mask & " " & TimeRemaining & " " & Chan.Bans.Item(A).SetBy & " :" & Chan.Bans.Item(A).Reason
                Next A
              End If
              SendWsock cptr.index, IRCRPL_ACCESSEND & " " & cptr.Nick & " " & Chan.Name, ":End of access entries"
            Else
              SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
            End If
          Else
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS)
            Exit Function
          End If
        Case Else:
          SendWsock cptr.index, IRCERR_BADCOMMAND & " " & cptr.Nick, "ACCESS " & TranslateCode(IRCERR_BADCOMMAND)
      End Select
    Else
      If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
        SendWsock cptr.index, IRCRPL_ACCESSSTART & " " & cptr.Nick & " " & Chan.Name, ":Start of access entries"
        If CLng(Chan.Owners.Count) > 0 Then
          For A = 1 To Chan.Owners.Count
            TimeRemaining = Chan.Owners.Item(A).Duration - ((UnixTime - Chan.Owners.Item(A).SetOn) \ 60)
            If Chan.Owners.Item(A).Duration = 0 Then TimeRemaining = 0
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "OWNER " & Chan.Owners.Item(A).Mask & " " & TimeRemaining & " " & Chan.Owners.Item(A).SetBy & " :" & Chan.Owners.Item(A).Reason
          Next A
        End If
        If Chan.Hosts.Count > 0 Then
          For A = 1 To Chan.Hosts.Count
            TimeRemaining = Chan.Hosts.Item(A).Duration - ((UnixTime - Chan.Hosts.Item(A).SetOn) \ 60)
            If Chan.Hosts.Item(A).Duration = 0 Then TimeRemaining = 0
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "HOST " & Chan.Hosts.Item(A).Mask & " " & TimeRemaining & " " & Chan.Hosts.Item(A).SetBy & " :" & Chan.Hosts.Item(A).Reason
          Next A
        End If
        If Chan.Voices.Count > 0 Then
          For A = 1 To Chan.Voices.Count
            TimeRemaining = Chan.Voices.Item(A).Duration - ((UnixTime - Chan.Voices.Item(A).SetOn) \ 60)
            If Chan.Voices.Item(A).Duration = 0 Then TimeRemaining = 0
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "VOICE " & Chan.Voices.Item(A).Mask & " " & TimeRemaining & " " & Chan.Voices.Item(A).SetBy & " :" & Chan.Voices.Item(A).Reason
          Next A
        End If
        If Chan.Grants.Count > 0 Then
          For A = 1 To Chan.Grants.Count
            TimeRemaining = Chan.Grants.Item(A).Duration - ((UnixTime - Chan.Grants.Item(A).SetOn) \ 60)
            If Chan.Grants.Item(A).Duration = 0 Then TimeRemaining = 0
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "GRANT " & Chan.Grants.Item(A).Mask & " " & TimeRemaining & " " & Chan.Grants.Item(A).SetBy & " :" & Chan.Grants.Item(A).Reason
          Next A
        End If
        If Chan.Bans.Count > 0 Then
          For A = 1 To Chan.Bans.Count
            TimeRemaining = Chan.Bans.Item(A).Duration - ((UnixTime - Chan.Bans.Item(A).SetOn) \ 60)
            If Chan.Bans.Item(A).Duration = 0 Then TimeRemaining = 0
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "DENY " & Chan.Bans.Item(A).Mask & " " & TimeRemaining & " " & Chan.Bans.Item(A).SetBy & " :" & Chan.Bans.Item(A).Reason
          Next A
        End If
        SendWsock cptr.index, IRCRPL_ACCESSEND & " " & cptr.Nick & " " & Chan.Name, ":End of access entries"
      Else
        SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
      End If
    End If
  End If
  Exit Function
errtrap:
  SendSvrMsg "%BUG: Error #" & err.Number & " (" & err.Description & ") occured in m_access_local(" & cptr.Nick & "," & sptr.Nick & ") at this point: " & tmpLoc & ". Please report this at http://bugs.ignition-project.com/."
End Function
