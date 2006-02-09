VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsChanMemberHashTable"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
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
' $Id: clsChanMemberHashTable.cls,v 1.3 2004/05/28 20:35:04 ziggythehamster Exp $
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


'----------------------------------------------
' HASHTABLE class module
'----------------------------------------------
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (dest As Any, source As Any, ByVal bytes As Long)

' default values
Const DEFAULT_HASHSIZE = 256
Const DEFAULT_LISTSIZE = 512
Const DEFAULT_CHUNKSIZE = 128

Private Type SlotType
    Key As String
    Value As clsChanMember
    nextItem As Long      ' 0 if last item
End Type

' for each hash code this array holds the first element
' in slotTable() with the corresponding hash code
Dim hashTbl() As Long
' the array that holds the data
Dim slotTable() As SlotType

' pointer to first free slot
Dim FreeNdx As Long
' size of hash table
Dim m_HashSize As Long
' size of slot table
Dim m_ListSize As Long
' chunk size
Dim m_ChunkSize As Long
' items in the slot table
Dim m_Count As Long

' member variable for IgnoreCase property
Private m_IgnoreCase As Boolean

' True if keys are searched in case-unsensitive mode
' this can be assigned to only when the hash table is empty
Property Get IgnoreCase() As Boolean
    IgnoreCase = m_IgnoreCase
End Property

Property Let IgnoreCase(ByVal newValue As Boolean)
    If m_Count Then Exit Property
    m_IgnoreCase = newValue
End Property

' initialize the hash table
Sub SetSize(ByVal HashSize As Long, Optional ByVal ListSize As Long, Optional ByVal ChunkSize As Long)
    ' provide defaults
    If ListSize <= 0 Then ListSize = m_ListSize
    If ChunkSize <= 0 Then ChunkSize = m_ChunkSize
    ' save size values
    m_HashSize = HashSize
    m_ListSize = ListSize
    m_ChunkSize = ChunkSize
    m_Count = 0
    ' rebuild tables
    FreeNdx = 0
    ReDim hashTbl(0 To HashSize - 1) As Long
    ReDim slotTable(0) As SlotType
    ExpandSlotTable m_ListSize
End Sub

' check whether an item is in the hash table
Function Exists(Key As String) As Boolean
    Exists = GetSlotIndex(Key) <> 0
End Function

' add a new element to the hash table
Function Add(Priv As ChanMemberFlags, Value As clsClient) As clsChanMember
    Dim ndx As Long, Create As Boolean, NMember As New clsChanMember
    ' get the index to the slot where the value is
    ' (allocate a new slot if necessary)
    Create = True
    ndx = GetSlotIndex(Value.Nick, Create)
    If Create Then
        ' the item was actually added
        Set NMember.Member = Value
        If Priv = ChanOwner Then 'IRCX - Ziggy
            NMember.IsOwner = True
        ElseIf Priv = ChanOwnerVoice Then 'IRCX - Ziggy
            NMember.IsOwner = True
            NMember.IsVoice = True
        ElseIf Priv = ChanOp Then
            NMember.IsOp = True
        ElseIf Priv = ChanOpVoice Then
            NMember.IsOp = True
            NMember.IsVoice = True
        'ElseIf Priv = ChanHOp Then
        '    NMember.IsHOp = True
        'ElseIf Priv = ChanHOpVoice Then
        '    NMember.IsHOp = True
        '    NMember.IsVoice = True
        ElseIf Priv = ChanVoice Then
            NMember.IsVoice = True
        End If
        Set slotTable(ndx).Value = NMember
        Set Add = NMember
    End If
End Function

' the value associated to a key
' (empty if not found)
Property Get Item(Key As String) As clsChanMember
    Dim ndx As Long
    ' get the index to the slot where the value is
    ndx = GetSlotIndex(Key)
    If ndx = 0 Then Exit Property
    Set Item = slotTable(ndx).Value
End Property

Property Let Item(Key As String, Value As clsChanMember)
    Dim ndx As Long
    ' get the index to the slot where the value is
    ' (allocate a new slot if necessary)
    ndx = GetSlotIndex(Key, True)
    ' store the value
    Set slotTable(ndx).Value = Value
End Property

Property Set Item(Key As String, Value As clsChanMember)
    Dim ndx As Long
    ' get the index to the slot where the value is
    ' (allocate a new slot if necessary)
    ndx = GetSlotIndex(Key, True)
    ' store the value
    Set slotTable(ndx).Value = Value
End Property

' remove an item from the hash table
Sub Remove(Key As String)
    Dim ndx As Long, HCode As Long, LastNdx As Long
    ndx = GetSlotIndex(Key, False, HCode, LastNdx)
    ' raise error if no such element
    If ndx = 0 Then Exit Sub
    
    If LastNdx Then
        ' this isn't the first item in the slotTable() array
        slotTable(LastNdx).nextItem = slotTable(ndx).nextItem
    ElseIf slotTable(ndx).nextItem Then
        ' this is the first item in the slotTable() array
        ' and is followed by one or more items
        hashTbl(HCode) = slotTable(ndx).nextItem
    Else
        ' this is the only item in the slotTable() array
        ' for this hash code
        hashTbl(HCode) = 0
    End If
    
    ' put the element back in the free list
    Set slotTable(ndx).Value = Nothing
    slotTable(ndx).nextItem = FreeNdx
    FreeNdx = ndx
    ' we have deleted an item
    m_Count = m_Count - 1
    
