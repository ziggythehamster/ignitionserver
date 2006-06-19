VERSION 5.00
Begin VB.Form frmMain 
   BackColor       =   &H00FFFFFF&
   BorderStyle     =   1  'Fixed Single
   Caption         =   "ignitionServer Monitor"
   ClientHeight    =   2625
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   8055
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "frmMain.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   Picture         =   "frmMain.frx":19822
   ScaleHeight     =   2625
   ScaleWidth      =   8055
   StartUpPosition =   3  'Windows Default
   Begin prjMonitor.ctlHoverMenu btnAdvanced 
      Height          =   255
      Left            =   4800
      TabIndex        =   12
      Top             =   2280
      Width           =   1455
      _ExtentX        =   2566
      _ExtentY        =   450
      Caption         =   "Advanced Settings"
   End
   Begin VB.Timer timLusers 
      Interval        =   5000
      Left            =   6720
      Top             =   840
   End
   Begin prjMonitor.ctlHoverMenu btnMoreInfo 
      Height          =   255
      Left            =   2760
      TabIndex        =   9
      Top             =   960
      Visible         =   0   'False
      Width           =   855
      _ExtentX        =   1508
      _ExtentY        =   450
      Caption         =   "More Info"
   End
   Begin VB.Timer timPing 
      Interval        =   65535
      Left            =   6360
      Top             =   0
   End
   Begin VB.Timer timFRetry 
      Interval        =   5000
      Left            =   6720
      Top             =   0
   End
   Begin VB.CheckBox cAutomaticIS 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Start automatically"
      ForeColor       =   &H00000000&
      Height          =   255
      Left            =   2880
      TabIndex        =   8
      ToolTipText     =   "Check this box to make ignitionServer start when the ignitionServer Monitor is started."
      Top             =   1440
      Width           =   1695
   End
   Begin VB.CheckBox cStartup 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Start with Windows"
      ForeColor       =   &H00000000&
      Height          =   255
      Left            =   6360
      TabIndex        =   7
      ToolTipText     =   "Check this box to automatically start the ignitionServer Monitor when your system starts."
      Top             =   2280
      Width           =   1695
   End
   Begin VB.Timer timTray 
      Interval        =   1
      Left            =   7200
      Top             =   0
   End
   Begin VB.PictureBox picTray 
      BorderStyle     =   0  'None
      Height          =   255
      Left            =   7800
      Picture         =   "frmMain.frx":33044
      ScaleHeight     =   255
      ScaleWidth      =   255
      TabIndex        =   6
      Top             =   0
      Visible         =   0   'False
      Width           =   255
   End
   Begin VB.Timer timServer 
      Interval        =   250
      Left            =   7080
      Top             =   840
   End
   Begin prjMonitor.ctlHoverMenu btnStart 
      Height          =   255
      Left            =   960
      TabIndex        =   5
      Top             =   1440
      Width           =   375
      _ExtentX        =   661
      _ExtentY        =   450
      Caption         =   "Start"
   End
   Begin prjMonitor.ctlHoverMenu btnRestart 
      Height          =   255
      Left            =   1440
      TabIndex        =   10
      Top             =   1440
      Visible         =   0   'False
      Width           =   615
      _ExtentX        =   1085
      _ExtentY        =   450
      Caption         =   "Restart"
   End
   Begin prjMonitor.ctlHoverMenu btnRehash 
      Height          =   255
      Left            =   2140
      TabIndex        =   11
      Top             =   1440
      Visible         =   0   'False
      Width           =   615
      _ExtentX        =   1085
      _ExtentY        =   450
      Caption         =   "Rehash"
   End
   Begin VB.Label Label3 
      BackStyle       =   0  'Transparent
      Caption         =   "This software currently cannot be monitored."
      ForeColor       =   &H00C0C0C0&
      Height          =   255
      Left            =   960
      TabIndex        =   4
      Top             =   2040
      Width           =   4575
   End
   Begin VB.Label Label2 
      BackStyle       =   0  'Transparent
      Caption         =   "ignitionServices"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00C0C0C0&
      Height          =   255
      Left            =   960
      TabIndex        =   3
      Top             =   1800
      Width           =   2655
   End
   Begin VB.Image Image3 
      Height          =   720
      Left            =   120
      Picture         =   "frmMain.frx":4C866
      Top             =   1800
      Width           =   720
   End
   Begin VB.Image Image2 
      Height          =   720
      Left            =   80
      Picture         =   "frmMain.frx":4D730
      Top             =   80
      Width           =   720
   End
   Begin VB.Label lblServerDesc 
      BackStyle       =   0  'Transparent
      Caption         =   "Querying status..."
      ForeColor       =   &H00000000&
      Height          =   255
      Left            =   960
      TabIndex        =   2
      Top             =   1200
      Width           =   6975
   End
   Begin VB.Label lblServerTitle 
      BackStyle       =   0  'Transparent
      Caption         =   "ignitionServer 0.3.7"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00000000&
      Height          =   255
      Left            =   960
      TabIndex        =   1
      Top             =   960
      Width           =   1695
   End
   Begin VB.Image Image1 
      Height          =   720
      Left            =   120
      Picture         =   "frmMain.frx":4F3FA
      Top             =   960
      Width           =   720
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "ignitionServer Monitor"
      BeginProperty Font 
         Name            =   "Franklin Gothic Medium"
         Size            =   15.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H80000009&
      Height          =   495
      Left            =   840
      TabIndex        =   0
      Top             =   200
      Width           =   4455
   End
   Begin VB.Shape shTop 
      BorderStyle     =   0  'Transparent
      FillColor       =   &H80000002&
      FillStyle       =   0  'Solid
      Height          =   855
      Left            =   0
      Top             =   0
      Width           =   8175
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'ignitionServer Monitor is (C)  Keith Gable
'------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'
'
' $Id: frmMain.frm,v 1.18 2004/12/08 22:16:58 ziggythehamster Exp $
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
Option Explicit
Public IsMisconfigured As Boolean
Public StaticData As String
Private Declare Function Shell_NotifyIcon Lib "shell32" Alias "Shell_NotifyIconA" (ByVal dwMessage As Long, lpData As NOTIFYICONDATA) As Long
Private Type NOTIFYICONDATA
    cbSize As Long
    hwnd As Long
    uID As Long
    uFlags As Long
    uCallbackMessage As Long
    hIcon As Long
    szTip As String * 64
