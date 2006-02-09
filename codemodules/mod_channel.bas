Attribute VB_Name = "mod_channel"
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
' $Id: mod_channel.bas,v 1.3 2004/05/28 20:20:54 ziggythehamster Exp $
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
'On Error Resume Next
On Error GoTo errtrap
Dim A As Integer
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
If cptr.AccessLevel = 4 Then
  'todo: server
Else
  tmpLoc = "entry"
  
  Set Chan = Channels(parv(0))
  #If Debugging = 1 Then
    SendSvrMsg "Channel Ready"
  #End If
  
  If Chan Is Nothing Then
    tmpLoc = "channel does not exist"
    SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
  Else
    tmpLoc = "channel exists"
    If UBound(parv) >= 1 Then
    tmpLoc = "specified a command"
    '#Channel (cmd)
    '0          1
    'we want ACCESS #Channel to be seperate - means "LIST"
      Select Case UCase(parv(1))
        Case "CLEAR"
          tmpLoc = "clear access"
          If UBound(parv) = 1 Then
            'only one parameter, obiously they've specified to clear all access
            If Chan.Member.Item(cptr.Nick).IsOp Then
              tmpLoc = "clear all access"
              Chan.Bans.Clear
              Chan.Grants.Clear
              Chan.Voices.Clear
              Chan.Hosts.Clear
              If Chan.Owners.Count > 0 Then
                SendWsock cptr.index, IRCERR_ACCESSSECURITY & " " & cptr.Nick, TranslateCode(IRCERR_ACCESSSECURITY)
              End If
            ElseIf Chan.Member.Item(cptr.Nick).IsOwner Then
              tmpLoc = "clear all access (owner)"
              Chan.Bans.Clear
              Chan.Grants.Clear
              Chan.Voices.Clear
              Chan.Hosts.Clear
              Chan.Owners.Clear
            End If
          Else
            tmpLoc = "clear specific level"
            If UCase(parv(2)) = "GRANT" Then
              tmpLoc = "clear grants"
              Chan.Grants.Clear
            ElseIf UCase(parv(2)) = "DENY" Then
              tmpLoc = "clear denys"
              Chan.Bans.Clear
            ElseIf UCase(parv(2)) = "VOICE" Then
              tmpLoc = "clear voices"
              Chan.Voices.Clear
            ElseIf UCase(parv(2)) = "HOST" Then
              tmpLoc = "clear hosts"
              Chan.Hosts.Clear
            ElseIf UCase(parv(2)) = "OWNER" Then
              tmpLoc = "clear owners"
              'can only remove access for owner if owner, else return no permissions to perform command
              If Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "clear owners (owner)"
                Chan.Owners.Clear
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
          If UBound(parv) < 5 Then
            tmpLoc = "add needs more params"
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS)
            Exit Function
          Else
            tmpLoc = "add has params"
            If UCase(parv(2)) = "GRANT" Then
              tmpLoc = "grant"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can set grant"
                Mask = CreateMask(parv(3))
                If Not FindGrant(Chan, Mask) Then
                  tmpLoc = "grant does not exist"
                  If Len(Mask) > 0 Then
                    Chan.Grants.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), CLng(parv(4)), CStr(parv(5))
                    SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " GRANT " & Mask & " " & parv(4) & " " & cptr.Nick & " :" & parv(5) & vbCrLf, 0
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
            ElseIf UCase(parv(2)) = "DENY" Then
              tmpLoc = "deny"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can set deny"
                Mask = CreateMask(parv(3))
                If Not FindDeny(Chan, Mask) Then
                  tmpLoc = "deny does not exist"
                  If Len(Mask) > 0 Then
                    Chan.Bans.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), CLng(parv(4)), CStr(parv(5))
                    SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " DENY " & Mask & " " & parv(4) & " " & cptr.Nick & " :" & parv(5) & vbCrLf, 0
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
            ElseIf UCase(parv(2)) = "VOICE" Then
              tmpLoc = "voice"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can set vouce"
                Mask = CreateMask(parv(3))
                If Not FindVoice(Chan, Mask) Then
                  tmpLoc = "voice does not exist"
                  If Len(Mask) > 0 Then
                    Chan.Voices.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), CLng(parv(4)), CStr(parv(5))
                    SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " VOICE " & Mask & " " & parv(4) & " " & cptr.Nick & " :" & parv(5) & vbCrLf, 0
                  End If
                Else
                  tmpLoc = "voice exists"
                  SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
                End If
              Else
                tmpLoc = "cannot set voice"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase(parv(2)) = "HOST" Then
              tmpLoc = "host"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can set host"
                Mask = CreateMask(parv(3))
                tmpLoc = "generated mask"
                If Not FindHost(Chan, Mask) Then
                  tmpLoc = "host does not exist"
                  If Len(Mask) > 0 Then
                    Chan.Hosts.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), CLng(parv(4)), CStr(parv(5))
                    SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " HOST " & Mask & " " & parv(4) & " " & cptr.Nick & " :" & parv(5) & vbCrLf, 0
                  End If
                Else
                  tmpLoc = "host exists"
                  SendWsock cptr.index, IRCERR_DUPACCESS & " " & cptr.Nick, TranslateCode(IRCERR_DUPACCESS)
                End If
              Else
                tmpLoc = "cannot set host"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase(parv(2)) = "OWNER" Then
              tmpLoc = "owner"
              If Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can set owner"
                Mask = CreateMask(parv(3))
                If Not FindOwner(Chan, Mask) Then
                  tmpLoc = "owner does not exist"
                  If Len(Mask) > 0 Then
                    Chan.Owners.AddX CStr(Mask), CStr(cptr.Nick), CLng(UnixTime), CLng(parv(4)), CStr(parv(5))
                    SendRawToChanOps Chan, IRCRPL_ACCESSADD, Chan.Name & " OWNER " & Mask & " " & parv(4) & " " & cptr.Nick & " :" & parv(5) & vbCrLf, 0
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
          End If
        Case "DELETE"
  '%%%%%%%%%%%%%%%%%%%%%%%%% DELETE ACCESS
          If UBound(parv) < 3 Then
            SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS)
            Exit Function
          Else
            tmpLoc = "delete access start"
            If UCase(parv(2)) = "GRANT" Then
              tmpLoc = "delete grant"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete grant"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindGrant(Chan, Mask) Then
                    tmpLoc = "cannot delete grant - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "grant exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveGrant Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " GRANT " & Mask & vbCrLf, 0
                  End If
                Else
                  tmpLoc = "can't delete grant"
                  SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
                End If
              End If
            ElseIf UCase(parv(2)) = "DENY" Then
              tmpLoc = "delete deny"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete deny"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindDeny(Chan, Mask) Then
                    tmpLoc = "cannot delete deny - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "deny exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveDeny Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " DENY " & Mask & vbCrLf, 0
                  End If
                End If
              Else
                tmpLoc = "can't delete deny"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase(parv(2)) = "VOICE" Then
              tmpLoc = "delete voice"
              If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete voice"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindVoice(Chan, Mask) Then
                    tmpLoc = "cannot delete voice - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "voice exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveVoice Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " VOICE " & Mask & vbCrLf, 0
                  End If
                End If
              Else
                tmpLoc = "cannot delete voice"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase(parv(2)) = "HOST" Then
               tmpLoc = "delete host"
               If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete host"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindHost(Chan, Mask) Then
                    tmpLoc = "cannot delete host - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "host exists, deleting"
                    'the entry does exist, delete and return message
                    RemoveHost Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " HOST " & Mask & vbCrLf, 0
                  End If
                End If
              Else
                tmpLoc = "cannot delete host"
                SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
              End If
            ElseIf UCase(parv(2)) = "OWNER" Then
              tmpLoc = "delete owner"
              If Chan.Member.Item(cptr.Nick).IsOwner Then
                tmpLoc = "can delete owner"
                Mask = CreateMask(parv(3))
                If Len(Mask) > 0 Then
                  If Not FindOwner(Chan, Mask) Then
                    tmpLoc = "cannot delete owner - nonexistant"
                    'the entry didn't exist in the first place
                    SendWsock cptr.index, IRCERR_MISACCESS & " " & cptr.Nick, ":Unknown access entry"
                  Else
                    tmpLoc = "owner found, deleting"
                    'the entry does exist, delete and return message
                    RemoveOwner Chan, Mask
                    SendRawToChanOps Chan, IRCRPL_ACCESSDELETE, Chan.Name & " OWNER " & Mask & vbCrLf, 0
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
          tmpLoc = "list"
          If UBound(parv) >= 1 Then
            If Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner Then
              SendWsock cptr.index, IRCRPL_ACCESSSTART & " " & cptr.Nick & " " & Chan.Name, ":Start of access entries" & vbCrLf
              If CInt(Chan.Owners.Count) > 0 Then
                For A = 1 To Chan.Owners.Count
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "OWNER " & Chan.Owners.Item(A).Mask & " " & Chan.Owners.Item(A).Duration & " " & Chan.Owners.Item(A).SetBy & " :" & Chan.Owners.Item(A).Reason & vbCrLf
                Next A
              End If
              If Chan.Hosts.Count > 0 Then
                For A = 1 To Chan.Hosts.Count
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "HOST " & Chan.Hosts.Item(A).Mask & " " & Chan.Hosts.Item(A).Duration & " " & Chan.Hosts.Item(A).SetBy & " :" & Chan.Hosts.Item(A).Reason & vbCrLf
                Next A
              End If
              If Chan.Voices.Count > 0 Then
                For A = 1 To Chan.Voices.Count
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "VOICE " & Chan.Voices.Item(A).Mask & " " & Chan.Voices.Item(A).Duration & " " & Chan.Voices.Item(A).SetBy & " :" & Chan.Voices.Item(A).Reason & vbCrLf
                Next A
              End If
              If Chan.Grants.Count > 0 Then
                For A = 1 To Chan.Grants.Count
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "GRANT " & Chan.Grants.Item(A).Mask & " " & Chan.Grants.Item(A).Duration & " " & Chan.Grants.Item(A).SetBy & " :" & Chan.Grants.Item(A).Reason & vbCrLf
                Next A
              End If
              If Chan.Bans.Count > 0 Then
                For A = 1 To Chan.Bans.Count
                  SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "DENY " & Chan.Bans.Item(A).Mask & " " & Chan.Bans.Item(A).Duration & " " & Chan.Bans.Item(A).SetBy & " :" & Chan.Bans.Item(A).Reason & vbCrLf
                Next A
              End If
              SendWsock cptr.index, IRCRPL_ACCESSEND & " " & cptr.Nick & " " & Chan.Name, ":End of access entries" & vbCrLf
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
        SendWsock cptr.index, IRCRPL_ACCESSSTART & " " & cptr.Nick & " " & Chan.Name, ":Start of access entries" & vbCrLf
        If CInt(Chan.Owners.Count) > 0 Then
          For A = 1 To Chan.Owners.Count
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "OWNER " & Chan.Owners.Item(A).Mask & " " & Chan.Owners.Item(A).Duration & " " & Chan.Owners.Item(A).SetBy & " :" & Chan.Owners.Item(A).Reason & vbCrLf
          Next A
        End If
        If Chan.Hosts.Count > 0 Then
          For A = 1 To Chan.Hosts.Count
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "HOST " & Chan.Hosts.Item(A).Mask & " " & Chan.Hosts.Item(A).Duration & " " & Chan.Hosts.Item(A).SetBy & " :" & Chan.Hosts.Item(A).Reason & vbCrLf
          Next A
        End If
        If Chan.Voices.Count > 0 Then
          For A = 1 To Chan.Voices.Count
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "VOICE " & Chan.Voices.Item(A).Mask & " " & Chan.Voices.Item(A).Duration & " " & Chan.Voices.Item(A).SetBy & " :" & Chan.Voices.Item(A).Reason & vbCrLf
          Next A
        End If
        If Chan.Grants.Count > 0 Then
          For A = 1 To Chan.Grants.Count
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "GRANT " & Chan.Grants.Item(A).Mask & " " & Chan.Grants.Item(A).Duration & " " & Chan.Grants.Item(A).SetBy & " :" & Chan.Grants.Item(A).Reason & vbCrLf
          Next A
        End If
        If Chan.Bans.Count > 0 Then
          For A = 1 To Chan.Bans.Count
            SendWsock cptr.index, IRCRPL_ACCESSLIST & " " & cptr.Nick & " " & Chan.Name, "DENY " & Chan.Bans.Item(A).Mask & " " & Chan.Bans.Item(A).Duration & " " & Chan.Bans.Item(A).SetBy & " :" & Chan.Bans.Item(A).Reason & vbCrLf
          Next A
        End If
        SendWsock cptr.index, IRCRPL_ACCESSEND & " " & cptr.Nick & " " & Chan.Name, ":End of access entries" & vbCrLf
      Else
        SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
      End If
    End If
  End If
