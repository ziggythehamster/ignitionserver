Attribute VB_Name = "modMain"
'ignitionServer Command Line Controller is (C) Keith Gable
'---------------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'
' $Id: modMain.bas,v 1.3 2004/06/29 19:15:28 ziggythehamster Exp $
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


Option Explicit
Public Declare Function SetTimer Lib "user32" (ByVal hWnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
Public Declare Function KillTimer Lib "user32" (ByVal hWnd As Long, ByVal nIDEvent As Long) As Long
Public Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Public Declare Function Send Lib "wsock32.dll" Alias "send" (ByVal s As Long, buf As Any, ByVal buflen As Long, ByVal flags As Long) As Long
Public Declare Function GetTickCount& Lib "kernel32" ()
Private Bye As Boolean
Public StartIS As Boolean
Public StopIS As Boolean
Public ISPort As Integer
Public AppVersion As String
Public Sockets As clsSox
Public Portal As typPortal
Public Type typPortal 'Class specific variables
    hWnd As Long 'The handle to the window we create on initialization that will receive WinSock messages
    WndProc As Long 'Pointer to the origional WindowProc of our window (We need to give control of ALL messages back to it before we destroy it)
    Sockets As Long 'How many Sockets are comming through the Portal, Actually hold the Socket array count. NB - MUST change with Redim of Sockets
End Type
Public CanKill As Boolean
Public mySocketHandle As Long
Public myInSox As Long


Public Sub Main()
On Error Resume Next
'probably better off letting this happen?
'If App.PrevInstance = True Then End
AppVersion = App.Major & "." & App.Minor & "." & App.Revision
Dim Parameters() As String
Dim A As Long
Parameters() = Split(Command, " ")

'/**************************************
' * COMMAND LINE PARAMETERS            *
' *  -start   : start the server       *
' *  -stop    : stop the server        *
' *  -p nnnn  : set server port        *
' **************************************
' * PLANNED PARAMETERS                 *
' *  -restart : restart the server     *
' *  -rehash  : rehash the server      *
' *  -motd    : rehash the motd        *
' *  -gc      : garbage collection     *
' **************************************/

InternalDebug "Processing parameters..."
ISPort = 6667

For A = LBound(Parameters) To UBound(Parameters)
  If LCase$(Left$(Parameters(A), 2)) = "-p" Then
    InternalDebug "Port specified..."
    'specifying a port
    ISPort = CInt(Parameters(A + 1))
  ElseIf LCase$(Left$(Parameters(A), 6)) = "-start" Then
    InternalDebug "Starting ignitionServer..."
    Call Shell(App.Path & "\ignitionServer.exe")
    End
    StartIS = True
    StopIS = False
  ElseIf LCase$(Left$(Parameters(A), 5)) = "-stop" Then
    InternalDebug "Stopping ignitionServer..."
    Set Sockets = New clsSox
    Sockets.Connect "127.0.0.1", ISPort
    StartIS = False
    StopIS = True
  End If
Next A

If StopIS = True Then
Do: DoEvents: Sleep 100: Loop Until CanKill = True
Sockets.TerminateSocket mySocketHandle
Terminate
End If
End Sub
Public Sub Terminate()
InternalDebug "Terminating..."
On Error Resume Next
Sockets.Unhook
'Destroy the core classes -Dill
Set Sockets = Nothing
InternalDebug "Terminated..."
End
End Sub
Public Sub InternalDebug(strDebug As String)
On Error Resume Next
Dim F As Long
F = FreeFile
Open App.Path & "\control.log" For Append As F
Print #F, "[" & Now & "] " & strDebug
Close #F
End Sub
