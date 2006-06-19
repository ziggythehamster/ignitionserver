VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cFindReplace"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Type FINDREPLACE
   lStructSize As Long        '// size of this struct 0x20
   hWndOwner As Long          '// handle to owner's window
   hInstance As Long          '// instance handle of.EXE that
                              '//   contains cust. dlg. template
   flags As Long            '// one or more of the FR_??
   lpstrFindWhat As Long      '// ptr. to search string
   lpstrReplaceWith As Long '// ptr. to replace string
   wFindWhatLen As Integer        '// size of find buffer
   wReplaceWithLen As Integer '// size of replace buffer
   lCustData As Long          '// data passed to hook fn.
   lpfnHook As Long           '// ptr. to hook fn. or NULL
   lpTemplateName As Long   '// custom template name
End Type
Private Declare Function FindTextA Lib "COMDLG32.DLL" (tF As FINDREPLACE) As Long
Private Declare Function ReplaceTextA Lib "COMDLG32.DLL" (tF As FINDREPLACE) As Long
Private Declare Function FindTextW Lib "COMDLG32.DLL" (tF As FINDREPLACE) As Long
Private Declare Function ReplaceTextW Lib "COMDLG32.DLL" (tF As FINDREPLACE) As Long
Public Enum EFindReplaceFlags
    FR_DOWN = &H1&
    FR_WHOLEWORD = &H2&
    FR_MATCHCASE = &H4&
    FR_ENABLEHOOK = &H100&
    FR_ENABLETEMPLATE = &H200&
    FR_NOUPDOWN = &H400&
    FR_NOMATCHCASE = &H800&
    FR_NOWHOLEWORD = &H1000&
    FR_ENABLETEMPLATEHANDLE = &H2000&
    FR_HIDEUPDOWN = &H4000&
    FR_HIDEMATCHCASE = &H8000&
    FR_HIDEWHOLEWORD = &H10000
End Enum
Private Enum EFindReplaceNotificationFlags
    FR_REPLACEALL = &H20&
    FR_DIALOGTERM = &H40&
    FR_SHOWHELP = &H80&
    FR_FINDNEXT = &H8&
    FR_REPLACE = &H10&
End Enum
Private Declare Function GetVersion Lib "kernel32" () As Long

Private m_iFindReplaceMsg As Long  '// message identifier for FINDMSGSTRING
Private Const FINDMSGSTRING = "commdlg_FindReplace"
Private Declare Function RegisterWindowMessage Lib "user32" Alias "RegisterWindowMessageA" (ByVal lpString As String) As Long
Private Declare Function LocalAlloc Lib "kernel32" (ByVal wFlags As Long, ByVal wBytes As Long) As Long
Private Declare Function LocalFree Lib "kernel32" (ByVal hMem As Long) As Long
Private Declare Function LocalLock Lib "kernel32" (ByVal hMem As Long) As Long
Private Declare Function LocalUnlock Lib "kernel32" (ByVal hMem As Long) As Long
Private Const GMEM_FIXED = &H0
Private Const GMEM_ZEROINIT = &H40
Private Const GPTR = (GMEM_FIXED Or GMEM_ZEROINIT)
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    lpvDest As Any, lpvSource As Any, ByVal cbCopy As Long)
Private Declare Function CloseWindow Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function SendMessageLong Lib "user32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Const WM_SYSCOMMAND = &H112
Private Const SC_RESTORE = &HF120
Private Const SC_CLOSE = &HF060&
Implements ISubclass

Private m_tF As FINDREPLACE
Private m_hWndFindText As Long

Private m_lBuffLen As Long
Private m_hFindBuffMem As Long
Private m_lptrFindBuff As Long
Private m_hReplaceBuffMem As Long
Private m_lptrReplaceBuff As Long

Private m_hWndOwner As Long

Public Event ShowHelp()
Public Event FindNext(ByVal sToFind As String, ByVal eFlags As EFindReplaceFlags)
Public Event Replace(ByVal sToReplace As String, ByVal sReplaceWith As String, ByVal eFlags As EFindReplaceFlags)
Public Event ReplaceAll(ByVal sToReplace As String, ByVal sReplaceWith As String, ByVal eFlags As EFindReplaceFlags)

