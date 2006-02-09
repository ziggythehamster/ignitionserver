Attribute VB_Name = "RecvQ"
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
Private colMsgQueue As Collection
Private colObjQueue As Collection
Private m_Count As Long

Public Type typMsg
    FromLink As clsClient
    Message As String
End Type

Public Sub InitList()
    Set colMsgQueue = New Collection
    Set colObjQueue = New Collection
    m_Count = 0
End Sub

' clear the queue
Sub RemoveAll()
InitList
End Sub

' push a new item into the queue
' the element is just appended to the collection
Sub Add(cptr As clsClient, Message As String)
colMsgQueue.Add Message
colObjQueue.Add cptr
m_Count = m_Count + 1
End Sub

' pop an item off the queue
' raises error 5 "illegal function call" if the queue is empty
Function Item(index As Long) As typMsg
    ' retrieve the element pushed least recently
    With Item
        .Message = colMsgQueue(1)
        Set .FromLink = colObjQueue(1)
    End With
    ' discard it
    colMsgQueue.Remove 1
    colObjQueue.Remove 1
    m_Count = m_Count - 1
End Function

' return the number of elements in the queue
Property Get Count() As Long
    Count = m_Count
End Property
