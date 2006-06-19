VERSION 5.00
Begin VB.Form frmVBTrace 
   Caption         =   "VB Tracer (for ignitionServer)"
   ClientHeight    =   5625
   ClientLeft      =   2280
   ClientTop       =   2565
   ClientWidth     =   8355
   Icon            =   "frmVBTrace.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   5625
   ScaleWidth      =   8355
   Begin VB.TextBox txtTrace 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   5475
      HideSelection   =   0   'False
      Left            =   120
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   3  'Both
      TabIndex        =   0
      Top             =   60
      Width           =   8115
   End
   Begin VB.Menu mnuFileTOP 
      Caption         =   "&File"
      Begin VB.Menu mnuFile 
         Caption         =   "&Save..."
         Index           =   0
         Shortcut        =   ^S
      End
      Begin VB.Menu mnuFile 
         Caption         =   "-"
         Index           =   1
      End
      Begin VB.Menu mnuFile 
         Caption         =   "E&xit"
         Index           =   2
      End
   End
   Begin VB.Menu mnuEditTOP 
      Caption         =   "&Edit"
      Begin VB.Menu mnuEdit 
         Caption         =   "&Copy"
         Index           =   0
         Shortcut        =   ^C
      End
      Begin VB.Menu mnuEdit 
         Caption         =   "-"
         Index           =   1
      End
      Begin VB.Menu mnuEdit 
         Caption         =   "&Find..."
         Index           =   2
         Shortcut        =   ^F
      End
      Begin VB.Menu mnuEdit 
         Caption         =   "Find &Next"
         Enabled         =   0   'False
         Index           =   3
         Shortcut        =   {F3}
      End
      Begin VB.Menu mnuEdit 
         Caption         =   "-"
         Index           =   4
      End
      Begin VB.Menu mnuEdit 
         Caption         =   "&Select All"
         Index           =   5
         Shortcut        =   ^A
      End
      Begin VB.Menu mnuEdit 
         Caption         =   "C&lear"
         Index           =   6
         Shortcut        =   {DEL}
      End
   End
   Begin VB.Menu mnuTraceTOP 
      Caption         =   "&Tracing"
      Begin VB.Menu mnuTrace 
         Caption         =   "&Pause"
         Checked         =   -1  'True
         Index           =   0
         Shortcut        =   {F5}
      End
      Begin VB.Menu mnuTrace 
         Caption         =   "-"
         Index           =   1
      End
      Begin VB.Menu mnuTrace 
         Caption         =   "&Configure..."
         Index           =   2
      End
   End
   Begin VB.Menu mnuHelpTOP 
      Caption         =   "&Help"
      Begin VB.Menu mnuHelp 
         Caption         =   "&About..."
         Index           =   0
      End
   End
End
Attribute VB_Name = "frmVBTrace"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function SendMessageStringA Lib "user32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As String) As Long
Private Declare Function SendMessageStringW Lib "user32" Alias "SendMessageW" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function SendMessageLong Lib "user32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function SendMessageLongW Lib "user32" Alias "SendMessageW" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function SendMessageRef Lib "user32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByRef wParam As Long, ByRef lParam As Long) As Long
Private Declare Function SendMessageRefW Lib "user32" Alias "SendMessageW" (ByVal hWnd As Long, ByVal wMsg As Long, ByRef wParam As Long, ByRef lParam As Long) As Long
Private Const EM_REPLACESEL = &HC2
Private Const EM_SETLIMITTEXT = &HC5 '        EM_LIMITTEXT   /* ;win40 Name change */
Private Const EM_GETLIMITTEXT = &HD5
Private Const EM_SETSEL = &HB1
Private Const EM_GETSEL = &HB0
Private Const WM_COPY = &H301
Private Const EM_GETLINE = &HC4
Private Const EM_GETLINECOUNT = &HBA
Private Const EM_LINEINDEX = &HBB
Private Const EM_LINEFROMCHAR = &HC9
Private Const EM_SCROLLCARET = &HB7
Private Const EM_LINELENGTH = &HC1

