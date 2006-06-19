VERSION 5.00
Begin VB.Form frmAbout 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "About VBTracer (for ignitionServer)"
   ClientHeight    =   3420
   ClientLeft      =   3660
   ClientTop       =   4275
   ClientWidth     =   5505
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3420
   ScaleWidth      =   5505
   ShowInTaskbar   =   0   'False
   Begin VB.CommandButton cmdOK 
      Caption         =   "OK"
      Height          =   435
      Left            =   4060
      TabIndex        =   5
      Top             =   2880
      Width           =   1395
   End
   Begin VB.Label lblInfo 
      Caption         =   "http://www.ignition-project.com/"
      Height          =   195
      Index           =   7
      Left            =   540
      TabIndex        =   8
      Top             =   2280
      Width           =   4935
   End
   Begin VB.Label lblInfo 
      Caption         =   "http://www.vbaccelerator.com/"
      Height          =   195
      Index           =   6
      Left            =   540
      TabIndex        =   7
      Top             =   2520
      Width           =   4935
   End
   Begin VB.Label lblInfo 
      BackColor       =   &H80000010&
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   30
      Index           =   5
      Left            =   540
      TabIndex        =   6
      Top             =   2760
      Width           =   5055
   End
   Begin VB.Label lblInfo 
      Caption         =   "Copyright"
      Height          =   255
      Index           =   4
      Left            =   600
      TabIndex        =   4
      Top             =   1380
      Width           =   4935
   End
   Begin VB.Label lblInfo 
      Caption         =   "Version "
      Height          =   255
      Index           =   3
      Left            =   600
      TabIndex        =   3
      Top             =   1020
      Width           =   4935
   End
   Begin VB.Label lblInfo 
      Caption         =   "vbAccelerator VBTracer Utility (for ignitionServer)"
      Height          =   255
      Index           =   2
      Left            =   600
      TabIndex        =   2
      Top             =   660
      Width           =   4935
   End
   Begin VB.Label lblInfo 
      BackColor       =   &H80000010&
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   135
      Index           =   1
      Left            =   0
      TabIndex        =   1
      Top             =   360
      Width           =   5535
   End
   Begin VB.Image imgIcon 
      Height          =   240
      Left            =   120
      Picture         =   "frmAbout.frx":0000
      Top             =   60
      Width           =   240
   End
   Begin VB.Label lblInfo 
      BackColor       =   &H80000015&
      Caption         =   "       VBTracer (for ignitionServer)"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   12
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H8000000F&
      Height          =   375
      Index           =   0
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   5535
   End
End
Attribute VB_Name = "frmAbout"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub cmdOK_Click()
   Unload Me
End Sub

Private Sub Form_Load()
   lblInfo(3).Caption = lblInfo(3).Caption & " " & App.Major & "." & App.Minor & " (Build " & App.Revision & ")"
   lblInfo(4).Caption = App.LegalCopyright
End Sub
