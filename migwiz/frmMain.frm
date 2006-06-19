VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "IRCXpro Migration Wizard"
   ClientHeight    =   4935
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
   ScaleHeight     =   4935
   ScaleWidth      =   8055
   StartUpPosition =   3  'Windows Default
   Begin VB.Frame fWelcome 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Welcome"
      ForeColor       =   &H00000000&
      Height          =   4095
      Left            =   0
      TabIndex        =   1
      Top             =   840
      Width           =   8055
      Begin VB.CommandButton cmdConvert 
         Caption         =   "&Convert"
         Default         =   -1  'True
         Height          =   375
         Left            =   6600
         TabIndex        =   11
         Top             =   3600
         Width           =   1335
      End
      Begin VB.TextBox txtIRCXpro 
         Height          =   285
         Left            =   1440
         TabIndex        =   10
         Text            =   "C:\Program Files\IRCXpro"
         Top             =   3120
         Width           =   6495
      End
      Begin VB.CheckBox cLLine 
         BackColor       =   &H00FFFFFF&
         Caption         =   "Server Links"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   120
         TabIndex        =   8
         Top             =   2160
         Value           =   1  'Checked
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.CheckBox cQLine 
         BackColor       =   &H00FFFFFF&
         Caption         =   "Illegal Nicknames"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   120
         TabIndex        =   6
         Top             =   1920
         Value           =   1  'Checked
         Width           =   1575
      End
      Begin VB.CheckBox cYLine 
         BackColor       =   &H00FFFFFF&
         Caption         =   "Client Connection Rules"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   120
         TabIndex        =   5
         Top             =   1680
         Value           =   1  'Checked
         Width           =   2055
      End
      Begin VB.CheckBox cOLine 
         BackColor       =   &H00FFFFFF&
         Caption         =   "IRC Operators"
         ForeColor       =   &H00000000&
         Height          =   255
         Left            =   120
         TabIndex        =   4
         Top             =   1440
         Value           =   1  'Checked
         Width           =   1455
      End
      Begin VB.Label Label5 
         BackStyle       =   0  'Transparent
         Caption         =   "Path to IRCXpro:"
         Height          =   255
         Left            =   120
         TabIndex        =   9
         Top             =   3120
         Width           =   1335
      End
      Begin VB.Label Label4 
         BackStyle       =   0  'Transparent
         Caption         =   $"frmMain.frx":2CFA
         Height          =   615
         Left            =   120
         TabIndex        =   7
         Top             =   2400
         Width           =   7815
      End
      Begin VB.Label Label3 
         BackStyle       =   0  'Transparent
         Caption         =   "This wizard is capable of importing the following things (check or uncheck as desired):"
         Height          =   255
         Left            =   120
         TabIndex        =   3
         Top             =   1200
         Width           =   7815
      End
      Begin VB.Label Label2 
         BackStyle       =   0  'Transparent
         Caption         =   $"frmMain.frx":2DE3
         Height          =   855
         Left            =   120
         TabIndex        =   2
         Top             =   240
         Width           =   7815
      End
   End
   Begin VB.Frame fConverting 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Converting"
      ForeColor       =   &H00000000&
      Height          =   4095
      Left            =   0
      TabIndex        =   12
      Top             =   840
      Visible         =   0   'False
      Width           =   8055
      Begin VB.TextBox txtConversion 
         BeginProperty Font 
            Name            =   "Courier New"
            Size            =   8.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   3495
         Left            =   120
         Locked          =   -1  'True
         MultiLine       =   -1  'True
         ScrollBars      =   2  'Vertical
         TabIndex        =   14
         Top             =   480
         Width           =   7815
      End
      Begin VB.Label Label6 
         BackStyle       =   0  'Transparent
         Caption         =   "Currently converting..."
         Height          =   255
         Left            =   120
         TabIndex        =   13
         Top             =   240
         Width           =   7815
      End
   End
   Begin VB.Label Label1 
      BackStyle       =   0  'Transparent
      Caption         =   "IRCXpro Migration Wizard"
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
   Begin VB.Image Image1 
      Height          =   720
      Left            =   0
      Picture         =   "frmMain.frx":2F88
      Top             =   60
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
Option Explicit
Private Declare Function GetPrivateProfileSectionNames Lib "kernel32.dll" Alias "GetPrivateProfileSectionNamesA" (ByVal lpszReturnBuffer As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function GetPrivateProfileSection Lib "kernel32" Alias "GetPrivateProfileSectionA" (ByVal lpAppName As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function GetPrivateProfileString Lib "kernel32" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function WritePrivateProfileString Lib "kernel32" Alias "WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpString As Any, ByVal lpFileName As String) As Long
Private Type IRCOper
  User As String
  Pass As String
  PassIRCXpro As String
  Privileges As Long
  Mask As String
  MaskCount As Long
End Type
Private Type YLine
  Class_Name As String
  ConnectionLimit As Long 'only thing that really goes in a Y: line
  PassIRCXpro As String
  Pass As String 'I: line item
  Mask As String 'Another I: line thing
  MaskCount As Long
End Type
Private Type QLine
  Mask As String
  Reason As String
End Type
Private Type LLine
  Pass As String
  PassIRCXpro As String
  Port As Long
  Server As String
End Type

Private IRCXpro_QLines() As QLine
Private IRCXpro_YLines() As YLine
Private IRCXpro_Opers() As IRCOper
Private IRCXconf_Template() As String

Private Sub cmdConvert_Click()
fWelcome.Visible = False
fConverting.Visible = True
AddText "Starting conversion process..."
If Dir(txtIRCXpro.Text & "\Settings.ini") = vbNullString Then
  MsgBox "We could not locate " & txtIRCXpro.Text & "\Settings.ini. If you included a trailing slash, please retry without it."
  End
End If
Dim IRCXpro_Version As String
Dim IRCXpro_File As String
Dim IRCXpro_CloneLimit As String
Dim IRCXpro_ChannelLimit As String
Dim IRCXpro_Description As String
Dim IRCXpro_ConnectionLimit As String
Dim IRCXpro_ContactInfo As String
Dim IRCXpro_ExtraInfo As String 'server location?
Dim IRCXpro_MinSecMsg As String 'floodcontrol Y: line
Dim IRCXpro_MaxBuffer As String 'max msgs in queue?
Dim IRCXpro_MaxWinsockBuffer As String 'SendQ
Dim IRCXpro_NickLength As String
Dim IRCXpro_Network As String
Dim IRCXpro_PingTimer As String
Dim IRCXpro_ServerName As String
Dim IRCXpro_ServerPorts As String

Dim OLine_Count As Long
Dim YLine_Count As Long
Dim QLine_Count As Long

Dim A As Long
Dim b As Long
Dim F As Long

IRCXpro_File = txtIRCXpro.Text & "\Settings.ini"
IRCXpro_Version = INIRead("Settings", "Version", IRCXpro_File, "")
AddText "Checking IRCXpro Version..."
AddText "Using IRCXpro Version " & IRCXpro_Version & "."
If IRCXpro_Version <> "1.1" Then
  MsgBox "You are using a version of IRCXpro other than 1.1. This wizard was designed for IRCXpro 1.1. This wizard may produce unpredictable results."
End If
'get regular settings!
AddText "Reading General Settings..."
IRCXpro_ChannelLimit = INIRead("Settings", "ChannelLimit", IRCXpro_File, ""): AddText "[-] ChannelLimit: " & IRCXpro_ChannelLimit
IRCXpro_CloneLimit = INIRead("Settings", "CloneLimit", IRCXpro_File, ""): AddText "[-] CloneLimit: " & IRCXpro_CloneLimit
IRCXpro_ConnectionLimit = INIRead("Settings", "ConnectionLimit", IRCXpro_File, ""): AddText "[-] ConnectionLimit: " & IRCXpro_ConnectionLimit
IRCXpro_ContactInfo = INIRead("Settings", "ContactInfo", IRCXpro_File, ""): AddText "[-] ContactInfo: " & IRCXpro_ContactInfo
IRCXpro_Description = INIRead("Settings", "Description", IRCXpro_File, ""): AddText "[-] Description: " & IRCXpro_Description
IRCXpro_ExtraInfo = INIRead("Settings", "ExtraInfo", IRCXpro_File, ""): AddText "[-] ExtraInfo: " & IRCXpro_ExtraInfo
IRCXpro_MinSecMsg = INIRead("Settings", "MinSecMsg", IRCXpro_File, ""): AddText "[-] MinSecMsg: " & IRCXpro_MinSecMsg
IRCXpro_MaxBuffer = INIRead("Settings", "MaxBuffer", IRCXpro_File, ""): AddText "[-] MaxBuffer: " & IRCXpro_MaxBuffer
IRCXpro_MaxWinsockBuffer = INIRead("Settings", "MaxWinsockBuffer", IRCXpro_File, ""): AddText "[-] MaxWinsockBuffer: " & IRCXpro_MaxWinsockBuffer
IRCXpro_NickLength = INIRead("Settings", "NickLength", IRCXpro_File, "0"): AddText "[-] NickLength: " & IRCXpro_NickLength
IRCXpro_Network = INIRead("Settings", "Network", IRCXpro_File, ""): AddText "[-] Network: " & IRCXpro_Network
IRCXpro_PingTimer = INIRead("Settings", "PingTimer", IRCXpro_File, ""): AddText "[-] PingTimer: " & IRCXpro_PingTimer
IRCXpro_ServerName = INIRead("Settings", "ServerName", IRCXpro_File, ""): AddText "[-] ServerName: " & IRCXpro_ServerName
IRCXpro_ServerPorts = INIRead("Settings", "ServerPorts", IRCXpro_File, ""): AddText "[-] ServerPorts: " & IRCXpro_ServerPorts
AddText "General Settings Read!"
If cOLine.Value = vbChecked Then
  AddText "Reading IRC Operators..."
  OLine_Count = CLng(INIRead("Lists", "OLineCount", IRCXpro_File, "0"))
  If OLine_Count > 0 Then
    AddText "[i] Importing " & OLine_Count & " IRC Operator(s)"
  Else
    AddText "[!] There are no IRC Operators!"
    GoTo StopReadingOpers
  End If
  
  ReDim IRCXpro_Opers(OLine_Count - 1) As IRCOper
  For A = 0 To OLine_Count - 1
    IRCXpro_Opers(A).User = INIRead("OLINE" & A + 1, "Operator", IRCXpro_File, "")
    If Len(IRCXpro_Opers(A).User) > 0 Then
      AddText "[-] Importing user '" & IRCXpro_Opers(A).User & "'"
    Else
      AddText "[!] There was an error importing operator number " & A + 1
      GoTo NextOLine
    End If
    IRCXpro_Opers(A).PassIRCXpro = INIRead("OLINE" & A + 1, "Password", IRCXpro_File, ""): AddText "    [-] Encoded Password: " & IRCXpro_Opers(A).PassIRCXpro
    IRCXpro_Opers(A).Pass = DecryptPass(IRCXpro_Opers(A).PassIRCXpro): AddText "    [-] Decoded Password: " & IRCXpro_Opers(A).Pass
    IRCXpro_Opers(A).MaskCount = CLng(INIRead("OLINE" & A + 1, "MaskCount", IRCXpro_File, "0"))
    If IRCXpro_Opers(A).MaskCount > 0 Then
      IRCXpro_Opers(A).Mask = INIRead("OLINE" & A + 1, "Mask1", IRCXpro_File, ""): AddText "    [-] Mask: " & IRCXpro_Opers(A).Mask
    Else
      IRCXpro_Opers(A).Mask = "*!*@*": AddText "    [-] Mask: " & IRCXpro_Opers(A).Mask
    End If
    IRCXpro_Opers(A).Privileges = CLng(INIRead("OLINE" & A + 1, "Privileges", IRCXpro_File, "0")): AddText "    [-] Privileges: " & IRCXpro_Opers(A).Privileges
NextOLine:
  Next A
  AddText "IRC Operators Read!"
StopReadingOpers:
End If
If cYLine.Value = vbChecked Then
  AddText "Reading Client Connection Rules..."
  YLine_Count = CLng(INIRead("Lists", "YLineCount", IRCXpro_File, "0"))
  If YLine_Count > 0 Then
    AddText "[i] Importing " & YLine_Count & " connection rule(s)"
  Else
    AddText "[!] There are no connection rules!"
    ReDim IRCXpro_YLines(0)
    IRCXpro_YLines(0).Class_Name = "Default"
    IRCXpro_YLines(0).ConnectionLimit = "0"
    IRCXpro_YLines(0).Mask = "*"
    IRCXpro_YLines(0).Pass = ""
    GoTo StopReadingYLines
  End If
  ReDim IRCXpro_YLines(YLine_Count - 1)
  For A = 0 To YLine_Count - 1
    IRCXpro_YLines(A).Class_Name = INIRead("YLINE" & A + 1, "Class", IRCXpro_File, "")
    If Len(IRCXpro_YLines(A).Class_Name) > 0 Then
      AddText "[-] Importing class '" & IRCXpro_YLines(A).Class_Name & "'"
    Else
      AddText "[-] Importing class number " & A + 1
    End If
    IRCXpro_YLines(A).ConnectionLimit = CLng(INIRead("YLINE" & A + 1, "ConnectionLimit", IRCXpro_File, "0")): AddText "    [-] ConnectionLimit: " & IRCXpro_YLines(A).ConnectionLimit
    IRCXpro_YLines(A).MaskCount = CLng(INIRead("YLINE" & A + 1, "MaskCount", IRCXpro_File, "0"))
    If IRCXpro_YLines(A).MaskCount > 0 Then
      IRCXpro_YLines(A).Mask = INIRead("YLINE" & A + 1, "Mask1", IRCXpro_File, ""): AddText "    [-] Mask: " & IRCXpro_YLines(A).Mask
    Else
      IRCXpro_YLines(A).Mask = "*@*": AddText "    [-] Mask: *@*"
    End If
    IRCXpro_YLines(A).PassIRCXpro = INIRead("YLINE" & A + 1, "Password", IRCXpro_File, ""): AddText "    [-] Encoded Password: " & IRCXpro_YLines(A).PassIRCXpro
    IRCXpro_YLines(A).Pass = DecryptPass(IRCXpro_YLines(A).PassIRCXpro): AddText "    [-] Decoded Password: " & IRCXpro_YLines(A).Pass
  Next A
  AddText "Client Connection Rules Read!"
StopReadingYLines:
End If
If cQLine.Value = vbChecked Then
  AddText "Reading Illegal Nicknames..."
  QLine_Count = CLng(INIRead("Lists", "QLineCount", IRCXpro_File, "0"))
  If QLine_Count > 0 Then
    AddText "[i] Importing " & QLine_Count & " illegal nickname(s)"
  Else
    AddText "[!] There are no illegal nicknames!"
    GoTo StopReadingQLines
  End If
  ReDim IRCXpro_QLines(QLine_Count - 1)
  For A = 0 To QLine_Count - 1
    IRCXpro_QLines(A).Mask = INIRead("QLINE" & A + 1, "Mask", IRCXpro_File, "")
    IRCXpro_QLines(A).Reason = INIRead("QLINE" & A + 1, "Reason", IRCXpro_File, "")
    If INIRead("QLINE" & A + 1, "Anywhere", IRCXpro_File, "") = "True" Then IRCXpro_QLines(A).Mask = "*" & IRCXpro_QLines(A).Mask & "*"
    IRCXpro_QLines(A).Mask = Replace(IRCXpro_QLines(A).Mask, "**", "*")
    AddText "[-] Imported mask '" & IRCXpro_QLines(A).Mask & "' with reason '" & IRCXpro_QLines(A).Reason & "'"
  Next A
  AddText "Illegal Nicknames Read!"
StopReadingQLines:
End If

'Links should be imported here, but since I currently can't accurately convert hostnames into IP addresses (dyndns)
'I'm going to pretend this feature doesn't exist :) (at least until I fix it in iS)
AddText "Importing completed."
AddText "Loading configuration template..."
F = FreeFile
If Dir(App.Path & "\migwiz.cftpl") = vbNullString Then
  MsgBox "The configuration template is missing! Please reinstall ignitionServer."
  End
End If
A = 0

Dim tmpString As String
Open App.Path & "\migwiz.cftpl" For Input As F
  Do
    ReDim Preserve IRCXconf_Template(A)
    Line Input #F, tmpString
    IRCXconf_Template(A) = tmpString
    A = A + 1
  Loop Until EOF(F)
Close #F
AddText "Configuration template loaded!"
AddText "Applying new settings to template..."
For A = 0 To UBound(IRCXconf_Template)
  If IRCXconf_Template(A) = "!insertmacro generator" Then
    IRCXconf_Template(A) = "# Generated by IRCXpro Migration Wizard v" & App.Major & "." & App.Minor & "." & App.Revision & vbCrLf & _
                           "# Configuration generated " & Now
  ElseIf IRCXconf_Template(A) = "!insertmacro m-line" Then
    'build the M: line
    If Len(IRCXpro_ServerName) = 0 Then IRCXpro_ServerName = "localhost"
    If Len(IRCXpro_Network) = 0 Then IRCXpro_Network = "Default Network"
    If Len(IRCXpro_Description) = 0 Then IRCXpro_Description = "IRCXpro - $300. Exchange - $1500. ignitionServer - Priceless." ' ^_^
    If Len(IRCXpro_ServerPorts) = 0 Then IRCXpro_ServerPorts = "6667"
    tmpString = "M:" & IRCXpro_ServerName & ":" & IRCXpro_ServerName & ":" & IRCXpro_Network & ":" & IRCXpro_Description & ":" & GetMainPort(IRCXpro_ServerPorts)
    Debug.Print tmpString
    IRCXconf_Template(A) = tmpString
  ElseIf IRCXconf_Template(A) = "!insertmacro a-line" Then
    'A:<ExtraInfo>:Your Name Here:<ContactInfo>
    If Len(IRCXpro_ExtraInfo) = 0 Then IRCXpro_ExtraInfo = "Your Location Here"
    If Len(IRCXpro_ContactInfo) = 0 Then IRCXpro_ContactInfo = "Your E-Mail Address Here"
    tmpString = "A:" & IRCXpro_ExtraInfo & ":Your Name Here:" & Replace(IRCXpro_ContactInfo, ":", "<$COLON$>")
    Debug.Print tmpString
    IRCXconf_Template(A) = tmpString
  ElseIf IRCXconf_Template(A) = "!insertmacro s-line" Then
    ' S:<MaxConn>:<MaxClones>:<MaxChans>:<NickLen>:<TopicLen>:<KickLen>:<PartLen>:<KeyLen>:<QuitLen>:<MaxWhoLen>:<MaxListLen>:<MaxMsgsInQueue>
    'IRCXpro lacks some of these features, so we can't accurately port them (use defaults instead)
    tmpString = "S:" & IRCXpro_ConnectionLimit & ":" & IRCXpro_CloneLimit & ":" & IRCXpro_ChannelLimit & ":" & IRCXpro_NickLength & ":150:150:150:10:150:200:0:" & IRCXpro_MaxBuffer
    Debug.Print tmpString
    IRCXconf_Template(A) = tmpString
  ElseIf IRCXconf_Template(A) = "!insertmacro y-line" Then
    'Y:<ID>:<PingCounter>:<FloodControl>:<MaxClients>:<SendQ>
    If cYLine.Value <> vbChecked Then
      IRCXconf_Template(A) = "# Y: Lines Not Imported!"
    Else
      If Len(IRCXpro_PingTimer) = 0 Then IRCXpro_PingTimer = "180"
      If Len(IRCXpro_MinSecMsg) = 0 Then IRCXpro_MinSecMsg = "0"
      If Len(IRCXpro_MaxWinsockBuffer) = 0 Then IRCXpro_MaxWinsockBuffer = "100000"
      IRCXconf_Template(A) = vbNullString
      For b = 0 To UBound(IRCXpro_YLines)
        tmpString = "Y:" & b + 1 & ":" & IRCXpro_PingTimer & ":" & IRCXpro_MinSecMsg & ":" & IRCXpro_YLines(b).ConnectionLimit & ":" & IRCXpro_MaxWinsockBuffer
        Debug.Print tmpString
        IRCXconf_Template(A) = IRCXconf_Template(A) & tmpString & vbCrLf
      Next b
      'now a Y: line for opers... ID: 1000 (nobody has THAT many connection classes ^_^)
      IRCXconf_Template(A) = IRCXconf_Template(A) & "Y:1000:180:0:100:1000000" & vbCrLf
    End If
  ElseIf IRCXconf_Template(A) = "!insertmacro i-line" Then
    'I:<IP Mask>:<Password>:<Hostmask>::<Connection Class>
    If cYLine.Value <> vbChecked Then
      IRCXconf_Template(A) = "# I: Lines Not Imported!"
    Else
      IRCXconf_Template(A) = vbNullString
      For b = 0 To UBound(IRCXpro_YLines)
        tmpString = ILineDemask(IRCXpro_YLines(b).Mask)
        If tmpString = "*" Then
          tmpString = "I:*:" & IRCXpro_YLines(b).Pass & ":*::" & b + 1
        Else
          tmpString = "I:NOMATCH:" & IRCXpro_YLines(b).Pass & ":" & tmpString & "::" & b + 1
        End If
        Debug.Print tmpString
        IRCXconf_Template(A) = tmpString & vbCrLf
      Next b
    End If
  ElseIf IRCXconf_Template(A) = "!insertmacro o-line" Then
    'O:<hostmask>:<password>:<username>:<operator flags>:<connection class>
    If cOLine.Value <> vbChecked Then
      IRCXconf_Template(A) = "# O: Lines Not Imported!"
    Else
      IRCXconf_Template(A) = vbNullString
      For b = 0 To UBound(IRCXpro_Opers)
        If Len(IRCXpro_Opers(b).User) > 0 Then
          'don't add users that were added for no real reason
          tmpString = OLineDemask(IRCXpro_Opers(b).Mask)
          tmpString = "O:" & tmpString & ":" & modMD5.oMD5.MD5(IRCXpro_Opers(b).Pass) & ":" & IRCXpro_Opers(b).User & ":" & MakeOperFlags(IRCXpro_Opers(b).Privileges) & ":1000"
          Debug.Print tmpString
          IRCXconf_Template(A) = IRCXconf_Template(A) & tmpString & vbCrLf
        End If
      Next b
    End If
  ElseIf IRCXconf_Template(A) = "!insertmacro k-line" Then
    IRCXconf_Template(A) = "# K: Lines Not Imported!"
  ElseIf IRCXconf_Template(A) = "!insertmacro v-line" Then
    IRCXconf_Template(A) = "# V: Lines Not Imported!"
  ElseIf IRCXconf_Template(A) = "!insertmacro q-line" Then
    If cQLine.Value <> vbChecked Then
      IRCXconf_Template(A) = "# Q: Lines Not Imported!"
    Else
      IRCXconf_Template(A) = vbNullString
      For b = 0 To UBound(IRCXpro_QLines)
        tmpString = "Q::" & Replace(IRCXpro_QLines(b).Reason, ":", "<$COLON$>") & ":" & IRCXpro_QLines(b).Mask
        Debug.Print tmpString
        IRCXconf_Template(A) = tmpString & vbCrLf
      Next b
    End If
  ElseIf IRCXconf_Template(A) = "!insertmacro z-line" Then
    IRCXconf_Template(A) = "# Z: Lines Not Imported!"
  ElseIf IRCXconf_Template(A) = "!insertmacro p-line" Then
    'really oughta do what IRCXpro's ServerPorts line says, but for now, ignore it.
    IRCXconf_Template(A) = "# P: Lines Not Imported!"
  ElseIf IRCXconf_Template(A) = "!insertmacro l-line" Then
    IRCXconf_Template(A) = "# L: Lines Not Imported!"
  End If
Next A
AddText "Settings applied to template."
AddText "Now saving to ircx.conf..."
F = FreeFile
Open App.Path & "\ircx.conf" For Output As F
For A = 0 To UBound(IRCXconf_Template)
  Print #F, IRCXconf_Template(A)
  Debug.Print IRCXconf_Template(A)
Next A
Close F
AddText "Done!"
MsgBox "The conversion process has completed. Please open ircx.conf and proceed to configuring ignitionServer, and make sure that your settings were properly transferred."
End Sub
Public Function MakeOperFlags(oLevel As Long) As String
Select Case oLevel
  Case 6
    MakeOperFlags = "NPs"
  Case 5
    MakeOperFlags = "OHPs"
  Case 4
    MakeOperFlags = "-OocekbBKPWHs"
  Case 3
    MakeOperFlags = "-OocekbBPWs"
  Case 2
    MakeOperFlags = "oPs"
  Case 1
    MakeOperFlags = "-os"
  Case Else
    MakeOperFlags = "-os"
End Select
End Function
Public Function OLineDemask(strMask As String) As String
Dim tmpArray() As String
Dim A As Long
Dim tmpMask As String
tmpMask = strMask
tmpArray = Split(tmpMask, "!")
If UBound(tmpArray) = 1 Then
  If tmpArray(1) = "*@*" Then
    OLineDemask = "*"
  Else
    OLineDemask = tmpArray(1)
  End If
Else
  OLineDemask = "*"
End If
End Function
Public Function ILineDemask(strMask As String) As String
Dim tmpArray() As String
Dim A As Long
Dim tmpMask As String
tmpMask = strMask
tmpArray = Split(tmpMask, "@")
If UBound(tmpArray) = 1 Then
  ILineDemask = tmpArray(1)
Else
  ILineDemask = tmpArray(0)
End If
End Function
Public Function GetMainPort(strPortString As String)
'this function returns what should go at the end of a M: line
'either it will be *:port or ip-address:port
Dim tmpArray() As String
Dim A As Long
Dim tmpPortString As String
tmpPortString = strPortString 'lets not pop on and off the stack here
tmpPortString = Replace(tmpPortString, ",", " ") 'we want spaces, not commas (should be updated to also include any other char IRCXpro may use if they update)
tmpArray = Split(tmpPortString, " ")
'only care about the first one, we have P: lines for everything else
If InStr(1, tmpArray(0), ":") Then
  'it contains a port, so we're going to assume that this port contains a bind-addr
  GetMainPort = tmpArray(0)
Else
  'no port, chug on
  GetMainPort = "*:" & tmpArray(0)
End If
End Function
Public Sub AddText(strText As String)
txtConversion.Text = txtConversion.Text & strText & vbCrLf
txtConversion.SelStart = Len(txtConversion.Text)
End Sub

Public Function ReadSections(ByVal Filename As String) As String()
  Dim szBuf As String, Length As Integer
  Dim SectionArr() As String, m As Integer
  szBuf = String$(255, 0)
  Length = GetPrivateProfileSectionNames(szBuf, 255, Filename)
  szBuf = Left$(szBuf, Length)
  SectionArr = Split(szBuf, vbNullChar)
  ReadSections = SectionArr
End Function
Public Function INIRead(ByVal Section As String, ByVal Key As String, ByVal file As String, Optional ByVal default As String) As String
Dim lngResult As Long
Dim strResult As String
If Len(Trim(default)) = 0 Then default = vbNullString
strResult = Space(255)
'strResult = Space(32767)
lngResult = GetPrivateProfileString(Section, Key, default, strResult, 255, file)
'lngResult = GetPrivateProfileString(Section, Key, default, strResult, 32767, file)
INIRead = Replace(Trim(strResult), vbNullChar, vbNullString)
End Function

Public Sub IniWrite(ByVal Section As String, ByVal Key As String, ByVal Value As String, ByVal file As String)
Dim lngResult As String
lngResult = WritePrivateProfileString(Section, Key, Value, file)
End Sub

Public Function DecryptPass(strPass As String) As String
Dim Decrypt_Len As Long
Dim Decrypt_Array() As String
Dim Decrypt_Long() As Long
Dim Decrypt_Long_Real() As Long
Dim Decrypted_Password As String
Dim A As Long
Dim b As Long

If Len(strPass) = 0 Then Exit Function

Decrypt_Len = Len(strPass) / 2 'the length of the decrypted password
Debug.Print "Decrypting a " & Decrypt_Len & " letter long password"
'take the password and put it in an array
For A = 0 To Decrypt_Len - 1
  ReDim Preserve Decrypt_Array(A)
  Decrypt_Array(A) = "&H" & Mid$(strPass, (A * 2) + 1, 2)
  Debug.Print "Decrypt_Array(" & A & "): " & Decrypt_Array(A)
Next A
'now take that array and turn it into a long
For A = LBound(Decrypt_Array) To UBound(Decrypt_Array)
  ReDim Preserve Decrypt_Long(A)
  Decrypt_Long(A) = Val(Decrypt_Array(A))
  Debug.Print "Decrypt_Long(" & A & "): " & Decrypt_Long(A)
Next A
'now we have an array that's a long of the IRCXpro password
'we now need to take this and shift it up the right number of characters
A = 0 'starting array position
b = 2 'starting shift number
While A <= UBound(Decrypt_Long)
  ReDim Preserve Decrypt_Long_Real(A)
  Decrypt_Long_Real(A) = Decrypt_Long(A) + b
  Debug.Print "Decrypt_Long_Real(" & A & "): " & Decrypt_Long_Real(A)
  A = A + 1
  b = b - 1
  If b = -1 Then b = 5
Wend
'we should now have a valid password stored as Long in Decrypt_Long_Real
'build the output and get the hell out of here :)
Decrypted_Password = vbNullString
For A = 0 To UBound(Decrypt_Long_Real)
  Decrypted_Password = Decrypted_Password & Chr(Decrypt_Long_Real(A))
Next A
DecryptPass = Decrypted_Password
End Function