End If
Exit Function

errtrap:
SendSvrMsg "** ERROR ON ACCESS: " & err.Number & " - " & err.Description & " LIB: " & err.LastDllError & " AT: " & tmpLoc
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
'On Error Resume Next
Dim Chan As clsChannel, I&, x&, Target As clsClient, op$, NewOp As Boolean, NewModes$(), ToUsers$()
Dim SendModes As Boolean, Mask$, Ban As clsBan, parc&, chans$(), y&, Inc&, MSwitch As Boolean
ReDim ToUsers(0): ReDim NewModes(0): parc = UBound(parv)
If cptr.AccessLevel = 4 Then
'NOTE: This portion of code is for AccessLevel "4"; I believe that this is the AL that servers get.
'scroll down to locate the code for clients!
    Dim NM$, MU$, ChanMember As clsChanMember
    If AscW(parv(0)) = 35 Then
        'chan
        Set Chan = Channels(parv(0))
        If Len(sptr.Nick) = 0 Then
            If Len(sptr.ServerName) > 0 Then op = cptr.ServerName
        Else
            op = sptr.Nick
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
                '** Removed HalfOp for now - Ziggy
                'Case cmHOp
                '    Inc = Inc + 1
                '    If MSwitch Then
                '        With Chan.Member.Item(parv(Inc))
                '            If Not .IsHOp Then
                '                .IsHOp = True
                '            End If
                '        End With
                '    Else
                '        With Chan.Member.Item(parv(Inc))
                '            If .IsHOp Then
                '                .IsHOp = False
                '            End If
                '        End With
                '    End If
                '    MU = MU & " " & parv(Inc)
                '    NM = NM & "H"
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
            End Select
        Next I
        MU = LTrim$(MU)
        SendToChan Chan, ":" & op & " MODE " & Chan.Name & " " & NM & " " & MU, vbNullString
        SendToServer_ButOne "MODE " & Chan.Name & " " & NM & " " & MU, cptr.ServerName, op
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
                    NM = NM & "o"
                Case umInvisible
                    Target.IsInvisible = MSwitch
                    NM = NM & "i"
                Case umHostCloak
                    Target.IsCloaked = MSwitch
                    NM = NM & "d"
                Case umRegistered
                    Target.IsRegistered = MSwitch
                    NM = NM & "r"
            End Select
        Next I
        GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & NM
        SendToServer_ButOne "MODE " & Target.Nick & " " & NM, cptr.ServerName, sptr.Nick
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
    If parc < 1 Then
      SendWsock cptr.index, SPrefix & " " & RPL_CHANNELMODEIS & " " & cptr.Nick & " " & Chan.Name & " :+" & GetModes(Chan), vbNullString, , True
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
        If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsHOp And Not Chan.Member.Item(cptr.Nick).IsOwner Then
          SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
          Exit Function
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
            Select Case AscW(op)
              Case modeAdd
                If parc < I Then
                  For x = 1 To Chan.Bans.Count
                    SendWsock cptr.index, SPrefix & " " & RPL_BANLIST & " " & cptr.Nick & " " & Chan.Name & " " & Chan.Bans(x).Mask & " " & Chan.Bans(x).SetBy & " :" & Chan.Bans(x).SetOn, vbNullString, , True
                  Next x
                  SendWsock cptr.index, SPrefix & " " & RPL_ENDOFBANLIST & " " & cptr.Nick & " " & Chan.Name & " :End of Channel Ban List", vbNullString, , True
                Else
                  If UBound(parv) > 2 Then
                    SendWsock cptr.index, IRCERR_TOOMANYARGUMENTS & " " & cptr.Nick & " MODE", TranslateCode(IRCERR_TOOMANYARGUMENTS)
                    Exit Function
                  End If
                  SendModes = True
                  Mask = CreateMask(parv(I))
                  Set Ban = Chan.Bans(Mask)
                  If Ban Is Nothing Then
                    Chan.Bans.Add Mask, cptr.Nick, UnixTime, Mask
                    GoTo banover
                  Else
                    'the ban already exists, no need to add it again
                    GoTo NextMode
                  End If
