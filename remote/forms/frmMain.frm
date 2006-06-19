VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Begin VB.Form frmMain 
   BackColor       =   &H00FFFFFF&
   Caption         =   "Administrate Your Server"
   ClientHeight    =   5835
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   8100
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
   ScaleHeight     =   5835
   ScaleWidth      =   8100
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer timWaitReset 
      Enabled         =   0   'False
      Interval        =   5000
      Left            =   7200
      Top             =   5400
   End
   Begin MSWinsockLib.Winsock wsIRC 
      Left            =   120
      Top             =   5400
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
   End
   Begin VB.PictureBox picConfigure 
      BackColor       =   &H80000002&
      BorderStyle     =   0  'None
      Height          =   255
      Left            =   6960
      MouseIcon       =   "frmMain.frx":2B82
      MousePointer    =   99  'Custom
      ScaleHeight     =   255
      ScaleWidth      =   1095
      TabIndex        =   7
      Top             =   0
      Width           =   1095
      Begin VB.Label lblConfigure 
         Alignment       =   1  'Right Justify
         AutoSize        =   -1  'True
         BackStyle       =   0  'Transparent
         Caption         =   "Configure..."
         BeginProperty Font 
            Name            =   "Tahoma"
            Size            =   8.25
            Charset         =   0
            Weight          =   400
            Underline       =   -1  'True
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H80000009&
         Height          =   195
         Left            =   120
         MouseIcon       =   "frmMain.frx":2CD4
         MousePointer    =   99  'Custom
         TabIndex        =   8
         Top             =   0
         Width           =   885
      End
   End
   Begin VB.Timer timHover 
      Interval        =   1
      Left            =   7680
      Top             =   5400
   End
   Begin VB.Frame fMenu 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Menu"
      ForeColor       =   &H00000000&
      Height          =   4935
      Left            =   0
      TabIndex        =   4
      Top             =   840
      Width           =   2535
      Begin MSComctlLib.TreeView tvMenu 
         Height          =   4575
         Left            =   120
         TabIndex        =   5
         Top             =   240
         Width           =   2295
         _ExtentX        =   4048
         _ExtentY        =   8070
         _Version        =   393217
         Indentation     =   529
         LabelEdit       =   1
         LineStyle       =   1
         Style           =   7
         Appearance      =   0
      End
   End
   Begin VB.Frame fSection 
      BackColor       =   &H00FFFFFF&
      ForeColor       =   &H00000000&
      Height          =   4935
      Left            =   2640
      TabIndex        =   3
      Top             =   840
      Width           =   5415
      Begin prjRemoteAdmin.pgUsers pgUsers 
         Height          =   4575
         Left            =   120
         TabIndex        =   11
         Top             =   240
         Width           =   5175
         _ExtentX        =   9128
         _ExtentY        =   8070
      End
      Begin prjRemoteAdmin.pgStats pgStats 
         Height          =   4575
         Left            =   120
         TabIndex        =   10
         Top             =   240
         Width           =   5175
         _ExtentX        =   9128
         _ExtentY        =   8070
      End
      Begin prjRemoteAdmin.pgHome pgHome 
         Height          =   4575
         Left            =   120
         TabIndex        =   9
         Top             =   240
         Width           =   5175
         _ExtentX        =   9128
         _ExtentY        =   8070
      End
      Begin prjRemoteAdmin.pgConnect pgConnect 
         Height          =   4575
         Left            =   120
         TabIndex        =   6
         Top             =   240
         Width           =   5175
         _ExtentX        =   9128
         _ExtentY        =   8070
      End
   End
   Begin VB.Label lblServer 
      BackStyle       =   0  'Transparent
      Caption         =   "Unknown"
      ForeColor       =   &H80000009&
      Height          =   255
      Left            =   1560
      TabIndex        =   2
      Top             =   480
      Width           =   4935
   End
   Begin VB.Label Label2 
      BackStyle       =   0  'Transparent
      Caption         =   "Server:"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H80000009&
      Height          =   255
      Left            =   840
      TabIndex        =   1
      Top             =   480
      Width           =   1215
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "Administrate Your Server"
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
      Top             =   120
      Width           =   4455
   End
   Begin VB.Image Image1 
      Height          =   720
      Left            =   0
      Picture         =   "frmMain.frx":2E26
      Top             =   0
      Width           =   720
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
'ignitionServer Remote is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>
'
' $Id: frmMain.frm,v 1.2 2004/12/27 02:26:42 ziggythehamster Exp $
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


