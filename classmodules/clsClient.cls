VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsClient"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
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
' $Id: clsClient.cls,v 1.28 2004/12/30 23:55:42 ziggythehamster Exp $
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

Public AccessLevel As Long
'it appears AccessLevel is (i may be wrong):
'1 - User
'2 - ?
'3 - ircop
'4 - server
Public Nick As String
Public Name As String
Public User As String
Public Host As String
Public GUID As String
Public Prefix As String
Public ServerName As String
Public ServerDescription As String
Public LocalPort As Long
Public RemotePort As Long
Public SendQ As String
Public SignOn As Long
Public AwayMsg As String
Public index As Long
Public SockHandle As Long
Public IsKilled As Boolean
Public IsAuthenticated As Boolean 'IRCX
Public IsIRCX As Boolean 'IRCX (+x)
Public IsService As Boolean '+S
Public GetsWallops As Boolean '+w

Public WaitingForPong As Boolean 'set by ping sub
Public LastAction As Long 'so you don't get pinged if active

Public OID As Long

Public RealHost As String 'Thanks to DG for pointing this out
Public WhoisAccessLevel As Long 'AccessLevel of user asking for /whois
Public WhoisIRCX As Boolean 'state of IRCX of the user asking for /whois

'Substituted Modes as String with Booleans
'as Booleans are 2 bytes only, and strings are 10 bytes (+stringlen*2), even if not used (memory usage that is)
'Booleans are also faster to check than strings:
'"If boolean = true" is way faster than "If String = OtherString"
'So the few additional bytes this uses are well worth it, in total only 26 -Dill

'/*
'** These need to be bytes. If Byte = 0, false, If Byte <> 0, true.
'** Bytes are smaller than booleans, and would be quicker to check (?)
'** At least, maybe. I dunno. We really need to lighten the footprint,
'** so we could probably make this change in BRANCH_FOOTPRINT or something.
'** That way, we don't potentially screw up HEAD and have to revert HEAD,
'** something that isn't really all that fun.     -Ziggy
'*/
Public IsInvisible As Boolean
Public IsLocOperator As Boolean
Public IsGlobOperator As Boolean
Public IsNetAdmin As Boolean
Public IsServerMsg As Boolean
Public IsCloaked As Boolean
Public IsRegistered As Boolean
Public IsLProtected As Boolean
Public IsProtected As Boolean
Public IsGagged As Boolean 'IRCX +z  -zg
Public IsRemoteAdmClient As Boolean
Public IsMonitored As Boolean '+L

Public CanGlobKill As Boolean
Public CanLocKill As Boolean
Public CanDie As Boolean
Public CanRestart As Boolean
Public CanRehash As Boolean
Public CanKline As Boolean
Public CanUnkline As Boolean
Public CanLocRoute As Boolean
Public CanGlobRoute As Boolean
Public CanAdd As Boolean
Public CanWallop As Boolean
Public CanChange As Boolean

Public Idle As Long
Public SentQuit As Boolean
Public IP As String
Public Class As Long, IIndex As Long        'Y-Line and I-Line -Dill
Public PassOK As Boolean
Public Password As String 'used to store the password they sent
Public SentLogonNotices As Boolean 'did the user get sent logon notices yet?
Public FromLink As clsClient
Public UpLink As String
Public HasRegistered As Boolean
Public NLined As Boolean

Public OnChannels As clsOnChannels
Public Events As clsEvents 'for event system
Public Timeout As Long
Public Hops As Long
Public tmp As String, tmpused As Boolean 'Telnet support -Dill
'Note: A standard win telnet sends data as soon as it is typed,
'char by char that is...and as soon as user hit enter a crlf is sent.
'so we need to buffer everything we received until a crlf arrives,
'so we get a full command line.
Public MsgsInQueue As Long

Public Function IsOnChan(Channel As String) As Boolean
On Error Resume Next
Dim i&
For i = 1 To OnChannels.Count
  If StrComp(OnChannels.Item(i).Name, Channel, vbTextCompare) = 0 Then
    IsOnChan = True
    Exit Function
  End If