End Sub

' remove all items from the hash table
Sub RemoveAll()
    SetSize m_HashSize, m_ListSize, m_ChunkSize
End Sub

' the number of items in the hash table
Property Get Count() As Long
    Count = m_Count
End Property

' the array of all values
' (VB5 users: convert return type to Variant)
Property Get Values() As clsChanMember()
    Dim I As Long, ndx As Long
    Dim n As Long
    If m_Count = 0 Then
        ReDim Res(0) As clsChanMember
        Values = Res
        Exit Property
    End If
    
    ReDim Res(0 To m_Count - 1) As clsChanMember
    
    For I = 0 To m_HashSize - 1
        ' take the pointer from the hash table
        ndx = hashTbl(I)
        ' walk the slottable() array
        Do While ndx
            Set Res(n) = slotTable(ndx).Value
            n = n + 1
            ndx = slotTable(ndx).nextItem
        Loop
    Next
        
    ' assign to the result
    Values = Res()
End Property

'-----------------------------------------
' Private procedures
'-----------------------------------------
Private Sub Class_Initialize()
    ' initialize the tables at default size
    SetSize DEFAULT_HASHSIZE, DEFAULT_LISTSIZE, DEFAULT_CHUNKSIZE
End Sub

' expand the slotTable() array
Private Sub ExpandSlotTable(ByVal numEls As Long)
    Dim newFreeNdx As Long, I As Long
    newFreeNdx = UBound(slotTable) + 1
    
    ReDim Preserve slotTable(0 To UBound(slotTable) + numEls) As SlotType
    ' create the linked list of free items
    For I = newFreeNdx To UBound(slotTable)
        slotTable(I).nextItem = I + 1
    Next
    ' overwrite the last (wrong) value
    slotTable(UBound(slotTable)).nextItem = FreeNdx
    ' we now know where to pick the first free item
    FreeNdx = newFreeNdx
End Sub

' return the hash code of a string
Private Function HashCode(Key As String) As Long
    Dim lastEl As Long, I As Long
    
    ' copy ansi codes into an array of long
    lastEl = (Len(Key) - 1) \ 4
    ReDim codes(lastEl) As Long
    ' this also converts from Unicode to ANSI
    CopyMemory codes(0), ByVal Key, Len(Key)
    
    ' XOR the ANSI codes of all characters
    For I = 0 To lastEl
        HashCode = HashCode Xor codes(I)
    Next
    
End Function

' get the index where an item is stored or 0 if not found
' if Create = True the item is created
'
' on exit Create=True only if a slot has been actually created
Private Function GetSlotIndex(ByVal Key As String, Optional Create As Boolean, Optional HCode As Long, Optional LastNdx As Long) As Long
    Dim ndx As Long
    
    ' raise error if invalid key
    If Len(Key) = 0 Then Exit Function
    
    ' keep case-unsensitiveness into account
    If m_IgnoreCase Then Key = UCase$(Key)
    ' get the index in the hashTbl() array
    HCode = HashCode(Key) Mod m_HashSize
    ' get the pointer to the slotTable() array
    ndx = hashTbl(HCode)
    
    ' exit if there is no item with that hash code
    Do While ndx
        ' compare key with actual value
        If slotTable(ndx).Key = Key Then Exit Do
        ' remember last pointer
        LastNdx = ndx
        ' check the next item
        ndx = slotTable(ndx).nextItem
    Loop
    
    ' create a new item if not there
    If ndx = 0 And Create Then
        ndx = GetFreeSlot()
        PrepareSlot ndx, Key, HCode, LastNdx
    Else
        ' signal that no item has been created
        Create = False
    End If
    ' this is the return value
    GetSlotIndex = ndx

End Function

' return the first free slot
Private Function GetFreeSlot() As Long
    ' allocate new memory if necessary
    If FreeNdx = 0 Then ExpandSlotTable m_ChunkSize
    ' use the first slot
    GetFreeSlot = FreeNdx
    ' update the pointer to the first slot
    FreeNdx = slotTable(GetFreeSlot).nextItem
    ' signal this as the end of the linked list
    slotTable(GetFreeSlot).nextItem = 0
    ' we have one more item
    m_Count = m_Count + 1
End Function

' assign a key and value to a given slot
Private Sub PrepareSlot(ByVal index As Long, ByVal Key As String, ByVal HCode As Long, ByVal LastNdx As Long)
    ' assign the key
    ' keep case-sensitiveness into account
    If m_IgnoreCase Then Key = UCase$(Key)
    slotTable(index).Key = Key
    
    If LastNdx Then
        ' this is the successor of another slot
        slotTable(LastNdx).nextItem = index
    Else
        ' this is the first slot for a given hash code
        hashTbl(HCode) = index
    End If
End Sub