banover:
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
                If Target.IsProtected = True Then
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
                If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
                  ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
                  NewModes(UBound(NewModes)) = "o": ToUsers(UBound(ToUsers)) = Target.Nick
                  With Chan.Member.Item(Target.Nick)
                    .IsOp = False
                  End With
            End Select
          'Case cmHOp
          '  If parc < i Then GoTo NextMode
          '  Select Case AscW(op)
          '    Case modeAdd
          '      If parc < i Then GoTo NextMode
          '      Set Target = GlobUsers(parv(i))
          '      If Target Is Nothing Then
          '        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(i), Chan.Name)
          '        GoTo NextMode
          '      End If
          '      If Not Chan.Member.Item(Target.Nick).IsHOp Then
          '        If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
          '        ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
          '        NewModes(UBound(NewModes)) = "H": ToUsers(UBound(ToUsers)) = Target.Nick
          '        With Chan.Member.Item(Target.Nick)
          '          .IsHOp = True
          '        End With
          '      End If
          '    Case modeRemove
          '      If parc < i Then GoTo NextMode
          '      Set Target = GlobUsers(parv(i))
          '      If Target Is Nothing Then
          '        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(i), Chan.Name)
          '        GoTo NextMode
          '      End If
          '      If Chan.Member.Item(Target.Nick).IsHOp Then
          '        If UBound(NewModes) = 12 Or UBound(ToUsers) = 12 Then GoTo Flush
          '        ReDim Preserve NewModes(UBound(NewModes) + 1): ReDim Preserve ToUsers(UBound(ToUsers) + 1)
          '        NewModes(UBound(NewModes)) = "h": ToUsers(UBound(ToUsers)) = Target.Nick
          '        With Chan.Member.Item(Target.Nick)
          '          .IsHOp = False
          '        End With
          '      End If
          '  End Select
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
    If Not cptr Is Target Then
        SendWsock cptr.index, ERR_USERSDONTMATCH, cptr.Nick & " " & TranslateCode(ERR_USERSDONTMATCH)
        Exit Function
    End If
    If UBound(parv) = 0 Then
        SendWsock cptr.index, SPrefix & " 221 " & cptr.Nick & " +" & cptr.GetModes, vbNullString, , True
        Exit Function
    End If
    Set Target = Nothing
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
                        cptr.IsLocOperator = False
                        cptr.IsGlobOperator = False
                        Opers.Remove cptr.GUID
                        cptr.AccessLevel = 1
                        op = op & Mask
                    End If
                End If
            Case umProtected
                If MSwitch = True Then
                  If cptr.IsLocOperator Or cptr.IsGlobOperator Then
                    cptr.IsProtected = True
                    op = op & Mask
                  End If
                Else
                  If cptr.IsLocOperator Or cptr.IsGlobOperator Then
                    cptr.IsProtected = False
                    op = op & Mask
                  End If
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
'            Case umKillMsg
'                If Not cptr.IsKillMsg = MSwitch Then
'                    cptr.IsKillMsg = MSwitch
'                    op = op & Mask
'                    If MSwitch Then
'                        KillMsg.Add cptr.GUID, cptr
'                    Else
'                        KillMsg.Remove cptr.GUID
'                    End If
'                End If
'            Case umCanRehash
'                op = op & Mask
'            Case umCanRestart
'                op = op & Mask
'            Case umCanDie
'                op = op & Mask
'            Case umGlobRouting
'                op = op & Mask
'            Case umLocRouting
'                op = op & Mask
'            Case umLocKills
'                op = op & Mask
'            Case umGlobKills
'                op = op & Mask
        End Select
    Next I
    If Len(op) > 1 Then
        GenerateEvent "USER", "MODECHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & op
        SendWsock cptr.index, "MODE " & cptr.Nick, op, ":" & cptr.Nick
        SendToServer "MODE " & cptr.Nick & " " & op, cptr.Nick
    End If
  End If
