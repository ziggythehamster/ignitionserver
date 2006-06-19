VERSION 5.00
Begin VB.Form frmConfigure 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Configure Tracer"
   ClientHeight    =   4815
   ClientLeft      =   4485
   ClientTop       =   5175
   ClientWidth     =   5775
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   4815
   ScaleWidth      =   5775
   ShowInTaskbar   =   0   'False
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   495
      Left            =   4380
      TabIndex        =   10
      Top             =   4200
      Width           =   1275
   End
   Begin VB.CommandButton cmdOK 
      Caption         =   "OK"
      Default         =   -1  'True
      Height          =   495
      Left            =   3060
      TabIndex        =   9
      Top             =   4200
      Width           =   1275
   End
   Begin VB.Frame fraTraceToFile 
      Caption         =   "Trace To &File"
      Height          =   1095
      Left            =   120
      TabIndex        =   5
      Top             =   3060
      Width           =   5535
      Begin VB.CommandButton cmdPick 
         Caption         =   "..."
         Height          =   315
         Left            =   5100
         TabIndex        =   8
         ToolTipText     =   "Pick File"
         Top             =   600
         Width           =   315
      End
      Begin VB.TextBox txtFileName 
         Height          =   315
         Left            =   420
         TabIndex        =   7
         Text            =   "C:\VBTrace.log"
         Top             =   600
         Width           =   4635
      End
      Begin VB.CheckBox chkTraceToFile 
         Caption         =   "&Enabled"
         Height          =   255
         Left            =   180
         TabIndex        =   6
         Top             =   240
         Width           =   3675
      End
   End
   Begin VB.Frame fraOptions 
      Caption         =   "&Trace Options"
      Height          =   2295
      Left            =   120
      TabIndex        =   0
      Top             =   660
      Width           =   5535
      Begin VB.CheckBox chkModuleName 
         Caption         =   "&Module Name"
         Height          =   255
         Left            =   1440
         TabIndex        =   16
         Top             =   540
         Value           =   1  'Checked
         Width           =   1335
      End
      Begin VB.CheckBox chkMsgClass 
         Caption         =   "Message &Class"
         Height          =   255
         Left            =   1440
         TabIndex        =   15
         Top             =   240
         Value           =   1  'Checked
         Width           =   1575
      End
      Begin VB.TextBox txtLines 
         Height          =   315
         Left            =   420
         TabIndex        =   14
         Text            =   "1000"
         Top             =   1740
         Width           =   4695
      End
      Begin VB.CheckBox chkOption 
         Caption         =   "&Date / Time"
         Height          =   255
         Index           =   3
         Left            =   120
         TabIndex        =   4
         Top             =   1140
         Value           =   1  'Checked
         Width           =   1155
      End
      Begin VB.CheckBox chkOption 
         Caption         =   "&Thread ID"
         Height          =   255
         Index           =   2
         Left            =   120
         TabIndex        =   3
         Top             =   840
         Value           =   1  'Checked
         Width           =   1155
      End
      Begin VB.CheckBox chkOption 
         Caption         =   "h&Instance"
         Height          =   255
         Index           =   1
         Left            =   120
         TabIndex        =   2
         Top             =   540
         Value           =   1  'Checked
         Width           =   1155
      End
      Begin VB.CheckBox chkOption 
         Caption         =   "&Exe Name"
         Height          =   255
         Index           =   0
         Left            =   120
         TabIndex        =   1
         Top             =   240
         Value           =   1  'Checked
         Width           =   1155
      End
      Begin VB.Label lblLineLimit 
         Caption         =   "&Line Limit (Min 10, Max 10,000):"
         Height          =   195
         Left            =   120
         TabIndex        =   13
         Top             =   1500
         Width           =   5295
      End
   End
   Begin VB.Label lblInfo 
      BackColor       =   &H80000010&
      Height          =   135
      Index           =   1
      Left            =   0
      TabIndex        =   12
      Top             =   360
      Width           =   5775
   End
   Begin VB.Image imgIcon 
      Height          =   240
      Left            =   180
      Picture         =   "frmConfigure.frx":0000
      Top             =   40
      Width           =   240
   End
   Begin VB.Label lblInfo 
      BackColor       =   &H80000015&
      Caption         =   "       VBTracer (for ignitionServer)"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   12
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H8000000F&
      Height          =   375
      Index           =   0
      Left            =   0
      TabIndex        =   11
      Top             =   0
      Width           =   5775
   End
End
Attribute VB_Name = "frmConfigure"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private m_bCancel As Boolean

Private Function Validate() As Boolean
   On Error Resume Next
   Dim lLines As Long
   lLines = CLng(txtLines.Text)
   If (Err.Number <> 0) Or (lLines < 10) Or (lLines > 10000) Then
      MsgBox "Line Limit must be between 10 and 10,000", vbInformation
      txtLines.SetFocus
      Validate = False
   Else
      Validate = True
   End If
End Function

Private Sub chkTraceToFile_Click()
   txtFileName.Locked = Not (chkTraceToFile.value = vbChecked)
   txtFileName.BackColor = IIf(chkTraceToFile.value = vbChecked, vbWindowBackground, Me.BackColor)
   cmdPick.Enabled = (chkTraceToFile.value = vbChecked)
End Sub

Private Sub cmdCancel_Click()
   Unload Me
End Sub

Private Sub cmdOK_Click()
   If (Validate) Then
      m_bCancel = False
      With g_cConfiguration
         .ShowExeName = (chkOption(0).value = vbChecked)
         .ShowHInstance = (chkOption(1).value = vbChecked)
         .ShowThreadId = (chkOption(2).value = vbChecked)
         .ShowDateTime = (chkOption(3).value = vbChecked)
         .TraceToFile = (chkTraceToFile.value = vbChecked)
         .MaxLines = CLng(txtLines.Text)
         .TraceFileName = txtFileName.Text
         .ShowModuleName = (chkModuleName.value = vbChecked)
         .ShowMessageClass = (chkMsgClass.value = vbChecked)
      End With
      Unload Me
   End If
End Sub

Private Sub cmdPick_Click()
   Dim cD As New cCommonDialog
   Dim sFileName As String
   If (cD.VBGetSaveFileName( _
         FileName:=sFileName, _
         Filter:="Log Files (*.log)|*.log|CSV Files (*.CSV)|*.csv|All Files (*.*)|*.*", _
         DefaultExt:="log", _
         Owner:=Me.hWnd)) Then
      txtFileName.Text = sFileName
   End If
End Sub

Private Sub Form_Load()
   Me.Icon = imgIcon.Picture
   m_bCancel = True
   With g_cConfiguration
      chkOption(0).value = Abs(.ShowExeName)
      chkOption(1).value = Abs(.ShowHInstance)
      chkOption(2).value = Abs(.ShowThreadId)
      chkOption(3).value = Abs(.ShowDateTime)
      chkTraceToFile.value = Abs(.TraceToFile)
      txtFileName.Text = .TraceFileName
      txtFileName.Locked = Not (.TraceToFile)
      txtFileName.BackColor = IIf(.TraceToFile, vbWindowBackground, Me.BackColor)
      cmdPick.Enabled = Not (.TraceToFile)
      txtLines.Text = .MaxLines
      chkMsgClass.value = Abs(.ShowMessageClass)
      chkModuleName.value = Abs(.ShowModuleName)
   End With
End Sub

Private Sub txtLines_KeyPress(KeyAscii As Integer)
   Select Case KeyAscii
   Case 9
   Case 10
   Case 13
   Case Asc("0") To Asc("9")
   Case Else
      KeyAscii = 0
   End Select
End Sub
