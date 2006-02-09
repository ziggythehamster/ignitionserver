VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsBans"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Collection" ,"clsBan"
Attribute VB_Ext_KEY = "Member0" ,"clsBan"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
'ignitionServer is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@silentsoft.net>
'                     Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
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
Private mCol As Collection

Public Function Add(Mask As String, SetBy As String, SetOn As Long, Optional sKey As String) As clsBan
    Dim objNewMember As clsBan
    Set objNewMember = New clsBan
    objNewMember.Mask = Mask
    objNewMember.SetOn = SetOn
    objNewMember.SetBy = SetBy
    If Len(sKey) = 0 Then
        mCol.Add objNewMember
    Else
        mCol.Add objNewMember, sKey
    End If
    Set Add = objNewMember
    Set objNewMember = Nothing
End Function
Public Sub AddX(Mask As String, SetBy As String, SetOn As Long, Duration As Long, Optional Reason As String, Optional sKey As String)
On Local Error Resume Next
    Dim objNewMember As clsBan
    Set objNewMember = New clsBan
    objNewMember.Mask = Mask
    objNewMember.Reason = Reason
    objNewMember.Duration = Duration
    objNewMember.SetOn = SetOn
    objNewMember.SetBy = SetBy
    If Len(sKey) = 0 Then
        mCol.Add objNewMember
    Else
        mCol.Add objNewMember, sKey
    End If
    Set objNewMember = Nothing
End Sub
Public Property Get Item(vntIndexKey As Variant) As clsBan
Attribute Item.VB_UserMemId = 0
  Set Item = mCol(vntIndexKey)
End Property

Public Property Get Count() As Long
    Count = mCol.Count
End Property

Public Sub Remove(vntIndexKey As Variant)
    mCol.Remove vntIndexKey
End Sub
Public Sub Clear() 'need this in order to facilitate access clearing
Dim a As Integer
    If mCol.Count > 0 Then
      For a = 1 To mCol.Count
        mCol.Remove a
      Next a
    End If
End Sub
Private Sub Class_Initialize()
    Set mCol = New Collection
End Sub

Private Sub Class_Terminate()
    Set mCol = Nothing
End Sub