End If
Exit Function
Flush:
If SendModes = False Then Exit Function
Dim M$, u$
M = Trim$(Join(NewModes, vbNullString)): u = Trim$(Join(ToUsers, " "))
If Len(M) <> 0 Then
SendToChan Chan, ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host & " MODE " & Chan.Name & " " & op & M & " " & u, 0
SendToServer "MODE " & Chan.Name & " " & op & M & " " & u, cptr.Nick
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
    Else
      sptr.OnChannels.Add Chan, Chan.Name
      Chan.Member.Add ChanNormal, sptr
      GenerateEvent "USER", "JOIN", Replace(sptr.Prefix, ":", ""), Replace(sptr.Prefix, ":", "") & " " & Chan.Name
      SendToChan Chan, sptr.Prefix & " JOIN " & Chan.Name, 0
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
    Set Chan = Channels(StrCache)
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
      SendWsock cptr.index, cptr.Prefix & " JOIN " & StrCache, vbNullString, , True
      SendWsock cptr.index, RPL_NAMREPLY & " " & cptr.Nick & " = " & StrCache, ":." & cptr.Nick
      SendWsock cptr.index, SPrefix & " " & RPL_ENDOFNAMES & " " & cptr.Nick & " " & Chan.Name & " :End of /NAMES list.", vbNullString, , True
      GenerateEvent "USER", "JOIN", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & Chan.Name
      SendToServer "JOIN " & Chan.Name, cptr.Nick
    Else
      CurrentInfo = "channel exists"
      'is there a user limit set? -Dill
      If Chan.Limit > 0 Then
        If Chan.Member.Count >= Chan.Limit Then
          CurrentInfo = "channel full"
          SendWsock cptr.index, ERR_CHANNELISFULL & " " & cptr.Nick & " " & TranslateCode(ERR_CHANNELISFULL, , Chan.Name), vbNullString, SPrefix
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
            Exit Function
          End If
        Else
          CurrentInfo = "invalid key"
          SendWsock cptr.index, ERR_BADCHANNELKEY & " " & cptr.Nick & " " & TranslateCode(ERR_BADCHANNELKEY, , Chan.Name), vbNullString, SPrefix
          Exit Function
        End If
      End If
      'is it invite-only? -Dill
      If Chan.IsInviteOnly Then
        CurrentInfo = "invite only"
        'is the user on the invite list? -Dill
        If Chan.IsInvited(cptr.Nick) = False Then
            CurrentInfo = "not invited"
            SendWsock cptr.index, ERR_INVITEONLYCHAN & " " & cptr.Nick & " " & TranslateCode(ERR_INVITEONLYCHAN, , Chan.Name), vbNullString, SPrefix
            Exit Function
        End If
      End If
      'cptr is allowed to join the channel, so we let it -Dill
      CurrentInfo = "allowed on channel"
      cptr.OnChannels.Add Chan, Chan.Name
      Chan.Member.Add ChanNormal, cptr
      'Notify all users about the new member -Dill
      SendToChan Chan, cptr.Prefix & " JOIN " & Chan.Name, 0
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
          SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick & vbCrLf, 0
          SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
        End If
        If parv(1) = Chan.Prop_Hostkey And Len(Chan.Prop_Hostkey) > 0 And Chan.Member.Item(cptr.Nick).IsOwner = False Then
          CurrentInfo = "hostkey"
          Chan.Member.Item(cptr.Nick).IsOp = True
          SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick & vbCrLf, 0
          SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
        End If
      End If
      CurrentInfo = "oper check"
      If ((cptr.IsGlobOperator) Or (cptr.IsLocOperator)) And (cptr.IsProtected) Then
        'Protected IRCOps should be auto-owner
        Chan.Member.Item(cptr.Nick).IsOwner = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick & vbCrLf, 0
        SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
      If IsOwnered(Chan, cptr) Then
        'is in owner access
        CurrentInfo = "user is ownered"
        Chan.Member.Item(cptr.Nick).IsOwner = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +q " & cptr.Nick & vbCrLf, 0
        SendToServer "MODE " & Chan.Name & " +q " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
      If IsHosted(Chan, cptr) Then
        'is in host access
        CurrentInfo = "user is hosted"
        Chan.Member.Item(cptr.Nick).IsOp = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +o " & cptr.Nick & vbCrLf, 0
        SendToServer "MODE " & Chan.Name & " +o " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
      If IsVoiced(Chan, cptr) Then
        'is in voice access
        CurrentInfo = "user is voiced"
        Chan.Member.Item(cptr.Nick).IsVoice = True
        SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " +v " & cptr.Nick & vbCrLf, 0
        SendToServer "MODE " & Chan.Name & " +v " & cptr.Nick, cptr.Nick
        GoTo pastaccess
      End If
