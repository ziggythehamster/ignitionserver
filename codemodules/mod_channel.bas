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
' $Id: mod_channel.bas,v 1.41 2004/06/30 20:43:58 ziggythehamster Exp $
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


Public Sub CycleAccDeny(Chan As clsChannel)
On Error GoTo CADErr
#If Debugging = 1 Then
  SendSvrMsg "CYCLEACCDENY called! (" & Chan.Name & ")"
#End If
Dim A As Long
If Chan.Bans.Count = 0 Then Exit Sub
For A = 1 To Chan.Bans.Count
With Chan.Bans.Item(A)
  If ((UnixTime / 60) - (.SetOn / 60)) > .Duration And .Duration <> 0 And Len(.Mask) <> 0 Then
    Chan.Bans.Remove A
    GoTo nextItemD
  End If
End With
nextItemD:
Next A
Exit Sub

CADErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CycleAccDeny'"
End Sub
Public Sub CycleAccGrant(Chan As clsChannel)
On Error GoTo CAGErr
#If Debugging = 1 Then
  SendSvrMsg "CYCLEACCGRANT called! (" & Chan.Name & ")"
#End If
Dim A As Long
Dim at As String
at = "start"
If Chan.Grants.Count = 0 Then Exit Sub
at = "loopbegin"
For A = 1 To Chan.Grants.Count
at = "check"
With Chan.Grants.Item(A)
  at = "scan"
  If ((UnixTime / 60) - (.SetOn / 60)) > .Duration And .Duration <> 0 And Len(.Mask) <> 0 Then
    at = "remove grant"
    Chan.Grants.Remove A
    at = "next item"
    GoTo nextItemG
  End If
End With
at = "begin next item"
nextItemG:
Next A
Exit Sub

CAGErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CycleAccGrant'"
End Sub
Public Sub CycleAccHost(Chan As clsChannel)
On Error GoTo CAHErr
#If Debugging = 1 Then
  SendSvrMsg "CYCLEACCHOST called! (" & Chan.Name & ")"
#End If
Dim A As Long
If Chan.Hosts.Count = 0 Then Exit Sub
For A = 1 To Chan.Hosts.Count
With Chan.Hosts.Item(A)
  If ((UnixTime / 60) - (.SetOn / 60)) > .Duration And .Duration <> 0 And Len(.Mask) <> 0 Then
    Chan.Hosts.Remove A
    GoTo nextItemH
  End If
End With
nextItemH:
Next A
Exit Sub

CAHErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CycleAccHost'"
End Sub
Public Sub CycleAccOwner(Chan As clsChannel)
On Error GoTo CAOErr
#If Debugging = 1 Then
  SendSvrMsg "CYCLEACCOWNER called! (" & Chan.Name & ")"
#End If
Dim A As Long
If Chan.Owners.Count = 0 Then Exit Sub
For A = 1 To Chan.Owners.Count
With Chan.Owners.Item(A)
  If ((UnixTime / 60) - (.SetOn / 60)) > .Duration And .Duration <> 0 And Len(.Mask) <> 0 Then
    Chan.Owners.Remove A
    GoTo nextItemO
  End If
End With
nextItemO:
Next A
Exit Sub

CAOErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CycleAccOwner'"
End Sub
Public Sub CycleAccVoice(Chan As clsChannel)
On Error GoTo CAVErr
#If Debugging = 1 Then
  SendSvrMsg "CYCLEACCVOICE called! (" & Chan.Name & ")"
#End If
Dim A As Long
If Chan.Voices.Count = 0 Then Exit Sub
For A = 1 To Chan.Voices.Count
With Chan.Voices.Item(A)
  If ((UnixTime / 60) - (.SetOn / 60)) > .Duration And .Duration <> 0 And Len(.Mask) <> 0 Then
    Chan.Voices.Remove A
    GoTo nextItemV
  End If
End With
nextItemV:
Next A
Exit Sub

CAVErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CycleAccVoice'"
End Sub
Public Sub CycleAccess(Chan As clsChannel)
On Error GoTo CAErr
#If Debugging = 1 Then
  SendSvrMsg "CYCLEACCESS called! (" & Chan.Name & ")"
#End If
Call CycleAccDeny(Chan)
Call CycleAccGrant(Chan)
Call CycleAccVoice(Chan)
Call CycleAccHost(Chan)
Call CycleAccOwner(Chan)
Exit Sub

CAErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CycleAccess'"
End Sub
Public Function m_access(cptr As clsClient, sptr As clsClient, parv$()) As Long
'On Error Resume Next
On Error GoTo errtrap
  Dim A As Long 'optimization
  Dim Chan As clsChannel, tmpGrant As clsGrant, tmpOwner As clsOwner, tmpHost As clsHost, tmpVoice As clsVoice, tmpDeny As clsBan
  Dim Mask$, tmpLoc$
  Dim User As clsClient
  Set Chan = New clsChannel
  Set tmpGrant = New clsGrant
  Set tmpOwner = New clsOwner
  Set tmpHost = New clsHost
  Set tmpVoice = New clsVoice
  Set tmpDeny = New clsBan
  
#If Debugging = 1 Then
  SendSvrMsg "ACCESS called! (" & cptr.Nick & ")"
#End If

If Len(parv(0)) = 0 Then  'if no channel given, complain
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "ACCESS")
    Exit Function
End If

If cptr.AccessLevel = 4 Then
  'TODO: process server ACCESS changes
  ':Nick ACCESS #Channel ADD|DELETE DENY|GRANT|VOICE|HOST|OWNER [Mask] [Duration] [Reason]
  '                0           1               2                  3         4        5
  'Last two parameters don't exist in DELETE
  'additionally, the server sends a CLEAR as a DELETE [level] *!*@*
  'since a CLEAR is equivalent to this, it shouldn't be a problem
  
  'see if channel exists
  Set Chan = Channels(parv(0))
  If Chan Is Nothing Then Exit Function
  Select Case UCase$(parv(1))
    Case "ADD"
      'some basic info
      Select Case UCase$(parv(2))
        Case "DENY"
          If Not FindDeny(Chan, parv(3)) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Bans.AddX parv(3), sptr.Nick, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " DENY " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD DENY " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "GRANT"
          If Not FindGrant(Chan, parv(3)) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Grants.AddX parv(3), sptr.Nick, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " GRANT " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD GRANT " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "VOICE"
          If Not FindVoice(Chan, parv(3)) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Voices.AddX parv(3), sptr.Nick, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " VOICE " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD VOICE " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "HOST"
          If Not FindHost(Chan, parv(3)) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Hosts.AddX parv(3), sptr.Nick, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " HOST " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD HOST " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
        Case "OWNER"
          If Not FindOwner(Chan, parv(3)) Then
            'don't send it if the deny already exists, just silently ignore it
            Chan.Owners.AddX parv(3), sptr.Nick, UnixTime, MakeNumber(parv(4)), parv(5)
            SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " OWNER " & parv(3) & " " & MakeNumber(parv(4)) & " " & sptr.Nick & " :" & parv(5), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " ADD OWNER " & parv(3) & " " & MakeNumber(parv(4)) & " :" & parv(5), cptr.ServerName, sptr.Nick
      End Select '</type>
    Case "DELETE"
      Select Case UCase$(parv(2))
        Case "DENY"
          If parv(3) = "*!*@*" And Chan.Bans.Count > 0 Then
            Chan.Bans.Clear
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & parv(3), 0
          End If
          
          If FindDeny(Chan, parv(3)) Then
            'only remove deny if it doesn't exist
            Chan.Bans.Remove parv(3)
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & parv(3), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE DENY " & parv(3), cptr.ServerName, sptr.Nick
        Case "GRANT"
          If parv(3) = "*!*@*" And Chan.Grants.Count > 0 Then
            Chan.Grants.Clear
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & parv(3), 0
          End If
          
          If FindGrant(Chan, parv(3)) Then
            Chan.Grants.Remove parv(3)
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & parv(3), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE GRANT " & parv(3), cptr.ServerName, sptr.Nick
        Case "VOICE"
          If parv(3) = "*!*@*" And Chan.Voices.Count > 0 Then
            Chan.Voices.Clear
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & parv(3), 0
          End If
          
          If FindVoice(Chan, parv(3)) Then
            Chan.Voices.Remove parv(3)
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & parv(3), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE VOICE " & parv(3), cptr.ServerName, sptr.Nick
        Case "HOST"
          If parv(3) = "*!*@*" And Chan.Hosts.Count > 0 Then
            Chan.Hosts.Clear
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & parv(3), 0
          End If
          
          If FindHost(Chan, parv(3)) Then
            Chan.Hosts.Remove parv(3)
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & parv(3), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE HOST " & parv(3), cptr.ServerName, sptr.Nick
        Case "OWNER"
          If parv(3) = "*!*@*" And Chan.Owners.Count > 0 Then
            Chan.Owners.Clear
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & parv(3), 0
          End If
          
          If FindOwner(Chan, parv(3)) Then
            Chan.Owners.Remove parv(3)
            SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & parv(3), 0
          End If
          SendToServer_ButOne "ACCESS " & Chan.Name & " DELETE OWNER " & parv(3), cptr.ServerName, sptr.Nick
      End Select '</type>
  End Select '</all>