End Type
Public InTray As Boolean

'A bunch of neccesary constants
Private Const NIM_ADD As Long = &H0
Private Const NIM_DELETE As Long = &H2
Private Const NIM_MODIFY As Long = &H1
Private Const NIF_MESSAGE As Long = &H1
Private Const NIF_ICON As Long = &H2
Private Const NIF_TIP As Long = &H4
Private Const WM_LBUTTONDOWN As Long = &H201
Private Const WM_LBUTTONDBLCLK As Long = &H203
Private Const WM_RBUTTONUP As Long = &H205

Private nidIcon As NOTIFYICONDATA
Public WithEvents sckServer As CSocketMaster
Attribute sckServer.VB_VarHelpID = -1

Private Sub btnAdvanced_Click()
frmAdvanced.Show
End Sub

Private Sub btnMoreInfo_Click()
frmMoreInfo.Show
End Sub

Private Sub btnRehash_Click()
  If Dir(App.Path & "\control.exe") = vbNullString Then
    MsgBox "ignitionServer cannot be rehashed; the commandline controller (control.exe) is missing."
    Exit Sub
  End If
  lblServerDesc.Caption = "Reloading ircx.conf..."
  btnStart.Caption = ""
  btnRestart.Visible = False
  btnMoreInfo.Visible = False
  btnRehash.Visible = False
  cAutomaticIS.Left = 960
  DoEvents
  Call Shell(App.Path & "\control.exe -p " & GetSetting("ignitionServer", "Monitor", "Server Port", "6667") & " -rehash")
  IsMisconfigured = False
End Sub

Private Sub btnRestart_Click()
  If Dir(App.Path & "\control.exe") = vbNullString Then
    MsgBox "ignitionServer cannot be restarted; the commandline controller (control.exe) is missing."
    Exit Sub
  End If
  lblServerDesc.Caption = "Restarting ignitionServer..."
  btnStart.Caption = ""
  btnRestart.Visible = False
  btnMoreInfo.Visible = False
  btnRehash.Visible = False
  cAutomaticIS.Left = 960
  DoEvents
  Call Shell(App.Path & "\control.exe -p " & GetSetting("ignitionServer", "Monitor", "Server Port", "6667") & " -restart")
  IsMisconfigured = False