pastaccess:
      GenerateEvent "USER", "JOIN", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & Chan.Name
      CurrentInfo = "onjoin"
      If Len(Chan.Prop_OnJoin) > 0 Then
        OnJoinS() = Split(Chan.Prop_OnJoin, "\n")
        For b = 0 To UBound(OnJoinS)
            SendWsock cptr.index, ":" & Chan.Name & " PRIVMSG " & Chan.Name & " :" & OnJoinS(b) & vbCrLf, vbNullString, , True
        Next b
      End If
    End If
NextChan:
  Next
End If
Exit Function
err:
SendSvrMsg "*** ERROR ON JOIN: " & err.Description & " AT: " & CurrentInfo & " BY: " & cptr.Nick
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
            'Case "%"
            '    cache = Mid$(nUser(i), 2)
            '    Modes = Modes & "H"
            '    nu = nu & cache & " "
            '    Set User = GlobUsers(cache)
            '    If Not User Is Nothing Then Chan.Member.Add ChanHOp, User
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
Dim x&, cmd$, Chan As clsChannel, chans$(), I&, A&, OnPartS$()
If cptr.AccessLevel = 4 Then
  chans = Split(parv(0), ",")
  With sptr
    For I = LBound(chans) To UBound(chans)  'Letting clients part multiple chans at one time -Dill
      Set Chan = .OnChannels.Item(chans(I))
      If Chan Is Nothing Then GoTo NextChannel
      If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
        cmd = .Prefix & " PART " & chans(I)
      Else
        cmd = .Prefix & " PART " & chans(I) & " :" & parv(1)
      End If
      SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
      SendToServer_ButOne "PART " & Chan.Name, cptr.ServerName, sptr.Nick
      Chan.Member.Remove .Nick
      .OnChannels.Remove chans(I)
      If Chan.Member.Count = 0 Then Channels.Remove Chan.Name
      Set Chan = Nothing
      GenerateEvent "USER", "PART", Replace(.Prefix, ":", ""), Replace(.Prefix, ":", "") & " " & chans(I)
