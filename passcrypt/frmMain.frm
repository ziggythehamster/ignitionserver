VERSION 5.00
Begin VB.Form frmMain 
   BackColor       =   &H00FFFFFF&
   BorderStyle     =   1  'Fixed Single
   Caption         =   "ignitionServer PassCrypt"
   ClientHeight    =   2685
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
   ScaleHeight     =   2685
   ScaleWidth      =   8055
   StartUpPosition =   3  'Windows Default
   Begin VB.Frame Frame1 
      BackColor       =   &H00FFFFFF&
      Caption         =   "ignitionServer PassCrypt"
      ForeColor       =   &H00000000&
      Height          =   1815
      Left            =   0
      TabIndex        =   1
      Top             =   840
      Width           =   8055
      Begin VB.CommandButton cmdClipboard 
         Caption         =   "&Copy to Clipboard"
         Height          =   375
         Left            =   6240
         TabIndex        =   7
         Top             =   1320
         Width           =   1695
      End
      Begin VB.TextBox txtMD5Enc 
         Height          =   285
         Left            =   1440
         Locked          =   -1  'True
         TabIndex        =   6
         Top             =   960
         Width           =   6495
      End
      Begin VB.TextBox txtPassword 
         Height          =   285
         Left            =   960
         TabIndex        =   4
         Top             =   600
         Width           =   6975
      End
      Begin VB.Label Label4 
         BackStyle       =   0  'Transparent
         Caption         =   "MD5 Encrypted:"
         Height          =   255
         Left            =   120
         TabIndex        =   5
         Top             =   960
         Width           =   1455
      End
      Begin VB.Label Label3 
         BackStyle       =   0  'Transparent
         Caption         =   "Password:"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   120
         TabIndex        =   3
         Top             =   600
         Width           =   735
      End
      Begin VB.Label Label2 
         BackStyle       =   0  'Transparent
         Caption         =   "This program generates encrypted passwords for use in ignitionServer."
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   120
         TabIndex        =   2
         Top             =   240
         Width           =   7815
      End
   End
   Begin VB.Image Image2 
      Height          =   720
      Left            =   80
      Picture         =   "frmMain.frx":2CFA
      Top             =   80
      Width           =   720
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "ignitionServer PassCrypt"
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
'ignitionServer PassCrypt is (C)  Keith Gable
'--------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'
'
' $Id: frmMain.frm,v 1.1 2004/06/28 20:50:57 ziggythehamster Exp $
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


Private Sub cmdClipboard_Click()
Clipboard.Clear
Clipboard.SetText txtMD5Enc.Text
End Sub

Private Sub txtPassword_Change()
txtMD5Enc.Text = modMD5.oMD5.MD5(txtPassword.Text)
End Sub