Private Declare Function LocalAlloc Lib "kernel32" (ByVal wFlags As Long, ByVal wBytes As Long) As Long
Private Declare Function LocalFree Lib "kernel32" (ByVal hMem As Long) As Long
Private Declare Function LocalLock Lib "kernel32" (ByVal hMem As Long) As Long
Private Declare Function LocalUnlock Lib "kernel32" (ByVal hMem As Long) As Long
Private Const GMEM_FIXED = &H0
Private Const GMEM_ZEROINIT = &H40
Private Const GPTR = (GMEM_FIXED Or GMEM_ZEROINIT)
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    lpvDest As Any, lpvSource As Any, ByVal cbCopy As Long)

Private Declare Function timeGetTime Lib "winmm.dll" () As Long
Private Declare Function timeBeginPeriod Lib "winmm.dll" (ByVal uPeriod As Long) As Long
Private Declare Function timeEndPeriod Lib "winmm.dll" (ByVal uPeriod As Long) As Long

Private Declare Function LoadImageLong Lib "user32" Alias "LoadImageA" (ByVal hInst As Long, ByVal lpsz As Long, ByVal uType As Long, ByVal cx As Long, ByVal cy As Long, ByVal uFlags As Long) As Long
Private Declare Function LoadImageString Lib "user32" Alias "LoadImageA" (ByVal hInst As Long, ByVal lpsz As String, ByVal uType As Long, ByVal cx As Long, ByVal cy As Long, ByVal uFlags As Long) As Long
Private Const IMAGE_BITMAP = 0
Private Const IMAGE_ICON = 1
Private Const IMAGE_CURSOR = 2
Private Declare Function DestroyIcon Lib "user32" (ByVal hIcon As Long) As Long

Private WithEvents m_cSysTray As frmSysTray
Attribute m_cSysTray.VB_VarHelpID = -1
Private WithEvents m_cMessage As frmMessageWindow
Attribute m_cMessage.VB_VarHelpID = -1
Private WithEvents m_cFindReplace As cFindReplace
Attribute m_cFindReplace.VB_VarHelpID = -1
Private m_iLength As Long
Private m_bPaused As Boolean
Private m_hIcon As Long

Private m_sToFind As String
Private m_iLastFindIndex As Long
Private m_eFindFlags As EFindReplaceFlags
Private m_lStartLine As Long

Public Sub Test()
   m_sToFind = "I've"
   txtTrace.Text = "This" & vbCrLf & "is " & vbCrLf & vbCrLf & "Some text " & vbCrLf & vbCrLf & "That I've added" & vbCrLf
   txtTrace.Text = txtTrace.Text + txtTrace.Text
   FindInTextBox
End Sub