NextChannel:
    Next I
  End With
Else
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PART")
    Exit Function
  End If
  If InStr(1, parv(0), ",") > 0 Then
    chans = Split(parv(0), ",")
    With cptr
      For I = LBound(chans) To UBound(chans)  'Letting clients part multiple chans at one time -Dill
        If Not .IsOnChan(parv(0)) Then    'if client wasn't on this channel then complain -Dill
          SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , chans(I))
          GoTo NextChan
        End If
        Set Chan = Channels(chans(I))
        If Chan Is Nothing Then Exit Function
        If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
          cmd = .Prefix & " PART " & chans(I)
        Else
          If PartLen > 0 Then
            parv(1) = Mid$(parv(1), 1, PartLen)
          End If
          cmd = .Prefix & " PART " & chans(I) & " :" & parv(1)
        End If
        SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
        SendToServer "PART " & chans(I) & " :" & cptr.Nick, cptr.Nick
        Chan.Member.Remove cptr.Nick
        .OnChannels.Remove chans(I)
        If Chan.Member.Count = 0 Then Channels.Remove Chan.Name
        Set Chan = Nothing
        GenerateEvent "USER", "PART", Replace(.Prefix, ":", ""), Replace(.Prefix, ":", "") & " " & chans(I)
        If Len(Chan.Prop_OnPart) > 0 Then
        OnPartS() = Split(Chan.Prop_OnPart, "\n")
        For A = 0 To UBound(OnPartS)
            SendWsock cptr.index, ":" & Chan.Name & " NOTICE " & Chan.Name & " :" & OnPartS(A) & vbCrLf, vbNullString, , True
        Next A
      End If
NextChan:
      Next I
    End With
  Else
    #If Debugging = 1 Then
        On Error GoTo 0
    #End If
        
    Set Chan = Channels(parv(0))
    If Chan Is Nothing Then
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , chans(I))
        GoTo NextChan
    End If
    If Not cptr.IsOnChan(Chan.Name) Then
        SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , chans(I))
        GoTo NextChan
    End If
    If UBound(parv) = 0 Then  'Did client provide a part msg? -Dill
        cmd = cptr.Prefix & " PART " & parv(0)
    Else
        cmd = cptr.Prefix & " PART " & parv(0) & " :" & parv(1)
    End If
    SendToChan Chan, cmd, 0   'Notify all channelmembers -Dill
    SendToServer "PART " & parv(0) & " :" & cptr.Nick, cptr.Nick
    Chan.Member.Remove cptr.Nick
    cptr.OnChannels.Remove parv(0)
    If Chan.Member.Count = 0 Then Channels.Remove Chan.Name
    Set Chan = Nothing
    GenerateEvent "USER", "PART", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & parv(0)
      If Len(Chan.Prop_OnPart) > 0 Then
        OnPartS() = Split(Chan.Prop_OnPart, "\n")
        For A = 0 To UBound(OnPartS)
            SendWsock cptr.index, ":" & Chan.Name & " NOTICE " & Chan.Name & " :" & OnPartS(A) & vbCrLf, vbNullString, , True
        Next A
      End If
  End If