Private Type POINTAPI   ' Mouse X,Y coordinates used in MouseMove
        X As Long
        Y As Long
End Type
Public IsLoggedIn As Boolean
Private Declare Function WindowFromPoint Lib "user32" (ByVal xPoint As Long, ByVal yPoint As Long) As Long
Private Declare Function GetCursorPos Lib "user32" (lpPoint As POINTAPI) As Long

Private Sub Form_Load()
With tvMenu.Nodes
.Add , , "Login", "Log In"
.Add , , "Quit", "Quit"
End With
ServerAddress = GetSetting("ignitionServer", "Remote Administration", "Server Address", "")
If Len(ServerAddress) = 0 Then
  frmConfigure.Show vbModal
End If
lblServer.Caption = ServerAddress
Call Form_Resize
ShowPage pgConnect
End Sub
Public Sub AddNodes()
With tvMenu.Nodes
.Add , , "Home", "Administration Home"
.Add , , "System", "System Information"
.Add "System", tvwChild, "Stats", "Statistics"
.Add , , "Users", "User Administration"
.Add "Users", tvwChild, "Opers", "Operator Management"
.Add "Users", tvwChild, "Kline", "Kill Line Management"
.Add "Users", tvwChild, "OnlineUsers", "Online Users"
'.Add "Users", tvwChild, "RegUsers", "Registered Users"
'.Add "Users", tvwChild, "Remote", "Remote Permissions"
.Add , , "Server", "Server Administration"
.Add "Server", tvwChild, "ServerSettings", "Server Settings"
.Add "Server", tvwChild, "DisplayName", "Server Display Name"
'.Add "Server", tvwChild, "IRCX", "IRCX Mode"
.Add "Server", tvwChild, "Security", "Security"
End With
End Sub
Private Sub Form_Resize()
On Error Resume Next
shTop.Width = ScaleWidth
lblServer.Width = ScaleWidth - lblServer.Left
fMenu.Height = ScaleHeight - shTop.Height - 60
fSection.Height = ScaleHeight - shTop.Height - 60
fSection.Width = ScaleWidth - fSection.Left - 60
tvMenu.Height = fMenu.Height - 400
picConfigure.Left = ScaleWidth - picConfigure.Width - 20
picConfigure.Width = lblConfigure.Width + 60
lblConfigure.Left = 20
picConfigure.Height = lblConfigure.Height + 60
lblConfigure.Top = 20
Call ResizePages
End Sub

Public Sub ResizePages()
On Error Resume Next
pgConnect.Width = fSection.Width - 400
pgConnect.Height = fSection.Height - 400
pgHome.Width = fSection.Width - 400
pgHome.Height = fSection.Height - 400
pgStats.Width = fSection.Width - 400
pgStats.Height = fSection.Height - 400
pgUsers.Width = fSection.Width - 400
pgUsers.Height = fSection.Height - 400
End Sub

Private Sub lblConfigure_Click()
Call Configure
End Sub

Private Sub picConfigure_Click()
Call Configure
End Sub

Private Sub picConfigure_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
picConfigure.BorderStyle = 1
Call Form_Resize
timHover.Enabled = True
End Sub

Private Sub timHover_Timer()
Dim pt As POINTAPI
GetCursorPos pt
If picConfigure.hWnd <> WindowFromPoint(pt.X, pt.Y) Then
    timHover.Enabled = False
    picConfigure.BorderStyle = 0
End If
End Sub
Public Sub Connect()
wsIRC.Close
tvMenu.Nodes.Clear
tvMenu.Nodes.Add , , "Connecting", "Connecting..."
wsIRC.Connect ServerAddress, 6667
End Sub
Public Sub Configure()
'called when you click configure
frmConfigure.Show
End Sub
Public Sub ShowPage(thePage As Variant)
On Error Resume Next
pgConnect.Visible = False
pgHome.Visible = False
pgStats.Visible = False
pgUsers.Visible = False
thePage.Visible = True
fSection.Caption = thePage.DisplayName
End Sub
Private Sub timWaitReset_Timer()
With tvMenu.Nodes
.Clear
.Add , , "Login", "Log In"
.Add , , "Quit", "Quit"
End With
ShowPage pgConnect
pgConnect.ResetControls
timWaitReset.Enabled = False
End Sub