Private Sub FindInTextBox()
Dim lLines As Long
Dim lFirstLine As Long
Dim lLine As Long
Dim sLine As String
Dim hMem As Long
Dim lPtrMem As Long
Dim iSize As Integer
Dim lR As Long
Dim b() As Byte
Dim eCompare As VbCompareMethod
Dim iPos As Long
Dim iCharIndex As Long
Dim iStartPos As Long

   If (m_eFindFlags And FR_MATCHCASE) = FR_MATCHCASE Then
      eCompare = vbBinaryCompare
   Else
      eCompare = vbTextCompare
   End If

   If (IsNt) Then
      hMem = LocalAlloc(GPTR, 4096)
   Else
      hMem = LocalAlloc(GPTR, 2048)
   End If
   lPtrMem = LocalLock(hMem)
   iSize = 2048

   If (IsNt) Then
      lLines = SendMessageLongW(txtTrace.hWnd, EM_GETLINECOUNT, 0, 0)
   Else
      lLines = SendMessageLong(txtTrace.hWnd, EM_GETLINECOUNT, 0, 0)
   End If
   lFirstLine = 0
   If (m_iLastFindIndex > 0) Then
      If (IsNt) Then
         lFirstLine = SendMessageLongW(txtTrace.hWnd, EM_LINEFROMCHAR, m_iLastFindIndex, 0)
      Else
         lFirstLine = SendMessageLong(txtTrace.hWnd, EM_LINEFROMCHAR, m_iLastFindIndex, 0)
      End If
   End If
   
   lLine = lFirstLine
   Do
      sLine = ""
      CopyMemory ByVal lPtrMem, iSize, 2
      If (IsNt) Then
         lR = SendMessageLongW(txtTrace.hWnd, EM_GETLINE, lLine, lPtrMem)
         If (lR > 0) Then
            ReDim b(0 To lR * 2 - 1) As Byte
            CopyMemory b(0), ByVal lPtrMem, lR * 2
            sLine = b
         End If
      Else
         lR = SendMessageLong(txtTrace.hWnd, EM_GETLINE, lLine, lPtrMem)
         If (lR > 0) Then
            ReDim b(0 To lR - 1) As Byte
            CopyMemory b(0), ByVal lPtrMem, lR
            sLine = StrConv(b, vbUnicode)
         End If
      End If
      
      iStartPos = 1
      If IsNt Then
         iCharIndex = SendMessageLongW(txtTrace.hWnd, EM_LINEINDEX, lLine, 0)
      Else
         iCharIndex = SendMessageLong(txtTrace.hWnd, EM_LINEINDEX, lLine, 0)
      End If
      If (m_iLastFindIndex > 0) Then
         ' does this line include m_iLastFindIndex?
         If (m_iLastFindIndex >= iCharIndex) And (m_iLastFindIndex <= iCharIndex + Len(sLine)) Then
            iStartPos = (m_iLastFindIndex + Len(m_sToFind) - iCharIndex) + 1
         End If
      End If
      iPos = InStr(iStartPos, sLine, m_sToFind, eCompare)
      
      If (iPos > 0) Then
         iCharIndex = iCharIndex + iPos - 1
         If (IsNt) Then
            SendMessageLongW txtTrace.hWnd, EM_SETSEL, iCharIndex, iCharIndex + Len(m_sToFind)
            SendMessageLongW txtTrace.hWnd, EM_SCROLLCARET, 0, 0
         Else
            SendMessageLong txtTrace.hWnd, EM_SETSEL, iCharIndex, iCharIndex + Len(m_sToFind)
            SendMessageLong txtTrace.hWnd, EM_SCROLLCARET, 0, 0
         End If
         Debug.Print iPos
         m_iLastFindIndex = iCharIndex
         txtTrace.SetFocus
         mnuEdit(3).Enabled = True
         Exit Do
      End If
      lLine = lLine + 1
   Loop While lLine < lLines
   
   
   LocalUnlock hMem
   LocalFree hMem
   
End Sub

Private Function GetIcon(ByVal lId As Long) As Long
   If Not (m_hIcon = 0) Then
      DestroyIcon m_hIcon
      m_hIcon = 0
   End If
   If (lId > 0) Then
      m_hIcon = LoadImageLong(App.hInstance, lId, IMAGE_ICON, 16, 16, 0)
   End If
   GetIcon = m_hIcon
End Function


Private Sub SaveTrace()

On Error GoTo ErrorHandler

Dim bPause As Boolean
   
   If Not (m_bPaused) Then
      bPause = True
      ActionHandler "PAUSE"
   End If
   
Dim cD As New cCommonDialog
Dim sFile As String
   If (cD.VBGetSaveFileName( _
      FileName:=sFile, _
      Filter:="Log Files (*.log)|*.log|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*|", _
      DefaultExt:="log", _
      Owner:=Me.hWnd)) Then
            
   End If
   
   If (bPause) Then
      ActionHandler "GO"
      bPause = False
   End If
   Exit Sub

ErrorHandler:
   MsgBox "An error occurred trying to save:" & Err.Description, vbExclamation
   If (bPause) Then
      ActionHandler "GO"
      bPause = False
   End If
   Exit Sub
End Sub

Private Sub CopyTrace()
Dim lStart As Long
Dim lEnd As Long
Dim lSwap As Long
Dim sBuf As String
Dim bPause As Boolean

On Error GoTo ErrorHandler

   If Not (m_bPaused) Then
      bPause = True
      ActionHandler "PAUSE"
   End If
   If IsNt Then
      SendMessageRefW txtTrace.hWnd, EM_GETSEL, lStart, lEnd
   Else
      SendMessageRef txtTrace.hWnd, EM_GETSEL, lStart, lEnd
   End If
   If (lStart = lEnd) Then
      ' everything
      sBuf = m_cMessage.Buffer
      Clipboard.Clear
      Clipboard.SetText sBuf
   Else
      If IsNt Then
         SendMessageLongW txtTrace.hWnd, WM_COPY, 0, 0
      Else
         SendMessageLong txtTrace.hWnd, WM_COPY, 0, 0
      End If
   End If
   
   If (bPause) Then
      ActionHandler "GO"
      bPause = False
   End If
   Exit Sub
   