End If
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
  If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsOwner And Not Chan.Member.Item(cptr.Nick).IsHOp Then
    SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
    Exit Function
  End If
  If Chan.Member.Item(victim.Nick).IsOwner Then
    If Chan.Member.Item(cptr.Nick).IsOp Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
    ElseIf Chan.Member.Item(cptr.Nick).IsHOp Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
    End If
  End If
  If Chan.Member.Item(victim.Nick).IsOp And Chan.Member.Item(cptr.Nick).IsHOp Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
  End If
  '%% commented-out - Ziggy
  '(I think that halfops can kick other halfops [?])
  'If Chan.Member.Item(victim.Nick).IsHOp And Chan.Member.Item(cptr.Nick).IsHOp Then
  '      SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
  '      Exit Function
  'End If
  
  If victim.IsProtected = True Then
  'note: this only checks to see if a user is kicking an oper
  'opers can kick other opers
    If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
      SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
      Exit Function
    End If
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
Dim tmpOwner As Boolean
Dim tmpHost As Boolean
Dim tmpHalfOp As Boolean
Dim tmpMember As Boolean
Dim tmpUser As Boolean 'outside the channel

If cptr.AccessLevel = 3 Then
  'ircop
  tmpOwner = True
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
      'If .Prop_Account <> vbNullString And tmpOwner Then SendWsock cptr.Index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Account :" & .Prop_Account
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And .Prop_Client <> vbNullString Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Client :" & .Prop_Client
      'If .Prop_ClientGUID <> vbNullString Then SendWsock cptr.Index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "ClientGUID :" & .Prop_ClientGUID
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Creation :" & .Prop_Creation
      '.Prop_Lag (future implementation)
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And .Prop_Language <> vbNullString Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Language :" & .Prop_Language
      If .Prop_Name <> vbNullString Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Name :" & .Prop_Name
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OID :" & .Prop_OID
      If .Prop_OnJoin <> vbNullString And (tmpOwner Or tmpHost) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OnJoin :" & .Prop_OnJoin
      If .Prop_OnPart <> vbNullString And (tmpOwner Or tmpHost) Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "OnPart :" & .Prop_OnPart
      '.Prop_PICS
      '.Prop_ServicePath
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And .Prop_Subject <> vbNullString Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Subject :" & .Prop_Subject
      If Not (tmpUser And (Chan.IsSecret Or Chan.IsPrivate)) And .Prop_Topic <> vbNullString Then SendWsock cptr.index, IRCRPL_PROPLIST & " " & cptr.Nick & " " & Chan.Name, "Topic :" & .Prop_Topic
      SendWsock cptr.index, IRCRPL_PROPEND & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCRPL_PROPEND)
    End With
  End If
