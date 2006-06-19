VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.UserControl pgUsers 
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
   Begin VB.CommandButton cmdKill 
      Caption         =   "Kill Selected"
      Height          =   375
      Left            =   1320
      TabIndex        =   3
      Top             =   3120
      Width           =   1095
   End
   Begin VB.CommandButton cmdRefresh 
      Caption         =   "Get Users"
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   3120
      Width           =   1095
   End
   Begin MSComctlLib.ListView lvUsers 
      Height          =   2055
      Left            =   120
      TabIndex        =   0
      Top             =   960
      Width           =   4575
      _ExtentX        =   8070
      _ExtentY        =   3625
      View            =   3
      LabelEdit       =   1
      LabelWrap       =   -1  'True
      HideSelection   =   -1  'True
      AllowReorder    =   -1  'True
      FullRowSelect   =   -1  'True
      GridLines       =   -1  'True
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      NumItems        =   4
      BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         Key             =   "nick"
         Text            =   "Nickname"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Key             =   "ident"
         Text            =   "Identity"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(3) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   2
         Key             =   "ircop"
         Text            =   "IRC Operator"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(4) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   3
         Key             =   "channels"
         Text            =   "Channels"
         Object.Width           =   2540
      EndProperty
   End
   Begin VB.Image Image1 
      Height          =   720
      Left            =   120
      Picture         =   "pgUsers.ctx":0000
      Top             =   120
      Width           =   720
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "Online Users"
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
      TabIndex        =   2
      Top             =   240
      Width           =   3855
   End
End
Attribute VB_Name = "pgUsers"
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
' $Id: pgUsers.ctl,v 1.1 2004/12/08 02:58:04 ziggythehamster Exp $
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

Private Sub cmdKill_Click()
On Error Resume Next
Dim NickToKill As String
Dim tmpResponse As Long
NickToKill = lvUsers.SelectedItem.Text
If NickToKill <> "" Then
  tmpResponse = MsgBox("Are you sure you want to forcibly remove '" & NickToKill & "' from the chat network?", vbYesNo Or vbQuestion)
  If tmpResponse = vbYes Then
    frmMain.wsIRC.SendData "KILL " & NickToKill & " :Killed by Remote Administrator (" & Now & ")" & vbCrLf
    lvUsers.ListItems.Remove lvUsers.SelectedItem.Index
  End If
End If
End Sub

Private Sub cmdRefresh_Click()
lvUsers.ListItems.Clear
lvUsers.Sorted = False
frmMain.wsIRC.SendData "WHOIS *" & vbCrLf
End Sub
Private Sub UserControl_Resize()
On Error Resume Next
lvUsers.Width = ScaleWidth - 300
cmdRefresh.Top = (ScaleHeight - 300) - cmdRefresh.Height
lvUsers.Height = (cmdRefresh.Top - 100) - lvUsers.Top
cmdKill.Top = cmdRefresh.Top
End Sub

Public Function DisplayName()
DisplayName = "Online Users"
End Function

Public Function AddUser(Nick As String) As ListItem
On Error Resume Next
Set AddUser = lvUsers.ListItems.Add(, Nick, Nick)
End Function

Public Function GetUser(Index As Variant) As ListItem
On Error Resume Next
Set GetUser = lvUsers.ListItems.Item(Index)
End Function

Public Function GetCount() As Integer
On Error Resume Next
GetCount = lvUsers.ListItems.Count
End Function

Public Sub SetSorted(Value As Boolean)
lvUsers.Sorted = Value
End Sub