Else
  tmpLoc = "entry"
  
  Set Chan = Channels(parv(0))
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
            'only one parameter, obiously they've specified to clear all access
            If Chan.Member.Item(cptr.Nick).IsOp Then
              'TODO: somehow pass an extra parameter so entries set by owners aren't deleted
              tmpLoc = "clear all access place 1"
              Chan.Bans.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE DENY *!*@*", cptr.Nick
              tmpLoc = "clear all access place 2"
              Chan.Grants.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE GRANT *!*@*", cptr.Nick
              tmpLoc = "clear all access place 3"
              Chan.Voices.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE VOICE *!*@*", cptr.Nick
              tmpLoc = "clear all access place 4"
              Chan.Hosts.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE HOST *!*@*", cptr.Nick
              tmpLoc = "clear all access place 5"
              If Chan.Owners.Count > 0 Then
                SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
              End If
            ElseIf Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "clear all access (owner) place 1"
              Chan.Bans.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE DENY *!*@*", cptr.Nick
              tmpLoc = "clear all access (owner) place 2"
              Chan.Grants.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE GRANT *!*@*", cptr.Nick
              tmpLoc = "clear all access (owner) place 3"
              Chan.Voices.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE VOICE *!*@*", cptr.Nick
              tmpLoc = "clear all access (owner) place 4"
              Chan.Hosts.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE HOST *!*@*", cptr.Nick
              tmpLoc = "clear all access (owner) place 5"
              Chan.Owners.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE OWNER *!*@*", cptr.Nick
              tmpLoc = "clear all access (owner) place 6"
            End If
          Else
            tmpLoc = "clear specific level"
            If UCase$(parv(2)) = "GRANT" Then
              tmpLoc = "clear grants"
              Chan.Grants.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE GRANT *!*@*", cptr.Nick
            ElseIf UCase$(parv(2)) = "DENY" Then
              tmpLoc = "clear denys"
              Chan.Bans.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE DENY *!*@*", cptr.Nick
            ElseIf UCase$(parv(2)) = "VOICE" Then
              tmpLoc = "clear voices"
              Chan.Voices.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE VOICE *!*@*", cptr.Nick
            ElseIf UCase$(parv(2)) = "HOST" Then
              tmpLoc = "clear hosts"
              Chan.Hosts.Clear
              SendToServer "ACCESS " & Chan.Name & " DELETE HOST *!*@*", cptr.Nick
            ElseIf UCase$(parv(2)) = "OWNER" Then
              tmpLoc = "clear owners"
              'can only remove access for owner if owner, else return no permissions to perform command
              If Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "clear owners (owner)"
                Chan.Owners.Clear
                SendToServer "ACCESS " & Chan.Name & " DELETE OWNER *!*@*", cptr.Nick
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
              If Not FindGrant(Chan, Mask) Then
                tmpLoc = "grant does not exist"
                If Len(Mask) > 0 Then
                  Chan.Grants.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
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
              If Not FindDeny(Chan, Mask) Then
                tmpLoc = "deny does not exist"
                If Len(Mask) > 0 Then
                  Chan.Bans.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
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
              If Not FindVoice(Chan, Mask) Then
                tmpLoc = "voice does not exist"
                If Len(Mask) > 0 Then
                  Chan.Voices.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
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
              If Not FindHost(Chan, Mask) Then
                tmpLoc = "host does not exist"
                If Len(Mask) > 0 Then
                  Chan.Hosts.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
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
              If Not FindOwner(Chan, Mask) Then
                tmpLoc = "owner does not exist"
                If Len(Mask) > 0 Then
                  Chan.Owners.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), AccessAdd_Duration, AccessAdd_Reason
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
                  If Mask = "*!*@*" Then
                    Chan.Grants.Clear
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE GRANT " & Mask, cptr.Nick
                    Exit Function
                  End If
                  'if this is cleared now, it won't match with anything
                  If Not FindGrant(Chan, Mask) Then
                    tmpLoc = "cannot delete grant - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "grant exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveGrant Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE GRANT " & Mask, cptr.Nick
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
                  If Mask = "*!*@*" Then
                    Chan.Bans.Clear
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE DENY " & Mask, cptr.Nick
                    Exit Function
                  End If
                  If Not FindDeny(Chan, Mask) Then
                    tmpLoc = "cannot delete deny - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "deny exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveDeny Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE DENY " & Mask, cptr.Nick
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
                  If Mask = "*!*@*" Then
                    Chan.Voices.Clear
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE VOICE " & Mask, cptr.Nick
                    Exit Function
                  End If
                  If Not FindVoice(Chan, Mask) Then
                    tmpLoc = "cannot delete voice - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "voice exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveVoice Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE VOICE " & Mask, cptr.Nick
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
                  If Mask = "*!*@*" Then
                    Chan.Hosts.Clear
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE HOST " & Mask, cptr.Nick
                    Exit Function
                  End If
                  If Not FindHost(Chan, Mask) Then
                    tmpLoc = "cannot delete host - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "host exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveHost Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE HOST " & Mask, cptr.Nick
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
                  If Mask = "*!*@*" Then
                    Chan.Owners.Clear
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE OWNER " & Mask, cptr.Nick
                    Exit Function
                  End If
                  If Not FindOwner(Chan, Mask) Then
                    tmpLoc = "cannot delete owner - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "owner found, deleting"
                    'the entry does exist, delete and return message
                    RemoveOwner Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & Mask, 0
                    SendToServer "ACCESS " & Chan.Name & " DELETE OWNER " & Mask, cptr.Nick
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
End If
Exit Function

errtrap:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_access' at " & tmpLoc
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

Dim Chan As clsChannel, I&, x&, Target As clsClient, op$, NewOp As Boolean, NewModes$(), ToUsers$()
Dim op_nohost As String
Dim SendModes As Boolean, Mask$, Ban As clsBan, parc&, chans$(), y&, Inc&, MSwitch As Boolean
ReDim ToUsers(0): ReDim NewModes(0): parc = UBound(parv)
If cptr.AccessLevel = 4 Then
'NOTE: This portion of code is for AccessLevel "4"; I believe that this is the AL that servers get.
'scroll down to locate the code for clients!
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
        For I = 1 To Len(parv(1))
            Mask = Mid$(parv(1), I, 1)
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
                                .IsOwner = True
                            End If
                        End With
                    Else
                        With Chan.Member.Item(parv(Inc))
                            If .IsOwner Then
                                .IsOwner = False
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
                                .IsOp = True
                            End If
                        End With
                    Else
                        With Chan.Member.Item(parv(Inc))
                            If .IsOp Then
                                .IsOp = False
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
                            End If
                        End With
                    Else
                        With Chan.Member.Item(parv(Inc))
                            If .IsVoice Then
                                .IsVoice = False
                            End If
                        End With
                    End If
                    MU = MU & " " & parv(Inc)
                    NM = NM & "v"
                Case cmBan
                    Inc = Inc + 1
                    If MSwitch Then
                        Chan.Bans.Add parv(I + Inc), op, UnixTime, parv(Inc)
                    Else
                        Chan.Bans.Remove parv(I + Inc)
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
                            NM = NM & "-p+s"
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
                            NM = NM & "-s+p"
                        Else
                            Chan.IsPrivate = True
                            NM = NM & "p"
                        End If
                    Else
                        NM = NM & "p"
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
                    NM = NM & "l"
                Case cmKey
                    Inc = Inc + 1
                    If MSwitch Then
                        Chan.Key = parv(Inc)
                        MU = MU & " " & parv(Inc)
                    Else
                        Chan.Key = vbNullString
                    End If
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
            End Select
        Next I
        MU = LTrim$(MU)
        SendToChanIRCX Chan, ":" & op & " MODE " & Chan.Name & " " & NM & " " & MU, vbNullString
        SendToChan1459 Chan, ":" & op & " MODE " & Chan.Name & " " & Replace(NM, "q", "o") & " " & MU, vbNullString
        SendToServer_ButOne "MODE " & Chan.Name & " " & NM & " " & MU, cptr.ServerName, op_nohost
    Else
        'user
        Set Target = GlobUsers(parv(0))
        For I = 1 To Len(parv(1))
            Mask = Mid$(parv(1), I, 1)
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
        Next I
        GenerateEvent "USER", "MODECHANGE", Replace(Target.Prefix, ":", ""), Replace(Target.Prefix, ":", "") & " " & NM
        SendToServer_ButOne "MODE " & Target.Nick & " " & NM, cptr.ServerName, sptr.Nick
        If Target.Hops = 0 Then SendWsock Target.index, sptr.Prefix & " MODE " & Target.Nick & " " & NM, vbNullString, , True
    End If