Else
Dim tmpVal As String
'prop # something :value
'     0    1        2
  With Chan
    'set prop, handle here
    Select Case UCase(parv(1))
      Case "OWNERKEY":
        If tmpOwner Then
          tmpVal = parv(2)
          .Prop_Ownerkey = tmpVal
          SendToChanOwners Chan, cptr.Prefix & " PROP " & Chan.Name & " OWNERKEY :" & tmpVal, 0
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "HOSTKEY":
        If tmpOwner Or tmpHost Then
          tmpVal = parv(2)
          .Prop_Hostkey = tmpVal
          SendToChanOps Chan, cptr.Prefix & " PROP " & Chan.Name & " HOSTKEY :" & tmpVal, 0
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "CLIENT":
        If (tmpOwner Or tmpHost) Then
          tmpVal = parv(2)
          .Prop_Client = tmpVal
          SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " CLIENT :" & tmpVal, 0
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "CREATION":
        'this cannot be set
        SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
      Case "LANGUAGE":
        If (tmpOwner Or tmpHost) Then
          tmpVal = parv(2)
          .Prop_Language = tmpVal
          SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " LANGUAGE :" & tmpVal, 0
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
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "ONPART":
        If (tmpOwner Or tmpHost) Then
          tmpVal = parv(2)
          .Prop_OnPart = tmpVal
          SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " ONPART :" & tmpVal, 0
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "SUBJECT":
        If (tmpOwner Or tmpHost) Then
          tmpVal = parv(2)
          .Prop_Subject = tmpVal
          SendToChan Chan, cptr.Prefix & " PROP " & Chan.Name & " SUBJECT :" & tmpVal, 0
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case "TOPIC":
        If (tmpOwner Or tmpHost) Or Chan.IsTopicOps Then
          tmpVal = parv(2)
          .Prop_Topic = tmpVal
          .Topic = tmpVal
          .TopicSetBy = sptr.Nick
          .TopcSetAt = UnixTime
        Else
          SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
        End If
      Case Else:
        SendWsock cptr.index, IRCERR_BADPROPERTY & " " & cptr.Nick & " " & Chan.Name, TranslateCode(IRCERR_BADPROPERTY)
    End Select
  End With
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
    SendToChan Chan, sptr.Prefix & " TOPIC " & Chan.Name & " :" & Left(parv(1), TopicLen), 0
    With Chan
        .Topic = Left(parv(1), TopicLen)
        .Prop_Topic = Left(parv(1), TopicLen)
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
      parv(1) = Mid$(parv(1), 1, TopicLen)
    End If
    If Chan.IsTopicOps Then
      If Not Chan.Member.Item(cptr.Nick).IsOp And Not Chan.Member.Item(cptr.Nick).IsHOp And Not Chan.Member.Item(cptr.Nick).IsOwner Then
        SendWsock cptr.index, ERR_CHANOPRIVSNEEDED & " " & cptr.Nick, TranslateCode(ERR_CHANOPRIVSNEEDED, , Chan.Name)
        Exit Function
      End If
    End If
    With Chan
        SendToChan Chan, cptr.Prefix & " TOPIC " & .Name & " :" & parv(1), 0
        SendToServer "TOPIC " & .Name & " :" & Left(parv(1), TopicLen), cptr.Nick
        .Topic = Left(parv(1), TopicLen)
        .Prop_Topic = Left(parv(1), TopicLen)
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
                    SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[" & GetModes(chans(I)) & "] " & chans(I).Topic
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
                        SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[" & Replace(GetModes(chans(I)), "+", "") & "] " & chans(I).Topic
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
                        SendWsock cptr.index, 322 & " " & cptr.Nick & " " & chans(I).Name & " " & chans(I).Member.Count, ":[" & Replace(GetModes(chans(I)), "+", "") & "] " & chans(I).Topic
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
                  If UCase(chans(I).Name) Like UCase(parv(0)) Then
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
SendSvrMsg "*** Error in LIST: " & err.Number & " - " & err.Description & " at: " & ListAt
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
            Mid$(RetVal, y, 1) = "."
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
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
For I = 1 To Channel.Bans.Count
    If UCase(UserMask) Like UCase(Channel.Bans.Item(I).Mask) Then
        For A = 1 To Channel.Grants.Count
          If UCase(UserMask) Like UCase(Channel.Grants.Item(A).Mask) Then
            IsBanned = False
            Exit Function
          End If
        Next A
        
        'check to see if the user is protected (+P)
        If ((User.IsLocOperator) Or (User.IsGlobOperator)) And (User.IsProtected) Then
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
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
For I = 1 To Channel.Bans.Count
    If UCase(UserMask) Like UCase(Channel.Bans.Item(I).Mask) Then
        
        'check to see if the user is protected (+P)
        If ((User.IsLocOperator) Or (User.IsGlobOperator)) And (User.IsProtected) Then
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
    SendSvrMsg "FINDVOICE called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Voices.Count
    If UCase(Mask) Like UCase(Channel.Voices.Item(I).Mask) Then
        FindVoice = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindHost(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDHOST called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Hosts.Count
    If UCase(Mask) Like UCase(Channel.Hosts.Item(I).Mask) Then
        FindHost = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindOwner(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDOWNER called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Owners.Count
    If UCase(Mask) Like UCase(Channel.Owners.Item(I).Mask) Then
        FindOwner = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindGrant(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDGRANT called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Grants.Count
    If UCase(Mask) Like UCase(Channel.Grants.Item(I).Mask) Then
        FindGrant = True
        Exit Function
    End If
Next I
ex:
End Function
Public Function FindDeny(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDDENY called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Bans.Count
    If UCase(Mask) Like UCase(Channel.Bans.Item(I).Mask) Then
        FindDeny = True
        Exit Function
    End If
Next I
ex:
End Function
Public Sub RemoveDeny(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEDENY called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Bans.Count
    If UCase(Mask) Like UCase(Channel.Bans.Item(I).Mask) Then
        Channel.Bans.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveGrant(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEGRANT called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Grants.Count
    If UCase(Mask) Like UCase(Channel.Grants.Item(I).Mask) Then
        Channel.Grants.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveVoice(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEVOICE called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Voices.Count
    If UCase(Mask) Like UCase(Channel.Voices.Item(I).Mask) Then
        Channel.Voices.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveHost(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEHOST called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Hosts.Count
    If UCase(Mask) Like UCase(Channel.Hosts.Item(I).Mask) Then
        Channel.Hosts.Remove I
    End If
Next I
ex:
End Sub
Public Sub RemoveOwner(Channel As clsChannel, Mask As String)
#If Debugging = 1 Then
    SendSvrMsg "REMOVEOWNER called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex

For I = 1 To Channel.Owners.Count
    If UCase(Mask) Like UCase(Channel.Owners.Item(I).Mask) Then
        Channel.Owners.Remove I
    End If
Next I
ex:
End Sub
Public Function IsGranted(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISGRANTED called! (" & User.Nick & ")"
#End If
Dim I As Long, UserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
For I = 1 To Channel.Grants.Count
    If UCase(UserMask) Like UCase(Channel.Grants.Item(I).Mask) Then
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
Dim I As Long, UserMask$
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
For I = 1 To Channel.Voices.Count
    If UCase(UserMask) Like UCase(Channel.Voices.Item(I).Mask) Then
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
Dim I As Long, UserMask$
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
For I = 1 To Channel.Hosts.Count
    If UCase(UserMask) Like UCase(Channel.Hosts.Item(I).Mask) Then
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
Dim I As Long, UserMask$
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
For I = 1 To Channel.Owners.Count
    If UCase(UserMask) Like UCase(Channel.Owners.Item(I).Mask) Then
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
    If .IsSecret Then
        Mid$(GetModesX, I, 1) = "s"
        I = I + 1
    End If
    If .IsHidden Then
        Mid$(GetModesX, I, 1) = "h"
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