Next i
End Function
Public Function GetOnChans1459(Optional UseCheckClient As Boolean = False, Optional UserNick As String) As String
Dim Chan As clsChannel, x&
Dim i&
For i = 1 To OnChannels.Count
    If UseCheckClient Then
      If Len(UserNick) > 0 Then
        'if the channel is hidden/secret, don't show the channel
        If (OnChannels.Item(i).IsSecret) Or (OnChannels.Item(i).IsPrivate) Then
          If OnChannels.Item(i).GetUser(UserNick) Is Nothing Then
            GoTo NextChannel
          End If
        End If
        'if this user is invisible, don't show the channel
        If IsInvisible Then
          If OnChannels.Item(i).GetUser(UserNick) Is Nothing Then
            GoTo NextChannel
          End If
        End If
      End If
    End If
    With OnChannels.Item(i).Member.Item(Nick)
        If .IsOwner Then
            GetOnChans1459 = GetOnChans1459 & Level_Host & OnChannels.Item(i).Name & " "
        ElseIf .IsOp Then
            GetOnChans1459 = GetOnChans1459 & Level_Host & OnChannels.Item(i).Name & " "
        ElseIf .IsVoice Then
            GetOnChans1459 = GetOnChans1459 & Level_Voice & OnChannels.Item(i).Name & " "
        Else
            GetOnChans1459 = GetOnChans1459 & OnChannels.Item(i).Name & " "
        End If
    End With
NextChannel:
Next i
GetOnChans1459 = Trim$(GetOnChans1459)
End Function
Public Function GetOnChans(Optional UseCheckClient As Boolean = False, Optional UserNick As String) As String
Dim Chan As clsChannel, x&
Dim i&
For i = 1 To OnChannels.Count
    If UseCheckClient Then
      If Len(UserNick) > 0 Then
        'if the channel is hidden/secret, don't show the channel
        If (OnChannels.Item(i).IsSecret) Or (OnChannels.Item(i).IsPrivate) Then
          If OnChannels.Item(i).GetUser(UserNick) Is Nothing Then
            GoTo NextChannel
          End If
        End If
        'if this user is invisible, don't show the channel
        If IsInvisible Then
          If OnChannels.Item(i).GetUser(UserNick) Is Nothing Then
            GoTo NextChannel
          End If
        End If
      End If
    End If
    With OnChannels.Item(i).Member.Item(Nick)
        If .IsOwner Then
            GetOnChans = GetOnChans & Level_Owner & OnChannels.Item(i).Name & " "
        ElseIf .IsOp Then
            GetOnChans = GetOnChans & Level_Host & OnChannels.Item(i).Name & " "
        ElseIf .IsVoice Then
            GetOnChans = GetOnChans & Level_Voice & OnChannels.Item(i).Name & " "
        Else
            GetOnChans = GetOnChans & OnChannels.Item(i).Name & " "
        End If
    End With
NextChannel:
Next i
GetOnChans = Trim$(GetOnChans)
End Function

Public Function GetWhois(Nickname$) As String
Dim tmpNick As String
On Error GoTo GetWhoisError
GetWhois = SPrefix & " " & RPL_WHOISUSER & " " & Nickname & " " & Nick & " " & User & " " & Host & " * :" & Name & vbCrLf
If WhoisAccessLevel >= 3 Or Nickname = Nick Then
  Dim tmpIP As String
  If Len(IP) > 0 Then
    tmpIP = IP
  Else
    tmpIP = "unknown"
  End If
  'changed this to 320, since 320 is RPL_WHOISSPECIAL and probably more widely recognized
  GetWhois = GetWhois & SPrefix & " 320 " & Nickname & " " & Nick & " :is connecting from " & RealHost & "; IP address is " & tmpIP & vbCrLf
End If
If IsRegistered Then GetWhois = GetWhois & SPrefix & " 307 " & Nickname & " " & Nick & " " & TranslateCode(RPL_WHOISREGNICK) & vbCrLf
If IsNetAdmin Then '-zg [this was rearranged because of the presence of the 308 raw]
  GetWhois = GetWhois & SPrefix & " 308 " & Nickname & " " & Nick & " :is a network administrator" & vbCrLf '-zg
End If
If Len(Trim$(GetOnChans(True, Nickname))) > 0 Or WhoisAccessLevel >= 3 Then
  If WhoisAccessLevel >= 3 And Len(Trim$(GetOnChans(True, ""))) = 0 Then GoTo NextThing
  tmpNick = Nickname
  If WhoisAccessLevel >= 3 Then tmpNick = vbNullString
  If WhoisIRCX Then
    GetWhois = GetWhois & SPrefix & " 319 " & Nickname & " " & Nick & " :" & GetOnChans(True, tmpNick) & vbCrLf
  Else
    GetWhois = GetWhois & SPrefix & " 319 " & Nickname & " " & Nick & " :" & GetOnChans1459(True, tmpNick) & vbCrLf
  End If
