VERSION 5.00
Begin VB.Form frmMessageWindow 
   Caption         =   "VB Trace Message Window"
   ClientHeight    =   3900
   ClientLeft      =   4050
   ClientTop       =   2565
   ClientWidth     =   7050
   LinkTopic       =   "Form1"
   ScaleHeight     =   3900
   ScaleWidth      =   7050
End
Attribute VB_Name = "frmMessageWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Const WM_COPYDATA = &H4A
Private Type COPYDATASTRUCT
   dwData As Long
   cbData As Long
   lpData As Long
End Type
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    lpvDest As Any, lpvSource As Any, ByVal cbCopy As Long)
Private Declare Function GetProp Lib "user32" Alias "GetPropA" (ByVal hWnd As Long, ByVal lpString As String) As Long
Private Declare Function SetProp Lib "user32" Alias "SetPropA" (ByVal hWnd As Long, ByVal lpString As String, ByVal hData As Long) As Long
Private Declare Function RemoveProp Lib "user32" Alias "RemovePropA" (ByVal hWnd As Long, ByVal lpString As String) As Long

Implements ISubclass

Private m_c As cStringBuilder
Private m_iLastIndex As Long

Public Event DataAdded()

Public Property Get Buffer() As String
   Buffer = m_c.ToString
End Property

Public Property Get SubString( _
      ByVal lStart As Long, _
      ByVal lEnd As Long _
   )
   SubString = m_c.SubString(lStart, (lEnd - lStart + 1))
End Property

Public Property Get Length() As Long
   Length = m_c.Length
End Property

Public Sub Clear()
   m_iLastIndex = 0
   Set m_c = New cStringBuilder
End Sub

Private Function processData(ByRef sData As String) As String
Dim iPos As Long
Dim iNextPos As Long
Dim sRet As String
Dim iState As Long
   iPos = 1
   Do
      iNextPos = InStr(iPos, sData, ": ")
      If (iNextPos > 0) Then
         Select Case iState
         Case 0
            If (g_cConfiguration.ShowExeName) Then
               sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
            End If
         Case 1
            If (g_cConfiguration.ShowHInstance) Then
               sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
            End If
         Case 2
            If (g_cConfiguration.ShowThreadId) Then
               sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
            End If
         Case 3
            If (g_cConfiguration.ShowDateTime) Then
               sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
            End If
         Case 4
            If (g_cConfiguration.ShowMessageClass) Then
              sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
            End If
         Case 5
            If (g_cConfiguration.ShowModuleName) Then
              sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
            End If
         Case Else
            ' another : in the string
            sRet = sRet & Mid$(sData, iPos, iNextPos - iPos + 1)
         End Select
         iState = iState + 1
         iPos = iNextPos + 2
      End If
   Loop While (iNextPos > 0)
   sRet = sRet & Mid$(sData, iPos)
   processData = sRet
   
End Function

Private Sub AddData(ByVal sData As String)
Dim sOutput As String
   On Error Resume Next
   sOutput = processData(sData)
   m_c.Append sOutput & vbCrLf
   If (g_cConfiguration.TraceToFile) Then
      On Error Resume Next
      Dim iFile As Integer
      iFile = FreeFile
      Open g_cConfiguration.TraceFileName For Append Shared As #iFile
      Print #iFile, sOutput
      Close #iFile
   End If
   RaiseEvent DataAdded
End Sub

Public Property Get NewData() As String
   If (m_iLastIndex = 0) Then
      NewData = m_c.ToString
   Else
      If (m_c.Length > m_iLastIndex) Then
         NewData = m_c.SubString(m_iLastIndex)
      End If
   End If
   m_c.Clear
   m_iLastIndex = m_c.Length
End Property

Private Sub Form_Load()
   Set m_c = New cStringBuilder
   AttachMessage Me, Me.hWnd, WM_COPYDATA
   SetProp Me.hWnd, THISAPPID & "_TRACEWIN", 1

End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
   RemoveProp Me.hWnd, THISAPPID & "_TRACEWIN"
End Sub

Private Property Let ISubclass_MsgResponse(ByVal RHS As EMsgResponse)
   '
End Property

Private Property Get ISubclass_MsgResponse() As EMsgResponse
   ISubclass_MsgResponse = emrPreprocess
End Property

Private Function ISubclass_WindowProc(ByVal hWnd As Long, ByVal iMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
   '
   Select Case iMsg
   Case WM_COPYDATA
      ' Copy for processing:
      Dim tCDS As COPYDATASTRUCT
      CopyMemory tCDS, ByVal lParam, Len(tCDS)
      If (tCDS.cbData > 1) Then
         Dim b() As Byte
         Dim sData As String
         ReDim b(0 To tCDS.cbData - 1) As Byte
         CopyMemory b(0), ByVal tCDS.lpData, tCDS.cbData
         sData = StrConv(b, vbUnicode)
         
         ' We've got the info, now do it:
         Debug.Print sData
         AddData sData
         
      Else
         ' no data.
      End If
      '
   End Select
End Function
