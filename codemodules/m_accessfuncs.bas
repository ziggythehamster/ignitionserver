Attribute VB_Name = "m_accessfuncs"
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
' $Id: m_accessfuncs.bas,v 1.7 2005/07/08 22:59:29 ziggythehamster Exp $
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
'/*
'** ACCESS functions
'** seperated from mod_channel to make mod_channel smaller and this easier to modify and edit...
'*/

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
Public Function CopyAccess(source As clsChannel, Destination As clsChannel)
Dim A As Long
On Error GoTo CpAcErr
If source.Bans.Count > 0 Then
  For A = 1 To source.Bans.Count
    Destination.Bans.AddX source.Bans(A).Mask, source.Bans(A).SetBy, source.Bans(A).SetOn, source.Bans(A).Duration, source.Bans(A).Reason
  Next A
End If
If source.Voices.Count > 0 Then
  For A = 1 To source.Voices.Count
    Destination.Voices.AddX source.Voices(A).Mask, source.Voices(A).SetBy, source.Voices(A).SetOn, source.Voices(A).Duration, source.Voices(A).Reason
  Next A
End If
If source.Hosts.Count > 0 Then
  For A = 1 To source.Hosts.Count
    Destination.Hosts.AddX source.Hosts(A).Mask, source.Hosts(A).SetBy, source.Hosts(A).SetOn, source.Hosts(A).Duration, source.Hosts(A).Reason
  Next A
End If
If source.Owners.Count > 0 Then
  For A = 1 To source.Owners.Count
    Destination.Owners.AddX source.Owners(A).Mask, source.Owners(A).SetBy, source.Owners(A).SetOn, source.Owners(A).Duration, source.Owners(A).Reason
  Next A
End If
Exit Function

