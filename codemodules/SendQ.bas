Attribute VB_Name = "SendQ"
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
Private colMsgQueue As New Collection
Private m_Count As Long
Private NTyp As typOutMsg

Public Type typOutMsg
    hSock As Long
    Message As String
End Type

Public Sub InitList()
    Set colMsgQueue = New Collection
    m_Count = 0
End Sub
'
'' clear the queue
'Sub RemoveAll()
'
'End Sub

' push a new item into the queue
' the element is just appended to the collection
Sub Add(Message As String, Socket As Long)
    With NTyp
        .hSock = Socket
        .Message = Message
    End With
    colMsgQueue.Add NTyp
    m_Count = m_Count + 1
End Sub

' pop an item off the queue
' raises error 5 "illegal function call" if the queue is empty
Function Item(Index As Long) As typOutMsg
    ' retrieve the element pushed least recently
    With colMsgQueue(1)
        Item.hSock = .hSock
        Item.Message = .Message
    End With
    ' discard it
    colMsgQueue.Remove 1
    m_Count = m_Count - 1
End Function

' return the number of elements in the queue
Property Get Count() As Long
    Count = m_Count
End Property
