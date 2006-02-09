VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsChannel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
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
' $Id: clsChannel.cls,v 1.2 2004/05/28 20:20:53 ziggythehamster Exp $
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

'General Settings -Dill
Public Name As String
Public Topic As String
Public TopcSetAt As Long
Public TopicSetBy As String
Public index As Long

'Modes -Dill
Public IsHidden As Boolean 'IRCX
Public IsPrivate As Boolean
Public IsSecret As Boolean
Public IsTopicOps As Boolean
Public IsNoExternalMsgs As Boolean
Public IsInviteOnly As Boolean
Public IsModerated As Boolean
Public IsRegistered As Boolean
Public Limit As Long
Public Key As String

'properties - Ziggy
Public Prop_OID As Long 'R/O
Public Prop_Name As String 'R/O
Public Prop_Creation As Long 'R/O
Public Prop_Language As String
Public Prop_Ownerkey As String 'W/O
Public Prop_Hostkey As String 'W/O
Public Prop_Memberkey As String 'W/O
Public Prop_Topic As String
Public Prop_Subject As String
Public Prop_Client As String
Public Prop_OnJoin As String
Public Prop_OnPart As String
'* the following will be implemented in the future
Public Prop_Lag As Integer
Public Prop_Account As String
Public Prop_ClientGUID As String
Public Prop_ServicePath As String
Public Prop_PICS As String 'IRCOp only

'Access List Stuff
Public Member As clsChanMemberHashTable
Public Bans As clsBans
Public Grants As clsGrants
Public Voices As clsVoices
Public Hosts As clsHosts
Public Owners As clsOwners
Private Invites As Collection

Public Function GetUser(Nick$) As clsClient
Dim ChM As clsChanMember
Set ChM = Member.Item(Nick)
If Not ChM Is Nothing Then Set GetUser = ChM.Member
End Function

Public Sub AddInvite(Invite As String)
Invites.Add Invite, Invite
End Sub

Public Function IsInvited(Invite As String) As Boolean
On Error GoTo quitfunc
If StrComp(Invites(Invite), Invite, vbTextCompare) Then
  Invites.Remove Invite
  IsInvited = True
End If
quitfunc:
Exit Function
End Function

Private Sub Class_Initialize()
IrcStat.Channels = IrcStat.Channels + 1
Set Bans = New clsBans
Set Grants = New clsGrants
Set Owners = New clsOwners
Set Hosts = New clsHosts
Set Voices = New clsVoices
Set Member = New clsChanMemberHashTable
Set Invites = New Collection
#If Debugging = 1 Then
    SendSvrMsg "Channel class created"
#End If
End Sub

Private Sub Class_Terminate()
IrcStat.Channels = IrcStat.Channels - 1
Do While Invites.Count > 0
    Invites.Remove 1
Loop
Set Bans = Nothing
Set Grants = Nothing
Set Owners = Nothing
Set Hosts = Nothing
Set Voices = Nothing
Set Member = Nothing
Set Invites = Nothing
#If Debugging = 1 Then
    SendSvrMsg "Channel class terminated"
#End If
End Sub