Else
'%%%%%%%%%%%%%%%%% this is the code for clients
  Set Ban = New clsBan
  'MODE #Channel +b Mask
  '        0      1   2  3... (illegal)
  If Len(parv(0)) = 0 Then    'oops, client forgot to tell us which channel it wanted to mode -Dill
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
    GoTo NextChan
  End If
  If AscW(parv(0)) = 35 Then
    Set Chan = Channels(parv(0))
    If Chan Is Nothing Then
      SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , chans(y))
      Exit Function
    End If
    Call CycleAccess(Chan)
    If parc < 1 Then
      SendWsock cptr.index, SPrefix & " " & RPL_CHANNELMODEIS & " " & cptr.Nick & " " & Chan.Name & " +" & GetModes(Chan), vbNullString, , True
    Else
      Select Case AscW(Mid$(parv(1), 2, 1))
        Case cmBan
            SendModes = False
        Case Else
            SendModes = True
      End Select
      If SendModes Then
        If Not cptr.IsOnChan(Chan.Name) Then
          SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , Chan.Name)
          Exit Function
        End If
        If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsOwner Then
          SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
          Exit Function
        End If
      End If
      If parv(1) = "-b+b" Then
        '#Channel -b+b old new
        '   0       1   2   3
        'rigging to make it work ;)
        If UBound(parv) = 3 Then
          If FindDeny(Chan, CreateMask(parv(2))) Then
            Chan.Bans.Remove CreateMask(parv(2))
          End If
          Chan.Bans.AddX CreateMask(parv(3)), cptr.Nick, UnixTime, 0, "", CreateMask(parv(3))
        Else
          SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
          GoTo NextChan
        End If
      End If
      
      op = Mid$(parv(1), 1, 1)
      For I = 2 To Len(parv(1))
        Select Case AscW(Mid$(parv(1), I, 1))
          Case modeAdd
            op = "+"
            GoTo Flush
          Case modeRemove
            op = "-"
            GoTo Flush
          Case cmBan
            #If Debugging = 1 Then
              SendSvrMsg "*** ban on " & Chan.Name
            #End If
            Select Case AscW(op)
              Case modeAdd
                If parc < I Then
                  For x = 1 To Chan.Bans.Count
                    SendWsock cptr.index, SPrefix & " " & RPL_BANLIST & " " & cptr.Nick & " " & Chan.Name & " " & Chan.Bans(x).Mask & " " & Chan.Bans(x).SetBy & " :" & Chan.Bans(x).SetOn, vbNullString, , True
                  Next x
                  SendWsock cptr.index, SPrefix & " " & RPL_ENDOFBANLIST & " " & cptr.Nick & " " & Chan.Name & " :End of Channel Ban List", vbNullString, , True
                Else
                  #If Debugging = 1 Then
                    SendSvrMsg "*** adding ban on " & Chan.Name
                  #End If
                  '#Channel +b Nick
                  '    0     1   2
                  'If UBound(parv) > 3 Then
                  '  SendWsock cptr.index, IRCERR_TOOMANYARGUMENTS & " " & cptr.Nick & " MODE", TranslateCode(IRCERR_TOOMANYARGUMENTS)
                  '  Exit Function
                  'End If
                  SendModes = True
                  Mask = CreateMask(parv(I))
                  
                  #If Debugging = 1 Then
                    SendSvrMsg "*** seeing if ban exists..."
                  #End If
                  'Set Ban = Chan.Bans.Item(Mask)
                  
                  If Not FindDeny(Chan, Mask) Then
                    Set Ban = Nothing
                    #If Debugging = 1 Then
                      SendSvrMsg "*** adding ban, please wait..."
                    #End If
                    Chan.Bans.AddX Mask, cptr.Nick, UnixTime, 0, vbNullString, Mask
                  Else
                    #If Debugging = 1 Then
                      SendSvrMsg "*** ban already exists"
                    #End If
                    'the ban already exists, no need to add it again
                    GoTo NextMode
                  End If
                  
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "b": ToUsers(UBound(ToUsers)) = Mask
                End If
              Case modeRemove
                SendModes = True
                If parc < I Then
                  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
                  Exit Function
                End If
                Mask = CreateMask(parv(I))
                Set Ban = Chan.Bans(Mask)
                If Ban Is Nothing Then GoTo NextMode
                If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                NewModes(UBound(NewModes)) = "b": ToUsers(UBound(ToUsers)) = Mask
                Chan.Bans.Remove Mask
            End Select
          Case cmOwner 'IRCX - Ziggy
            If parc < I Then GoTo NextMode
            Select Case AscW(op)
              Case modeAdd
                If parc < I Then GoTo NextMode
                Set Target = GlobUsers(parv(I))
                If Target Is Nothing Then
                  SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(I), Chan.Name)
                  GoTo NextMode
                End If
                If Chan.Member.Item(cptr.Nick).IsOwner = True Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "q": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsOwner = True
                  End With
                Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
                End If
              Case modeRemove
                If parc < I Then GoTo NextMode
                Set Target = GlobUsers(parv(I))
                If Target Is Nothing Then
                  SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(I), Chan.Name)
                  GoTo NextMode
                End If
                If Target.IsProtected Or Target.IsLProtected Then
                  'note: this is only checking to see if a user is trying to
                  'deowner Target. Opers *can* deowner other opers.
                  If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
                    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                    GoTo NextMode
                  End If
                End If
                If Chan.Member.Item(cptr.Nick).IsOwner = True Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "q": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsOwner = False
                  End With
                Else
                  SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
                End If
            End Select
          Case cmOp
            If parc < I Then GoTo NextMode
            Select Case AscW(op)
              Case modeAdd
                If parc < I Then GoTo NextMode
                Set Target = GlobUsers(parv(I))
                If Target Is Nothing Then
                  SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(I), Chan.Name)
                  GoTo NextMode
                End If
                  'If the target is an owner, and the current user is not an owner, then ignore
                  If Chan.Member.Item(Target.Nick).IsOwner And Not Chan.Member.Item(cptr.Nick).IsOwner Then GoTo NextMode
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "o": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsOp = True
                  End With
              Case modeRemove
                If parc < I Then GoTo NextMode
                Set Target = GlobUsers(parv(I))
                If Target Is Nothing Then
                  SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(I), Chan.Name)
                  GoTo NextMode
                End If
                If Target.IsProtected Or Target.IsLProtected Then
                  'note: this is only checking to see if a user is trying to
                  'deowner Target. Opers *can* deop other opers.
                  If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
                    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                    GoTo NextMode
                  End If
                End If
                If Chan.Member.Item(Target.Nick).IsOwner And Not Chan.Member.Item(cptr.Nick).IsOwner Then GoTo NextMode
                If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "o": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsOp = False
                  End With
            End Select
          Case cmVoice
            If parc < I Then GoTo NextMode
            Select Case AscW(op)
              Case modeAdd
                If parc < I Then GoTo NextMode
                Set Target = GlobUsers(parv(I))
                If Target Is Nothing Then
                  SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(I), Chan.Name)
                  GoTo NextMode
                End If
                  If Chan.Member.Item(Target.Nick).IsOwner And Not Chan.Member.Item(cptr.Nick).IsOwner Then GoTo NextMode
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "v": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsVoice = True
                  End With
              Case modeRemove
                If parc < I Then GoTo NextMode
                Set Target = GlobUsers(parv(I))
                If Target Is Nothing Then
                  SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(I), Chan.Name)
                  GoTo NextMode
                End If
                If Target.IsProtected Or Target.IsLProtected Then
                  'note: this is only checking to see if a user is trying to
                  'deowner Target. Opers *can* devoice other opers.
                  If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
                    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                    GoTo NextMode
                  End If
                End If
                  If Chan.Member.Item(Target.Nick).IsOwner And Not Chan.Member.Item(cptr.Nick).IsOwner Then GoTo NextMode
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "v": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsVoice = False
                  End With
            End Select
          Case cmModerated
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsModerated Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "m"
                End If
                Chan.IsModerated = True
              Case modeRemove
                If Chan.IsModerated Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "m"
                End If
                Chan.IsModerated = False
            End Select
          Case cmKnock
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsKnock Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "u"
                End If
                Chan.IsKnock = True
              Case modeRemove
                If Chan.IsKnock Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "u"
                End If
                Chan.IsKnock = False
            End Select
          Case cmNoExternalMsg
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsNoExternalMsgs Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "n"
                End If
                Chan.IsNoExternalMsgs = True
              Case modeRemove
                If Chan.IsNoExternalMsgs Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "n"
                End If
                Chan.IsNoExternalMsgs = False
            End Select
          Case cmOpTopic
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsTopicOps Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "t"
                End If
                Chan.IsTopicOps = True
              Case modeRemove
                If Chan.IsTopicOps Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "t"
                End If
                Chan.IsTopicOps = False
            End Select
          Case cmKey
            If StrComp(parv(I), vbNullString) = 0 Then
              SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
              Exit Function
            End If
            Select Case AscW(op)
              Case modeAdd
                If Len(Chan.Key) = 0 Then
                  If KeyLen > 0 Then
                    parv(I) = Mid$(parv(I), 1, KeyLen)
                  End If
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "k": ToUsers(UBound(ToUsers)) = (parv(I))
                  Chan.Key = (parv(I))
                  Chan.Prop_Memberkey = (parv(I))
                  If IRCXM_Strict = True Then
                    SendToChanIRCX Chan, cptr.Prefix & " PROP " & Chan.Name & " MEMBERKEY :" & parv(I), 0
                  ElseIf IRCXM_Both = True Then
                    SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " MEMBERKEY :" & parv(I), 0
                  End If
                Else
                  SendWsock cptr.index, ERR_KEYSET & " " & cptr.Nick, TranslateCode(ERR_KEYSET, , Chan.Name)
                  GoTo NextMode
                End If
              Case modeRemove
                If Len(Chan.Key) <> 0 Then
                  If Chan.Key = (parv(I)) Then
                    If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                    ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                    NewModes(UBound(NewModes)) = "k": ToUsers(UBound(ToUsers)) = (parv(I))
                    Chan.Key = vbNullString
                    Chan.Prop_Memberkey = vbNullString
                  End If
                End If
            End Select
          Case cmLimit
            Select Case AscW(op)
              Case modeAdd
                If Len(parv(I)) = 0 Then
                  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
                  GoTo NextMode
                End If
                If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                NewModes(UBound(NewModes)) = "l": ToUsers(UBound(ToUsers)) = (parv(I))
                Chan.Limit = CLng(parv(I))
              Case modeRemove
                If Chan.Limit > 0 Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "l"
                  Chan.Limit = 0
                End If
            End Select
          Case cmHidden
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsHidden Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  If Chan.IsSecret Or Chan.IsPrivate Then
                    NewModes(UBound(NewModes)) = "h"
                    If Chan.IsSecret = True Then SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " -s", 0
                    If Chan.IsPrivate = True Then SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " -p", 0
                    Chan.IsSecret = False
                    Chan.IsPrivate = False
                  Else
                    NewModes(UBound(NewModes)) = "h"
                  End If
                End If
                Chan.IsHidden = True
              Case modeRemove
                If Chan.IsHidden Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "h"
                End If
                Chan.IsHidden = False
            End Select
          Case cmPrivate
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsPrivate Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  If Chan.IsSecret Or Chan.IsHidden Then
                    NewModes(UBound(NewModes)) = "p"
                    If Chan.IsHidden = True Then SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " -h", 0
                    If Chan.IsSecret = True Then SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " -s", 0
                    Chan.IsSecret = False
                    Chan.IsHidden = False
                  Else
                    NewModes(UBound(NewModes)) = "p"
                  End If
                End If
                Chan.IsPrivate = True
              Case modeRemove
                If Chan.IsPrivate Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "p"
                End If
                Chan.IsPrivate = False
            End Select
          Case cmSecret
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsSecret Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  If Chan.IsPrivate Or Chan.IsHidden Then
                    NewModes(UBound(NewModes)) = "s"
                    If Chan.IsHidden = True Then SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " -h", 0
                    If Chan.IsPrivate = True Then SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " -p", 0
                    Chan.IsHidden = False
                    Chan.IsPrivate = False
                  Else
                    NewModes(UBound(NewModes)) = "s"
                  End If
                  NewModes(UBound(NewModes)) = "s"
                End If
                Chan.IsSecret = True
              Case modeRemove
                If Chan.IsSecret Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "s"
                End If
                Chan.IsSecret = False
            End Select
          Case cmInviteOnly
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsInviteOnly Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "i"
                End If
                Chan.IsInviteOnly = True
              Case modeRemove
                If Chan.IsInviteOnly Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "i"
                End If
                Chan.IsInviteOnly = False
              End Select
          Case cmOperOnly
            If cptr.IsGlobOperator Or cptr.IsNetAdmin Then
            Select Case AscW(op)
              Case modeAdd
                If Not Chan.IsOperOnly Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "O"
                End If
                Chan.IsOperOnly = True
              Case modeRemove
                If Chan.IsOperOnly Then
                  If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "O"
                End If
                Chan.IsOperOnly = False
              End Select
              Else
                SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
              End If
          Case cmPersistant
            If RegChanMode_ModeR Then
              If (cptr.IsGlobOperator Or cptr.IsLocOperator) Then
                Select Case AscW(op)
                  Case modeAdd
                    If Not Chan.IsPersistant Then
                      If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                      ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                      NewModes(UBound(NewModes)) = "R"
                    End If
                    Chan.IsPersistant = True
                  Case modeRemove
                    If Chan.IsPersistant Then
                      If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                      ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                      NewModes(UBound(NewModes)) = "R"
                    End If
                    Chan.IsPersistant = False
                  End Select
                Else
                  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
                End If
              Else
                SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, op & Mid$(parv(1), I, 1), Chan.Name)
              End If
            Case Else
                SendWsock cptr.index, ERR_UNKNOWNMODE & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNMODE, op & Mid$(parv(1), I, 1), Chan.Name)
        End Select
        NewOp = False
