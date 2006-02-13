VERSION 5.00
Begin VB.UserControl pgConnect 
   BackColor       =   &H00FFFFFF&
   ClientHeight    =   3600
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4920
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   ScaleHeight     =   3600
   ScaleWidth      =   4920
   Begin VB.Timer timStatusText 
      Enabled         =   0   'False
      Interval        =   1
      Left            =   2520
      Top             =   3120
   End
   Begin VB.Timer Timer1 
      Interval        =   1
      Left            =   1080
      Top             =   3120
   End
   Begin VB.PictureBox picLogin 
      Appearance      =   0  'Flat
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   1695
      Left            =   0
      ScaleHeight     =   1695
      ScaleWidth      =   4695
      TabIndex        =   5
      Top             =   1080
      Width           =   4695
      Begin VB.TextBox txtNickName 
         Height          =   285
         Left            =   840
         TabIndex        =   1
         Top             =   0
         Width           =   3735
      End
      Begin VB.TextBox txtUser 
         Height          =   285
         Left            =   840
         TabIndex        =   2
         Top             =   360
         Width           =   3735
      End
      Begin VB.TextBox txtPass 
         Height          =   285
         IMEMode         =   3  'DISABLE
         Left            =   840
         PasswordChar    =   "*"
         TabIndex        =   3
         Top             =   720
         Width           =   3735
      End
      Begin VB.CommandButton cmdConnect 
         Caption         =   "&Connect"
         Height          =   375
         Left            =   0
         TabIndex        =   4
         Top             =   1080
         Width           =   1335
      End
      Begin VB.Label lblStatus 
         AutoSize        =   -1  'True
         BackStyle       =   0  'Transparent
         ForeColor       =   &H00000000&
         Height          =   195
         Left            =   1440
         TabIndex        =   9
         Top             =   1200
         Width           =   45
      End
      Begin VB.Label Label2 
         BackStyle       =   0  'Transparent
         Caption         =   "Nickname:"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   0
         TabIndex        =   8
         Top             =   40
         Width           =   1815
      End
      Begin VB.Label Label3 
         BackStyle       =   0  'Transparent
         Caption         =   "Username:"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   0
         TabIndex        =   7
         Top             =   380
         Width           =   855
      End
      Begin VB.Label Label4 
         BackStyle       =   0  'Transparent
         Caption         =   "Password:"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   0
         TabIndex        =   6
         Top             =   740
         Width           =   735
      End
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   $"pgConnect.ctx":0000
      ForeColor       =   &H00000000&
      Height          =   780
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   4830
      WordWrap        =   -1  'True
   End
End
Attribute VB_Name = "pgConnect"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
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
' $Id: pgConnect.ctl,v 1.1 2004/12/08 02:58:04 ziggythehamster Exp $
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


Private Sub cmdConnect_Click()
Timer1.Enabled = False
timStatusText.Enabled = True
StatusText = "Connecting to server..."
cmdConnect.Enabled = False
cmdConnect.Caption = "Connecting..."
txtUser.Enabled = False
txtPass.Enabled = False
txtNickName.Enabled = False
User = txtUser.Text
Pass = txtPass.Text
Nick = txtNickName.Text
Randomize Timer
Randomize
If Nick = "" Then Nick = "Remote" & Int(Rnd * 1000)
frmMain.Connect
End Sub

Private Sub Timer1_Timer()
If txtUser.Text <> "" And txtPass.Text <> "" Then cmdConnect.Enabled = True Else cmdConnect.Enabled = False
End Sub

Private Sub timStatusText_Timer()
lblStatus.Caption = StatusText
End Sub
Public Function DisplayName()
DisplayName = "Please Log In"
End Function
Private Sub UserControl_Resize()
On Error Resume Next
Label1.Width = ScaleWidth
txtNickName.Width = ScaleWidth - txtNickName.Left
picLogin.Width = ScaleWidth
picLogin.Top = Label1.Height + 80
txtUser.Width = ScaleWidth - txtUser.Left
txtPass.Width = ScaleWidth - txtPass.Left
lblStatus.Width = ScaleWidth - (cmdConnect.Left + cmdConnect.Width)
End Sub

Public Sub ResetControls()
StatusText = ""
Timer1.Enabled = True
timStatusText.Enabled = False
txtUser.Enabled = True
txtPass.Enabled = True
cmdConnect.Enabled = True
cmdConnect.Caption = "Connect"
txtNickName.Enabled = True
End Sub

Public Sub SetText(strText As String)
cmdConnect.Caption = strText
End Sub