End Sub

Private Sub btnStart_Click()
sckServer.CloseSck
Select Case btnStart.Caption
  Case "Start"
    btnStart.Caption = ""
    If Dir(App.Path & "\control.exe") = vbNullString Then
      MsgBox "ignitionServer cannot be started; the commandline controller (control.exe) is missing."
      Exit Sub
    End If
    Call Shell(App.Path & "\control.exe -start")
    IsMisconfigured = False
  Case "Stop"
    btnStart.Caption = ""
    If Dir(App.Path & "\control.exe") = vbNullString Then
      MsgBox "ignitionServer cannot be stopped; the commandline controller (control.exe) is missing."
      Exit Sub
    End If
    Call Shell(App.Path & "\control.exe -p " & GetSetting("ignitionServer", "Monitor", "Server Port", "6667") & " -stop")
End Select
End Sub

Private Sub cAutomaticIS_Click()
Dim c As New cRegistry
Dim w As Long
If cAutomaticIS.Value = vbChecked Then
  With c
    .ClassKey = HKEY_LOCAL_MACHINE
    .SectionKey = "Software\The Ignition Project\ignitionServer Monitor"
    .ValueKey = "Autostart ignitionServer"
    .ValueType = REG_DWORD
    .Value = 1
  End With
Else
  With c
  .ClassKey = HKEY_LOCAL_MACHINE
  .SectionKey = "Software\The Ignition Project\ignitionServer Monitor"
  .ValueKey = "Autostart ignitionServer"
  .ValueType = REG_DWORD
  w = .Value
  End With
  If w = 1 Then
    With c
      .ClassKey = HKEY_LOCAL_MACHINE
      .SectionKey = "Software\The Ignition Project\ignitionServer Monitor"
      .ValueKey = "Autostart ignitionServer"
      .ValueType = REG_DWORD
      .Value = 0
    End With
  End If
End If
End Sub

Private Sub cStartup_Click()
Dim c As New cRegistry
Dim w As String
Dim EXEN As String
If cStartup.Value = vbChecked Then
  Debug.Print "** run"
  
  If UCase$(Right(App.EXEName, 4)) <> ".EXE" Then
    EXEN = App.EXEName & ".exe"
  Else
    EXEN = App.EXEName
  End If
  
  With c
    .ClassKey = HKEY_LOCAL_MACHINE
    .SectionKey = "Software\Microsoft\Windows\CurrentVersion\Run"
    .ValueKey = "ISMonitor"
    .ValueType = REG_SZ
    .Value = Chr(34) & App.Path & "\" & EXEN & Chr(34) & " /tray"
  End With
Else
  Debug.Print "** no run"
  With c
  .ClassKey = HKEY_LOCAL_MACHINE
  .SectionKey = "Software\Microsoft\Windows\CurrentVersion\Run"
  .ValueKey = "ISMonitor"
  .ValueType = REG_SZ
  w = .Value
  End With
  If Len(w) > 0 Then
    With c
      .ClassKey = HKEY_LOCAL_MACHINE
      .SectionKey = "Software\Microsoft\Windows\CurrentVersion\Run"
      .ValueKey = "ISMonitor"
      .ValueType = REG_SZ
      .DeleteValue
    End With
  End If
End If
End Sub

Private Sub Form_Load()
On Error Resume Next
If App.PrevInstance = True Then End
If Command = "/tray" Then Me.WindowState = 1
Set sckServer = New CSocketMaster
Dim c As New cRegistry
Dim w As String
Dim x As Long
With c
  .ClassKey = HKEY_LOCAL_MACHINE
  .SectionKey = "Software\Microsoft\Windows\CurrentVersion\Run"
  .ValueKey = "ISMonitor"
  .ValueType = REG_SZ
  w = .Value
End With
Err.Clear
Debug.Print "'" & w & "'"
If Len(w) = 0 Then
  cStartup.Value = vbUnchecked
Else
  cStartup.Value = vbChecked