NextMode:
      Next I
    End If
NextChan:
    GoTo Flush
  Else
    Dim NModes As String
'    If UBound(parv) = 0 Then
'        SendWsock cptr.Index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "MODE")
'        Exit Function
'    End If
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
    If Not (cptr Is Target) And (cptr.IsLocOperator Or cptr.IsGlobOperator) And ((parv(1) <> "+z") And (parv(1) <> "-z")) Then
        SendWsock cptr.index, ERR_USERSDONTMATCH, cptr.Nick & " " & TranslateCode(ERR_USERSDONTMATCH)
        Exit Function
    End If
    'Set Target = Nothing
    m_mode = AscW(parv(1))
    If m_mode <> modeAdd Then
        If m_mode <> modeRemove Then
            Exit Function
        End If
    End If
    op = vbNullString
    For I = 1 To Len(parv(1))
        Mask = Mid$(parv(1), I, 1)
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
    Next I
    If Len(op) > 1 Then
        If InStr(1, op, "z") Then
          'obviously, we deny normal users from setting +z on themselves
          'and opers can't set +z on themselves (how stupid would that be)
          'this modechange was forced upon Target, not cptr!
          GenerateEvent "USER", "MODECHANGE", Replace(Target.Prefix, ":", ""), Replace(Target.Prefix, ":", "") & " " & op
          If ShowGag Then SendWsock Target.index, "MODE " & Target.Nick, op, cptr.Prefix 'notify the one being gagged
          SendWsock cptr.index, "MODE " & Target.Nick, op, cptr.Prefix  'notify the gagger
          SendToServer "MODE " & Target.Nick & " " & op, cptr.Nick
        Else
          GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & op
          SendWsock cptr.index, "MODE " & cptr.Nick, op, cptr.Prefix
          SendToServer "MODE " & cptr.Nick & " " & op, cptr.Nick
        End If
    End If
  End If
