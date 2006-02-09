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
' $Id: clsClient.cls,v 1.5 2004/05/28 21:27:35 ziggythehamster Exp $
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
Public Port As String
Public SendQ As String
Public SignOn As Long
Public AwayMsg As String
Public index As Long
Public SockHandle As Long
Public IsKilled As Boolean
Public IsAuthenticated As Boolean 'IRCX
Public IsIRCX As Boolean 'IRCX (+x)

Public WaitingForPong As Boolean 'set by ping sub

Public RealHost As String 'Thanks to DG for pointing this out
Public WhoisAccessLevel As Integer 'AccessLevel of user asking for /whois

'Substituted Modes as String with Booleans
'as Booleans are 2 bytes only, and strings are 10 bytes (+stringlen*2), even if not used (memory usage that is)
'Booleans are also faster to check than strings:
'"If boolean = true" is way faster than "If String = OtherString"
'So the few additional bytes this uses are well worth it, in total only 26 -Dill
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

Public Idle As Long
Public SentQuit As Boolean
Public IP As String
Public Class As Long, IIndex As Long        'Y-Line and I-Line -Dill
Public PassOK As Boolean
Public FromLink As clsClient
Public UpLink As String
Public HasRegistered As Boolean
Public LLined As Boolean

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
Dim I&
For I = 1 To OnChannels.Count
  If StrComp(OnChannels.Item(I).Name, Channel, vbTextCompare) = 0 Then
    IsOnChan = True
    Exit Function
  End If
Next I
End Function

Public Function GetOnChans() As String
Dim Chan As clsChannel, x&
Dim I&
For I = 1 To OnChannels.Count
    With OnChannels.Item(I).Member.Item(Nick)
        If .IsOwner Then
            GetOnChans = GetOnChans & "." & OnChannels.Item(I).Name & " "
        ElseIf .IsOp Then
            GetOnChans = GetOnChans & "@" & OnChannels.Item(I).Name & " "
        'ElseIf .IsHOp Then 'HalfOp seems to be an unwriten standard in IRC now...
        '    GetOnChans = GetOnChans & "%" & OnChannels.Item(i).Name & " "
        ElseIf .IsVoice Then
            GetOnChans = GetOnChans & "+" & OnChannels.Item(I).Name & " "
        Else
            GetOnChans = GetOnChans & OnChannels.Item(I).Name & " "
        End If
    End With
Next I
GetOnChans = Trim$(GetOnChans)
End Function

Public Function GetWhois(Nickname$) As String
GetWhois = SPrefix & " " & RPL_WHOISUSER & " " & Nickname & " " & Nick & " " & User & " " & Host & " * :" & Name & vbCrLf
If WhoisAccessLevel >= 3 Or Nickname = Nick Then
  Dim tmpIP As String
  If IP <> "" Then
    tmpIP = IP
  Else
    tmpIP = "unknown"
  End If
  GetWhois = GetWhois & SPrefix & " 378 " & Nickname & " " & Nick & " :is connecting from " & RealHost & "; IP address is " & tmpIP & vbCrLf
End If
If IsRegistered Then GetWhois = GetWhois & SPrefix & " 307 " & Nickname & " " & Nick & " " & TranslateCode(RPL_WHOISREGNICK) & vbCrLf
If IsNetAdmin Then '-zg [this was rearranged because of the presence of the 308 raw]
  GetWhois = GetWhois & SPrefix & " 308 " & Nickname & " " & Nick & " :is a network administrator" & vbCrLf '-zg
End If
If OnChannels.Count > 0 Then GetWhois = GetWhois & SPrefix & " 319 " & Nickname & " " & Nick & " :" & GetOnChans & vbCrLf
If Len(AwayMsg) > 0 Then GetWhois = GetWhois & SPrefix & " 301 " & Nickname & " " & Nick & " :" & AwayMsg & vbCrLf
GetWhois = GetWhois & SPrefix & " 312 " & Nickname & " " & Nick & " " & ServerName & " :" & ServerDescription & vbCrLf
If IsGlobOperator And IsLocOperator Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is a global IRC Operator" & vbCrLf
ElseIf IsGlobOperator Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is a global IRC Operator" & vbCrLf
ElseIf IsLocOperator Then
    GetWhois = GetWhois & SPrefix & " 313 " & Nickname & " " & Nick & " :is a local IRC Operator" & vbCrLf
End If
If Idle > 0 Then GetWhois = GetWhois & SPrefix & " 317 " & Nickname & " " & Nick & " " & (UnixTime - Idle) & " " & SignOn & " :seconds idle, signon time" & vbCrLf
WhoisAccessLevel = 0
End Function
Private Sub Class_Initialize()
Set OnChannels = New clsOnChannels
Set Events = New clsEvents
GUID = CreateGUID
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
If IsInvisible Then GetModes = "i"
If IsLocOperator Then GetModes = GetModes & "o"
If IsGlobOperator Then GetModes = GetModes & "O"
If IsServerMsg Then GetModes = GetModes & "s"
If IsCloaked Then GetModes = GetModes & "d"
If CanGlobKill Then GetModes = GetModes & "K"
If CanLocKill Then GetModes = GetModes & "k"
If CanDie Then GetModes = GetModes & "D"
If CanRestart Then GetModes = GetModes & "R"
If CanRehash Then GetModes = GetModes & "e"
If IsRegistered Then GetModes = GetModes & "r"
If CanKline Then GetModes = GetModes & "b"
If CanUnkline Then GetModes = GetModes & "B"
If CanLocRoute Then GetModes = GetModes & "c"
If CanGlobRoute Then GetModes = GetModes & "C"
If IsIRCX Then GetModes = GetModes & "x"
If IsGagged And ShowGag Then GetModes = GetModes & "z"
If IsRemoteAdmClient Then GetModes = GetModes & "Z"
If IsNetAdmin Then GetModes = GetModes & "N"
If IsProtected Then GetModes = GetModes & "P"
If IsLProtected Then GetModes = GetModes & "p"
  End Function