CpAcErr:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'CopyAccess'"
End Function
Public Function IsBanned(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISBANNED called! (" & User.Nick & ")"
#End If
Dim i As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For i = 1 To Channel.Bans.Count
    If (UCase$(UserMask) Like UCase$(Channel.Bans.Item(i).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Bans.Item(i).Mask)) Then
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
Next i
ex:
End Function
Public Function IsDenied(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISDENIED called! (" & User.Nick & ")"
#End If
Dim i As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For i = 1 To Channel.Bans.Count
    If (UCase$(UserMask) Like UCase$(Channel.Bans.Item(i).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Bans.Item(i).Mask)) Then
        
        'check to see if the user is protected (+P)
        If (User.IsLocOperator Or User.IsGlobOperator) And (User.IsProtected Or User.IsLProtected) Then
          IsDenied = False
          Exit Function
        End If
        
        IsDenied = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function FindVoice(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDVOICE called! (" & Mask & ")"
#End If
Dim i As Long, UserMask$
Dim A As Long
On Error GoTo ex

For i = 1 To Channel.Voices.Count
    If UCase$(Mask) Like UCase$(Channel.Voices.Item(i).Mask) Then
        FindVoice = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function FindHost(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDHOST called! (" & Mask & ")"
#End If
Dim i As Long, UserMask$
Dim A As Long
On Error GoTo ex

For i = 1 To Channel.Hosts.Count
    If UCase$(Mask) Like UCase$(Channel.Hosts.Item(i).Mask) Then
        FindHost = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function FindOwner(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDOWNER called! (" & Mask & ")"
#End If
Dim i As Long, UserMask$
Dim A As Long
On Error GoTo ex

For i = 1 To Channel.Owners.Count
    If UCase$(Mask) Like UCase$(Channel.Owners.Item(i).Mask) Then
        FindOwner = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function FindGrant(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDGRANT called! (" & Mask & ")"
#End If
Dim i As Long, UserMask$
Dim A As Long
On Error GoTo ex

For i = 1 To Channel.Grants.Count
    If UCase$(Mask) Like UCase$(Channel.Grants.Item(i).Mask) Then
        FindGrant = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function FindDeny(Channel As clsChannel, Mask As String) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "FINDDENY called! (" & Mask & ")"
#End If
Dim i As Long, UserMask$
Dim A As Long
On Error GoTo ex

For i = 1 To Channel.Bans.Count
    If UCase$(Mask) Like UCase$(Channel.Bans.Item(i).Mask) Then
        FindDeny = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function FindAccessEntry(Channel As clsChannel, Mask As String, AccessKind As enmAccessType)
#If Debugging = 1 Then
    SendSvrMsg "FINDACCESSENTRY called! (" & Mask & " - AccessKind: " & CInt(AccessKind) & ")"
#End If
Dim i As Long, UserMask$
On Error GoTo oops

'/*
'** Hopefully, this code won't suck as bad as the other subs do.
'** You know, since, like, the code is dirty and nasty. I have like
'** 8 subs that all do essentially the same thing. This is *so* the
'** better way to handle this. Anyways, this code is supposed to do
'** EXACT matching. Please don't file any bugs saying that it's not
'** doing wildcard matching -- this is the intended behavior. Mmkay?
'*/

If AccessKind = aDeny Then
  If Channel.Bans.Count > 0 Then
    For i = 1 To Channel.Bans.Count
        If UCase$(Mask) = UCase$(Channel.Bans.Item(i).Mask) Then
            FindAccessEntry = True
            Exit Function
        End If
    Next i
  End If
ElseIf AccessKind = aGrant Then
  If Channel.Grants.Count > 0 Then
    For i = 1 To Channel.Grants.Count
        If UCase$(Mask) = UCase$(Channel.Grants.Item(i).Mask) Then
            FindAccessEntry = True
            Exit Function
        End If
    Next i
  End If
ElseIf AccessKind = aHost Then
  If Channel.Hosts.Count > 0 Then
    For i = 1 To Channel.Hosts.Count
        If UCase$(Mask) = UCase$(Channel.Hosts.Item(i).Mask) Then
            FindAccessEntry = True
            Exit Function
        End If
    Next i
  End If
ElseIf AccessKind = aOwner Then
  If Channel.Owners.Count > 0 Then
    For i = 1 To Channel.Owners.Count
        If UCase$(Mask) = UCase$(Channel.Owners.Item(i).Mask) Then
            FindAccessEntry = True
            Exit Function
        End If
    Next i
  End If
ElseIf AccessKind = aVoice Then
  If Channel.Voices.Count > 0 Then
    For i = 1 To Channel.Voices.Count
        If UCase$(Mask) = UCase$(Channel.Voices.Item(i).Mask) Then
            FindAccessEntry = True
            Exit Function
        End If
    Next i
  End If
Else
  #If Debugging = 1 Then
    SendSvrMsg "%DEBUG: Unknown access entry type passed to FindAccessEntry. Value: " & CInt(AccessKind)
  #End If
End If
Exit Function
oops:
SendSvrMsg "%BUG: Error #" & err.Number & " (" & err.Description & ") occured in FindAccessEntry(" & Channel.Name & "," & Mask & "," & CInt(AccessKind) & "). Please report this at http://bugs.ignition-project.com/."
End Function
Public Function ClearAccessEntries(Channel As clsChannel, AccessKind As enmAccessType, Optional IsOwner As Boolean = True) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "CLEARACCESSENTRIES called! (" & Channel.Name & " - AccessKind: " & CInt(AccessKind) & ")"
#End If
Dim i As Long
Dim r As Boolean
r = True 'always assume true unless false

'this is a bad way to do this, FIXME
If AccessKind = aDeny Then
  If Channel.Bans.Count > 0 Then
    For i = Channel.Bans.Count To 1
      If Channel.Bans.Item(i).SetByOwner And IsOwner Then
        #If Debugging = 1 Then
          SendSvrMsg "%DEBUG: Removing " & Channel.Bans(i).Mask
        #End If
        Channel.Bans.Remove i
      ElseIf Channel.Bans.Item(i).SetByOwner And Not IsOwner Then
        #If Debugging = 1 Then
          SendSvrMsg "%DEBUG: Not removing " & Channel.Bans(i).Mask
        #End If
        r = False
      Else
        'not set by an owner
        #If Debugging = 1 Then
          SendSvrMsg "%DEBUG: Removing " & Channel.Bans(i).Mask
        #End If
        Channel.Bans.Remove i
      End If
    Next i
  End If
ElseIf AccessKind = aGrant Then
  If Channel.Grants.Count > 0 Then
    For i = Channel.Grants.Count To 1
      If Channel.Grants.Item(i).SetByOwner And IsOwner Then
        Channel.Grants.Remove i
      ElseIf Channel.Grants.Item(i).SetByOwner And Not IsOwner Then
        r = False
      Else
        'not set by an owner
        Channel.Grants.Remove i
      End If
    Next i
  End If
ElseIf AccessKind = aHost Then
  If Channel.Hosts.Count > 0 Then
    For i = Channel.Hosts.Count To 1
      If Channel.Hosts.Item(i).SetByOwner And IsOwner Then
        Channel.Hosts.Remove i
      ElseIf Channel.Hosts.Item(i).SetByOwner And Not IsOwner Then
        r = False
      Else
        'not set by an owner
        Channel.Hosts.Remove i
      End If
    Next i
  End If
ElseIf AccessKind = aOwner Then
  If Channel.Owners.Count > 0 Then
    For i = Channel.Owners.Count To 1
      If Channel.Owners.Item(i).SetByOwner And IsOwner Then
        Channel.Owners.Remove i
      ElseIf Channel.Owners.Item(i).SetByOwner And Not IsOwner Then
        r = False
      Else
        'not set by an owner
        Channel.Owners.Remove i
      End If
    Next i
  End If
ElseIf AccessKind = aVoice Then
  If Channel.Voices.Count > 0 Then
    For i = Channel.Voices.Count To 1
      If Channel.Voices.Item(i).SetByOwner And IsOwner Then
        Channel.Voices.Remove i
      ElseIf Channel.Voices.Item(i).SetByOwner And Not IsOwner Then
        r = False
      Else
        'not set by an owner
        Channel.Voices.Remove i
      End If
    Next i
  End If
Else
  #If Debugging = 1 Then
    SendSvrMsg "%DEBUG: Unknown access entry type passed to ClearAccessEntries. Value: " & CInt(AccessKind)
  #End If
End If
'send back the value of r
ClearAccessEntries = r
Exit Function
oops:
SendSvrMsg "%BUG: Error #" & err.Number & " (" & err.Description & ") occured in ClearAccessEntries(" & Channel.Name & "," & CInt(AccessKind) & "," & IsOwner & "). Please report this at http://bugs.ignition-project.com/."
End Function
Public Function RemoveAccessEntry(Channel As clsChannel, Mask As String, AccessKind As enmAccessType, Optional IsOwner As Boolean = True) As Boolean
'/*
'** We are specifically saying the default is assuming IsOwner = True
'** because it might make some code that expected this to always return
'** true stop working.
'*/
#If Debugging = 1 Then
    SendSvrMsg "REMOVEACCESSENTRY called! (" & Mask & " - AccessKind: " & CInt(AccessKind) & ")"
#End If
Dim i As Long, UserMask$, What$
On Error GoTo oops
What = "entering function"
If AccessKind = aDeny Then
  If Channel.Bans.Count > 0 Then
    For i = 1 To Channel.Bans.Count
      What = "checking Channel.Bans(" & i & ")"
      If UCase$(Mask) = UCase$(Channel.Bans.Item(i).Mask) Then
        If Channel.Bans.Item(i).SetByOwner And IsOwner Then
          Channel.Bans.Remove i
          RemoveAccessEntry = True
        ElseIf Channel.Bans.Item(i).SetByOwner And Not IsOwner Then
          RemoveAccessEntry = False
        Else
          'not set by an owner
          Channel.Bans.Remove i
          RemoveAccessEntry = True
        End If
        Exit Function
      End If
    Next i
  End If
ElseIf AccessKind = aGrant Then
  If Channel.Grants.Count > 0 Then
    For i = 1 To Channel.Grants.Count
      What = "checking Channel.Grants(" & i & ")"
      If UCase$(Mask) = UCase$(Channel.Grants.Item(i).Mask) Then
        If Channel.Grants.Item(i).SetByOwner And IsOwner Then
          Channel.Grants.Remove i
          RemoveAccessEntry = True
        ElseIf Channel.Grants.Item(i).SetByOwner And Not IsOwner Then
          RemoveAccessEntry = False
        Else
          'not set by an owner
          Channel.Bans.Remove i
          RemoveAccessEntry = True
        End If
        Exit Function
      End If
    Next i
  End If
ElseIf AccessKind = aHost Then
  If Channel.Hosts.Count > 0 Then
    For i = 1 To Channel.Hosts.Count
      What = "checking Channel.Hosts(" & i & ")"
      If UCase$(Mask) = UCase$(Channel.Hosts.Item(i).Mask) Then
        If Channel.Hosts.Item(i).SetByOwner And IsOwner Then
          Channel.Hosts.Remove i
          RemoveAccessEntry = True
        ElseIf Channel.Hosts.Item(i).SetByOwner And Not IsOwner Then
          RemoveAccessEntry = False
        Else
          'not set by an owner
          Channel.Hosts.Remove i
          RemoveAccessEntry = True
        End If
        Exit Function
      End If
    Next i
  End If
ElseIf AccessKind = aOwner Then
  If Channel.Owners.Count > 0 Then
    For i = 1 To Channel.Owners.Count
      What = "checking Channel.Owners(" & i & ")"
      If UCase$(Mask) = UCase$(Channel.Owners.Item(i).Mask) Then
        If Channel.Owners.Item(i).SetByOwner And IsOwner Then
          Channel.Owners.Remove i
          RemoveAccessEntry = True
        ElseIf Channel.Owners.Item(i).SetByOwner And Not IsOwner Then
          RemoveAccessEntry = False
        Else
          'not set by an owner
          Channel.Owners.Remove i
          RemoveAccessEntry = True
        End If
        Exit Function
      End If
    Next i
  End If
ElseIf AccessKind = aVoice Then
  If Channel.Voices.Count > 0 Then
    For i = 1 To Channel.Voices.Count
      What = "checking Channel.Voices(" & i & ")"
      If UCase$(Mask) = UCase$(Channel.Voices.Item(i).Mask) Then
        If Channel.Voices.Item(i).SetByOwner And IsOwner Then
          Channel.Voices.Remove i
          RemoveAccessEntry = True
        ElseIf Channel.Voices.Item(i).SetByOwner And Not IsOwner Then
          RemoveAccessEntry = False
        Else
          'not set by an owner
          Channel.Voices.Remove i
          RemoveAccessEntry = True
        End If
        Exit Function
      End If
    Next i
  End If
Else
  #If Debugging = 1 Then
    SendSvrMsg "%DEBUG: Unknown access entry type passed to RemoveAccessEntry. Value: " & CInt(AccessKind)
  #End If
End If
Exit Function
oops:
SendSvrMsg "%BUG: Error #" & err.Number & " (" & err.Description & ") occured in RemoveAccessEntry(" & Channel.Name & "," & Mask & "," & CInt(AccessKind) & "," & IsOwner & ") while " & What & ". Please report this at http://bugs.ignition-project.com/."
End Function
Public Function IsGranted(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISGRANTED called! (" & User.Nick & ")"
#End If
Dim i As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For i = 1 To Channel.Grants.Count
    If (UCase$(UserMask) Like UCase$(Channel.Grants.Item(i).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Grants.Item(i).Mask)) Then
        IsGranted = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function IsVoiced(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISVOICED called! (" & User.Nick & ")"
#End If
Dim i As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For i = 1 To Channel.Voices.Count
    If (UCase$(UserMask) Like UCase$(Channel.Voices.Item(i).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Voices.Item(i).Mask)) Then
        'voiced!
        IsVoiced = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function IsHosted(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISHOSTED called! (" & User.Nick & ")"
#End If
Dim i As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For i = 1 To Channel.Hosts.Count
    If (UCase$(UserMask) Like UCase$(Channel.Hosts.Item(i).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Hosts.Item(i).Mask)) Then
        'a host
        IsHosted = True
        Exit Function
    End If
Next i
ex:
End Function
Public Function IsOwnered(Channel As clsChannel, User As clsClient) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "ISOWNERED called! (" & User.Nick & ")"
#End If
Dim i As Long, UserMask$, RealUserMask$
Dim A As Long
On Error GoTo ex
UserMask = Mid$(User.Prefix, 2)
RealUserMask = User.Nick & "!" & User.User & "@" & User.RealHost

For i = 1 To Channel.Owners.Count
    If (UCase$(UserMask) Like UCase$(Channel.Owners.Item(i).Mask)) Or (UCase$(RealUserMask) Like UCase$(Channel.Owners.Item(i).Mask)) Then
        'an owner
        IsOwnered = True
        Exit Function
    End If
Next i
ex:
End Function