End If
Exit Function
Flush:
If SendModes = False Then Exit Function
Dim m$, u$
m = Trim$(Join(NewModes, vbNullString)): u = Trim$(Join(ToUsers, " "))
If Len(m) <> 0 Then
SendToChanIRCX Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & op & m & " " & u, 0
SendToChan1459 Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & op & Replace(m, "q", "o") & " " & u, 0
SendToServer "MODE " & Chan.Name & " " & op & m & " " & u, cptr.Nick
End If
ReDim ToUsers(0): ReDim NewModes(0)
'Resume
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
Dim Chan As clsChannel, x&, y$(), A, Names$(0), OnJoinS$(), b&
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
      GenerateEvent "USER", "JOIN", Replace(sptr.Prefix, ":", ""), Replace(sptr.Prefix, ":", "") & " " & Chan.Name
      GenerateEvent "CHANNEL", "CREATE", Chan.Name, Chan.Name & " " & sptr.Nick
      GenerateEvent "CHANNEL", "JOIN", Chan.Name, Chan.Name & " " & sptr.Nick
    Else
      sptr.OnChannels.Add Chan, Chan.Name
      Chan.Member.Add ChanNormal, sptr
      GenerateEvent "USER", "JOIN", Replace(sptr.Prefix, ":", ""), Replace(sptr.Prefix, ":", "") & " " & Chan.Name
      GenerateEvent "CHANNEL", "JOIN", Chan.Name, Chan.Name & " " & sptr.Nick
      SendToChan Chan, sptr.Prefix & " JOIN :" & Chan.Name, 0
      SendToServer_ButOne "JOIN " & Chan.Name, cptr.ServerName, sptr.Nick
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
    If MaxChannelsPerUser > 0 Then
        If cptr.OnChannels.Count >= MaxChannelsPerUser Then
            CurrentInfo = "too many channels"
            SendWsock cptr.index, ERR_TOOMANYCHANNELS & " " & cptr.Nick, TranslateCode(ERR_TOOMANYCHANNELS, , parv(0))
            Exit Function
        End If
    End If
    StrCache = A
    If Len(StrCache) < 2 Then 'cant have a "blank" room name -Airwalk
        CurrentInfo = "channel name null"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , , StrCache)
        Exit Function
    End If
    'If AscW(StrCache) <> 35 And AscW(StrCache) <> 48 Then 'note: % = 37, 0 = 48; add % soon - Ziggy
    If AscW(StrCache) <> 35 Then 'use this for now
        CurrentInfo = "no such channel"
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , StrCache)
        GoTo NextChan
    End If
    'The following bit of code is a pain in the ass, - Ziggy
    'If StrCache Like "0*" Then       '#0 means part all -Dill
    '                             'No, it doesn't (#0 is a perfectly legitimate chan name) - Ziggy
    '  ReDim parv(1)
    '  parv(1) = "0"
    '  Do While cptr.OnChannels.Count > 0
    '    parv(0) = cptr.OnChannels.Item(1).Name
    '    m_part cptr, cptr, parv
    '    cptr.OnChannels.Remove 1
    '  Loop
    '  GoTo NextChan
    'End If
    CurrentInfo = "setting up chan (exist/nonexist?)"
    If cptr.IsOnChan(StrCache) Then GoTo NextChan
    CurrentInfo = "setting up chan (exist/nonexist?)1"
    Set Chan = Channels(StrCache)
    CurrentInfo = "setting up chan (exist/nonexist?)2"
    If Chan Is Nothing Then
      CurrentInfo = "channel does not exist"
      'the channel cptr wants to join doesn't exist, so we create it -Dill
      Set Chan = Channels.Add(StrCache, New clsChannel)
      Chan.Name = StrCache
      Chan.Prop_Creation = UnixTime
      Chan.Prop_Name = StrCache
      Chan.Member.Add ChanOwner, cptr
      cptr.OnChannels.Add Chan, Chan.Name
      Chan.IsNoExternalMsgs = True
      Chan.IsTopicOps = True
      SendWsock cptr.index, cptr.Prefix & " JOIN :" & StrCache, vbNullString, , True
      If cptr.IsIRCX Then
        SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & StrCache, ":." & cptr.Nick
      Else
        SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & StrCache, ":@" & cptr.Nick
      End If
      SendWsock cptr.index, SPrefix & " " & RPL_ENDOFNAMES & " " & cptr.Nick & " " & Chan.Name & " :End of /NAMES list.", vbNullString, , True
      GenerateEvent "USER", "JOIN", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & Chan.Name
      GenerateEvent "CHANNEL", "CREATE", Chan.Name, Chan.Name & " " & cptr.Nick
      GenerateEvent "CHANNEL", "JOIN", Chan.Name, Chan.Name & " " & cptr.Nick
      SendToServer "JOIN " & Chan.Name, cptr.Nick
    Else
      Call CycleAccess(Chan)
      CurrentInfo = "channel exists"
      'is there a user limit set? -Dill
      If Chan.Limit > 0 Then
        If Chan.Member.Count >= Chan.Limit Then
          CurrentInfo = "channel full"
          SendWsock cptr.index, ERR_CHANNELISFULL & " " & cptr.Nick & " " & TranslateCode(ERR_CHANNELISFULL, , Chan.Name), vbNullString, SPrefix
          If Chan.IsKnock Then
            SendToChanOpsIRCX Chan, cptr.Prefix & " KNOCK " & Chan.Name & " :Channel is full (+l)", 0
            SendToServer "KNOCK " & Chan.Name & " :Channel is full (+l)", cptr.Nick
          End If
          Exit Function
        End If
      End If
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
      If IsBanned(Chan, cptr) And Not (IsHosted(Chan, cptr) Or IsOwnered(Chan, cptr)) Then
          If UBound(parv) > 0 Then
            If parv(1) = Chan.Prop_Ownerkey And Len(Chan.Prop_Ownerkey) > 0 Then
              CurrentInfo = "banned, ownerkey"
              GoTo pastban
            End If
            If parv(1) = Chan.Prop_Hostkey And Len(Chan.Prop_Hostkey) > 0 And Chan.Member.Item(cptr.Nick).IsOwner = False Then
              CurrentInfo = "banned, hostkey"
              GoTo pastban
            End If
            If parv(1) = Chan.Prop_Memberkey And Len(Chan.Prop_Memberkey) > 0 Then
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
      If Len(Chan.Key) <> 0 Then
        CurrentInfo = "channel locked"
        'if they have the ownerkey, or hostkey, let them in
        If UBound(parv) > 0 Then
          If StrComp(parv(1), Chan.Key) <> 0 And StrComp(parv(1), Chan.Prop_Hostkey) <> 0 And StrComp(parv(1), Chan.Prop_Ownerkey) <> 0 Then
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
      'cptr is allowed to join the channel, so we let it -Dill
      CurrentInfo = "allowed on channel"
      cptr.OnChannels.Add Chan, Chan.Name
      Chan.Member.Add ChanNormal, cptr
      'Notify all users about the new member -Dill
      SendToChan Chan, cptr.Prefix & " JOIN :" & Chan.Name, 0
      SendToServer "JOIN " & Chan.Name, cptr.Nick
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
        If parv(1) = Chan.Prop_Ownerkey And Len(Chan.Prop_Ownerkey) > 0 Then
          CurrentInfo = "ownerkey"
          Chan.Member.Item(cptr.Nick).IsOwner = True
          SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
          SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
        End If
        If parv(1) = Chan.Prop_Hostkey And Len(Chan.Prop_Hostkey) > 0 And Chan.Member.Item(cptr.Nick).IsOwner = False Then
          CurrentInfo = "hostkey"
          Chan.Member.Item(cptr.Nick).IsOp = True
          SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
          SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
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
            SendToChanIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
            SendToChan1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
            SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
            GoTo pastaccess
        ElseIf HighProtAso Then
            Chan.Member.Item(cptr.Nick).IsOp = True
            SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
            SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
            GoTo pastaccess
        ElseIf HighProtAsv Then
            Chan.Member.Item(cptr.Nick).IsVoice = True
            SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +v " & cptr.Nick, 0
            SendToServer "MODE " & Chan.Name & " +v " & cptr.Nick, cptr.Nick
            GoTo pastaccess
        ElseIf HighProtAsn Then
            GoTo pastaccess
        End If
      End If
      CurrentInfo = "oper check - low protection"
      If ((cptr.IsGlobOperator) Or (cptr.IsLocOperator)) And (cptr.IsLProtected) Then
        'Low Protection get a different defined level because some want to control other opers
        'Other than themselves differently (e.g. give them +o and admins +q)
        If LowProtAsq Then
            Chan.Member.Item(cptr.Nick).IsOwner = True
            SendToChanIRCX Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
            SendToChan1459 Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
            SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
            GoTo pastaccess
        ElseIf LowProtAso Then
            Chan.Member.Item(cptr.Nick).IsOp = True
            SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
            SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
            GoTo pastaccess
        ElseIf LowProtAsv Then
            Chan.Member.Item(cptr.Nick).IsVoice = True
            SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +v " & cptr.Nick, 0
            SendToServer "MODE " & Chan.Name & " +v " & cptr.Nick, cptr.Nick
            GoTo pastaccess
        ElseIf LowProtAsn Then
            GoTo pastaccess
        End If
      End If
      If IsOwnered(Chan, cptr) Then
        'is in owner access
        CurrentInfo = "user is ownered"
        Chan.Member.Item(cptr.Nick).IsOwner = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick, 0
        SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
      If IsHosted(Chan, cptr) Then
        'is in host access
        CurrentInfo = "user is hosted"
        Chan.Member.Item(cptr.Nick).IsOp = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick, 0
        SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
      If IsVoiced(Chan, cptr) Then
        'is in voice access
        CurrentInfo = "user is voiced"
        Chan.Member.Item(cptr.Nick).IsVoice = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +v " & cptr.Nick, 0
        SendToServer "MODE " & Chan.Name & " +v " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
pastaccess:
      GenerateEvent "USER", "JOIN", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & Chan.Name
      GenerateEvent "CHANNEL", "JOIN", Chan.Name, Chan.Name & " " & cptr.Nick
      CurrentInfo = "onjoin"
      If Len(Chan.Prop_OnJoin) > 0 Then
        OnJoinS() = Split(Chan.Prop_OnJoin, "\n")
        For b = 0 To UBound(OnJoinS)
            SendWsock cptr.index, ":" & Chan.Name & " PRIVMSG " & Chan.Name & " :" & OnJoinS(b) & vbCrLf, vbNullString, , True
            'SendWsock cptr.index, ":" & Chan.Name & " PRIVMSG " & cptr.Nick & " :" & OnJoinS(b) & vbCrLf, vbNullString, , True
        Next b
      End If
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
    Dim I&, Chan As clsChannel, User As clsClient, nUser$()
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
    For I = LBound(nUser) To UBound(nUser)
        Select Case Left$(nUser(I), 1)
            Case "."
                cache = Mid$(nUser(I), 2)
                Modes = Modes & "q"
                nu = nu & cache & " "
                Set User = GlobUsers(cache)
                If Not User Is Nothing Then Chan.Member.Add ChanOwner, User
            Case "@"
                cache = Mid$(nUser(I), 2)
                Modes = Modes & "o"
                nu = nu & cache & " "
                Set User = GlobUsers(cache)
                If Not User Is Nothing Then Chan.Member.Add ChanOp, User
            Case "+"
                cache = Mid$(nUser(I), 2)
                Modes = Modes & "v"
                nu = nu & cache & " "
                If Not User Is Nothing Then Set User = GlobUsers(cache)
                Chan.Member.Add ChanVoice, User
            Case Else
                cache = nUser(I)
                If Not User Is Nothing Then Set User = GlobUsers(cache)
                Chan.Member.Add ChanNormal, User
        End Select
        If Not User Is Nothing Then User.OnChannels.Add Chan, Chan.Name
        SendToChan Chan, User.Prefix & " JOIN " & Chan.Name, ""
    Next I
    If Len(Modes) > 0 Then SendToChan Chan, ":" & sptr.ServerName & " MODE " & Chan.Name & " +" & Modes & " " & nu, ""
    SendToServer_ButOne "NJOIN " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.ServerName