End If
'now read the registry and see if the monitor should autostart stuff
With c
  .ClassKey = HKEY_LOCAL_MACHINE
  .SectionKey = "Software\The Ignition Project\ignitionServer Monitor"
  .ValueKey = "Autostart ignitionServer"
  .ValueType = REG_DWORD
  x = .Value
End With
Err.Clear
If x = 1 Then
  btnStart.Caption = ""
  Call Shell(App.Path & "\control.exe -start")
  cAutomaticIS.Value = vbChecked
End If
frmAdvanced.txtServerAddress.Text = GetSetting("ignitionServer", "Monitor", "Server Address", "127.0.0.1")
frmAdvanced.txtPort.Text = GetSetting("ignitionServer", "Monitor", "Server Port", "6667")
frmAdvanced.Hide
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
Unload frmMoreInfo
Unload frmAdvanced
End
End Sub


Private Sub picTray_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
On Error Resume Next
Select Case CLng(x \ Screen.TwipsPerPixelX)
      Case WM_LBUTTONDBLCLK
        WindowState = 0
        Show
      Case WM_RBUTTONUP
        WindowState = 0
        Show
End Select
End Sub

Private Sub sckServer_Connect()
Randomize Timer
sckServer.SendData "NICK Monitor" & Int(Rnd * 1000) & vbCrLf
sckServer.SendData "USER monitor ""localhost"" ""localhost"" :ignitionServer Monitor" & vbCrLf
End Sub

Private Sub sckServer_DataArrival(ByVal bytesTotal As Long)
Dim tmpString As String
Dim tmpSplitLF() As String
Dim tmpSplit() As String
Dim A As Long
sckServer.GetData tmpString, vbString
InternalDebug tmpString
tmpString = Replace(tmpString, vbCrLf, vbLf)
tmpString = Replace(tmpString, vbCr, vbLf)
tmpSplitLF = Split(tmpString, vbLf)
For A = LBound(tmpSplitLF) To UBound(tmpSplitLF)
  tmpSplit = Split(tmpSplitLF(A), " ")
  If Len(tmpSplitLF(A)) = 0 Then GoTo NextLine
 
  If UCase$(tmpSplit(0)) = "PING" Then
    sckServer.SendData "PONG " & tmpSplit(1) & vbCrLf
    InternalDebug "Sent: PONG " & tmpSplit(1)
  ElseIf UCase$(tmpSplit(0)) = "ERROR" Then
    If InStr(1, tmpString, "Server Misconfigured") <> 0 Then
      IsMisconfigured = True
    Else
      lblServerDesc.Caption = "Monitor was disconnected. Reconnecting..."
    End If
    sckServer.CloseSck
  End If
  Select Case UCase$(tmpSplit(1))
    Case "001"
      IsMisconfigured = False
      sckServer.SendData "STATS u" & vbCrLf
    Case "004"
      ':ignition.servebeer.com 004 Monitor273 ignition.servebeer.com ignitionServer-0.3.6 bcdeikoprswxzBCDEHKLNOPRSWZ bhiklmnopqrstuvxzOR
      ':ignition.servebeer.com 005 Monitor273 IRCX CHANTYPES=# CHANLIMIT=#:10 NICKLEN=32 PREFIX=(qov).@+ CHANMODES=b,k,l,himnopqrstuvxzOR NETWORK=Ziggy's_Test_Server CASEMAPPING=ascii CHARSET=ascii MAXTARGETS=5 MAXCLONES=5 RFC1459 :are supported by this server
      StaticData = StaticData & "Server: " & tmpSplit(3) & vbCrLf
      StaticData = StaticData & "Version: " & tmpSplit(4) & vbCrLf
    Case "251"
      With frmMoreInfo.txtMoreInfo
        .Text = StaticData & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "252"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & tmpSplit(3) & " " & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "253"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & tmpSplit(3) & " " & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "254"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & tmpSplit(3) & " " & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "255"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "265"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "266"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "242"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & "Uptime: " & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "250"
      With frmMoreInfo.txtMoreInfo
        .Text = .Text & RightOf(tmpSplitLF(A), ":") & vbCrLf
      End With
    Case "JOIN"
      'we don't want the monitor in any channels, sheesh!
      ':Monitor59!monitor@localhost JOIN :#Lobby
      sckServer.SendData "PART " & RightOf(tmpSplitLF(A), ":") & " :ignitionServer Monitor" & vbCrLf
  End Select
