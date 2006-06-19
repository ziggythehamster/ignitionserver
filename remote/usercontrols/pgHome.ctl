VERSION 5.00
Begin VB.UserControl pgHome 
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
   Begin prjRemoteAdmin.ctlHoverMenu cmdLink 
      Height          =   255
      Left            =   600
      TabIndex        =   4
      Top             =   2160
      Width           =   1695
      _ExtentX        =   2990
      _ExtentY        =   450
      Caption         =   "Link to another server"
   End
   Begin prjRemoteAdmin.ctlHoverMenu cmdInfo 
      Height          =   255
      Left            =   600
      TabIndex        =   3
      Top             =   1800
      Width           =   1575
      _ExtentX        =   2778
      _ExtentY        =   450
      Caption         =   "View Server Statistics"
   End
   Begin prjRemoteAdmin.ctlHoverMenu cmdOpers 
      Height          =   255
      Left            =   600
      TabIndex        =   2
      Top             =   1440
      Width           =   2295
      _ExtentX        =   4048
      _ExtentY        =   450
      Caption         =   "Add/Delete/Edit IRC Operators"
   End
   Begin VB.Image Image4 
      Height          =   240
      Left            =   240
      Picture         =   "pgHome.ctx":0000
      Top             =   2160
      Width           =   240
   End
   Begin VB.Image Image3 
      Height          =   240
      Left            =   240
      Picture         =   "pgHome.ctx":038A
      Top             =   1800
      Width           =   240
   End
   Begin VB.Image Image2 
      Height          =   240
      Left            =   240
      Picture         =   "pgHome.ctx":0714
      Top             =   1440
      Width           =   240
   End
   Begin VB.Label Label2 
      BackStyle       =   0  'Transparent
      Caption         =   "I want to..."
      ForeColor       =   &H00000000&
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   1080
      Width           =   4575
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "Administration Home"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   15.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00000000&
      Height          =   615
      Left            =   840
      TabIndex        =   0
      Top             =   240
      Width           =   3855
   End
   Begin VB.Image Image1 
      Height          =   720
      Left            =   0
      Picture         =   "pgHome.ctx":0A9E
      Top             =   120
      Width           =   720
   End
End
Attribute VB_Name = "pgHome"
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
' $Id: pgHome.ctl,v 1.2 2004/12/27 02:26:42 ziggythehamster Exp $
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
DisplayName = "Welcome to " & ServerAddress
End Function

Private Sub cmdInfo_Click()
With frmMain
  .ShowPage .pgStats
End With
End Sub

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