Else
  SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, ":Permission Denied"
  Exit Function
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
Dim x&, cmd$, Chan As clsChannel, chans$(), I&, A&, b As Long, OnPartS() As String
If cptr.AccessLevel = 4 Then
  at = "server user part"
  chans = Split(parv(0), ",")
  With sptr
    For I = LBound(chans) To UBound(chans)  'Letting clients part multiple chans at one time -Dill
      Set Chan = .OnChannels.Item(chans(I))
      If Chan Is Nothing Then GoTo NextChannel
      If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
        cmd = .Prefix & " PART " & chans(I)
      Else
        cmd = .Prefix & " PART " & chans(I) & " :""" & parv(1) & """"
      End If
      SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
      SendToServer_ButOne "PART " & Chan.Name, cptr.ServerName, sptr.Nick
      Chan.Member.Remove .Nick
      .OnChannels.Remove chans(I)
      If Chan.Member.Count = 0 Then
        'the channel only dies if it's not registered, or not persistant
        'and there's no people in it
        If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
          Channels.Remove Chan.Name
          Set Chan = Nothing
        ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
          Channels.Remove Chan.Name
          Set Chan = Nothing
        ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
          Channels.Remove Chan.Name
          Set Chan = Nothing
        End If
      End If
      GenerateEvent "USER", "PART", Replace(.Prefix, ":", ""), Replace(.Prefix, ":", "") & " " & chans(I)
NextChannel:
    Next I
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
      For I = LBound(chans) To UBound(chans)  'Letting clients part multiple chans at one time -Dill
        If Not .IsOnChan(chans(I)) Then    'if client wasn't on this channel then complain -Dill / fixed error -Zg
          at = "throw error"
          SendWsock cptr.index, ERR_NOTONCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOTONCHANNEL, , chans(I))
          GoTo NextChan
        End If
        Set Chan = Channels(chans(I))
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
        SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
        SendToServer "PART " & chans(I) & " :" & cptr.Nick, cptr.Nick
        If Len(Chan.Prop_OnPart) > 0 Then
          #If Debugging = 1 Then
            SendSvrMsg "Debug - OnPart Sending"
          #End If
          OnPartS() = Split(Chan.Prop_OnPart, "\n")
          For b = 0 To UBound(OnPartS)
            #If Debugging = 1 Then
              SendSvrMsg "Debug - Sending OnPart Line: :" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(b)
            #End If
            'bloody hell.. this should, by all means, be working!
            'SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & Chan.Name & " :" & OnPartS(b) & vbCrLf
            SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(b) & vbCrLf
          Next b
        End If
        Chan.Member.Remove cptr.Nick
        .OnChannels.Remove chans(I)
        If Chan.Member.Count = 0 Then
          'the channel only dies if it's not registered, or not persistant
          'and there's no people in it
          If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
            Channels.Remove Chan.Name
            Set Chan = Nothing
          ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
            Channels.Remove Chan.Name
            Set Chan = Nothing
          ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
            Channels.Remove Chan.Name
            Set Chan = Nothing
          End If
        End If
        Set Chan = Nothing
        GenerateEvent "USER", "PART", Replace(.Prefix, ":", ""), Replace(.Prefix, ":", "") & " " & chans(I)
NextChan:
      Next I
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
    SendToChan Chan, cmd, vbNullString   'Notify all channelmembers -Dill
    SendToServer "PART " & parv(0) & " :" & cptr.Nick, cptr.Nick
    #If Debugging = 1 Then
      SendSvrMsg "Debug - OnPart Len: " & Len(Chan.Prop_OnPart)
      SendSvrMsg "Debug - OnPart: " & Chan.Prop_OnPart
    #End If
    at = "send onpart"
    If Len(Chan.Prop_OnPart) > 0 Then
      #If Debugging = 1 Then
        SendSvrMsg "Debug - OnPart Sending"
      #End If
      OnPartS() = Split(Chan.Prop_OnPart, "\n")
      For b = 0 To UBound(OnPartS)
        #If Debugging = 1 Then
          SendSvrMsg "Debug - Sending OnPart Line: :" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(b)
        #End If
        'SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & Chan.Name & " :" & OnPartS(b) & vbCrLf
        SendDirect cptr.index, ":" & Chan.Name & " NOTICE " & cptr.Nick & " :" & OnPartS(b) & vbCrLf
      Next b
    End If
    at = "after onpart"
    Chan.Member.Remove cptr.Nick
    cptr.OnChannels.Remove parv(0)
    If Chan.Member.Count = 0 Then
      'the channel only dies if it's not registered, or not persistant
      'and there's no people in it
      If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
        Channels.Remove Chan.Name
        Set Chan = Nothing
      ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
        Channels.Remove Chan.Name
        Set Chan = Nothing
      ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
        Channels.Remove Chan.Name
        Set Chan = Nothing
      End If
    End If
    Set Chan = Nothing
    GenerateEvent "USER", "PART", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & parv(0)
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
Dim Chan As clsChannel, I&, victim As clsClient, Reason$
If cptr.AccessLevel = 4 Then
  Reason = parv(2)
  SendToChan Chan, sptr.Prefix & " KICK " & parv(0) & " " & parv(1) & " :" & Reason, 0
  Chan.Member.Remove parv(1)
  GlobUsers(parv(1)).OnChannels.Remove Chan.Name
  If Chan.Member.Count = 0 Then
    'the channel only dies if it's not registered, or not persistant
    'and there's no people in it
    If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
      Channels.Remove Chan.Name
      Set Chan = Nothing
    ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
      Channels.Remove Chan.Name
      Set Chan = Nothing
    ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
      Channels.Remove Chan.Name
      Set Chan = Nothing
    End If
  End If
  SendToServer_ButOne "KICK " & Chan.Name & " " & parv(1) & " :" & Reason, cptr.ServerName, sptr.Nick
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
  If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsOwner Then
    SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
    Exit Function
  End If
  If Chan.Member.Item(victim.Nick).IsOwner Then
    If Chan.Member.Item(cptr.Nick).IsOp Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
    End If
  End If
  If Chan.Member.Item(victim.Nick).IsOp Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
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
  Chan.Member.Remove victim.Nick
  If Chan.Member.Count = 0 Then
    'the channel only dies if it's not registered, or not persistant
    'and there's no people in it
    If Not Chan.IsRegistered And RegChanMode_Always Then 'if it's not registered, and regchanmode = 0
      Channels.Remove Chan.Name
      Set Chan = Nothing
    ElseIf RegChanMode_Never Then 'who cares, all regged rooms close - regchanmode = 1
      Channels.Remove Chan.Name
      Set Chan = Nothing
    ElseIf Not Chan.IsPersistant And RegChanMode_ModeR Then 'if it's not persistant and regchanmode = 2
      Channels.Remove Chan.Name
      Set Chan = Nothing
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

Dim Chan As clsChannel, I&

'check if null (not enough params)
If Len(parv(0)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PROP")
  Exit Function
End If
If Len(parv(1)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PROP")
  Exit Function
End If

Set Chan = Channels(parv(0))

'cache the owner, host, and member statuses
Dim tmpGod As Boolean
Dim tmpOwner As Boolean
Dim tmpHost As Boolean
Dim tmpHalfOp As Boolean
Dim tmpMember As Boolean
Dim tmpUser As Boolean 'outside the channel

Dim tmpSvrName As String 'because I'm lazy and don't want to write a server PROP section
Dim tmpAccessLvl As Long '    "    "

If cptr.AccessLevel = 3 Then
  'ircop
  tmpOwner = True
ElseIf cptr.AccessLevel = 4 Then
 'server
 tmpOwner = True
 tmpGod = True
 'before messing up cptr, let's tell the other servers
 'about the dirty deed
 If Not Chan Is Nothing Then
   SendToServer_ButOne "PROP " & Chan.Name & " " & parv(1) & " :" & parv(2), cptr.ServerName, sptr.Nick
 End If
 tmpSvrName = cptr.ServerName
 tmpAccessLvl = cptr.AccessLevel
 Set cptr = sptr
ElseIf cptr.AccessLevel = 1 Then
  tmpOwner = CBool(Chan.Member.Item(cptr.Nick).IsOwner)
  tmpHost = CBool(Chan.Member.Item(cptr.Nick).IsOp)
  tmpHalfOp = CBool(Chan.Member.Item(cptr.Nick).IsHOp)
  If Not (tmpOwner = True Or tmpHost = True Or tmpHalfOp) Then tmpMember = True
  'If not a member of the channel, there are some props we can't read
    If Chan.GetUser(cptr.Nick) Is Nothing Then
      #If Debugging = 1 Then
        SendSvrMsg "Is a user!"
      #End If
      tmpUser = True
      tmpGod = False
      tmpOwner = False
      tmpHost = False
      tmpHalfOp = False
      tmpMember = False
    End If
End If
'prop # *
If StrComp(parv(1), "*") = 0 Then
  'show all properties
  If Chan Is Nothing Then
    'is a user, show user props
    'not yet coded
  Else
    With Chan
      If .Prop_Account <> vbNullString And tmpOwner Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Account :" & .Prop_Account
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Client) <> 0 Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Client :" & .Prop_Client
      'If .Prop_ClientGUID <> vbNullString Then SendWsock cptr.Index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "ClientGUID :" & .Prop_ClientGUID
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Creation :" & .Prop_Creation
      '.Prop_Lag (future implementation)
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Language) <> 0 Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Language :" & .Prop_Language
      If Len(.Prop_Memberkey) <> 0 And Not (tmpUser) And ((tmpMember) Or (tmpOwner) Or (tmpHost)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "MemberKey :" & .Prop_Memberkey
      If Len(.Prop_Name) <> 0 Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Name :" & .Prop_Name
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OID :" & .Prop_OID
      If Len(.Prop_OnJoin) <> 0 And (tmpOwner Or tmpHost) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OnJoin :" & .Prop_OnJoin
      If Len(.Prop_OnPart) <> 0 And (tmpOwner Or tmpHost) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OnPart :" & .Prop_OnPart
      '.Prop_PICS
      '.Prop_ServicePath
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Subject) <> 0 Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Subject :" & .Prop_Subject
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And Len(.Prop_Topic) <> 0 Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Topic :" & .Prop_Topic
      SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCRPL_PROPEND)
    End With
  End If
Else
Dim tmpVal As String
'prop # something :value
'     0    1        2
  With Chan
    'set prop, handle here
    Select Case UCase$(parv(1))
      Case "ACCOUNT":
        If tmpGod Then
          tmpVal = parv(2)
          .Prop_Account = tmpVal
          SendToChanOwners Chan, cptr.Prefix & " PROP " & Chan.Name & " ACCOUNT :" & tmpVal, 0
          If tmpAccessLvl = 4 Then
            SendToServer_ButOne "PROP " & Chan.Name & " ACCOUNT :" & tmpVal, tmpSvrName, cptr.Nick
          Else
            SendToServer "PROP " & Chan.Name & " ACCOUNT :" & tmpVal, cptr.Nick
          End If
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "OWNERKEY":
        If tmpOwner Then
          tmpVal = parv(2)
          .Prop_Ownerkey = tmpVal
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
          .Prop_Hostkey = tmpVal
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
          .Prop_Memberkey = tmpVal
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
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "CLIENT":
        If (tmpOwner Or tmpHost) Then
          tmpVal = parv(2)
          .Prop_Client = tmpVal
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
          .Prop_Account = tmpVal
          SendToChanOwners Chan, cptr.Prefix & " PROP " & Chan.Name & " CREATION :" & tmpVal, 0
          If tmpAccessLvl = 4 Then
            SendToServer_ButOne "PROP " & Chan.Name & " CREATION :" & tmpVal, tmpSvrName, cptr.Nick
          Else
            SendToServer "PROP " & Chan.Name & " CREATION :" & tmpVal, cptr.Nick
          End If
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "LANGUAGE":
        If (tmpOwner Or tmpHost) Then
          tmpVal = parv(2)
          .Prop_Language = tmpVal
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
          .Prop_OnJoin = tmpVal
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
          .Prop_OnPart = tmpVal
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
          .Prop_Subject = tmpVal
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
          .Prop_Topic = tmpVal
          .Topic = tmpVal
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
          GenerateEvent "CHANNEL", "TOPICCHANGE", Chan.Name, Chan.Name & " " & cptr.Nick & " :" & tmpVal
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case Else:
        SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
    End Select
  End With
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
Dim Chan As clsChannel, I&
If cptr.AccessLevel = 4 Then
  Set Chan = Channels(parv(0))
  If UBound(parv) = 1 Then
    'added maxlen (ircx default 160) - ziggy
    SendToChan Chan, sptr.Prefix & " TOPIC " & Chan.Name & " :" & Left$(parv(1), TopicLen), 0
    With Chan
        .Topic = Left$(parv(1), TopicLen)
        .Prop_Topic = Left$(parv(1), TopicLen)
        .TopicSetBy = sptr.Nick
        .TopcSetAt = UnixTime
        SendToServer_ButOne "TOPIC " & .Name & " :" & .Topic, cptr.ServerName, sptr.Nick
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
      If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsHOp And Not Chan.Member.Item(cptr.Nick).IsOwner Then
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
        GenerateEvent "CHANNEL", "TOPICCHANGE", Chan.Name, Chan.Name & " " & cptr.Nick & " :" & parv(1)
        .Topic = parv(1)
        .Prop_Topic = parv(1)
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
#If Debugging = 1 Then
    SendSvrMsg "LISTX called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
'server listing?
Else
    Dim I As Long, Ucount As Long, chans() As clsChannel, ret&
    chans = Channels.Values
    SendWsock cptr.index, IRCRPL_LISTXSTART & " " & cptr.Nick, ":Start of ListX"
    
    If UBound(chans) = 0 And chans(0) Is Nothing Then
        SendWsock cptr.index, IRCRPL_LISTXEND & " " & cptr.Nick, ":End of /LISTX"
        Exit Function
    End If
    'not handling parameters yet
    For I = 0 To UBound(chans)
        If Not (chans(I).IsSecret Or chans(I).IsHidden Or chans(I).IsPrivate) Then
            SendWsock cptr.index, IRCRPL_LISTXLIST & " " & cptr.Nick & " " & chans(I).Name & " +" & Replace(GetModesX(chans(I)), "+", "") & " " & chans(I).Member.Count & " " & chans(I).Limit, ":" & chans(I).Topic
            If MaxListLen > 0 Then
                ret = ret + 1
                If ret = MaxListLen Then Exit For
            End If
        End If
    Next I
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
Else
    Dim I As Long, Ucount As Long, chans() As clsChannel, ret&
    chans = Channels.Values
    ListAt = "check for no channels"
    If UBound(chans) = 0 And chans(0) Is Nothing Then
        ListAt = "no chans"
        SendWsock cptr.index, RPL_LISTEND & " " & cptr.Nick, ":End of /LIST"
        Exit Function
    End If
    ListAt = "check parameters"
    Select Case parv(0)
        Case vbNullString
            ListAt = "no parameters"
            For I = 0 To UBound(chans)
                ListAt = "scan all channels"
                If Not (chans(I).IsSecret Or chans(I).IsHidden Or chans(I).IsPrivate) Then
                    ListAt = "show all chans not +phs"
                    SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[+" & GetModes(chans(I)) & "] " & chans(I).Topic
                    If MaxListLen > 0 Then
                        ret = ret + 1
                        If ret = MaxListLen Then Exit For
                    End If
                End If
            Next I
        Case ">"
            ListAt = "more users than..."
            If UBound(parv) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "LIST")
                Exit Function
            End If
            Ucount = CLng(parv(1))
            For I = 1 To UBound(chans)
                If chans(I).Member.Count > Ucount Then
                    If Not (chans(I).IsSecret Or chans(I).IsHidden Or chans(I).IsPrivate) Then
                        SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[+" & Replace(GetModes(chans(I)), "+", "") & "] " & chans(I).Topic
                        If MaxListLen > 0 Then
                            ret = ret + 1
                            If ret = MaxListLen Then Exit For
                        End If
                    End If
                End If
            Next I
        Case "<"
            ListAt = "less users than"
            If UBound(parv) = 0 Then
                SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "LIST")
                Exit Function
            End If
            Ucount = CLng(parv(1))
            For I = 1 To UBound(chans)
                If chans(I).Member.Count < Ucount Then
                    If Not (chans(I).IsSecret Or chans(I).IsHidden Or chans(I).IsPrivate) Then
                        SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[+" & Replace(GetModes(chans(I)), "+", "") & "] " & chans(I).Topic
                        If MaxListLen > 0 Then
                            ret = ret + 1
                            If ret = MaxListLen Then Exit For
                        End If
                    End If
                End If
            Next I
        Case Else
            ListAt = "case else"
            If InStr(1, parv(0), "*") Then
              ListAt = "contains wildcards"
              For I = LBound(chans) To UBound(chans)
                  ListAt = "scanning channels"
                  If UCase$(chans(I).Name) Like UCase$(parv(0)) Then
                      ListAt = "matches wildcard"
                      If Not (chans(I).IsSecret Or chans(I).IsHidden Or chans(I).IsPrivate) Then
                          ListAt = "can be shown (w/c)"
                          SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[+" & Replace(GetModes(chans(I)), "+", "") & "] " & chans(I).Topic
                          If MaxListLen > 0 Then
                              ret = ret + 1
                              If ret = MaxListLen Then Exit For
                          End If
                      End If
                  End If
              Next I
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
  Dim I&, Chan As clsChannel, RetVal$, x&, chans$(), Membrs() As clsChanMember, y&, z&
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
    For I = LBound(Membrs) To UBound(Membrs) 'List all members of a chan -Dill
      With Membrs(I).Member
          y = y + 1
          If Membrs(I).IsOwner Then
            z = Len(.Nick)
            If cptr.IsIRCX Or cptr.AccessLevel = 4 Then
              'servers aren't supposed to send IRCX when they connect
              'so consider them to be IRCX anyways
              Mid$(RetVal, y, 1) = "."
            Else
              'older clients
              Mid$(RetVal, y, 1) = "@"
            End If
            y = y + 1
            Mid$(RetVal, y, z) = .Nick
            y = y + z
            
          ElseIf Membrs(I).IsOp Then
            z = Len(.Nick)
            Mid$(RetVal, y, 1) = "@"
            y = y + 1
            Mid$(RetVal, y, z) = .Nick
            y = y + z
            
          ElseIf Membrs(I).IsHOp Then
            z = Len(.Nick)
            Mid$(RetVal, y, 1) = "%"
            y = y + 1
            Mid$(RetVal, y, z) = .Nick
            y = y + z
            
          ElseIf Membrs(I).IsVoice Then
            
            z = Len(.Nick)
            Mid$(RetVal, y, 1) = "+"
            y = y + 1
            Mid$(RetVal, y, z) = .Nick
            y = y + z
            
          Else
            z = Len(.Nick)
            Mid$(RetVal, y, z) = .Nick
            y = y + z
            
          End If
          If y > 450 Then 'in case it exceeds 512 bytes, directly send names reply -Dill
            RetVal = Trim$(RetVal)
            'RetVal = Left$(RetVal, InStrRev(RetVal, " "))
            SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & Chan.Name, " :" & RetVal
            RetVal = Space$(500)
            I = I - 1
            y = 0
          End If
      End With
    Next I
    RetVal = Left$(RetVal, y - 1) 'remove leading/trailing spaces -Dill
    'if the buffer still contains char's, send em out -Dill
    If Len(RetVal) > 0 Then SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & Chan.Name, ":" & RetVal
NextChan:
    SendWsock cptr.index, RPL_ENDOFNAMES & " " & cptr.Nick & " " & chans(x) & " :End of /NAMES list.", vbNullString
    RetVal = vbNullString
  Next x
End If
End Function

'/************************************************************************
' * Generic Channel functions
' ************************************************************************/

Public Function IsBanned(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISBANNED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For I = 1 To Channel.Bans.Count
    If (UCase$(UserMask) Like UCase$(Channel.Bans.Item(I).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Bans.Item(I).Mask)) Then
        For A = 1 To Channel.Grants.Count
          If UCase$(UserMask) Like UCase$(Channel.Grants.Item(A).Mask) Then
            IsBanned = False
            Exit Function
          End If
        Next A
        
        'check to see if the user is protected (+P)
        If (User.IsLocOperator Or User.IsGlobOperator) And (User.IsProtected Or User.IsLProtected) Then
          IsBanned = False
          Exit Function
        End If
        
        'no grants for them, banned!
        IsBanned = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function IsDenied(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISDENIED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For I = 1 To Channel.Bans.Count
    If (UCase$(UserMask) Like UCase$(Channel.Bans.Item(I).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Bans.Item(I).Mask)) Then
        
        'check to see if the user is protected (+P)
        If (User.IsLocOperator Or User.IsGlobOperator) And (User.IsProtected Or User.IsLProtected) Then
          IsDenied = False
          Exit Function
        End If
        
        IsDenied = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindVoice(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDVOICE called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Voices.Count
    If UCase$(Mask) Like UCase$(Channel.Voices.Item(I).Mask) Then
        FindVoice = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindHost(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDHOST called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Hosts.Count
    If UCase$(Mask) Like UCase$(Channel.Hosts.Item(I).Mask) Then
        FindHost = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindOwner(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDOWNER called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Owners.Count
    If UCase$(Mask) Like UCase$(Channel.Owners.Item(I).Mask) Then
        FindOwner = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindGrant(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDGRANT called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Grants.Count
    If UCase$(Mask) Like UCase$(Channel.Grants.Item(I).Mask) Then
        FindGrant = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindDeny(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDDENY called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Bans.Count
    If UCase$(Mask) Like UCase$(Channel.Bans.Item(I).Mask) Then
        FindDeny = True
        Exit Function
    End If
Next I
ex:
End Function
Public Sub RemoveDeny(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEDENY called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Bans.Count
    If UCase$(Mask) Like UCase$(Channel.Bans.Item(I).Mask) Then
        Channel.Bans.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveGrant(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEGRANT called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Grants.Count
    If UCase$(Mask) Like UCase$(Channel.Grants.Item(I).Mask) Then
        Channel.Grants.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveVoice(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEVOICE called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Voices.Count
    If UCase$(Mask) Like UCase$(Channel.Voices.Item(I).Mask) Then
        Channel.Voices.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveHost(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEHOST called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Hosts.Count
    If UCase$(Mask) Like UCase$(Channel.Hosts.Item(I).Mask) Then
        Channel.Hosts.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveOwner(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEOWNER called! (" & Mask & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Owners.Count
    If UCase$(Mask) Like UCase$(Channel.Owners.Item(I).Mask) Then
        Channel.Owners.Remove I
    End If
Next I
ex:
End Sub
Public Function IsGranted(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISGRANTED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For I = 1 To Channel.Grants.Count
    If (UCase$(UserMask) Like UCase$(Channel.Grants.Item(I).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Grants.Item(I).Mask)) Then
        IsGranted = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function IsVoiced(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISVOICED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For I = 1 To Channel.Voices.Count
    If (UCase$(UserMask) Like UCase$(Channel.Voices.Item(I).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Voices.Item(I).Mask)) Then
        'voiced!
        IsVoiced = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function IsHosted(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISHOSTED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For I = 1 To Channel.Hosts.Count
    If (UCase$(UserMask) Like UCase$(Channel.Hosts.Item(I).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Hosts.Item(I).Mask)) Then
        'a host
        IsHosted = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function IsOwnered(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISOWNERED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For I = 1 To Channel.Owners.Count
    If (UCase$(UserMask) Like UCase$(Channel.Owners.Item(I).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Owners.Item(I).Mask)) Then
        'an owner
        IsOwnered = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function GetModes(Channel As clsChannel) As String
#If Debugging = 1 Then
    SendSvrMsg "GETMODES called! (" & Channel.Name & ")"
#End If
Dim I&
GetModes = Space$(30)
I = 1
With Channel
    If .IsInviteOnly Then
        Mid$(GetModes, I, 1) = "i"
        I = I + 1
    End If
    If .IsModerated Then
        Mid$(GetModes, I, 1) = "m"
        I = I + 1
    End If
    If .IsNoExternalMsgs Then
        Mid$(GetModes, I, 1) = "n"
        I = I + 1
    End If
    If .IsPrivate Then
        Mid$(GetModes, I, 1) = "p"
        I = I + 1
    End If
    If .IsHidden Then
        Mid$(GetModes, I, 1) = "h"
        I = I + 1
    End If
    If .IsSecret Then
        Mid$(GetModes, I, 1) = "s"
        I = I + 1
    End If
    If .IsTopicOps Then
        Mid$(GetModes, I, 1) = "t"
        I = I + 1
    End If
    If .IsRegistered Then
        Mid$(GetModes, I, 1) = "r"
        I = I + 1
    End If
    If .IsOperOnly Then
        Mid$(GetModes, I, 1) = "O"
        I = I + 1
    End If
    If .IsPersistant Then
        Mid$(GetModes, I, 1) = "R"
        I = I + 1
    End If
    If Len(.Key) > 0 And .Limit > 0 Then
        Mid$(GetModes, I, 3) = "lk "
        I = I + 3
        Mid$(GetModes, I, Len(CStr(.Limit))) = .Limit
        I = I + Len(CStr(.Limit))
    ElseIf Len(.Key) > 0 And .Limit = 0 Then
        Mid$(GetModes, I, 1) = "k"
        I = I + 1
    ElseIf Len(.Key) = 0 And .Limit > 0 Then
        Mid$(GetModes, I, 3) = "l "
        I = I + 2
        Mid$(GetModes, I, Len(CStr(.Limit))) = .Limit
        I = I + Len(CStr(.Limit))
    End If
End With
GetModes = Left$(GetModes, I - 1)
End Function
Public Function GetModesX(Channel As clsChannel) As String
#If Debugging = 1 Then
    SendSvrMsg "GETMODESX called! (" & Channel.Name & ")"
#End If
Dim I&
GetModesX = Space$(30)
I = 1
With Channel
    If .IsInviteOnly Then
        Mid$(GetModesX, I, 1) = "i"
        I = I + 1
    End If
    If .IsModerated Then
        Mid$(GetModesX, I, 1) = "m"
        I = I + 1
    End If
    If .IsNoExternalMsgs Then
        Mid$(GetModesX, I, 1) = "n"
        I = I + 1
    End If
    If .IsPrivate Then
        Mid$(GetModesX, I, 1) = "p"
        I = I + 1
    End If
    If .IsHidden Then
        Mid$(GetModesX, I, 1) = "h"
        I = I + 1
    End If
    If .IsSecret Then
        Mid$(GetModesX, I, 1) = "s"
        I = I + 1
    End If
    If .IsTopicOps Then
        Mid$(GetModesX, I, 1) = "t"
        I = I + 1
    End If
    If .IsRegistered Then
        Mid$(GetModesX, I, 1) = "r"
        I = I + 1
    End If
    If .IsOperOnly Then
        Mid$(GetModesX, I, 1) = "O"
        I = I + 1
    End If
    If .IsPersistant Then
        Mid$(GetModesX, I, 1) = "R"
        I = I + 1
    End If
End With
GetModesX = Left$(GetModesX, I - 1)
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

Public Function m_whisper(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHISPER called! (" & cptr.Nick & ")"
#End If
'/*****************************************************
'* I know, this is basically a copy of m_message -_-  *
'******************************************************/
Dim cmd$, RecList$(), I, x&, Chan As clsChannel, Recp As clsClient, RecvServer() As clsClient, ChM As clsChanMember
If cptr.AccessLevel = 4 Then
    Set Chan = Channels(parv(0))
    If Chan Is Nothing Then Exit Function
    
    RecList = Split(parv(1), ",")
    For Each I In RecList
        If AscW(CStr(I)) = 35 Then
            'you can't whisper to a channel...
            GoTo NextCmd
        Else
            Set Recp = GlobUsers(CStr(I))
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
    For Each I In RecList
      If Len(I) = 0 Then GoTo nextmsg
      If AscW(CStr(I)) = 35 Then
        SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(I))
        GoTo nextmsg
      Else
        'user message -Dill
        If InStr(1, I, "*") <> 0 Then
          If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then 'Can't send to wildcarded recipient list if not an oper -Dill
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
          Else
            'WILDCARD recievelist -Dill
            Dim Umask$, Target() As clsClient
            Umask = ":" & CreateMask(CStr(I))
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
        Set sptr = GlobUsers(CStr(I))
        If sptr Is Nothing Then 'in case user does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(I))
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
        cptr.Idle = UnixTime
      End If
nextmsg:
    Next
End If
End Function
