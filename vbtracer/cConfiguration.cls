VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cConfiguration"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_bShowModuleName As Boolean
Private m_bShowMessageClass As Boolean
Private m_bShowExeName As Boolean
Private m_bShowHInstance As Boolean
Private m_bShowThreadId As Boolean
Private m_bShowDateTime As Boolean
Private m_bTraceToFile As Boolean
Private m_sTraceFileName As String
Private m_bDirty As Boolean
Private m_lMaxLines As Long

Public Property Get ShowModuleName() As Boolean
  ShowModuleName = m_bShowModuleName
End Property
Public Property Let ShowModuleName(ByVal value As Boolean)
  If Not (m_bShowModuleName = value) Then
    m_bShowModuleName = value
    m_bDirty = True
  End If
End Property
Public Property Get ShowMessageClass() As Boolean
  ShowMessageClass = m_bShowMessageClass
End Property
Public Property Let ShowMessageClass(ByVal value As Boolean)
  If Not (m_bShowModuleName = value) Then
    m_bShowModuleName = value
    m_bDirty = True
  End If
End Property

Public Property Get ShowExeName() As Boolean
   ShowExeName = m_bShowExeName
End Property
Public Property Let ShowExeName(ByVal value As Boolean)
   If Not (m_bShowExeName = value) Then
      m_bShowExeName = value
      m_bDirty = True
   End If
End Property

Public Property Get ShowHInstance() As Boolean
   ShowHInstance = m_bShowHInstance
End Property
Public Property Let ShowHInstance(ByVal value As Boolean)
   If Not (m_bShowHInstance = value) Then
      m_bShowHInstance = value
      m_bDirty = True
   End If
End Property

Public Property Get ShowThreadId() As Boolean
   ShowThreadId = m_bShowThreadId
End Property
Public Property Let ShowThreadId(ByVal value As Boolean)
   If Not (m_bShowThreadId = value) Then
      m_bShowThreadId = value
      m_bDirty = True
   End If
End Property

Public Property Get ShowDateTime() As Boolean
   ShowDateTime = m_bShowDateTime
End Property
Public Property Let ShowDateTime(ByVal value As Boolean)
   If Not (m_bShowDateTime = value) Then
      m_bShowDateTime = value
      m_bDirty = True
   End If
End Property

Public Property Get TraceToFile() As Boolean
   TraceToFile = m_bTraceToFile
End Property
Public Property Let TraceToFile(ByVal value As Boolean)
   If Not (m_bTraceToFile = value) Then
      m_bTraceToFile = value
      m_bDirty = True
   End If
End Property

Public Property Get TraceFileName() As String
   TraceFileName = m_sTraceFileName
End Property
Public Property Let TraceFileName(ByVal value As String)
   If Not (StrComp(m_sTraceFileName, value, vbTextCompare) = 0) Then
      m_sTraceFileName = value
      m_bDirty = True
   End If
End Property

Public Property Get MaxLines() As Long
   MaxLines = m_lMaxLines
End Property
Public Property Let MaxLines(ByVal value As Long)
   If Not (value = m_lMaxLines) Then
      m_lMaxLines = value
      m_bDirty = True
   End If
End Property

Public Property Get Dirty() As Boolean
   Dirty = m_bDirty
End Property

Private Sub Class_Initialize()
   m_bShowModuleName = True
   m_bShowMessageClass = True
   m_bShowExeName = False
   m_bShowHInstance = False
   m_bShowThreadId = False
   m_bShowDateTime = True
   m_bTraceToFile = False
   m_sTraceFileName = "C:\VBTrace.log"
   m_lMaxLines = 1000
End Sub

Private Sub Class_Terminate()
   '
End Sub
