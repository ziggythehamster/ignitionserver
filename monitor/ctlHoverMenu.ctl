VERSION 5.00
Begin VB.UserControl ctlHoverMenu 
   BackColor       =   &H00FFFFFF&
   ClientHeight    =   270
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4800
   ScaleHeight     =   270
   ScaleWidth      =   4800
   Begin VB.Timer timHover 
      Interval        =   1
      Left            =   4440
      Top             =   0
   End
   Begin VB.Label lblText 
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   255
      Left            =   0
      MouseIcon       =   "ctlHoverMenu.ctx":0000
      TabIndex        =   0
      Top             =   0
      Width           =   4695
   End
End
Attribute VB_Name = "ctlHoverMenu"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
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
' $Id: ctlHoverMenu.ctl,v 1.2 2004/06/29 00:22:30 ziggythehamster Exp $
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
Private Declare Function WindowFromPoint Lib "user32" (ByVal xPoint As Long, ByVal yPoint As Long) As Long
Private Declare Function GetCursorPos Lib "user32" (lpPoint As POINTAPI) As Long
Private TheText As String
Event Click()

Private Sub lblText_Click()
On Error Resume Next
RaiseEvent Click
End Sub

Private Sub lblText_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
On Error Resume Next
timHover.Enabled = True
lblText.FontUnderline = True
lblText.ForeColor = vbBlue
lblText.MousePointer = 99
End Sub

Private Sub timHover_Timer()
On Error Resume Next
Dim pt As POINTAPI
GetCursorPos pt
If UserControl.hwnd <> WindowFromPoint(pt.X, pt.Y) Then
    timHover.Enabled = False
    lblText.FontUnderline = False
    lblText.ForeColor = vbBlack
    lblText.MousePointer = 0
End If
End Sub

Public Property Get Caption() As String
On Error Resume Next
Caption = TheText
End Property

Public Property Let Caption(ByVal NewValue As String)
On Error Resume Next
TheText = NewValue
lblText.Caption = TheText
PropertyChanged "Caption"
End Property

Private Sub UserControl_Initialize()
On Error Resume Next
timHover.Enabled = False
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
On Error Resume Next
With PropBag
  TheText = .ReadProperty("Caption", "")
End With
lblText.Caption = TheText
End Sub

Private Sub UserControl_Resize()
On Error Resume Next
lblText.Left = 0
lblText.Top = 0
lblText.Height = ScaleHeight
lblText.Width = ScaleWidth
End Sub

Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
On Error Resume Next
With PropBag
  Call .WriteProperty("Caption", TheText, "")
End With
lblText.Caption = TheText
End Sub
