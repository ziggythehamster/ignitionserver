VERSION 5.00
Begin VB.UserControl pgStats 
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
   Begin VB.CommandButton cmdRefresh 
      Caption         =   "&Get Statistics"
      Height          =   375
      Left            =   120
      TabIndex        =   2
      Top             =   3120
      Width           =   1095
   End
   Begin VB.Timer timStats 
      Interval        =   1
      Left            =   4320
      Top             =   480
   End
   Begin VB.TextBox txtStats 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   9
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2055
      Left            =   120
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   1
      Top             =   960
      Width           =   4575
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "Server Statistics"
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
      Left            =   960
      TabIndex        =   0
      Top             =   240
      Width           =   3855
   End
   Begin VB.Image Image1 
      Height          =   720
      Left            =   120
      Picture         =   "pgStats.ctx":0000
      Top             =   120
      Width           =   720
   End
End
Attribute VB_Name = "pgStats"
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
' $Id: pgStats.ctl,v 1.1 2004/12/08 02:58:04 ziggythehamster Exp $
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


Private Sub cmdRefresh_Click()
StatsText = "Downloading statistics..."
frmMain.wsIRC.SendData "LUSERS" & vbCrLf
frmMain.wsIRC.SendData "STATS m" & vbCrLf
frmMain.wsIRC.SendData "STATS u" & vbCrLf
End Sub

Private Sub timStats_Timer()
txtStats.Text = StatsText
End Sub

Private Sub UserControl_Initialize()
StatsText = "Click 'Get Statistics' to get the statistics."
tmpStatsText = ""
End Sub

Public Function DisplayName()
DisplayName = "Server Statistics"
End Function

Private Sub UserControl_Resize()
On Error Resume Next
txtStats.Width = ScaleWidth - 300
cmdRefresh.Top = (ScaleHeight - 300) - cmdRefresh.Height
txtStats.Height = (cmdRefresh.Top - 100) - txtStats.Top
End Sub