End If
NextThing:
If Len(AwayMsg) > 0 Then GetWhois = GetWhois & SPrefix & " 301 " & Nickname & " " & Nick & " :" & AwayMsg & vbCrLf
GetWhois = GetWhois & SPrefix & " 312 " & Nickname & " " & Nick & " " & ServerName & " :" & ServerDescription & vbCrLf
If IsService Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is an IRC service" & vbCrLf
ElseIf IsGlobOperator And IsLocOperator Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is a global IRC Operator" & vbCrLf
ElseIf IsGlobOperator Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is a global IRC Operator" & vbCrLf
ElseIf IsLocOperator Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is a local IRC Operator" & vbCrLf
End If
If Idle > 0 Then GetWhois = GetWhois & SPrefix & " 317 " & Nickname & " " & Nick & " " & (UnixTime - Idle) & " " & SignOn & " :seconds idle, signon time"
WhoisAccessLevel = 0
Exit Function

GetWhoisError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'clsClient.GetWhois'"
End Function
Private Sub Class_Initialize()
Set OnChannels = New clsOnChannels
Set Events = New clsEvents
GUID = CreateGUID
OID = 0
#If Debugging = 1 Then
    SendSvrMsg "Client class created"
#End If
End Sub
Public Sub Class_Terminate()
On Local Error Resume Next
If Class > 0 Then YLine(Class).CurClients = YLine(Class).CurClients - 1
If AccessLevel = 4 Then
    If Hops = 1 Then
        IrcStat.LocServers = IrcStat.LocServers - 1
        IrcStat.GlobServers = IrcStat.GlobServers - 1
    Else
        IrcStat.GlobServers = IrcStat.GlobServers - 1
    End If
Else
    Dim ww As typWhoWas
    With ww
        .Host = Host
        .Name = Name
        .Nick = Nick
        If Not FromLink Is Nothing Then .Server = FromLink.ServerName
        .SignOn = SignOn
        .User = User
    End With
    modWhoWasHashTable.Add Nick, ww
    If Hops = 0 Then
        IrcStat.LocUsers = IrcStat.LocUsers - 1
        IrcStat.GlobUsers = IrcStat.GlobUsers - 1
    Else
        IrcStat.GlobUsers = IrcStat.GlobUsers - 1
    End If
End If
If IsLocOperator Or IsGlobOperator Then
    Opers.Remove GUID
    IrcStat.Operators = IrcStat.Operators - 1
End If
If AccessLevel = 0 Then IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
Set OnChannels = Nothing
Set Events = Nothing
#If Debugging = 1 Then
    SendSvrMsg "Client class terminated"
#End If
End Sub
Public Function GetModes() As String
'lowercase
If CanKline Then GetModes = GetModes & "b"                '+b
If CanLocRoute Then GetModes = GetModes & "c"             '+c
If IsCloaked Then GetModes = GetModes & "d"               '+d
If CanRehash Then GetModes = GetModes & "e"               '+e
If IsInvisible Then GetModes = "i"                        '+i
If CanLocKill Then GetModes = GetModes & "k"              '+k
If IsLocOperator Then GetModes = GetModes & "o"           '+o
If IsLProtected Then GetModes = GetModes & "p"            '+p
If IsRegistered Then GetModes = GetModes & "r"            '+r
If IsServerMsg Then GetModes = GetModes & "s"             '+s
If GetsWallops Then GetModes = GetModes & "w"             '+w
If IsIRCX Then GetModes = GetModes & "x"                  '+x
If IsGagged And ShowGag Then GetModes = GetModes & "z"    '+z

'uppercase
If CanUnkline Then GetModes = GetModes & "B"              '+B
If CanGlobRoute Then GetModes = GetModes & "C"            '+C
If CanDie Then GetModes = GetModes & "D"                  '+D
If CanChange Then GetModes = GetModes & "H"               '+H
If CanGlobKill Then GetModes = GetModes & "K"             '+K
If IsMonitored Then GetModes = GetModes & "L"             '+L
If IsNetAdmin Then GetModes = GetModes & "N"              '+N
If IsGlobOperator Then GetModes = GetModes & "O"          '+O
If IsProtected Then GetModes = GetModes & "P"             '+P
If CanRestart Then GetModes = GetModes & "R"              '+R
If CanWallop Then GetModes = GetModes & "W"               '+W
If IsRemoteAdmClient Then GetModes = GetModes & "Z"       '+Z
End Function
