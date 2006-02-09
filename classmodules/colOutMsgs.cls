VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "colOutMsgs"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Collection" ,"clsOutMsg"
Attribute VB_Ext_KEY = "Member0" ,"clsOutMsg"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
' * IRC - Internet Relay Chat
'   * PURE IRCd - pure IRC for everybody...
'   * Copyright (C) 2003
'       Dennis Fisch    (fox_jk_recruiter@yahoo.de)
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
'local variable to hold collection
Private mCol As Collection
Public Count As Long
Private Type typOutMsg
    strSend As String
    hsock As Long
End Type


Public Sub Add(strSend As String, Socket As Long)
    On Error Resume Next
    Dim objNewMember As typOutMsg
    If mCol(CStr(Socket)) Is Nothing Then
        With objNewMember
            .strSend = strSend
            .hsock = Socket
        End With
        mCol.Add objNewMember, CStr(Socket)
        Count = Count + 1
    Else
        With mCol(CStr(Socket))
            .strSend = .strSend & strSend
        End With
    End If
End Sub

Public Property Get Item(vntIndexKey As Variant) As clsOutMsg
Attribute Item.VB_UserMemId = 0
  Set Item = mCol(vntIndexKey)
End Property

Public Sub Remove(vntIndexKey As Variant)
    mCol.Remove vntIndexKey
    Count = Count - 1
End Sub

Private Sub Class_Initialize()
    'creates the collection when this class is created
    Set mCol = New Collection
End Sub

Private Sub Class_Terminate()
    'destroys collection when this class is terminated
    Set mCol = Nothing
End Sub

