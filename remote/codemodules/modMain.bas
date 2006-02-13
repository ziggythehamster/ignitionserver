Attribute VB_Name = "modMain"
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
' $Id: modMain.bas,v 1.2 2004/12/27 02:26:42 ziggythehamster Exp $
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


Public ServerAddress As String
Public Nick As String
Public User As String
Public Pass As String
Public StatusText As String
Public StatsText As String
Public tmpStatsText As String
Public BandwidthUsage As Currency

Sub Main()
DebugLog "**** STARTUP [" & Now & "]"
frmMain.Show
End Sub

Public Sub DebugLog(strText As String)
On Error Resume Next
Debug.Print strText
Open App.Path & "\debug.txt" For Append As 1
Print #1, strText
Close #1
End Sub
