VERSION 5.00
Begin VB.Form frmConfigure 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Configure Remote Administration"
   ClientHeight    =   4695
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   6000
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "frmConfigure.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   4695
   ScaleWidth      =   6000
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   375
      Left            =   3600
      TabIndex        =   8
      Top             =   4200
      Width           =   1095
   End
   Begin VB.Timer timEnable 
      Interval        =   1
      Left            =   120
      Top             =   4200
   End
   Begin VB.CommandButton cmdOK 
      Caption         =   "&OK"
      Default         =   -1  'True
      Enabled         =   0   'False
      Height          =   375
      Left            =   4800
      TabIndex        =   6
      Top             =   4200
      Width           =   1095
   End
   Begin VB.TextBox txtServer 
      Height          =   285
      Left            =   1440
      TabIndex        =   5
      Top             =   2160
      Width           =   4455
   End
   Begin VB.Frame Frame1 
      Caption         =   "ignitionServer Remote Administration"
      Enabled         =   0   'False
      Height          =   1335
      Left            =   -120
      TabIndex        =   3
      Top             =   3960
      Width           =   6255
   End
   Begin VB.Label Label5 
      BackStyle       =   0  'Transparent
      Caption         =   $"frmConfigure.frx":0902
      ForeColor       =   &H80000017&
      Height          =   975
      Left            =   240
      TabIndex        =   7
      Top             =   2760
      Width           =   5535
   End
   Begin VB.Shape Shape2 
      FillColor       =   &H80000018&
      FillStyle       =   0  'Solid
      Height          =   1215
      Left            =   120
      Top             =   2640
      Width           =   5775
   End
   Begin VB.Label Label4 
      Caption         =   "Server Address:"
      Height          =   255
      Left            =   120
      TabIndex        =   4
      Top             =   2160
      Width           =   1455
   End
   Begin VB.Label Label3 
      Caption         =   $"frmConfigure.frx":0A62
      Height          =   975
      Left            =   120
      TabIndex        =   2
      Top             =   960
      Width           =   5775
   End
   Begin VB.Image Image1 
      Height          =   735
      Left            =   5220
      Picture         =   "frmConfigure.frx":0B55
      Top             =   60
      Width           =   735
   End
   Begin VB.Label Label2 
      BackStyle       =   0  'Transparent
      Caption         =   "Configure general remote settings"
      ForeColor       =   &H00000000&
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   360
      Width           =   4335
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "Configuration"
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
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   2055
   End
   Begin VB.Shape Shape1 
      FillColor       =   &H00FFFFFF&
      FillStyle       =   0  'Solid
      Height          =   855
      Left            =   -480
      Top             =   0
      Width           =   6975
   End
End
Attribute VB_Name = "frmConfigure"
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
' $Id: frmConfigure.frm,v 1.2 2004/12/27 02:26:42 ziggythehamster Exp $
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


Private Sub cmdCancel_Click()
Unload Me
End Sub

Private Sub cmdOK_Click()
SaveSetting "ignitionServer", "Remote Administration", "Server Address", txtServer.Text
ServerAddress = txtServer.Text
frmMain.lblServer.Caption = ServerAddress
Unload Me
End Sub

Private Sub Form_Load()
txtServer.Text = ServerAddress
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
If Len(ServerAddress) = 0 Then End
End Sub

Private Sub timEnable_Timer()
If Len(txtServer.Text) > 0 Then cmdOK.Enabled = True Else cmdOK.Enabled = False
End Sub