Public Function VBFindText( _
        ByVal hWndOwner As Long, _
        Optional ByVal sFindWhat As String = "", _
        Optional ByVal eFlags As EFindReplaceFlags _
    ) As Boolean
      
   If Not (m_hWndFindText = 0) Then
      SendMessageLong m_hWndFindText, WM_SYSCOMMAND, SC_CLOSE, 0
   End If
      
   m_tF.hWndOwner = hWndOwner
   m_tF.lCustData = hWndOwner
   m_tF.hInstance = 0
   m_tF.flags = eFlags
   SetString m_tF.lpstrFindWhat, sFindWhat
   If IsNt Then
      m_hWndFindText = FindTextW(m_tF)
   Else
      m_hWndFindText = FindTextA(m_tF)
   End If
   If Not (m_hWndFindText = 0) Then
      m_hWndOwner = hWndOwner
      AttachMessage Me, hWndOwner, m_iFindReplaceMsg
      VBFindText = True
   End If
    
End Function

Public Function VBReplaceText( _
      ByVal hWndOwner As Long, _
      Optional ByVal sReplaceWhat As String = "", _
      Optional ByVal sReplaceWith As String = "", _
      Optional ByVal eFlags As EFindReplaceFlags _
   ) As Boolean
   
   If Not (m_hWndFindText = 0) Then
      SendMessageLong m_hWndFindText, WM_SYSCOMMAND, SC_CLOSE, 0
   End If
      
   m_tF.hWndOwner = hWndOwner
   m_tF.lCustData = hWndOwner
   m_tF.hInstance = 0
   m_tF.flags = eFlags
   SetString m_tF.lpstrFindWhat, sReplaceWhat
   SetString m_tF.lpstrReplaceWith, sReplaceWith
   If IsNt Then
      m_hWndFindText = ReplaceTextW(m_tF)
   Else
      m_hWndFindText = ReplaceTextA(m_tF)
   End If
   If Not (m_hWndFindText = 0) Then
      m_hWndOwner = hWndOwner
      AttachMessage Me, hWndOwner, m_iFindReplaceMsg
      VBReplaceText = True
   End If
   
End Function

Public Property Get hWndDialog() As Long
   hWndDialog = m_hWndFindText
End Property

Private Sub Class_Initialize()
    
   m_tF.lStructSize = Len(m_tF)
   
   If IsNt Then
      m_lBuffLen = 1024
   Else
      m_lBuffLen = 512
   End If
   
   m_hFindBuffMem = LocalAlloc(GPTR, m_lBuffLen)
   m_lptrFindBuff = LocalLock(m_hFindBuffMem)
   
   m_hReplaceBuffMem = LocalAlloc(GPTR, m_lBuffLen)
   m_lptrReplaceBuff = LocalLock(m_hReplaceBuffMem)
   
   m_tF.lpstrFindWhat = m_lptrFindBuff
   m_tF.wFindWhatLen = m_lBuffLen
   m_tF.lpstrReplaceWith = m_lptrReplaceBuff
   m_tF.wReplaceWithLen = m_lBuffLen
         
   m_iFindReplaceMsg = RegisterWindowMessage(FINDMSGSTRING)

End Sub

Private Sub Class_Terminate()
   If Not (m_hWndOwner = 0) Then
      DetachMessage Me, m_hWndOwner, m_iFindReplaceMsg
   End If
   If Not (m_hWndFindText = 0) Then
      ' Want to close the dialog:
      SendMessageLong m_hWndFindText, WM_SYSCOMMAND, SC_CLOSE, 0
   End If
   If Not (m_lptrFindBuff = 0) Then
      LocalUnlock m_hFindBuffMem
      m_lptrFindBuff = 0
   End If
   If Not (m_hFindBuffMem = 0) Then
      LocalFree m_hFindBuffMem
   End If
   If Not (m_lptrReplaceBuff = 0) Then
      LocalUnlock m_hReplaceBuffMem
      m_lptrReplaceBuff = 0
   End If
   If Not (m_hReplaceBuffMem = 0) Then
      LocalFree m_hReplaceBuffMem
      m_hReplaceBuffMem = 0
   End If