NextLine:
Next A
End Sub
Function RightOf(strData As String, strDelim As String) As String
    Dim tmpData As String
    tmpData = strData
    If Left(tmpData, 1) = ":" Then tmpData = Right(tmpData, Len(tmpData) - 1)
    Dim intPos As Integer
    intPos = InStr(tmpData, strDelim)
    
    If intPos Then
        RightOf = Mid(tmpData, intPos + 1, Len(tmpData) - intPos)
    Else
        RightOf = tmpData
    End If
End Function
Public Sub InternalDebug(strText As String)
Dim F As Long
F = FreeFile
'Open App.Path & "\monitor.log" For Append As F
'Print #F, "[" & Now & "] " & strText
'Close #F
Debug.Print strText
End Sub

Private Sub sckServer_Error(ByVal Number As Integer, Description As String, ByVal sCode As Long, ByVal Source As String, ByVal HelpFile As String, ByVal HelpContext As Long, CancelDisplay As Boolean)
sckServer.CloseSck
InternalDebug "Error " & Number & " - " & Description
CancelDisplay = True
End Sub

Private Sub timFRetry_Timer()
'this is run on a 5s interval
'if the socket's state <> connected, close it
'timServer will recognize this change and
'automagically try reconnecting
If sckServer.State <> sckConnected Then sckServer.CloseSck
End Sub

Private Sub timLusers_Timer()
If sckServer.State = sckConnected Then
  sckServer.SendData "LUSERS" & vbCrLf
  sckServer.SendData "STATS u" & vbCrLf
End If
End Sub

Private Sub timPing_Timer()
If sckServer.State = sckConnected Then
  sckServer.SendData "PING :localhost" & vbCrLf
End If
End Sub

Private Sub timServer_Timer()
If sckServer.State = sckClosed Then
  If IsMisconfigured Then
    lblServerDesc.Caption = "ignitionServer is misconfigured. Please see ircx.conf in the ignitionServer folder."
    btnStart.Caption = "Start"
  Else
    lblServerDesc.Caption = "ignitionServer is offline."
    btnStart.Caption = "Start"
  End If
  btnMoreInfo.Visible = False
  btnRestart.Visible = False
  btnRehash.Visible = False
  cAutomaticIS.Left = 1440
  sckServer.CloseSck
  sckServer.Connect GetSetting("ignitionServer", "Monitor", "Server Address", "127.0.0.1"), GetSetting("ignitionServer", "Monitor", "Server Port", "6667") 'need a UI to change this
ElseIf sckServer.State = sckConnected Then
  If IsMisconfigured Then
    lblServerDesc.Caption = "ignitionServer is misconfigured. Please see ircx.conf in the ignitionServer folder."
    btnStart.Caption = "Start"
    btnMoreInfo.Visible = False
    btnRestart.Visible = False
    btnRehash.Visible = False
    cAutomaticIS.Left = 1440
    sckServer.CloseSck
  Else
    lblServerDesc.Caption = "ignitionServer is up and running!"
    btnRestart.Visible = True
    cAutomaticIS.Left = 2880
    btnStart.Caption = "Stop"
    btnMoreInfo.Visible = True
    btnRehash.Visible = True
  End If
End If
DoEvents
End Sub

Private Sub timTray_Timer()
If WindowState = 1 Then
  'they minimized
  Dim Handle As Long
  With nidIcon
      .cbSize = Len(nidIcon)
      .hwnd = frmMain.picTray.hwnd
      .uFlags = NIF_ICON Or NIF_TIP Or NIF_MESSAGE
      .uCallbackMessage = WM_LBUTTONDOWN
      .hIcon = picTray.Picture.Handle
      .szTip = "ignitionServer Monitor" & vbNullChar
  End With
  'add the icon to the tray
  Shell_NotifyIcon NIM_ADD, nidIcon
  InTray = True
  DoEvents
  Hide
  Exit Sub
End If
If WindowState <> 1 And InTray = True Then
  Shell_NotifyIcon NIM_DELETE, nidIcon
  Me.Hide
  Me.Show
  DoEvents
  InTray = False
  Me.SetFocus
End If
DoEvents
End Sub
