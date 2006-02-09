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
' $Id: modMain.bas,v 1.5 2004/09/12 04:00:56 ziggythehamster Exp $
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
Public ISPort As Long
Public Sockets As clsSox
Public AppVersion As String
Public StartIS As Boolean: Public StopIS As Boolean: Public RestartIS As Boolean
Public RehashIS As Boolean


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
' *  -restart : restart the server     *
' *  -rehash  : rehash the server      *
' *  -p nnnn  : set server port        *
' **************************************
' * PLANNED PARAMETERS                 *
' *  -motd    : rehash the motd        *
' *  -gc      : garbage collection     *
' **************************************/

InternalDebug "Processing parameters..."
ISPort = 6667
Set Sockets = New clsSox

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
    Sockets.Protocol = sckTCPProtocol
    Sockets.RemoteHost = "127.0.0.1"
    Sockets.Connect "127.0.0.1", ISPort
    StartIS = False
    StopIS = True
    RestartIS = False
    RehashIS = False
  ElseIf LCase$(Left$(Parameters(A), 8)) = "-restart" Then
    InternalDebug "Restarting ignitionServer..."
    Sockets.Protocol = sckTCPProtocol
    Sockets.RemoteHost = "127.0.0.1"
    Sockets.Connect "127.0.0.1", ISPort
    StartIS = False
    StopIS = False
    RehashIS = False
    RestartIS = True
  ElseIf LCase$(Left$(Parameters(A), 7)) = "-rehash" Then
    InternalDebug "Rehashing ignitionServer..."
    Sockets.Protocol = sckTCPProtocol
    Sockets.RemoteHost = "127.0.0.1"
    Sockets.Connect "127.0.0.1", ISPort
    StartIS = False
    StopIS = False
    RehashIS = True
    RestartIS = False
  End If
Next A
End Sub
Public Sub Terminate()
InternalDebug "Terminating..."
On Error Resume Next
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