End Sub

Private Property Let ISubclass_MsgResponse(ByVal RHS As EMsgResponse)
   '
End Property

Private Property Get ISubclass_MsgResponse() As EMsgResponse
   ISubclass_MsgResponse = emrPreprocess
End Property

Private Function ISubclass_WindowProc(ByVal hWnd As Long, ByVal iMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Dim tFR As FINDREPLACE
Dim eFlags As EFindReplaceFlags
Dim sToFind As String
Dim sReplaceWith As String

   Select Case iMsg
   Case m_iFindReplaceMsg
      CopyMemory tFR, ByVal lParam, Len(tFR)
      Select Case True
      Case ((tFR.flags And FR_DIALOGTERM) = FR_DIALOGTERM)
         DetachMessage Me, m_hWndOwner, m_iFindReplaceMsg
         m_hWndFindText = 0
      Case ((tFR.flags And FR_SHOWHELP) = FR_SHOWHELP)
         RaiseEvent ShowHelp
      Case ((tFR.flags And FR_FINDNEXT) = FR_FINDNEXT)
         eFlags = tFR.flags And Not (FR_DIALOGTERM Or FR_SHOWHELP Or FR_FINDNEXT Or FR_REPLACE Or FR_REPLACEALL)
         sToFind = GetString(tFR.lpstrFindWhat)
         RaiseEvent FindNext(sToFind, eFlags)
      Case ((tFR.flags And FR_REPLACE) = FR_REPLACE)
         eFlags = tFR.flags And Not (FR_DIALOGTERM Or FR_SHOWHELP Or FR_FINDNEXT Or FR_REPLACE Or FR_REPLACEALL)
         sToFind = GetString(tFR.lpstrFindWhat)
         sReplaceWith = GetString(tFR.lpstrReplaceWith)
         RaiseEvent Replace(sToFind, sReplaceWith, eFlags)
      Case ((tFR.flags And FR_REPLACEALL) = FR_REPLACEALL)
         eFlags = tFR.flags And Not (FR_DIALOGTERM Or FR_SHOWHELP Or FR_FINDNEXT Or FR_REPLACE Or FR_REPLACEALL)
         sToFind = GetString(tFR.lpstrFindWhat)
         sReplaceWith = GetString(tFR.lpstrReplaceWith)
         RaiseEvent ReplaceAll(sToFind, sReplaceWith, eFlags)
      End Select
   End Select
End Function

Private Function GetString(ByVal lPtr As Long) As String
   Dim sRet As String
   If Not (lPtr = 0) Then
      Dim b() As Byte
      ReDim b(0 To m_lBuffLen - 1) As Byte
      CopyMemory b(0), ByVal lPtr, m_lBuffLen
      If IsNt Then
         sRet = b
      Else
         sRet = StrConv(b, vbUnicode)
      End If
      Dim iPos As Long
      iPos = InStr(sRet, vbNullChar)
      If (iPos > 1) Then
         GetString = Left(sRet, iPos - 1)
      End If
   End If
End Function
Private Sub SetString(ByVal lPtr As Long, ByVal sString As String)
   If Not (lPtr = 0) Then
      If (Len(sString) > 0) Then
         Dim b() As Byte
         If IsNt Then
            If (Len(sString) > m_lBuffLen \ 2) Then
               sString = Left(sString, m_lBuffLen \ 2)
            End If
            b = sString
         Else
            If (Len(sString) > m_lBuffLen) Then
               sString = Left(sString, m_lBuffLen)
            End If
            b = StrConv(sString, vbFromUnicode)
         End If
         ReDim Preserve b(0 To m_lBuffLen) As Byte
         CopyMemory ByVal lPtr, b(0), m_lBuffLen
      End If
   End If
End Sub
Private Function IsNt()
Dim lVer As Long
   lVer = GetVersion()
   IsNt = ((lVer And &H80000000) = 0)
End Function




