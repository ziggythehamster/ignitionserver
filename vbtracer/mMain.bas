Attribute VB_Name = "mMain"
Option Explicit

' ===========================================================================
' Filename: mMain.bas
' Author:   Steve McMahon (steve@vbaccelerator.com)
' Date:     2 January 1999
'
' Description:
' A re-usable module for single instance applications which can have a
' a command line.
'
' a) To absolutely prevent two instances, we use a system Mutex via
'    CreateMutex (rather than App.PrevInstance, which may not return True).
'    However this is a pain during development if you press Stop (have to
'    shutdown VB to clear the Mutex) so we just use App.PrevInstance then.
' b) When window is created, it is tagged with a Windows property so any
'    new instances can be accurately identified.
' c) When the user tries to start a second instance (either by double
'    clicking on the EXE or by double clicking an associated file), the
'    window is identified and the command line (if any) is sent to it.
'
' ---------------------------------------------------------------------------
' vbAccelerator - free, advanced source code for VB programmers.
'     http://vbaccelerator.com
' ===========================================================================

Private Declare Function CreateMutex Lib "kernel32" Alias "CreateMutexA" (ByVal lpMutexAttributes As Long, ByVal bInitialOwner As Long, ByVal lpName As String) As Long
Private Declare Function GetLastError Lib "kernel32" () As Long
Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long
Private Const ERROR_ALREADY_EXISTS = 183&
Private Declare Function EnumWindows Lib "user32" (ByVal lpEnumFunc As Long, ByVal lParam As Long) As Long
Private Declare Function IsWindowVisible Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function BringWindowToTop Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function SetForegroundWindow Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function GetClassName Lib "user32" Alias "GetClassNameA" (ByVal hWnd As Long, ByVal lpClassName As String, ByVal nMaxCount As Long) As Long
Private Declare Function GetProp Lib "user32" Alias "GetPropA" (ByVal hWnd As Long, ByVal lpString As String) As Long
Private Declare Function SetProp Lib "user32" Alias "SetPropA" (ByVal hWnd As Long, ByVal lpString As String, ByVal hData As Long) As Long
Private Declare Function RemoveProp Lib "user32" Alias "RemovePropA" (ByVal hWnd As Long, ByVal lpString As String) As Long
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    lpvDest As Any, lpvSource As Any, ByVal cbCopy As Long)
Private Declare Function SendMessageByLong Lib "user32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Const WM_SYSCOMMAND = &H112
Private Const SC_RESTORE = &HF120
Private Declare Function IsIconic Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function GetVersion Lib "kernel32" () As Long

' Change this line:
Public Const THISAPPID = "vbAcceleratorVBTRACER"

Private Type CommonControlsEx
    dwSize As Long
    dwICC As Long
End Type
Private Declare Function InitCommonControlsEx Lib "COMCTL32.DLL" (iccex As CommonControlsEx) As Boolean
Private Const ICC_BAR_CLASSES = &H4
Private Const ICC_COOL_CLASSES = &H400
Private Const ICC_USEREX_CLASSES = &H200& '// comboex
Private Const ICC_WIN95_CLASSES = &HFF&

Private m_hWndPrevious As Long
Private m_bInDevelopment As Boolean
Private m_hMutex As Long
Private m_hWnd As Long

Public g_cConfiguration As cConfiguration

Public Sub Main()
   
   On Error Resume Next
   ' Call InitCommonControls:
   Dim tIccex As CommonControlsEx
   With tIccex
       .dwSize = LenB(tIccex)
       .dwICC = ICC_BAR_CLASSES
   End With
   'We need to make this call to make sure the common controls are loaded
   InitCommonControlsEx tIccex
   On Error GoTo 0

   Set g_cConfiguration = New cConfiguration

   ' Check if this is the first instance:
   If (WeAreAlone(THISAPPID & "_APPLICATION_MUTEX")) Then
      
      ' If it is, then start the app:
      frmVBTrace.Show
      
   Else
            
      ' There is an existing instance.
      ' First try to find it:
      EnumerateWindows
      
      ' If we get it:
      If Not (m_hWndPrevious = 0) Then
         ' Try to activate the existing window:
         RestoreAndActivate m_hWndPrevious
      Else
         ' something has gone wrong...
      End If
   End If

End Sub
Private Function WeAreAlone(ByVal sMutex As String) As Boolean
   ' Don't call Mutex when in VBIDE because it will apply
   ' for the entire VB IDE session, not just the app's
   ' session.
   If InDevelopment Then
      WeAreAlone = Not (App.PrevInstance)
   Else
      ' Ensures we don't run a second instance even
      ' if the first instance is in the start-up phase
      m_hMutex = CreateMutex(ByVal 0&, 1, sMutex)
      If (Err.LastDllError = ERROR_ALREADY_EXISTS) Then
         CloseHandle m_hMutex
      Else
         WeAreAlone = True
      End If
   End If
End Function

Public Sub RestoreAndActivate(ByVal hWnd As Long)
   If (IsIconic(hWnd)) Then
      SendMessageByLong hWnd, WM_SYSCOMMAND, SC_RESTORE, 0
   End If
   ActivateWindow hWnd
End Sub

Public Sub TagWindow(ByVal hWnd As Long)
   ' Applies a window property to allow the window to
   ' be clearly identified.
   SetProp hWnd, THISAPPID & "_APPLICATION", 1
   m_hWnd = hWnd
End Sub

Private Function IsThisApp(ByVal hWnd As Long) As Boolean
   ' Check if the windows property is set for this
   ' window handle:
   If GetProp(hWnd, THISAPPID & "_APPLICATION") = 1 Then
      IsThisApp = True
   End If
End Function


Private Function EnumWindowsProc( _
        ByVal hWnd As Long, _
        ByVal lParam As Long _
    ) As Long
Dim bStop As Boolean
   ' Customised windows enumeration procedure.  Stops
   ' when it finds another application with the Window
   ' property set, or when all windows are exhausted.
   bStop = False
   If IsThisApp(hWnd) Then
      EnumWindowsProc = 0
      m_hWndPrevious = hWnd
   Else
      EnumWindowsProc = 1
   End If
End Function

Public Function EnumerateWindows() As Boolean
   ' Enumerate top-level windows:
   m_hWndPrevious = 0
   EnumWindows AddressOf EnumWindowsProc, 0
End Function

Public Sub ActivateWindow(ByVal lHwnd As Long)
    SetForegroundWindow lHwnd
End Sub
Public Function InDevelopment() As Boolean
   ' Debug.Assert code not run in an EXE.  Therefore
   ' m_bInDevelopment variable is never set.
   Debug.Assert InDevelopmentHack() = True
   InDevelopment = m_bInDevelopment
End Function
Private Function InDevelopmentHack() As Boolean
   ' .... '
   m_bInDevelopment = True
   InDevelopmentHack = m_bInDevelopment
End Function

Public Function EndApp()
   ' Call this to remove the Mutex.  It will be cleared
   ' anyway by windows, but this ensures it works.
   If (m_hMutex <> 0) Then
      CloseHandle m_hMutex
   End If
   m_hMutex = 0
   If (m_hWnd <> 0) Then
      RemoveProp m_hWnd, THISAPPID & "_APPLICATION"
      m_hWnd = 0
   End If

End Function

Public Function IsNt()
Dim lVer As Long
   lVer = GetVersion()
   IsNt = ((lVer And &H80000000) = 0)
End Function

Public Sub Test()
   'Forms(0).AddData "Hi Mum"
   Forms(0).Test
End Sub