Private Sub tvMenu_NodeClick(ByVal Node As MSComctlLib.Node)
Select Case Node.Key
  Case "Login"
    ShowPage pgConnect
  Case "Quit"
    End
  Case "Home"
    ShowPage pgHome
  Case "Stats"
    ShowPage pgStats
  Case "OnlineUsers"
    ShowPage pgUsers
End Select
End Sub

Private Sub wsIRC_Close()
tvMenu.Nodes.Clear
tvMenu.Nodes.Add , , "Disconnected", "Disconnected!"
pgConnect.SetText "Failed!"
ShowPage pgConnect
timWaitReset.Enabled = True
wsIRC.Close
End Sub

Private Sub wsIRC_Connect()
StatusText = "Connected! Authenticating..."
wsIRC.SendData "NICK " & Nick & vbCrLf
wsIRC.SendData "USER remoteadmin """ & wsIRC.LocalHostName & """ """ & ServerAddress & """ :ignitionServer Remote Administration" & vbCrLf
End Sub

Private Sub wsIRC_DataArrival(ByVal bytesTotal As Long)
    Dim strData As String
    Dim RestLine As String
    Dim IRCLine() As String
    Dim i As Long
    
    wsIRC.GetData strData, vbString
    If Len(strData) = 0 Then Exit Sub
    
    If Len(RestLine) > 0 Then
        strData = RestLine & strData
    End If
    
    IRCLine = Split(strData, Chr(10))
    
    If Right(strData, 1) = Chr(10) Or Right(strData, 1) = Chr(13) Then
        RestLine = ""
        For i = 0 To UBound(IRCLine)
            If IRCLine(i) <> "" Then
                'IRCLine(i) = Replace(IRCLine(i), Chr(22), "")
                IRCLine(i) = Replace(IRCLine(i), Chr(13), "")
                IRCLine(i) = Replace(IRCLine(i), Chr(10), "")
                ProcessData IRCLine(i)
            End If
        Next i
    Else
        RestLine = IRCLine(UBound(IRCLine))
        For i = 0 To UBound(IRCLine) - 1
            If IRCLine(i) <> "" Then
                'IRCLine(i) = Replace(IRCLine(i), Chr(22), "")
                IRCLine(i) = Replace(IRCLine(i), Chr(13), "")
                IRCLine(i) = Replace(IRCLine(i), Chr(10), "")
                ProcessData IRCLine(i)
            End If
        Next i
    End If
    ReDim IRCLine(0)
    strData = vbNullString
End Sub

Private Sub wsIRC_Error(ByVal Number As Integer, Description As String, ByVal Scode As Long, ByVal Source As String, ByVal HelpFile As String, ByVal HelpContext As Long, CancelDisplay As Boolean)
wsIRC.Close
tvMenu.Nodes.Clear
tvMenu.Nodes.Add , , "Error", "Error!"
StatusText = "Error " & Number & ": " & Description
pgConnect.SetText "Error!"
ShowPage pgConnect
timWaitReset.Enabled = True
End Sub

Public Sub ProcessData(sData As String)
DebugLog sData
On Error Resume Next
'If Len(sData) = 0 Then Exit Sub
If Split(sData, " ")(0) = "PING" Then
  wsIRC.SendData "PONG " & Split(sData, " ")(1) & vbCrLf
  Exit Sub
End If
If Split(sData, " ")(0) = "ERROR" Then
  wsIRC.Close
  tvMenu.Nodes.Clear
  tvMenu.Nodes.Add , , "Error", "Error!"
  StatusText = "Error: " & RightOf(sData, ":")
  pgConnect.SetText "Error!"
  ShowPage pgConnect
  timWaitReset.Enabled = True
End If

Dim tmpItem As ListItem
Set tmpItem = Nothing

Select Case UCase(Split(sData, " ")(1))
  'numerics
  Case "001":
    IsLoggedIn = False
    StatusText = "Logging in..."
  Case "381":
    StatusText = "Logged in!"
    tvMenu.Nodes.Clear
    Call AddNodes
    Call ShowPage(pgHome)
  Case "251":
    tmpStatsText = "User Information" & vbCrLf & _
                   "================" & vbCrLf & vbCrLf
    tmpStatsText = tmpStatsText & RightOf(sData, ":") & vbCrLf
  Case "252":
    tmpStatsText = tmpStatsText & "There are " & Split(sData, " ")(3) & " IRC Operator(s) online" & vbCrLf
  Case "254":
    tmpStatsText = tmpStatsText & "There are " & Split(sData, " ")(3) & " channel(s)" & vbCrLf
  Case "255":
    tmpStatsText = tmpStatsText & Replace(RightOf(sData, ":"), "I have", "There are") & " connected" & vbCrLf
  Case "265":
    tmpStatsText = tmpStatsText & RightOf(sData, ":") & vbCrLf
  Case "266":
    If IsLoggedIn = True Then
      tmpStatsText = tmpStatsText & RightOf(sData, ":") & vbCrLf
      tmpStatsText = tmpStatsText & vbCrLf & vbCrLf & vbCrLf & vbCrLf
      tmpStatsText = tmpStatsText & "Command Usage Information" & vbCrLf & _
                                    "=========================" & vbCrLf & vbCrLf
    Else
      DebugLog "Sending Login Command..."
      wsIRC.SendData "IRCX" & vbCrLf
      wsIRC.SendData "OPER " & User & " " & Pass & vbCrLf
      IsLoggedIn = True
    End If
  Case "212":
    tmpStatsText = tmpStatsText & Split(RightOf(sData, ":"), " ")(0) & ": Used " & Split(RightOf(sData, ":"), " ")(1) & " time(s) (" & Round((CInt(Split(RightOf(sData, ":"), " ")(2)) / 1024), 3) & "kb)" & vbCrLf
    BandwidthUsage = BandwidthUsage + (CInt(Split(RightOf(sData, ":"), " ")(2)) / 1024)
  Case "219":
    If Split(sData, " ")(3) = "m" Then
      tmpStatsText = tmpStatsText & "Total Bandwidth Usage: " & Round(BandwidthUsage, 3) & "kb" & vbCrLf
      BandwidthUsage = 0
    End If
  Case "242":
    tmpStatsText = tmpStatsText & vbCrLf & vbCrLf & vbCrLf & vbCrLf
    tmpStatsText = tmpStatsText & "Uptime Information" & vbCrLf & _
                                  "==================" & vbCrLf & vbCrLf
    tmpStatsText = tmpStatsText & "Uptime: " & RightOf(sData, ":") & vbCrLf
  Case "250":
    tmpStatsText = tmpStatsText & RightOf(sData, ":")
    StatsText = tmpStatsText
  Case "311":
    Set tmpItem = pgUsers.AddUser(CStr(Split(sData, " ")(3)))
    tmpItem.ListSubItems.Add , "ident", CStr(Split(sData, " ")(3) & "!" & Split(sData, " ")(4) & "@" & Split(sData, " ")(5))
    tmpItem.ListSubItems.Add , "ircop", "No"
    tmpItem.ListSubItems.Add , "channels", "None"
  Case "319":
    Set tmpItem = pgUsers.GetUser(pgUsers.GetCount)
    tmpItem.ListSubItems(tmpItem.ListSubItems.Count).Text = RightOf(sData, ":")
  Case "313":
    Set tmpItem = pgUsers.GetUser(pgUsers.GetCount)
    tmpItem.ListSubItems(tmpItem.ListSubItems.Count - 1).Text = "Yes"
  Case "318":
    pgUsers.SetSorted True
  Case "491":
    wsIRC.SendData "QUIT :" & vbCrLf
    wsIRC.Close
    tvMenu.Nodes.Clear
    tvMenu.Nodes.Add , , "Error", "Error!"
    StatusText = "Error: " & RightOf(sData, ":")
    pgConnect.SetText "Error!"
    ShowPage pgConnect
    timWaitReset.Enabled = True
End Select
Set tmpItem = Nothing
sData = ""
End Sub
Function RightOf(strData As String, strDelim As String) As String
    If Left(strData, 1) = ":" Then strData = Right(strData, Len(strData) - 1)
    Dim intPos As Integer
    intPos = InStr(strData, strDelim)
    
    If intPos Then
        RightOf = Mid(strData, intPos + 1, Len(strData) - intPos)
    Else
        RightOf = strData
    End If
End Function