ErrorHandler:
   MsgBox "An error occurred trying to copy:" & Err.Description, vbExclamation
   If (bPause) Then
      ActionHandler "GO"
      bPause = False
   End If
   Exit Sub
End Sub

Private Sub SelectAll()
   '
Dim lLines As Long
Dim lCharIndex As Long
Dim lSize As Long

   lLines = SendMessageLong(txtTrace.hWnd, EM_GETLINECOUNT, 0, 0) - 1
   lCharIndex = SendMessageLong(txtTrace.hWnd, EM_LINEINDEX, lLines, 0)
   lSize = SendMessageLong(txtTrace.hWnd, EM_LINELENGTH, lCharIndex, 0)
   SendMessageLong txtTrace.hWnd, EM_SETSEL, 0, lCharIndex + lSize
   '
End Sub

Private Sub ConfigureTracer()
   '
   Dim f As New frmConfigure
   f.Show vbModal, Me
   '
End Sub

Private Sub ActionHandler(ByVal sAction As String)
   Select Case sAction
   Case "SAVE"
      SaveTrace
   
   Case "FIND"
      If (m_cFindReplace.hWndDialog = 0) Then
         m_cFindReplace.VBFindText Me.hWnd
      End If
   
   Case "FINDNEXT"
      FindInTextBox
      
   Case "COPY"
      CopyTrace
   
   Case "SELECTALL"
      SelectAll
      
   Case "CLEAR"
      m_cMessage.Clear
      txtTrace.Text = ""
      m_iLength = 0
   
   Case "PAUSE"
      m_bPaused = True
      mnuTrace(0).Checked = True
      m_cSysTray.IconHandle = GetIcon(25)
   
   Case "GO"
      m_bPaused = False
      m_cMessage_DataAdded
      mnuTrace(0).Checked = False
      m_cSysTray.IconHandle = GetIcon(24)
      
   Case "CONFIGURE"
      ConfigureTracer
      
   Case "RESTORE"
      Me.Tag = "RESTORE"
      Me.Visible = True
      m_cSysTray.RestoreAndActivate Me.hWnd
      Me.Tag = ""
      
   Case "EXIT"
      Unload Me
   
   Case "ABOUT"
      Dim fA As New frmAbout
      Set fA.Icon = Me.Icon
      fA.Show vbModal, Me
      
   End Select
End Sub

Private Sub Command1_Click()

   Dim sNewData As String
   sNewData = String$(100, "0") & vbCrLf
   Dim i As Long
   txtTrace.Visible = False
   For i = 1 To 700
      AddData sNewData
   Next i
   txtTrace.Visible = True
   
   Dim lStart As Long
   Dim lEnd As Long
   If IsNt Then
      SendMessageRefW txtTrace.hWnd, EM_GETSEL, lStart, lEnd
   Else
      SendMessageRef txtTrace.hWnd, EM_GETSEL, lStart, lEnd
   End If
   Debug.Print lStart, lEnd
   
'   Dim sNewData As String
'   sNewData = "Hi Mum" & vbCrLf
'   Dim lT As Long
'   Dim i As Long
'   timeBeginPeriod 1
'
'   txtTrace.Text = ""
'   txtTrace.Visible = False
'   lT = timeGetTime()
'   For i = 1 To 2000
'      txtTrace.Text = txtTrace.Text & sNewData
'   Next i
'   txtTrace.Visible = True
'   MsgBox "VB Method: " & timeGetTime() - lT
'
'   txtTrace.Text = ""
'   m_iLength = 0
'   lT = timeGetTime()
'   txtTrace.Visible = False
'   For i = 1 To 2000
'      txtTrace.SelStart = m_iLength
'      SendMessageString txtTrace.hwnd, EM_REPLACESEL, 0, sNewData
'      m_iLength = m_iLength + Len(sNewData)
'   Next i
'   txtTrace.Visible = True
'   MsgBox "API Method: " & timeGetTime() - lT
'
'   timeEndPeriod 1
End Sub

Public Sub AddData(ByVal sData As String)
Dim lLines As Long
Dim lStart As Long
Dim lEnd As Long
   If (Len(sData) > 0) Then
      If (IsNt) Then
         lLines = SendMessageLongW(txtTrace.hWnd, EM_GETLINECOUNT, 0, 0)
         If (lLines > g_cConfiguration.MaxLines) Then
            lStart = SendMessageLongW(txtTrace.hWnd, EM_LINEINDEX, 0, 0)
            lEnd = SendMessageLongW(txtTrace.hWnd, EM_LINEINDEX, 1, 0)
            SendMessageLongW txtTrace.hWnd, EM_SETSEL, lStart, lEnd - 1
            SendMessageStringW txtTrace.hWnd, EM_REPLACESEL, 0, StrPtr("")
         End If
         SendMessageLongW txtTrace.hWnd, EM_SETSEL, m_iLength, m_iLength
         SendMessageStringW txtTrace.hWnd, EM_REPLACESEL, 0, StrPtr(sData)
      Else
         SendMessageLong txtTrace.hWnd, EM_SETSEL, m_iLength, m_iLength
         SendMessageStringA txtTrace.hWnd, EM_REPLACESEL, 0, sData
      End If
      m_iLength = m_iLength + Len(sData)
   End If
End Sub

Private Sub Form_Load()
   
   TagWindow Me.hWnd
      
   Set m_cSysTray = New frmSysTray
   Set m_cSysTray.Icon = Me.Icon
   m_cSysTray.AddMenuItem "&Restore", "RESTORE", True
   m_cSysTray.AddMenuItem "-"
   m_cSysTray.AddMenuItem "E&xit", "EXIT"
   m_cSysTray.ToolTip = "VB Tracer"
   Load m_cSysTray
   
   Set m_cMessage = New frmMessageWindow
   Load m_cMessage
   
   Set m_cFindReplace = New cFindReplace
   
   ActionHandler "GO"
   
End Sub

Private Sub Form_Resize()
   If Me.Tag <> "RESTORE" Then
      If (Me.WindowState = vbMinimized) Then
         Me.Visible = False
      End If
   End If
   On Error Resume Next
   txtTrace.Move txtTrace.Left, txtTrace.Top, Me.ScaleWidth - txtTrace.Left * 2, Me.ScaleHeight - txtTrace.Top * 2
End Sub

Private Sub m_cFindReplace_FindNext(ByVal sToFind As String, ByVal eFlags As EFindReplaceFlags)
   '
   If Not (StrComp(sToFind, m_sToFind) = 0) Then
      m_sToFind = sToFind
      m_iLastFindIndex = 0
   End If
   FindInTextBox
   '
End Sub

Private Sub m_cFindReplace_ShowHelp()
   '
End Sub

Private Sub m_cMessage_DataAdded()
   '
   If Not m_bPaused Then
      AddData m_cMessage.NewData
   End If
   '
End Sub

Private Sub m_cSysTray_MenuClick(ByVal lIndex As Long, ByVal sKey As String)
   ActionHandler sKey
End Sub

Private Sub m_cSysTray_SysTrayDoubleClick(ByVal eButton As MouseButtonConstants)
   ActionHandler "RESTORE"
End Sub

Private Sub m_cSysTray_SysTrayMouseUp(ByVal eButton As MouseButtonConstants)
   If (eButton = vbLeftButton) Then
      ActionHandler "RESTORE"
   ElseIf (eButton = vbRightButton) Then
      m_cSysTray.ShowMenu
   End If
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
   GetIcon 0
   Unload m_cSysTray
   Set m_cSysTray = Nothing
   Unload m_cMessage
   Set m_cMessage = Nothing
   EndApp
   
End Sub

Private Sub mnuEdit_Click(Index As Integer)
   Select Case Index
   Case 0
      ActionHandler "COPY"
   Case 2
      ActionHandler "FIND"
   Case 3
      ActionHandler "FINDNEXT"
   Case 5
      ActionHandler "SELECTALL"
   Case 6
      ActionHandler "CLEAR"
   End Select
End Sub

Private Sub mnuFile_Click(Index As Integer)
   Select Case Index
   Case 0
      ActionHandler "SAVE"
   Case 2
      ActionHandler "EXIT"
   End Select
End Sub

Private Sub mnuHelp_Click(Index As Integer)
   Select Case Index
   Case 0
      ActionHandler "ABOUT"
   End Select
End Sub

Private Sub mnuTrace_Click(Index As Integer)
   Select Case Index
   Case 0
      If (mnuTrace(0).Checked) Then
         ActionHandler "GO"
      Else
         ActionHandler "PAUSE"
      End If
   Case 2
      ActionHandler "CONFIGURE"
   End Select
End Sub

